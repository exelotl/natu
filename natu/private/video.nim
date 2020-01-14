## Video functions
## ===============
## Basic video-IO, color, background and object functionality

# Constants
# ---------
# Sizes in pixels
const
  SCREEN_WIDTH* = 240
  SCREEN_HEIGHT* = 160
  M3_WIDTH* = SCREEN_WIDTH
  M3_HEIGHT* = SCREEN_HEIGHT
  M4_WIDTH* = SCREEN_WIDTH
  M4_HEIGHT* = SCREEN_HEIGHT
  M5_WIDTH* = 160
  M5_HEIGHT* = 128

const
  SCREEN_WIDTH_T* = (SCREEN_WIDTH div 8)    ## Width in tiles
  SCREEN_HEIGHT_T* = (SCREEN_HEIGHT div 8)  ## Height in tiles
  
const
  SCREEN_LINES* = 228  ## Total scanlines

# Alpha blend layers (use with REG_BLDMOD)
const
  LAYER_BG0* = 0x0001
  LAYER_BG1* = 0x0002
  LAYER_BG2* = 0x0004
  LAYER_BG3* = 0x0008
  LAYER_OBJ* = 0x0010
  LAYER_BD* = 0x0020

const
  CLR_BLACK*:Color = 0x0000
  CLR_RED*:Color = 0x001F
  CLR_LIME*:Color = 0x03E0
  CLR_YELLOW*:Color = 0x03FF
  CLR_BLUE*:Color = 0x7C00
  CLR_MAG*:Color = 0x7C1F
  CLR_CYAN*:Color = 0x7FE0
  CLR_WHITE*:Color = 0x7FFF
  CLR_DEAD*:Color = 0xDEAD
  CLR_MAROON*:Color = 0x0010
  CLR_GREEN*:Color = 0x0200
  CLR_OLIVE*:Color = 0x0210
  CLR_ORANGE*:Color = 0x021F
  CLR_NAVY*:Color = 0x4000
  CLR_PURPLE*:Color = 0x4010
  CLR_TEAL*:Color = 0x4200
  CLR_GRAY*:Color = 0x4210
  CLR_MEDGRAY*:Color = 0x5294
  CLR_SILVER*:Color = 0x6318
  CLR_MONEYGREEN*:Color = 0x6378
  CLR_FUCHSIA*:Color = 0x7C1F
  CLR_SKYBLUE*:Color = 0x7B34
  CLR_CREAM*:Color = 0x7BFF

const
  CLR_MASK*:uint32 = 0x001F
  RED_MASK*:uint32 = 0x001F
  RED_SHIFT*:uint32 = 0
  GREEN_MASK*:uint32 = 0x03E0
  GREEN_SHIFT*:uint32 = 5
  BLUE_MASK*:uint32 = 0x7C00
  BLUE_SHIFT*:uint32 = 10

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

template rgb15*(red, green, blue: int): Color =
  ## Create a 15bit BGR color.
  (red + (green shl 5) + (blue shl 10)).Color

template rgb15safe*(red, green, blue: int): Color =
  ## Create a 15bit BGR color, with proper masking of R,G,B components.
  ((red and 31) + ((green and 31) shl 5) + ((blue and 31) shl 10)).Color

template rgb8*(red, green, blue: uint8): Color =
  ## Create a 15bit BGR color, using 8bit components
  ((red.uint shr 3) + ((green.uint shr 3) shl 5) + ((blue.uint shr 3) shl 10)).Color

template rgb8*(rgb: int): Color =
  ## Create a 15 bit BGR color from a 24-bit RGB color of the form 0xRRGGBB
  (((rgb and 0xff0000) shr 19) + (((rgb and 0x00ff00) shr 11) shl 5) + (((rgb and 0x0000ff) shr 3) shl 10)).Color


proc cbbClear*(cbb: int) =
  memset32(addr tileMem[cbb], 0, CBB_SIZE div 4)

proc sbbClear*(sbb: int) =
  memset32(addr seMem[sbb], 0, SBB_SIZE div 4)

proc sbbClearRow*(sbb, row: int) =
  memset32(addr seMem[sbb][row*32], 0, 32 div 2)

proc bgIsAffine*(n:int):bool {.importc: "BG_IS_AFFINE", header: "tonc.h".}
proc bgIsAvail*(n:int):bool {.importc: "BG_IS_AVAIL", header: "tonc.h".}

proc seFill*(sbb: ptr ScrEntry; se: ScrEntry) {.importc: "se_fill", header: "tonc.h".}
## Fill screenblock `sbb` with `se`
proc sePlot*(sbb: ptr ScrEntry; x, y: int; se: ScrEntry) {.importc: "se_plot", header: "tonc.h".}
## Plot a screen entry at (`x`,`y`) of screenblock `sbb`.
proc seRect*(sbb: ptr ScrEntry; left, top, right, bottom: int; se: ScrEntry) {.importc: "se_rect", header: "tonc.h".}
## Fill a rectangle on `sbb` with `se`.
proc seFrame*(sbb: ptr ScrEntry; left, top, right, bottom: int; se: ScrEntry) {.importc: "se_frame", header: "tonc.h".}
## Create a border on `sbb` with `se`.
proc seWindow*(sbb: ptr ScrEntry; left, top, right, bottom: int; se0: ScrEntry) {.importc: "se_window", header: "tonc.h".}
proc seHline*(sbb: ptr ScrEntry; x0, x1, y: int; se: ScrEntry) {.importc: "se_hline", header: "tonc.h".}
proc seVline*(sbb: ptr ScrEntry; x, y0, y1: int; se: ScrEntry) {.importc: "se_vline", header: "tonc.h".}


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


proc m3Clear*() = memset32(addr vidMem, 0, M3_SIZE div 4)
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
proc m5Hline*(x1, y, x2: int; clr: Color) {.importc: "m5_hline", header: "tonc.h".}
  ## Draw a colored horizontal line in mode 5.
proc m5Vline*(x, y1, y2: int; clr: Color) {.importc: "m5_vline", header: "tonc.h".}
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

proc tid*(se:ScrEntry): int = (se and SE_ID_MASK).int
proc hflip*(se:ScrEntry): bool = (se and SE_HFLIP) != 0
proc vflip*(se:ScrEntry): bool = (se and SE_VFLIP) != 0
proc palbank*(se:ScrEntry): int = ((se and SE_PALBANK_MASK) shr SE_PALBANK_SHIFT).int

proc `tid=`*(se:var ScrEntry, val: int) =     se = ((val.uint16 shl SE_ID_SHIFT) and SE_ID_MASK) or (se and not SE_ID_MASK)
proc `hflip=`*(se:var ScrEntry, val: bool) =  se = (val.uint16 shl 10) or (se and not SE_HFLIP)
proc `vflip=`*(se:var ScrEntry, val: bool) =  se = (val.uint16 shl 11) or (se and not SE_VFLIP)
proc `palbank=`*(se:var ScrEntry, val: int) = se = ((val.uint16 shl SE_PALBANK_SHIFT) and SE_PALBANK_MASK) or (se and not SE_PALBANK_MASK)
