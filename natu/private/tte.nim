## Tonc Text Engine
## ================
## As of v1.3, Tonc has a completely new way of handling text. It can
##  handle (practically) all modes, VRAM types and font sizes and brings
##  them together under a unified interface. It uses function pointers to
##  store *drawg* and *erase* functions of each rendering family. The
##  families currently supported are:
##
## - `ase`: Affine screen entries (Affine tiled BG)
## - `bmp8`: 8bpp bitmaps (Mode 4)
## - `bmp16`: 16bpp bitmaps (Mode 3/5)
## - `chr4c`: 4bpp characters, column-major (Regular tiled BG)
## - `chr4r`: 4bpp characters, row-major (Regular tiled BG)
## - `obj`: Objects
## - `se`: Regular screen entries (Regular tiled BG)
##
## Each of these consists of an initializer, `tte_init_foo`, and
##  one or more glyph rendering functions, `foo_puts_bar`, The `bar`
##  part of the renderer denotes the style of the particular renderer,
##  which can indicate:
##
##  - Expected bitdepth of font data (`b1` for 1bpp, etc)
##  - Expected sizes of the character (`w8` and `h8`, for example).
##  - Application of system colors (`c`).
##  - Transparent or opaque background pixels (`t` or `o`).
##  - Whether the font-data is in 'strip' layout (`s` )
##
## The included renderers here are usually transparent,
##  recolored, using 1bpp strip glyphs (`_b1cts` ). The initializer
##  takes a bunch of options specific to each family, as well as font
##  and renderer pointers. You can provide your own font and renderers,
##  provided they're formatted correcty. For the default font/renderers,
##  use `NULL`.
##
## After the calling the initializer, you can write utf-8 encoded text
##  with tte_write() or tte_write_ex(). You can also enable stdio-related
##  functions by calling tte_init_con().
##
##  The system also supposed rudimentary scripting for positions, colors,
##  margins and erases. See tte_cmd_default() and con_cmd_parse() for
##  details.

import common
import types, surface, reg, math

{.compile(toncPath & "/src/font/sys8.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana10.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9_b4.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9b.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9i.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9.s", toncAsmFlags).}
{.compile(toncPath & "/src/tte/ase_drawg.c", toncCFlags).}
{.compile(toncPath & "/src/tte/bmp16_drawg_b1cs.c", toncCFlags).}
{.compile(toncPath & "/src/tte/bmp16_drawg.c", toncCFlags).}
{.compile(toncPath & "/src/tte/bmp8_drawg_b1cs.c", toncCFlags).}
{.compile(toncPath & "/src/tte/bmp8_drawg_b1cts_fast.s", toncAsmFlags).}
{.compile(toncPath & "/src/tte/bmp8_drawg.c", toncCFlags).}
{.compile(toncPath & "/src/tte/chr4c_drawg_b1cts.c", toncCFlags).}
{.compile(toncPath & "/src/tte/chr4c_drawg_b1cts_fast.s", toncAsmFlags).}
{.compile(toncPath & "/src/tte/chr4c_drawg_b4cts.c", toncCFlags).}
{.compile(toncPath & "/src/tte/chr4c_drawg_b4cts_fast.s", toncAsmFlags).}
{.compile(toncPath & "/src/tte/chr4r_drawg_b1cts.c", toncCFlags).}
{.compile(toncPath & "/src/tte/chr4r_drawg_b1cts_fast.s", toncAsmFlags).}
{.compile(toncPath & "/src/tte/obj_drawg.c", toncCFlags).}
{.compile(toncPath & "/src/tte/se_drawg.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_init_ase.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_init_bmp.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_init_chr4c.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_init_chr4r.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_init_obj.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_init_se.c", toncCFlags).}
# {.compile(toncPath & "/src/tte/tte_iohook.c", toncCFlags).}  # Natu doesn't support stdio.
{.compile(toncPath & "/src/tte/tte_main.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_types.s", toncAsmFlags).}


# Constants
# ---------

const
  TTE_TAB_WIDTH* = 24
  
const
  TTE_INK* = 0
  TTE_SHADOW* = 1
  TTE_PAPER* = 2
  TTE_SPECIAL* = 3

# Types
# -----

type
  FnDrawg* = proc (gid: uint) {.nimcall.}
    ## Glyph render function format.
  FnErase* = proc (left, top, right, bottom: int) {.nimcall.}
    ## Erase rectangle function format.
  
  Font* = ptr FontObj
  FontObj* {.importc: "TFont", header: "tonc.h", bycopy.} = object
    ## Font description struct.
    ## The `FontObj` contains a description of the font, including pointers
    ##  to the glyph data and width data (for VWF fonts), an ascii-offset
    ##  for when the first glyph isn't for ascii-null (which is likely.
    ##  Usually it starts at ' ' (32)).
    ##
    ##  The font-bitmap is a stack of cells, each containing one glyph
    ##  each. The cells and characters need not be the same size, but
    ##  the character glyph must fit within the cell.
    ##
    ##  The formatting of the glyphs themselves should fit the rendering
    ##  procedure. The default renderers use 1bpp 8x8 tiled graphics,
    ##  where for multi-tiled cells the tiles are in a *vertical*
    ##  'strip' format. In a 16x16 cell, the 4 tiles would be arranged as:
    ##  +---+---+
    ##  | 0 | 2 |
    ##  +---+---+
    ##  | 1 | 3 |
    ##  +---+---+
    data* {.importc: "data".}: pointer            ## Character data.
    widths* {.importc: "widths".}: ptr uint8      ## Width table for variable width font.
    heights* {.importc: "heights".}: ptr uint8    ## Height table for variable height font.
    charOffset* {.importc: "charOffset".}: uint16 ## Character offset
    charCount* {.importc: "charCount".}: uint16   ## Number of characters in font.
    charW* {.importc: "charW".}: uint8            ## Character width (fwf).
    charH* {.importc: "charH".}: uint8            ## Character height.
    cellW* {.importc: "cellW".}: uint8            ## Glyph cell width.
    cellH* {.importc: "cellH".}: uint8            ## Glyph cell height.
    cellSize* {.importc: "cellSize".}: uint16     ## Cell-size (bytes).
    bpp* {.importc: "bpp".}: uint8                ## Font bitdepth;
    extra* {.importc: "extra".}: uint8            ## Padding. Free to use.
  
  TextContext* = ptr TextContextObj
  TextContextObj* {.importc: "TTC", header: "tonc.h", bycopy.} = object
    ## TTE context struct.
    
    # Members for renderers
    dst* {.importc: "dst".}: Surface              ## Destination surface.
    cursorX* {.importc: "cursorX".}: int16        ## Cursor X-coord.
    cursorY* {.importc: "cursorY".}: int16        ## Cursor Y-coord.
    font* {.importc: "font".}: Font          ## Current font.
    charLut* {.importc: "charLut".}: ptr uint8    ## Character mapping lut. (if any).
    cattr* {.importc: "cattr".}: array[4, uint16] ## ink, shadow, paper and special color attributes.
    
    # Higher-up members
    flags0* {.importc: "flags0".}: uint16
    ctrl* {.importc: "ctrl".}: uint16             ## BG control flags
    marginLeft* {.importc: "marginLeft".}: uint16
    marginTop* {.importc: "marginTop".}: uint16
    marginRight* {.importc: "marginRight".}: uint16
    marginBottom* {.importc: "marginBottom".}: uint16
    savedX* {.importc: "savedX".}: int16
    savedY* {.importc: "savedY".}: int16
    
    # Callbacks and table pointers
    drawgProc* {.importc: "drawgProc".}: FnDrawg          ## Glyph render procedure.
    eraseProc* {.importc: "eraseProc".}: FnErase          ## Text eraser procedure.
    fontTable* {.importc: "fontTable".}: ptr Font         ## Pointer to font table for `f`.
    stringTable* {.importc: "stringTable".}: cstringArray ## Pointer to string table for `s`.


# Internal Fonts
# --------------

var sys8Font* {.importc: "sys8Font", header: "tonc.h".}: FontObj              ## System font. FWF 8x8\@1.
var verdana9Font* {.importc: "verdana9Font", header: "tonc.h".}: FontObj      ## Verdana 9. VWF 8x12\@1.
var verdana9bFont* {.importc: "verdana9bFont", header: "tonc.h".}: FontObj    ## Verdana 9 bold. VWF 8x12\@1.
var verdana9iFont* {.importc: "verdana9iFont", header: "tonc.h".}: FontObj    ## Verdana 9 italic. VWF 8x12\@1.
var verdana10Font* {.importc: "verdana10Font", header: "tonc.h".}: FontObj    ## Verdana 10. VWF 6x14\@1.
var verdana9b4Font* {.importc: "verdana9_b4Font", header: "tonc.h".}: FontObj ## Verdana 9. VWF 8x12@4.

# Default fonts
var fwfDefault* {.importc: "fwf_default", header: "tonc.h".}: FontObj  ## sys8
var vwfDefault* {.importc: "vwf_default", header: "tonc.h".}: FontObj  ## verdana9i

# Default Initializers
# --------------------

template tteInitSeDefault*(bgnr:int, bgcnt: BgCnt) =
  tteInitSe(bgnr, bgcnt, 0xF000, clrYellow.uint32, 0, addr(fwfDefault), nil)

template tteInitAseDefault*(bgnr:int, bgcnt: BgCnt) =
  tteInitAse(bgnr, bgcnt, 0x0000, clrYellow.uint32, 0, addr(fwfDefault), nil)

template tteInitChr4cDefault*(bgnr:int, bgcnt: BgCnt) =
  tteInitChr4c(bgnr, bgcnt, 0xF000, 0x0201, (clrOrange.uint32 shl 16) or (clrYellow.uint32), addr(vwfDefault), nil)

template tteInitChr4rDefault*(bgnr:int, bgcnt: BgCnt) =
  tteInitChr4r(bgnr, bgcnt, 0xF000, 0x0201, (clrOrange.uint32 shl 16) or (clrYellow.uint32), addr(vwfDefault), nil)

template tteInitChr4cb4Default*(bgnr:int, bgcnt: BgCnt) =
  tteInitChr4c(bgnr, bgcnt, 0xF000, 0x0201, (clrOrange.uint32 shl 16) or (clrYellow.uint32), addr(verdana9_b4Font), chr4cDrawg_b4cts)

template tteInitBmpDefault*(mode: int) =
  tteInitBmp(mode, addr(vwfDefault), nil)

template tteInitObjDefault*(pObj: ObjAttrPtr) =
  tteInitObj(pObj, 0, 0, 0xF000, clrYellow.uint32, 0, addr(fwfDefault), nil)

# Operations
# ----------
# This covers most of the things you can actually use TTE for,
# like writing the text, getting information about a glyph and setting
# color attributes.

proc tteSetContext*(tc: TextContext) {.importc: "tte_set_context", header: "tonc.h".}
  ## Set the master context pointer.
proc tteGetContext*(): TextContext {.importc: "tte_get_context", header: "tonc.h".}
  ## Get the master context pointer.
proc tteGetGlyphId*(ch: int): uint {.importc: "tte_get_glyph_id", header: "tonc.h".}
  ## Get the glyph index of character `ch`.
proc tteGetGlyphWidth*(gid: uint): int {.importc: "tte_get_glyph_width", header: "tonc.h".}
  ## Get the width of glyph `id`.
proc tteGetGlyphHeight*(gid: uint): int {.importc: "tte_get_glyph_height", header: "tonc.h".}
  ## Get the height of glyph `id`.
proc tteGetGlyphData*(gid: uint): pointer {.importc: "tte_get_glyph_data", header: "tonc.h".}
  ## Get the glyph data of glyph `id`.
proc tteSetColor*(typ: uint; clr: uint16) {.importc: "tte_set_color", header: "tonc.h".}
  ## Set color of `type` to `cattr`.
proc tteSetColors*(colors: ptr uint16) {.importc: "tte_set_colors", header: "tonc.h".}
  ## Load important color data.
proc tteSetColorAttr*(typ: uint; cattr: uint16) {.importc: "tte_set_color_attr", header: "tonc.h".}
  ## Set color attribute of `type` to `cattr`.
proc tteSetColorAttrs*(cattrs: ptr uint16) {.importc: "tte_set_color_attrs", header: "tonc.h".}
  ## Load important color attribute data.
proc tteCmdDefault*(str: cstring): cstring {.importc: "tte_cmd_default", header: "tonc.h".}
  ## Text command handler.
  ## Takes commands formatted as "#{[cmd]:[opt];[[cmd]:[opt];...]} and deals with them.
  ## Command list:
  ## - ``P``             Set cursor to margin top-left.
  ## - ``Ps``            Save cursor position
  ## - ``Pr``            Restore cursor position.
  ## - ``P:#x,#y``       Set cursorX/Y to `x`, `y`.
  ## - ``X``             Set cursorX to margin left.
  ## - ``X:#x``          Set cursorX to `x`.
  ## - ``Y``             Set cursorY to margin top.
  ## - ``Y:#y``          Set cursorX to `y`.
  ## - ``c[ispx]:#val``  Set ink/shadow/paper/special color to `val`.
  ## - ``e[slbfr]``      Erase screen/line/backward/forward/rect
  ## - ``m:#l,#t,#r,#b`` Set all margins
  ## - ``m[ltrb]:#val``  Set margin to `val`.
  ## - ``p:#x,#y``       Move cursorX/Y by `x`, `y`.
  ## - ``w:#val``        Wait `val` frames.
  ## - ``x:#x``          Move cursorX by `x`.
  ## - ``y:#y``          Move cursorX by `y`.
  ##  
  ## Examples:
  ## - ``#{X:32}``        Move to `x` = 32;
  ## - ``#{ci:0x7FFF}``   Set ink color to white.
  ## - ``#{w:120;es;P}``  Wait 120 frames, clear screen, return to top of screen.
  ##
  ## Arguments:
  ## `str` Start of command. Assumes the initial "\{" is lobbed off already.
  ## Returns: pointer to after the parsed command.
  ## Note: Routine does text wrapping. Make sure margins are set.

proc ttePutc*(ch: int|char): int {.importc: "tte_putc", header: "tonc.h", discardable.}
  ## Plot a single character; does wrapping too.
  ## `ch` Character to plot (not glyph-id).
  ## Returns: Character width.
  ## Note: Overhead: ~70 cycles.

proc tteWrite*(text: cstring): int {.importc: "tte_write", header: "tonc.h", discardable.}
  ## Render a string.
  ## `text` String to parse and write.
  ## Returns: Number of parsed characters.

proc tteWriteEx*(x: int; y: int; text: cstring; clrlut: ptr uint16): int {.importc: "tte_write_ex", header: "tonc.h", discardable.}
  ## Extended string writer, with positional and color info

proc tteEraseRect*(left: int; top: int; right: int; bottom: int) {.importc: "tte_erase_rect", header: "tonc.h".}
  ## Erase a porttion of the screen (ignores margins)

proc tteEraseScreen*() {.importc: "tte_erase_screen", header: "tonc.h".}
  ## Erase the screen (within the margins).

proc tteEraseLine*() {.importc: "tte_erase_line", header: "tonc.h".}
  ## Erase the whole line (within the margins).

proc tteGetTextSize*(str: cstring): Point16 {.importc: "tte_get_text_size", header: "tonc.h".}
  ## Get the size taken up by a string.
  ## `str` String to check.
  ## Returns: width and height, packed into a POINT16.
  ## Note: This function *ignores* tte commands, so don't use on strings that use commands.

proc tteInitBase*(font: Font; drawProc: FnDrawg; eraseProc: FnErase) {.importc: "tte_init_base", header: "tonc.h".}

# Text Attribute Functions
# ------------------------

# Getters:

proc tteGetPos*(x, y: var int) {.importc: "tte_get_pos", header: "tonc.h".}
  ## Get cursor position (mutates parameters)
proc tteGetPos*(): Vec2i {.noinit.} = tteGetPos(result.x, result.y)
  ## Get cursor position as vector
proc tteGetInk*(): uint16 {.importc: "tte_get_ink", header: "tonc.h".}
  ## Get ink color attribute.
proc tteGetShadow*(): uint16 {.importc: "tte_get_shadow", header: "tonc.h".}
  ## Get shadow color attribute.
proc tteGetPaper*(): uint16 {.importc: "tte_get_paper", header: "tonc.h".}
  ## Get paper color attribute.
proc tteGetSpecial*(): uint16 {.importc: "tte_get_special", header: "tonc.h".}
  ## Get special color attribute.
proc tteGetSurface*(): SurfacePtr {.importc: "tte_get_surface", header: "tonc.h".}
  ## Get a pointer to the text surface.
proc tteGetFont*(): Font {.importc: "tte_get_font", header: "tonc.h".}
  ## Get the active font
proc tteGetDrawg*(): FnDrawg {.importc: "tte_get_drawg", header: "tonc.h".}
  ## Get the active character plotter
proc tteGetErase*(): FnErase {.importc: "tte_get_erase", header: "tonc.h".}
  ## Get the erase function
proc tteGetStringTable*(): cstringArray {.importc: "tte_get_string_table", header: "tonc.h".}
  ## Get string table
proc tteGetFontTable*(): ptr Font {.importc: "tte_get_font_table", header: "tonc.h".}
  ## Get font table

# Setters:

proc tteSetPos*(x, y: int) {.importc: "tte_set_pos", header: "tonc.h".}
  ## Set cursor position
proc tteSetInk*(cattr: uint16) {.importc: "tte_set_ink", header: "tonc.h".}
  ## Set ink color attribute.
proc tteSetShadow*(cattr: uint16) {.importc: "tte_set_shadow", header: "tonc.h".}
  ## Set shadow color attribute.
proc tteSetPaper*(cattr: uint16) {.importc: "tte_set_paper", header: "tonc.h".}
  ## Set paper color attribute.
proc tteSetSpecial*(cattr: uint16) {.importc: "tte_set_special", header: "tonc.h".}
  ## Set special color attribute.
proc tteSetSurface*(srf: SurfacePtr) {.importc: "tte_set_surface", header: "tonc.h".}
  ## Set the text surface.
proc tteSetFont*(font: Font) {.importc: "tte_set_font", header: "tonc.h".}
  ## Set the font
proc tteSetDrawg*(fn: FnDrawg = nil) {.importc: "tte_set_drawg", header: "tonc.h".}
  ## Set the character plotter
proc tteSetErase*(fn: FnErase) {.importc: "tte_set_erase", header: "tonc.h".}
  ## Set the erase function
proc tteSetStringTable*(table: ptr cstring) {.importc: "tte_set_string_table", header: "tonc.h".}
  ## Set string table
proc tteSetFontTable*(table: ptr Font) {.importc: "tte_set_font_table", header: "tonc.h".}
  ## Set font table
proc tteSetMargins*(left: int; top: int; right: int; bottom: int) {.importc: "tte_set_margins", header: "tonc.h".}

# Console Functions
# -----------------
# These functions allow you to use stdio routines for writing, like printf, puts and such.
# proc tteInitCon*() {.importc: "tte_init_con", header: "tonc.h".}
# proc tteCmdVt100*(text: cstring): int {.importc: "tte_cmd_vt100", header: "tonc.h".}
# proc tteConWrite*(r: ptr _reent; fd: int; text: cstring; len: csize): csize {.importc: "tte_con_write", header: "tonc.h".}
# proc tteConNocash*(r: ptr _reent; fd: int; text: cstring; len: csize): csize {.importc: "tte_con_nocash", header: "tonc.h".}

# Regular tilemaps
# ----------------
# The tilemap sub-system loads the tiles into memory first, then
# writes to the map to show the letters. For this to work properly,
# the glyph sizes should be 8-pixel aligned.
# Note: At present, the regular tilemap text ignores screenblock
#  boundaries, so 512px wide maps may not work properly.

proc tteInitSe*(bgnr: int; bgcnt: BgCnt; se0: ScrEntry; clrs: uint32; bupofs: uint32; font: Font = addr(fwfDefault); fn: FnDrawg = nil) {.importc: "tte_init_se", header: "tonc.h".}
  ## Initialize text system for screen-entry fonts.
  ## `bgnr`   Number of background to be used for text.
  ## `bgcnt`  Background control flags.
  ## `se0`    Base screen entry. This allows a greater range in capabilities, like offset tile-starts and palettes.
  ## `clrs`   colors to use for the text. The palette entries used depends on `se0` and `bupofs`.
  ## `bupofs` Flags for font bit-unpacking. Basically indicates pixel values (and hence palette use).
  ## `font`   Font to initialize with.
  ## `fn`     Glyph renderer.

proc seErase*(left: int; top: int; right: int; bottom: int) {.importc: "se_erase", header: "tonc.h".}
  ## Erase part of the regular tilemap canvas.
proc seDrawgW8H8*(gid: uint) {.importc: "se_drawg_w8h8", header: "tonc.h".}
  ## Character-plot for reg BGs using an 8x8 font.
proc seDrawgW8H16*(gid: uint) {.importc: "se_drawg_w8h16", header: "tonc.h".}
  ## Character-plot for reg BGs using an 8x16 font.
proc seDrawg*(gid: uint) {.importc: "se_drawg", header: "tonc.h".}
  ## Character-plot for reg BGs, any sized font.
proc seDrawgS*(gid: uint) {.importc: "se_drawg_s", header: "tonc.h".}
  ## Character-plot for reg BGs, any sized, vertically tiled font.

# Affine tilemaps
# ---------------
proc tteInitAse*(bgnr: int; bgcnt: BgCnt; ase0: uint8; clrs: uint32; bupofs: uint32; font: Font = addr(fwfDefault); fn: FnDrawg = nil) {.importc: "tte_init_ase", header: "tonc.h".}
  ## 
proc aseErase*(left: int; top: int; right: int; bottom: int) {.importc: "ase_erase", header: "tonc.h".}
  ## Erase part of the affine tilemap canvas.
proc aseDrawgW8H8*(gid: uint) {.importc: "ase_drawg_w8h8", header: "tonc.h".}
  ## Character-plot for affine BGs using an 8x16 font.
proc aseDrawgW8H16*(gid: uint) {.importc: "ase_drawg_w8h16", header: "tonc.h".}
  ## Character-plot for affine BGs using an 8x16 font.
proc aseDrawg*(gid: uint) {.importc: "ase_drawg", header: "tonc.h".}
  ## Character-plot for affine Bgs, any size.
proc aseDrawgS*(gid: uint) {.importc: "ase_drawg_s", header: "tonc.h".}
  ## Character-plot for affine BGs, any sized, vertically oriented font.

# 4bpp tiles
# ----------
# There are actually two *chr4* systems. The difference
# between the two is the ordering of the tiles: column-major
# versus row-major. Since column-major is 'better', this is
# considered the primary sub-system for tiled text.

proc tteInitChr4c*(bgnr: int; bgcnt: BgCnt, se0: uint16; cattrs, clrs: uint32; font: Font = addr(vwfDefault); fn: FnDrawg = nil) {.importc: "tte_init_chr4c", header: "tonc.h".}
  ## Initialize text system for 4bpp tiled, column-major surfaces.
  ## `bgnr`   Background number.
  ## `bgcnt`  Background control flags.
  ## `se0`    Base offset for screen-entries.
  ## `cattrs` Color attributes; one byte per attr.
  ## `clrs`   ink(/shadow) colors.
  ## `font`   Font to initialize with.
  ## `fn`     Glyph renderer
  
proc chr4cErase*(left, top, right, bottom: int) {.importc: "chr4c_erase", header: "tonc.h".}
  ## Erase part of the 4bpp text canvas.

proc chr4cDrawgB1CTS*(gid: uint) {.importc: "chr4c_drawg_b1cts_fast", header: "tonc.h".}
  ## Render 1bpp fonts to 4bpp tiles, column-major

proc chr4cDrawgB4CTS*(gid: uint) {.importc: "chr4c_drawg_b4cts_fast", header: "tonc.h".}
  ## Render 4bpp fonts to 4bpp tiles, column-major


proc tteInitChr4r*(bgnr: int; bgcnt: BgCnt; se0: uint16; cattrs: uint32; clrs: uint32; font: Font = addr(vwfDefault); fn: FnDrawg = nil) {.importc: "tte_init_chr4r", header: "tonc.h".}
  ## Initialize text system for 4bpp tiled, column-major surfaces.
  ## `bgnr`   Background number.
  ## `bgcnt`  Background control flags.
  ## `se0`    Base offset for screen-entries.
  ## `cattrs` Color attributes; one byte per attr.
  ## `clrs`   ink(/shadow) colors.
  ## `font`   Font to initialize with.
  ## `fn`     Glyph renderer

proc chr4rErase*(left, top, right, bottom: int) {.importc: "chr4r_erase", header: "tonc.h".}
  ## Erase part of the 4bpp text canvas.

proc chr4rDrawgB1CTS*(gid: uint) {.importc: "chr4r_drawg_b1cts_fast", header: "tonc.h".}
  ## Render 1bpp fonts to 4bpp tiles, row-major


# Bitmap Text
# -----------
# Text for 16bpp and 8bpp bitmap surfaces: modes 3, 4 and 5.
# Note that TTE does not update the pointer of the surface for
#  page-flipping. You'll have to do that yourself.

proc tteInitBmp*(vmode: int; font: Font = addr(vwfDefault); fn: FnDrawg = nil) {.importc: "tte_init_bmp", header: "tonc.h".}
  ## Initialize text system for bitmap fonts.
  ## `vmode` Video mode (3,4 or 5).
  ## `font`  Font to initialize with.
  ## `fn`    Glyph renderer.

# 8bpp bitmaps
proc bmp8Erase*(left, top, right, bottom: int) {.importc: "bmp8_erase", header: "tonc.h".}
proc bmp8Drawg*(gid: uint) {.importc: "bmp8_drawg", header: "tonc.h".}
  ## Linear 8bpp bitmap glyph renderer, opaque.
  ## `gid`  Character to plot.
  ## Font params: bitmapped, 8bpp.
  ## Untested
proc bmp8DrawgT*(gid: uint) {.importc: "bmp8_drawg_t", header: "tonc.h".}
  ## Linear 8bpp bitmap glyph renderer, transparent.
  ## `gid` Character to plot.
  ## Font params: bitmapped, 8bpp. special cattr is transparent.
  ## Untested
proc bmp8DrawgB1CTS*(gid: uint) {.importc: "bmp8_drawg_b1cts_fast", header: "tonc.h".}
  ## 8bpp bitmap glyph renderer. 1->8bpp recolored, any size, transparent
proc bmp8DrawgB1COS*(gid: uint) {.importc: "bmp8_drawg_b1cos", header: "tonc.h".}
  ## 8bpp bitmap glyph renderer. 1->8bpp recolored, any size, opaque

# 16bpp bitmaps
proc bmp16Erase*(left, top, right, bottom: int) {.importc: "bmp16_erase", header: "tonc.h".}
  ## Erase part of the 16bpp text canvas.
  
proc bmp16Drawg*(gid: uint) {.importc: "bmp16_drawg", header: "tonc.h".}
  ## Linear 16bpp bitmap glyph renderer, opaque.
  ## Works on a 16 bpp bitmap.
  ## `gid` Character to plot.
  ## Font params: bitmapped, 16bpp.
  
proc bmp16DrawgT*(gid: uint) {.importc: "bmp16_drawg_t", header: "tonc.h".}
  ## Linear 16bpp bitmap glyph renderer, transparent.
  ## Works on a 16 bpp bitmap
  ## `gid` Character to plot.
  ## Font params: bitmapped, 16bpp. special cattr is transparent.
  
proc bmp16DrawgB1CTS*(gid: uint) {.importc: "bmp16_drawg_b1cts", header: "tonc.h".}
  ## Linear bitmap, 16bpp transparent character plotter.
  ## Works on a 16 bpp bitmap (mode 3 or 5).
  ## `gid` Character to plot.
  ## Font req: Any width/height. 1bpp font, 8px strips.
  
proc bmp16DrawgB1COS*(gid: uint) {.importc: "bmp16_drawg_b1cos", header: "tonc.h".}
  ## Linear bitmap, 16bpp opaque character plotter.
  ## Works on a 16 bpp bitmap (mode 3 or 5).
  ## `gid` Character to plot.
  ## Font req: Any width/height. 1bpp font, 8px strips.

# Objects
# -------
# Text using object (1 glyph per object)

proc tteInitObj*(dst: ObjAttrPtr; attr0, attr1, attr2: uint32; clrs: uint32, bupofs: uint32; font: Font = addr(fwfDefault); fn: FnDrawg = nil) {.importc: "tte_init_obj", header: "tonc.h".}
  ## `obj`    Destination object.
  ## `attr0`  Base obj.attr0. 
  ## `attr1`  Base obj.attr1.
  ## `attr2`  Base obj.attr2.
  ## `clrs`   Colors to use for the text. The palette entries used depends on `attr2` and `bupofs`.
  ## `bupofs` Flags for font bit-unpacking. Basically indicates pixel values (and hence palette use).
  ## `font`   Font to initialize with.
  ## `fn`     Character plotting procedure.
  ## Note: The TTE-obj system uses the surface differently than then rest. Be careful when modifying the surface data.

proc objErase*(left, top, right, bottom: int) {.importc: "obj_erase", header: "tonc.h".}
  ## Unwind the object text-buffer
proc objDrawg*(gid: uint) {.importc: "obj_drawg", header: "tonc.h".}
  ## Character-plot for objects. 



# Extras
# ------

template ink*(tc: TextContext | TextContextObj): uint16 =  tc.cattr[TTE_INK]
template shadow*(tc: TextContext | TextContextObj): uint16 =  tc.cattr[TTE_SHADOW]
template paper*(tc: TextContext | TextContextObj): uint16 =  tc.cattr[TTE_PAPER]
template special*(tc: TextContext | TextContextObj): uint16 =  tc.cattr[TTE_SPECIAL]

template `ink=`*(tc: TextContext | var TextContextObj, v: uint16) =  tc.cattr[TTE_INK] = v
template `shadow=`*(tc: TextContext | var TextContextObj, v: uint16) =  tc.cattr[TTE_SHADOW] = v
template `paper=`*(tc: TextContext | var TextContextObj, v: uint16) =  tc.cattr[TTE_PAPER] = v
template `special=`*(tc: TextContext | var TextContextObj, v: uint16) =  tc.cattr[TTE_SPECIAL] = v
