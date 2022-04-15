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

import private/[common, types, reg, math]
import ./surface
from video import clrOrange, clrYellow

{.compile(toncPath & "/src/font/sys8.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana10.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9_b4.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9b.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9i.s", toncAsmFlags).}
{.compile(toncPath & "/src/tte/tte_main.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_types.s", toncAsmFlags).}
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

{.pragma: tonc, header: "tonc_tte.h".}
{.pragma: toncinl, header: "tonc_tte.h".}  # inline from header.

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
  FontObj* {.importc: "TFont", tonc, bycopy.} = object
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
    ##  === ===
    ##   0   2
    ##   1   3
    ##  === ===
    data*: pointer                      ## Character data.
    widths*: ptr UncheckedArray[uint8]  ## Width table for variable width font.
    heights*: ptr UncheckedArray[uint8] ## Height table for variable height font.
    charOffset*: uint16                 ## Character offset
    charCount*: uint16                  ## Number of characters in font.
    charW*: uint8                       ## Character width (fwf).
    charH*: uint8                       ## Character height.
    cellW*: uint8                       ## Glyph cell width.
    cellH*: uint8                       ## Glyph cell height.
    cellSize*: uint16                   ## Cell-size (bytes).
    bpp*: uint8                         ## Font bitdepth;
    extra*: uint8                       ## Padding. Free to use.
  
  TextContext* = ptr TextContextObj
  TextContextObj* {.importc: "TTC", tonc, bycopy.} = object
    ## TTE context struct.
    
    # Members for renderers
    dst*: Surface                        ## Destination surface.
    cursorX*: int16                      ## Cursor X-coord.
    cursorY*: int16                      ## Cursor Y-coord.
    font*: Font                          ## Current font.
    charLut*: ptr UncheckedArray[uint8]  ## Character mapping lut. (if any).
    cattr*: array[4, uint16]             ## ink, shadow, paper and special color attributes.
    
    # Higher-up members
    flags0*: uint16
    ctrl*: BgCntU16                      ## BG control flags
    marginLeft*: uint16
    marginTop*: uint16
    marginRight*: uint16
    marginBottom*: uint16
    savedX*: int16
    savedY*: int16
    
    # Callbacks and table pointers
    drawgProc*: FnDrawg                       ## Glyph render procedure.
    eraseProc*: FnErase                       ## Text eraser procedure.
    fontTable*: ptr UncheckedArray[Font]      ## Pointer to font table for `f`.
    stringTable*: ptr UncheckedArray[cstring] ## Pointer to string table for `s`.


# Internal Fonts
# --------------

var fntSys8* {.importc: "(&sys8Font)", tonc.}: Font              ## System font. FWF 8x8\@1.
var fntVerdana9* {.importc: "(&verdana9Font)", tonc.}: Font      ## Verdana 9. VWF 8x12\@1.
var fntVerdana9b* {.importc: "(&verdana9bFont)", tonc.}: Font    ## Verdana 9 bold. VWF 8x12\@1.
var fntVerdana9i* {.importc: "(&verdana9iFont)", tonc.}: Font    ## Verdana 9 italic. VWF 8x12\@1.
var fntVerdana10* {.importc: "(&verdana10Font)", tonc.}: Font    ## Verdana 10. VWF 6x14\@1.
var fntVerdana9b4* {.importc: "(&verdana9_b4Font)", tonc.}: Font ## Verdana 9. VWF 8x12@4.


# Default Initializers
# --------------------

template initSe*(bgnr:int, bgcnt: BgCntU16) =
  initSe(bgnr, bgcnt, 0xF000, clrYellow.uint32, 0, fntSys8, nil)

template initAse*(bgnr:int, bgcnt: BgCntU16) =
  initAse(bgnr, bgcnt, 0x0000, clrYellow.uint32, 0, fntSys8, nil)

template initChr4c*(bgnr:int, bgcnt: BgCntU16) =
  initChr4c(bgnr, bgcnt, 0xF000, 0x0201, (clrOrange.uint32 shl 16) or (clrYellow.uint32), fntVerdana9, nil)

template initChr4r*(bgnr:int, bgcnt: BgCntU16) =
  initChr4r(bgnr, bgcnt, 0xF000, 0x0201, (clrOrange.uint32 shl 16) or (clrYellow.uint32), fntVerdana9, nil)

template initChr4cb4*(bgnr:int, bgcnt: BgCntU16) =
  initChr4c(bgnr, bgcnt, 0xF000, 0x0201, (clrOrange.uint32 shl 16) or (clrYellow.uint32), fntVerdana9b4, chr4cDrawg_b4cts)

template initBmp*(mode: int) =
  initBmp(mode, fntVerdana9, nil)

template initObj*(pObj: ObjAttrPtr) =
  initObj(pObj, 0, 0, 0xF000, clrYellow.uint32, 0, fntSys8, nil)

# Operations
# ----------
# This covers most of the things you can actually use TTE for,
# like writing the text, getting information about a glyph and setting
# color attributes.

proc setContext*(tc: TextContext) {.importc: "tte_set_context", tonc.}
  ## Set the master context pointer.

proc getContext*(): TextContext {.importc: "tte_get_context", toncinl.}
  ## Get the master context pointer.

proc getGlyphId*(ch: int): uint {.importc: "tte_get_glyph_id", toncinl.}
  ## Get the glyph index of character `ch`.

proc getGlyphWidth*(gid: uint): int {.importc: "tte_get_glyph_width", toncinl.}
  ## Get the width of glyph `id`.

proc getGlyphHeight*(gid: uint): int {.importc: "tte_get_glyph_height", toncinl.}
  ## Get the height of glyph `id`.

proc getGlyphData*(gid: uint): pointer {.importc: "tte_get_glyph_data", toncinl.}
  ## Get the glyph data of glyph `id`.

proc setColor*(typ: uint; clr: uint16) {.importc: "tte_set_color", tonc.}
  ## Set color of `type` to `cattr`.

proc setColors*(colors: ptr UncheckedArray[uint16]) {.importc: "tte_set_colors", tonc.}
  ## Load important color data.

proc setColorAttr*(typ: uint; cattr: uint16) {.importc: "tte_set_color_attr", tonc.}
  ## Set color attribute of `type` to `cattr`.

proc setColorAttrs*(cattrs: ptr UncheckedArray[uint16]) {.importc: "tte_set_color_attrs", tonc.}
  ## Load important color attribute data.

proc cmdDefault*(str: cstring): cstring {.importc: "tte_cmd_default", tonc.}
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

proc putc*(ch: int|char): int {.importc: "tte_putc", discardable, tonc.}
  ## Plot a single character; does wrapping too.
  ## `ch` Character to plot (not glyph-id).
  ## Returns: Character width.
  ## Note: Overhead: ~70 cycles.

proc write*(text: cstring): int {.importc: "tte_write", discardable, tonc.}
  ## Render a string.
  ## `text` String to parse and write.
  ## Returns: Number of parsed characters.

proc writeEx*(x: int; y: int; text: cstring; clrlut: ptr UncheckedArray[uint16]): int {.importc: "tte_write_ex", discardable, tonc.}
  ## Extended string writer, with positional and color info

proc eraseRect*(left, top, right, bottom: int) {.importc: "tte_erase_rect", tonc.}
  ## Erase a porttion of the screen (ignores margins)

proc eraseScreen*() {.importc: "tte_erase_screen", tonc.}
  ## Erase the screen (within the margins).

proc eraseLine*() {.importc: "tte_erase_line", tonc.}
  ## Erase the whole line (within the margins).

proc getTextSize*(str: cstring): Point16 {.importc: "tte_get_text_size", tonc.}
  ## Get the size taken up by a string.
  ## `str` String to check.
  ## Returns: width and height, packed into a POINT16.
  ## Note: This function *ignores* tte commands, so don't use on strings that use commands.

proc initBase*(font: Font; drawProc: FnDrawg; eraseProc: FnErase) {.importc: "tte_init_base", tonc.}

# Text Attribute Functions
# ------------------------

# Getters:

proc getPos*(x, y: var int) {.importc: "tte_get_pos", toncinl.}
  ## Get cursor position (mutates parameters)
proc getPos*(): Vec2i {.inline, noinit.} = getPos(result.x, result.y)
  ## Get cursor position as vector
proc getInk*(): uint16 {.importc: "tte_get_ink", toncinl.}
  ## Get ink color attribute.
proc getShadow*(): uint16 {.importc: "tte_get_shadow", toncinl.}
  ## Get shadow color attribute.
proc getPaper*(): uint16 {.importc: "tte_get_paper", toncinl.}
  ## Get paper color attribute.
proc getSpecial*(): uint16 {.importc: "tte_get_special", toncinl.}
  ## Get special color attribute.
proc getSurface*(): SurfacePtr {.importc: "tte_get_surface", toncinl.}
  ## Get a pointer to the text surface.
proc getFont*(): Font {.importc: "tte_get_font", toncinl.}
  ## Get the active font
proc getDrawg*(): FnDrawg {.importc: "tte_get_drawg", toncinl.}
  ## Get the active character plotter
proc getErase*(): FnErase {.importc: "tte_get_erase", toncinl.}
  ## Get the erase function
proc getStringTable*(): ptr UncheckedArray[cstring] {.importc: "tte_get_string_table", toncinl.}
  ## Get string table
proc getFontTable*(): ptr UncheckedArray[Font] {.importc: "tte_get_font_table", toncinl.}
  ## Get font table

# Setters:

proc setPos*(x, y: int) {.importc: "tte_set_pos", toncinl.}
  ## Set cursor position
proc setPos*(p: Vec2i) {.inline.} = setPos(p.x, p.y)
  ## Set cursor position
proc setInk*(cattr: uint16) {.importc: "tte_set_ink", toncinl.}
  ## Set ink color attribute.
proc setShadow*(cattr: uint16) {.importc: "tte_set_shadow", toncinl.}
  ## Set shadow color attribute.
proc setPaper*(cattr: uint16) {.importc: "tte_set_paper", toncinl.}
  ## Set paper color attribute.
proc setSpecial*(cattr: uint16) {.importc: "tte_set_special", toncinl.}
  ## Set special color attribute.
proc setSurface*(srf: SurfacePtr) {.importc: "tte_set_surface", toncinl.}
  ## Set the text surface.
proc setFont*(font: Font) {.importc: "tte_set_font", toncinl.}
  ## Set the font
proc setDrawg*(fn: FnDrawg = nil) {.importc: "tte_set_drawg", toncinl.}
  ## Set the character plotter
proc setErase*(fn: FnErase) {.importc: "tte_set_erase", toncinl.}
  ## Set the erase function
proc setStringTable*(table: ptr UncheckedArray[cstring]) {.importc: "tte_set_string_table", toncinl.}
  ## Set string table
proc setFontTable*(table: ptr UncheckedArray[Font]) {.importc: "tte_set_font_table", toncinl.}
  ## Set font table
proc setMargins*(left, top, right, bottom: int) {.importc: "tte_set_margins", tonc.}

# Console Functions
# -----------------
# These functions allow you to use stdio routines for writing, like printf, puts and such.
# proc initCon*() {.importc: "tte_init_con", tonc.}
# proc cmdVt100*(text: cstring): int {.importc: "tte_cmd_vt100", tonc.}
# proc conWrite*(r: ptr _reent; fd: int; text: cstring; len: csize): csize {.importc: "tte_con_write", tonc.}
# proc conNocash*(r: ptr _reent; fd: int; text: cstring; len: csize): csize {.importc: "tte_con_nocash", tonc.}

# Regular tilemaps
# ----------------
# The tilemap sub-system loads the tiles into memory first, then
# writes to the map to show the letters. For this to work properly,
# the glyph sizes should be 8-pixel aligned.
# Note: At present, the regular tilemap text ignores screenblock
#  boundaries, so 512px wide maps may not work properly.

proc initSe*(bgnr: int; bgcnt: BgCntU16; se0: ScrEntry; clrs: uint32; bupofs: uint32; font: Font = fntSys8; fn: FnDrawg = nil) {.importc: "tte_init_se", tonc.}
  ## Initialize text system for screen-entry fonts.
  ## `bgnr`   Number of background to be used for text.
  ## `bgcnt`  Background control flags.
  ## `se0`    Base screen entry. This allows a greater range in capabilities, like offset tile-starts and palettes.
  ## `clrs`   colors to use for the text. The palette entries used depends on `se0` and `bupofs`.
  ## `bupofs` Flags for font bit-unpacking. Basically indicates pixel values (and hence palette use).
  ## `font`   Font to initialize with.
  ## `fn`     Glyph renderer.

proc seErase*(left, top, right, bottom: int) {.importc: "se_erase", tonc.}
  ## Erase part of the regular tilemap canvas.
proc seDrawgW8H8*(gid: uint) {.importc: "se_drawg_w8h8", tonc.}
  ## Character-plot for reg BGs using an 8x8 font.
proc seDrawgW8H16*(gid: uint) {.importc: "se_drawg_w8h16", tonc.}
  ## Character-plot for reg BGs using an 8x16 font.
proc seDrawg*(gid: uint) {.importc: "se_drawg", tonc.}
  ## Character-plot for reg BGs, any sized font.
proc seDrawgS*(gid: uint) {.importc: "se_drawg_s", tonc.}
  ## Character-plot for reg BGs, any sized, vertically tiled font.

# Affine tilemaps
# ---------------
proc initAse*(bgnr: int; bgcnt: BgCntU16; ase0: uint8; clrs: uint32; bupofs: uint32; font: Font = fntSys8; fn: FnDrawg = nil) {.importc: "tte_init_ase", tonc.}
  ## 
proc aseErase*(left, top, right, bottom: int) {.importc: "ase_erase", tonc.}
  ## Erase part of the affine tilemap canvas.
proc aseDrawgW8H8*(gid: uint) {.importc: "ase_drawg_w8h8", tonc.}
  ## Character-plot for affine BGs using an 8x16 font.
proc aseDrawgW8H16*(gid: uint) {.importc: "ase_drawg_w8h16", tonc.}
  ## Character-plot for affine BGs using an 8x16 font.
proc aseDrawg*(gid: uint) {.importc: "ase_drawg", tonc.}
  ## Character-plot for affine Bgs, any size.
proc aseDrawgS*(gid: uint) {.importc: "ase_drawg_s", tonc.}
  ## Character-plot for affine BGs, any sized, vertically oriented font.

# 4bpp tiles
# ----------
# There are actually two *chr4* systems. The difference
# between the two is the ordering of the tiles: column-major
# versus row-major. Since column-major is 'better', this is
# considered the primary sub-system for tiled text.

proc initChr4c*(bgnr: int; bgcnt: BgCntU16, se0: uint16; cattrs, clrs: uint32; font: Font = fntVerdana9; fn: FnDrawg = nil) {.importc: "tte_init_chr4c", tonc.}
  ## Initialize text system for 4bpp tiled, column-major surfaces.
  ## `bgnr`   Background number.
  ## `bgcnt`  Background control flags.
  ## `se0`    Base offset for screen-entries.
  ## `cattrs` Color attributes; one byte per attr.
  ## `clrs`   ink(/shadow) colors.
  ## `font`   Font to initialize with.
  ## `fn`     Glyph renderer
  
proc chr4cErase*(left, top, right, bottom: int) {.importc: "chr4c_erase", tonc.}
  ## Erase part of the 4bpp text canvas.

proc chr4cDrawgB1CTS*(gid: uint) {.importc: "chr4c_drawg_b1cts_fast", tonc.}
  ## Render 1bpp fonts to 4bpp tiles, column-major

proc chr4cDrawgB4CTS*(gid: uint) {.importc: "chr4c_drawg_b4cts_fast", tonc.}
  ## Render 4bpp fonts to 4bpp tiles, column-major


proc initChr4r*(bgnr: int; bgcnt: BgCntU16; se0: uint16; cattrs: uint32; clrs: uint32; font: Font = fntVerdana9; fn: FnDrawg = nil) {.importc: "tte_init_chr4r", tonc.}
  ## Initialize text system for 4bpp tiled, column-major surfaces.
  ## `bgnr`   Background number.
  ## `bgcnt`  Background control flags.
  ## `se0`    Base offset for screen-entries.
  ## `cattrs` Color attributes; one byte per attr.
  ## `clrs`   ink(/shadow) colors.
  ## `font`   Font to initialize with.
  ## `fn`     Glyph renderer

proc chr4rErase*(left, top, right, bottom: int) {.importc: "chr4r_erase", tonc.}
  ## Erase part of the 4bpp text canvas.

proc chr4rDrawgB1CTS*(gid: uint) {.importc: "chr4r_drawg_b1cts_fast", tonc.}
  ## Render 1bpp fonts to 4bpp tiles, row-major


# Bitmap Text
# -----------
# Text for 16bpp and 8bpp bitmap surfaces: modes 3, 4 and 5.
# Note that TTE does not update the pointer of the surface for
#  page-flipping. You'll have to do that yourself.

proc initBmp*(vmode: int; font: Font = fntVerdana9; fn: FnDrawg = nil) {.importc: "tte_init_bmp", tonc.}
  ## Initialize text system for bitmap fonts.
  ## `vmode` Video mode (3,4 or 5).
  ## `font`  Font to initialize with.
  ## `fn`    Glyph renderer.

# 8bpp bitmaps
proc bmp8Erase*(left, top, right, bottom: int) {.importc: "bmp8_erase", tonc.}
proc bmp8Drawg*(gid: uint) {.importc: "bmp8_drawg", tonc.}
  ## Linear 8bpp bitmap glyph renderer, opaque.
  ## `gid`  Character to plot.
  ## Font params: bitmapped, 8bpp.
  ## Untested
proc bmp8DrawgT*(gid: uint) {.importc: "bmp8_drawg_t", tonc.}
  ## Linear 8bpp bitmap glyph renderer, transparent.
  ## `gid` Character to plot.
  ## Font params: bitmapped, 8bpp. special cattr is transparent.
  ## Untested
proc bmp8DrawgB1CTS*(gid: uint) {.importc: "bmp8_drawg_b1cts_fast", tonc.}
  ## 8bpp bitmap glyph renderer. 1->8bpp recolored, any size, transparent
proc bmp8DrawgB1COS*(gid: uint) {.importc: "bmp8_drawg_b1cos", tonc.}
  ## 8bpp bitmap glyph renderer. 1->8bpp recolored, any size, opaque

# 16bpp bitmaps
proc bmp16Erase*(left, top, right, bottom: int) {.importc: "bmp16_erase", tonc.}
  ## Erase part of the 16bpp text canvas.
  
proc bmp16Drawg*(gid: uint) {.importc: "bmp16_drawg", tonc.}
  ## Linear 16bpp bitmap glyph renderer, opaque.
  ## Works on a 16 bpp bitmap.
  ## `gid` Character to plot.
  ## Font params: bitmapped, 16bpp.
  
proc bmp16DrawgT*(gid: uint) {.importc: "bmp16_drawg_t", tonc.}
  ## Linear 16bpp bitmap glyph renderer, transparent.
  ## Works on a 16 bpp bitmap
  ## `gid` Character to plot.
  ## Font params: bitmapped, 16bpp. special cattr is transparent.
  
proc bmp16DrawgB1CTS*(gid: uint) {.importc: "bmp16_drawg_b1cts", tonc.}
  ## Linear bitmap, 16bpp transparent character plotter.
  ## Works on a 16 bpp bitmap (mode 3 or 5).
  ## `gid` Character to plot.
  ## Font req: Any width/height. 1bpp font, 8px strips.
  
proc bmp16DrawgB1COS*(gid: uint) {.importc: "bmp16_drawg_b1cos", tonc.}
  ## Linear bitmap, 16bpp opaque character plotter.
  ## Works on a 16 bpp bitmap (mode 3 or 5).
  ## `gid` Character to plot.
  ## Font req: Any width/height. 1bpp font, 8px strips.

# Objects
# -------
# Text using object (1 glyph per object)

proc initObj*(dst: ObjAttrPtr; attr0, attr1, attr2: uint32; clrs: uint32, bupofs: uint32; font: Font = fntSys8; fn: FnDrawg = nil) {.importc: "tte_init_obj", tonc.}
  ## `obj`    Destination object.
  ## `attr0`  Base obj.attr0. 
  ## `attr1`  Base obj.attr1.
  ## `attr2`  Base obj.attr2.
  ## `clrs`   Colors to use for the text. The palette entries used depends on `attr2` and `bupofs`.
  ## `bupofs` Flags for font bit-unpacking. Basically indicates pixel values (and hence palette use).
  ## `font`   Font to initialize with.
  ## `fn`     Character plotting procedure.
  ## Note: The TTE-obj system uses the surface differently than then rest. Be careful when modifying the surface data.

proc objErase*(left, top, right, bottom: int) {.importc: "obj_erase", tonc.}
  ## Unwind the object text-buffer
proc objDrawg*(gid: uint) {.importc: "obj_drawg", tonc.}
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
