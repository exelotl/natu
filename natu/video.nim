## Video functions
## ===============
## Basic video-IO, color, background and object functionality

{.warning[UnusedImport]: off.}

import private/[common, types, core, math, memmap, memdef]

{.compile(toncPath & "/src/tonc_video.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg_affine.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp8.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp16.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_color.c", toncCFlags).}
{.compile(toncPath & "/asm/clr_blend_fast.s", toncAsmFlags).}
{.compile(toncPath & "/asm/clr_fade_fast.s", toncAsmFlags).}

# Constants
# ---------
# Sizes in pixels
const
  ScreenWidth* = 240          ## Width in pixels
  ScreenHeight* = 160         ## Height in pixels
  ScreenLines* = 228          ## Total number of scanlines (max vcount value)
  Mode3Width* = ScreenWidth
  Mode3Height* = ScreenHeight
  Mode4Width* = ScreenWidth
  Mode4Height* = ScreenHeight
  Mode5Width* = 160
  Mode5Height* = 128

# Size in tiles
const
  ScreenWidthInTiles* = (ScreenWidth div 8)    ## Width in tiles
  ScreenHeightInTiles* = (ScreenHeight div 8)  ## Height in tiles
  
# Color constants
const
  clrBlack* = 0x0000.Color
  clrRed* = 0x001F.Color
  clrLime* = 0x03E0.Color
  clrYellow* = 0x03FF.Color
  clrBlue* = 0x7C00.Color
  clrMagenta* = 0x7C1F.Color
  clrCyan* = 0x7FE0.Color
  clrWhite* = 0x7FFF.Color
  clrDead* = 0xDEAD.Color
  clrMaroon* = 0x0010.Color
  clrGreen* = 0x0200.Color
  clrOlive* = 0x0210.Color
  clrOrange* = 0x021F.Color
  clrNavy* = 0x4000.Color
  clrPurple* = 0x4010.Color
  clrTeal* = 0x4200.Color
  clrGray* = 0x4210.Color
  clrMedGray* = 0x5294.Color
  clrSilver* = 0x6318.Color
  clrMoneyGreen* = 0x6378.Color
  clrFuchsia* = 0x7C1F.Color
  clrSkyBlue* = 0x7B34.Color
  clrCream* = 0x7BFF.Color


# TODO: Rework color/pal function signatures?

proc clrRotate*(clrs: ptr Color; nclrs: uint; ror: int) {.importc: "clr_rotate", header: "tonc.h".}
  ## Rotate `nclrs` colors at `clrs` to the right by `ror`.

proc clrBlend*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs, alpha: uint32) {.importc: "clr_blend", header: "tonc.h".}
  ## Blends color arrays `srca` and `srcb` into `dst`.
  ## Specific transitional blending effects can be created by making a 'target' color array
  ##  with other routines, then using `alpha` to morph into it.
  ## `srca`  Source array A.
  ## `srcb`  Source array B
  ## `dst`   Destination array.
  ## `nclrs` Number of colors.
  ## `alpha` Blend weight (range: 0-32). 0 Means full `srca`

proc clrFade*(src: ptr Color; clr: Color; dst: ptr Color; nclrs, alpha: uint32) {.importc: "clr_fade", header: "tonc.h".}
  ## Fades color arrays `srca` to `clr` into `dst`.
  ## `src`   Source array.
  ## `clr`   Final color (at alpha=32).
  ## `dst`   Destination array.
  ## `nclrs` Number of colors.
  ## `alpha` Blend weight (range: 0-32). 0 Means full `srca`

proc clrGrayscale*(dst: ptr Color; src: ptr Color; nclrs: uint) {.importc: "clr_grayscale", header: "tonc.h".}
  ## Transform colors to grayscale.
  ## `dst`   Destination color array
  ## `src`   Source color array.
  ## `nclrs` Number of colors.

proc clrRgbscale*(dst: ptr Color; src: ptr Color; nclrs: uint; clr: Color) {.importc: "clr_rgbscale", header: "tonc.h".}
  ## Transform colors to an rgb-scale.
  ## Note: `clr` indicates a color vector in RGB-space. Each source color is converted to a brightness value (i.e. grayscale) and then mapped 
  ## onto that color vector. A grayscale is a special case of this, using a color with R=G=B.
  ## `dst`   Destination color array
  ## `src`   Source color array.
  ## `nclrs` Number of colors.
  ## `clr`   Destination color vector.

proc clrAdjBrightness*(dst: ptr Color; src: ptr Color; nclrs: uint; bright: Fixed) {.importc: "clr_adj_brightness", header: "tonc.h".}
  ## Adjust brightness by `bright`
  ## Operation: color= color+dB;
  ## `dst`    Destination color array
  ## `src`    Source color array.
  ## `nclrs`  Number of colors.
  ## `bright` Brightness difference, dB (in .8f)

proc clrAdjContrast*(dst: ptr Color; src: ptr Color; nclrs: uint; contrast: Fixed) {.importc: "clr_adj_contrast", header: "tonc.h".}
  ## Adjust contrast by `contrast`
  ## Operation: color = color*(1+dC) - MAX*dC/2
  ## `dst`      Destination color array
  ## `src`      Source color array.
  ## `nclrs`    Number of colors.
  ## `contrast` Contrast differencem dC (in .8f)

proc clrAdjIntensity*(dst: ptr Color; src: ptr Color; nclrs: uint; intensity: Fixed) {.importc: "clr_adj_intensity", header: "tonc.h".}
  ## Adjust intensity by `intensity`. 
  ## Operation: color = (1+dI)*color.
  ## `dst`       Destination color array
  ## `src`       Source color array.
  ## `nclrs`     Number of colors.
  ## `intensity` Intensity difference, dI (in .8f)

proc palGradient*(pal: ptr Color; first: int; last: int) {.importc: "pal_gradient", header: "tonc.h".}
  ## Create a gradient between pal[first] and pal[last].
  ## `pal`    Palette to work on.
  ## `first` First index of gradient.
  ## `last`  Last index of gradient.

proc palGradient*(pal: ptr Color; first: int; last: int; clr_first: Color; clr_last: Color) {.importc: "pal_gradient_ex", header: "tonc.h".}
  ## Create a gradient between pal[first] and pal[last].
  ## `pal`       Palette to work on.
  ## `first`     First index of gradient.
  ## `last`      Last index of gradient.
  ## `clr_first` Color of first index.
  ## `clr_last`  Color of last index.

proc clrBlendFast*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs: uint; alpha: uint32) {.importc: "clr_blend_fast", header: "tonc.h".}
  ## Blends color arrays `srca` and `srcb` into `dst`.
  ## `srca`  Source array A.
  ## `srcb`  Source array B
  ## `dst`   Destination array.
  ## `nclrs` Number of colors.
  ## `alpha` Blend weight (range: 0-32).
  ## Note: Handles 2 colors per loop. Very fast.

proc clrFadeFast*(src: ptr Color; clr: Color; dst: ptr Color; nclrs: uint; alpha: uint32) {.importc: "clr_fade_fast", header: "tonc.h".}
  ## Fades color arrays `srca` to `clr` into `dst`.
  ## `src`   Source array.
  ## `clr`   Final color (at alpha=32).
  ## `dst`   Destination array.
  ## `nclrs` Number of colors.
  ## `alpha` Blend weight (range: 0-32).
  ## Note: Handles 2 colors per loop. Very fast.

## Colors
## ------

{.push inline.}

proc rgb15*(red, green, blue: int): Color {.deprecated:"Use rgb5 instead".} =
  ## Create a 15-bit BGR color.
  (red + (green shl 5) + (blue shl 10)).Color

proc rgb15safe*(red, green, blue: int): Color {.deprecated:"Use rgb5 instead".} =
  ## Create a 15-bit BGR color, with proper masking of R,G,B components.
  ((red and 31) + ((green and 31) shl 5) + ((blue and 31) shl 10)).Color

proc rgb5*(red, green, blue: int): Color =
  ## Create a 15-bit BGR color.
  (red + (green shl 5) + (blue shl 10)).Color

proc rgb5safe*(red, green, blue: int): Color =
  ## Create a 15-bit BGR color, with proper masking of R,G,B components.
  ((red and 31) + ((green and 31) shl 5) + ((blue and 31) shl 10)).Color

proc rgb8*(red, green, blue: uint8): Color =
  ## Create a 15-bit BGR color, using 8-bit components
  ((red.uint shr 3) + ((green.uint shr 3) shl 5) + ((blue.uint shr 3) shl 10)).Color

proc rgb8*(rgb: int): Color =
  ## Create a 15-bit BGR color from a 24-bit RGB color of the form 0xRRGGBB
  (((rgb and 0xff0000) shr 19) + (((rgb and 0x00ff00) shr 11) shl 5) + (((rgb and 0x0000ff) shr 3) shl 10)).Color

proc clear*[T: Screenblock | Charblock | Charblock8 | Tile | Tile8](dst: var T) =
  ## Set all bytes in some VRAM block or tile to zero.
  memset32(addr dst, 0, sizeof(T) div 4)

proc clearRow*(sbb: var Screenblock, row: range[0..31]) =
  memset32(addr sbb[row*32], 0, 32 div sizeof(ScrEntry))

{.pop.}

# TODO: document and/or port these two
proc bgIsAffine*(n:int):bool {.importc: "BG_IS_AFFINE", header: "tonc.h".}
proc bgIsAvail*(n:int):bool {.importc: "BG_IS_AVAIL", header: "tonc.h".}

proc fill*(sbb: var Screenblock; se: ScrEntry) {.importc: "se_fill", header: "tonc.h".}
  ## Fill screenblock `sbb` with `se`.

proc plot*(sbb: var Screenblock; x, y: int; se: ScrEntry) {.importc: "se_plot", header: "tonc.h".}
  ## Plot a screen entry at (`x`,`y`) of screenblock `sbb`.

proc rect*(sbb: var Screenblock; left, top, right, bottom: int; se: ScrEntry) {.importc: "se_rect", header: "tonc.h".}
  ## Fill a rectangle on `sbb` with `se`.

proc frame*(sbb: var Screenblock; left, top, right, bottom: int; se: ScrEntry) {.importc: "se_frame", header: "tonc.h".}
  ## Create a border on `sbb` with `se`.

proc window*(sbb: var Screenblock; left, top, right, bottom: int; se0: ScrEntry) {.importc: "se_window", header: "tonc.h".}
proc hline*(sbb: var Screenblock; x0, x1, y: int; se: ScrEntry) {.importc: "se_hline", header: "tonc.h".}
proc vline*(sbb: var Screenblock; x, y0, y1: int; se: ScrEntry) {.importc: "se_vline", header: "tonc.h".}


# TODO: rework below

proc bgAffSet*(bgaff: ptr BgAffine; pa, pb, pc, pd: Fixed) {.importc: "bg_aff_set", header: "tonc.h".}
  ## Set the elements of a bg affine matrix.

proc bgAffIdentity*(bgaff: ptr BgAffine) {.importc: "bg_aff_identity", header: "tonc.h".}
  ## Set an bg affine matrix to the identity matrix

proc bgAffScale*(bgaff: ptr BgAffine; sx, sy: Fixed) {.importc: "bg_aff_scale", header: "tonc.h".}
  ## Set an bg affine matrix for scaling.

proc bgAffShearX*(bgaff: ptr BgAffine; hx: Fixed) {.importc: "bg_aff_shearx", header: "tonc.h".}
proc bgAffShearY*(bgaff: ptr BgAffine; hy: Fixed) {.importc: "bg_aff_sheary", header: "tonc.h".}

proc bgAffRotate*(bgaff: ptr BgAffine; alpha: uint16) {.importc: "bg_aff_rotate", header: "tonc.h".}
  ## Set bg matrix to counter-clockwise rotation.
  ## `bgaff` Object affine struct to set.
  ## `alpha` CCW angle. full-circle is 10000h.

proc bgAffRotscale*(bgaff: ptr BgAffine; sx, sy: int; alpha: uint16) {.importc: "bg_aff_rotscale", header: "tonc.h".}
  ## Set bg matrix to 2d scaling, then counter-clockwise rotation.
  ## `bgaff` Object affine struct to set.
  ## `sx`    Horizontal scale (zoom). .8 fixed point.
  ## `sy`    Vertical scale (zoom). .8 fixed point.
  ## `alpha` CCW angle. full-circle is 10000h.

proc bgAffRotscale*(bgaff: ptr BgAffine; `as`: ptr AffSrc) {.importc: "bg_aff_rotscale2", header: "tonc.h".}
  ## Set bg matrix to 2d scaling, then counter-clockwise rotation.
  ## `bgaff` Object affine struct to set.
  ## `as`    Struct with scales and angle.

proc bgAffPremul*(dst: ptr BgAffine; src: ptr BgAffine) {.importc: "bg_aff_premul", header: "tonc.h".}
  ## Pre-multiply `dst` by `src`: D = S*D

proc bgAffPostmul*(dst: ptr BgAffine; src: ptr BgAffine) {.importc: "bg_aff_postmul", header: "tonc.h".}
  ## Post-multiply `dst` by `src`: D= D*S

proc bgRotscaleEx*(bgaff: ptr BgAffine; asx: ptr AffSrcEx) {.importc: "bg_rotscale_ex", header: "tonc.h".}
  ## Set bg affine matrix to a rot/scale around an arbitrary point.
  ## `bgaff` BG affine data to set.
  ## `asx`   Affine source data: screen and texture origins, scales and angle.


proc m3Clear*() {.inline.} =
  memset32(addr vidMem, 0, M3_SIZE div 4)
proc m3Fill*(clr: Color) {.importc: "m3_fill", header: "tonc.h".}
  ## Fill the mode 3 background with color `clr`.
proc m3Plot*(x, y: int; clr: Color) {.importc: "m3_plot", header: "tonc.h".}
  ## Plot a single colored pixel in mode 3 at (`x`, `y`).
proc m3Hline*(x1, y, x2: int; clr: Color) {.importc: "m3_hline", header: "tonc.h".}
  ## Draw a colored horizontal line in mode 3.
proc m3Vline*(x, y1, y2: int; clr: Color) {.importc: "m3_vline", header: "tonc.h".}
  ## Draw a colored vertical line in mode 3.
proc m3Line*(x1, y1, x2, y2: int; clr: Color) {.importc: "m3_line", header: "tonc.h".}
  ## Draw a colored line in mode 3.
proc m3Rect*(left, top, right, bottom: int; clr: Color) {.importc: "m3_rect", header: "tonc.h".}
  ## Draw a colored rectangle in mode 3.
  ## `left`   Left side, inclusive.
  ## `top`    Top size, inclusive.
  ## `right`  Right size, exclusive.
  ## `bottom` Bottom size, exclusive.
  ## `clr`  Color.
  ## Note: Normalized, but not clipped.
proc m3Frame*(left, top, right, bottom: int; clr: Color) {.importc: "m3_frame", header: "tonc.h".}
  ## Draw a colored frame in mode 3.
  ## `left`   Left side, inclusive.
  ## `top`    Top size, inclusive.
  ## `right`  Right size, exclusive.
  ## `bottom` Bottom size, exclusive.
  ## `clr`    Color.
  ## Note: Normalized, but not clipped.

proc m4Clear*() = memset32(vidPage, 0, M4_SIZE div 4)
proc m4Fill*(clrid: uint8) {.importc: "m4_fill", header: "tonc.h".}
  ## Fill the current mode 4 backbuffer with `clrid`
proc m4Plot*(x, y: int; clrid: uint8) {.importc: "m4_plot", header: "tonc.h".}
  ## Plot a `clrid` pixel on the current mode 4 backbuffer
proc m4Hline*(x1, y, x2: int; clrid: uint8) {.importc: "m4_hline", header: "tonc.h".}
  ## Draw a `clrid` colored horizontal line in mode 4.
proc m4Vline*(x, y1, y2: int; clrid: uint8) {.importc: "m4_vline", header: "tonc.h".}
  ## Draw a `clrid` colored vertical line in mode 4.
proc m4Line*(x1, y1, x2, y2: int; clrid: uint8) {.importc: "m4_line", header: "tonc.h".}
  ## Draw a `clrid` colored line in mode 4.
proc m4Rect*(left, top, right, bottom: int; clrid: uint8) {.importc: "m4_rect", header: "tonc.h".}
  ## Draw a `clrid` colored rectangle in mode 4.
  ## `left`   Left side, inclusive.
  ## `top`    Top size, inclusive.
  ## `right`  Right size, exclusive.
  ## `bottom` Bottom size, exclusive.
  ## `clrid`  color index.
  ## Note: Normalized, but not clipped.
proc m4Frame*(left, top, right, bottom: int; clrid: uint8) {.importc: "m4_frame", header: "tonc.h".}
  ## Draw a `clrid` colored frame in mode 4.
  ## `left`   Left side, inclusive.
  ## `top`    Top size, inclusive.
  ## `right`  Right size, exclusive.
  ## `bottom` Bottom size, exclusive.
  ## `clrid`  color index.
  ## Note: Normalized, but not clipped.

proc m5Clear*() = memset32(vidPage, 0, M5_SIZE div 4)
proc m5Fill*(clr: Color) {.importc: "m5_fill", header: "tonc.h".}
  ## Fill the current mode 5 backbuffer with `clr`
proc m5Plot*(x, y: int; clr: Color) {.importc: "m5_plot", header: "tonc.h".}
  ## Plot a `clrid` pixel on the current mode 5 backbuffer
proc m5HLine*(x1, y, x2: int; clr: Color) {.importc: "m5_hline", header: "tonc.h".}
  ## Draw a colored horizontal line in mode 5.
proc m5VLine*(x, y1, y2: int; clr: Color) {.importc: "m5_vline", header: "tonc.h".}
  ## Draw a colored vertical line in mode 5.
proc m5Line*(x1, y1, x2, y2: int; clr: Color) {.importc: "m5_line", header: "tonc.h".}
  ## Draw a colored line in mode 5.
proc m5Rect*(left, top, right, bottom: int; clr: Color) {.importc: "m5_rect", header: "tonc.h".}
  ## Draw a colored rectangle in mode 5.
  ## `left`   Left side, inclusive.
  ## `top`    Top size, inclusive.
  ## `right`  Right size, exclusive.
  ## `bottom` Bottom size, exclusive.
  ## `clr`    Color.
  ## Note: Normalized, but not clipped.
proc m5Frame*(left, top, right, bottom: int; clr: Color) {.importc: "m5_frame", header: "tonc.h".}
  ## Draw a colored frame in mode 5.
  ## `left`   Left side, inclusive.
  ## `top`    Top size, inclusive.
  ## `right`  Right size, exclusive.
  ## `bottom` Bottom size, exclusive.
  ## `clr`    Color.
  ## Note: Normalized, but not clipped.


# Extras
# ------

# Convenience procs for working with tile map entries

{.push inline.}

proc tid*(se: ScrEntry): int = (se and SE_ID_MASK).int
proc hflip*(se: ScrEntry): bool = (se and SE_HFLIP) != 0
proc vflip*(se: ScrEntry): bool = (se and SE_VFLIP) != 0
proc palbank*(se: ScrEntry): int {.deprecated:"Use `pal` instead".} = ((se and SE_PALBANK_MASK) shr SE_PALBANK_SHIFT).int
proc pal*(se: ScrEntry): int = ((se and SE_PALBANK_MASK) shr SE_PALBANK_SHIFT).int

proc `tid=`*(se: var ScrEntry, val: int) =     se = ((val.uint16 shl SE_ID_SHIFT) and SE_ID_MASK) or (se and not SE_ID_MASK)
proc `hflip=`*(se: var ScrEntry, val: bool) =  se = (val.uint16 shl 10) or (se and not SE_HFLIP)
proc `vflip=`*(se: var ScrEntry, val: bool) =  se = (val.uint16 shl 11) or (se and not SE_VFLIP)
proc `palbank=`*(se: var ScrEntry, val: int) {.deprecated:"Use `pal` instead".} = se = ((val.uint16 shl SE_PALBANK_SHIFT) and SE_PALBANK_MASK) or (se and not SE_PALBANK_MASK)
proc `pal=`*(se: var ScrEntry, val: int) = se = ((val.uint16 shl SE_PALBANK_SHIFT) and SE_PALBANK_MASK) or (se and not SE_PALBANK_MASK)

{.pop.}


# Color component getters and setters

{.push inline.}

func r*(color: Color): int =
  ## Get the red component of a 15-bit color.
  color.int and 0x001F

func `r=`*(color: var Color, r: int) =
  ## Set the red component of a 15-bit color.
  uint16(color) = (color.uint16 and 0b1_11111_11111_00000) or (r.uint16 and 0x001F)


func g*(color: Color): int =
  ## Get the green component of a 15-bit color.
  (color.int shr 5) and 0x001F

func `g=`*(color: var Color, g: int) =
  ## Set the green component of a 15-bit color.
  uint16(color) = (color.uint16 and 0b1_11111_00000_11111) or (g.uint16 and 0x001F) shl 5


func b*(color: Color): int =
  ## Get the blue component of a 15-bit color.
  (color.int shr 10) and 0x001F

func `b=`*(color: var Color, b: int) =
  ## Set the blue component of a 15-bit color.
  uint16(color) = (color.uint16 and 0b1_00000_11111_11111) or (b.uint16 and 0x001F) shl 10

{.pop.}


proc cbbClear*(cbb: int) {.inline, deprecated:"Use e.g. bgTileMem[i].clear() instead.".} =
  memset32(addr bgTileMem[cbb], 0, CBB_SIZE div 4)

proc sbbClear*(sbb: int) {.inline, deprecated:"Use seMem[i].clear() instead.".} =
  memset32(addr seMem[sbb], 0, SBB_SIZE div 4)

proc sbbClearRow*(sbb, row: int) {.inline, deprecated:"Use seMem[i].clearRow(n) instead.".} =
  memset32(addr seMem[sbb][row*32], 0, 32 div 2)

# proc setWindow*(id: range[0..1], bounds: Rect) {.inline.} =
#   winh[id] = WinBoundsH(left: bounds.left.uint8, right: bounds.right.uint8)
#   winv[id] = WinBoundsV(top: bounds.top.uint8, bottom: bounds.bottom.uint8)
