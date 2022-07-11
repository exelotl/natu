## Video functions
## ===============
## Basic video-IO, color, background and object functionality

{.warning[UnusedImport]: off.}

import private/[common, types, memmap, memdef, reg]
import ./math
import ./utils

export reg   # todo


# types
export
  Block,
  Color,
  ScrEntry,
  ScrAffEntry,
  Tile,
  Tile4,
  Tile8,
  ObjAffineSource,
  BgAffineSource,
  ObjAffineDest,
  BgAffineDest,
  AffSrc,
  AffSrcEx,
  AffDst,
  AffDstEx,
  BgPoint,
  Point16,
  Palbank,
  Palette,
  M3Line,
  M4Line,
  M5Line,
  M3Mem,
  M4Mem,
  M5Mem,
  Screenline,
  ScreenMat,
  Screenblock,
  Charblock,
  Charblock8,
  UnboundedCharblock,
  UnboundedCharblock8,
  `[]`,
  `[]=`,
  toArray


# Palette
export
  bgColorMem,
  bgPalMem,
  objColorMem,
  objPalMem,
  palBgMem,
  palObjMem,
  palBgBank,
  palObjBank

# VRAM
export
  bgTileMem,
  bgTileMem8,
  objTileMem,
  objTileMem8,
  tileMem,
  tile8Mem,
  tileMemObj,
  tile8MemObj,
  seMem,
  seMat,
  vidMem,
  m3Mem,
  m4Mem,
  m5Mem,
  vidMemFront,
  vidMemBack,
  m4MemBack,
  m5MemBack

{.compile(toncPath & "/src/tonc_video.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg_affine.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp8.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp16.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_color.c", toncCFlags).}
{.compile(toncPath & "/asm/clr_blend_fast.s", toncAsmFlags).}
{.compile(toncPath & "/asm/clr_fade_fast.s", toncAsmFlags).}

{.pragma: tonc, header: "tonc_video.h".}
{.pragma: toncinl, header: "tonc_video.h".}  # inline from header.

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

## Colors
## ------

{.push inline.}

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


# TODO: Rework color/pal function signatures?

proc clrRotate*(clrs: ptr Color; nclrs: uint; ror: int) {.importc: "clr_rotate", tonc.}
  ## Rotate `nclrs` colors at `clrs` to the right by `ror`.

proc clrBlend*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs, alpha: uint32) {.importc: "clr_blend", tonc.}
  ## Blends color arrays `srca` and `srcb` into `dst`.
  ## Specific transitional blending effects can be created by making a 'target' color array
  ##  with other routines, then using `alpha` to morph into it.
  ## 
  ## **Parameters:**
  ## 
  ## srca
  ##   Source array A.
  ## 
  ## srcb
  ##   Source array B
  ## 
  ## dst
  ##   Destination array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## alpha
  ##   Blend weight (range: 0-32). 0 Means full `srca`

proc clrFade*(src: ptr Color; clr: Color; dst: ptr Color; nclrs, alpha: uint32) {.importc: "clr_fade", tonc.}
  ## Fades color arrays `srca` to `clr` into `dst`.
  ## 
  ## **Parameters:**
  ## 
  ## src
  ##   Source array.
  ## 
  ## clr
  ##   Final color (at alpha=32).
  ## 
  ## dst
  ##   Destination array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## alpha
  ##   Blend weight (range: 0-32). 0 Means full `srca`

proc clrGrayscale*(dst: ptr Color; src: ptr Color; nclrs: uint) {.importc: "clr_grayscale", tonc.}
  ## Transform colors to grayscale.
  ## 
  ## **Parameters:**
  ## 
  ## dst
  ##   Destination color array
  ## 
  ## src
  ##   Source color array.
  ## 
  ## nclrs
  ##   Number of colors.

proc clrRgbscale*(dst: ptr Color; src: ptr Color; nclrs: uint; clr: Color) {.importc: "clr_rgbscale", tonc.}
  ## Transform colors to an rgb-scale.
  ## .. note:: `clr` indicates a color vector in RGB-space. Each source color is converted to a brightness value (i.e. grayscale) and then mapped 
  ## onto that color vector. A grayscale is a special case of this, using a color with R=G=B.
  ## 
  ## **Parameters:**
  ## 
  ## dst
  ##   Destination color array
  ## 
  ## src
  ##   Source color array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## clr
  ##   Destination color vector.

proc clrAdjBrightness*(dst: ptr Color; src: ptr Color; nclrs: uint; bright: Fixed) {.importc: "clr_adj_brightness", tonc.}
  ## Adjust brightness by `bright`
  ## Operation: `color= color+dB`;
  ## 
  ## **Parameters:**
  ## 
  ## dst
  ##   Destination color array
  ## 
  ## src
  ##   Source color array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## bright
  ##   Brightness difference, dB (in .8f)

proc clrAdjContrast*(dst: ptr Color; src: ptr Color; nclrs: uint; contrast: Fixed) {.importc: "clr_adj_contrast", tonc.}
  ## Adjust contrast by `contrast`
  ## Operation: `color = color*(1+dC) - MAX*dC/2`
  ## 
  ## **Parameters:**
  ## 
  ## dst
  ##   Destination color array
  ## 
  ## src
  ##   Source color array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## contrast
  ##   Contrast differencem dC (in .8f)

proc clrAdjIntensity*(dst: ptr Color; src: ptr Color; nclrs: uint; intensity: Fixed) {.importc: "clr_adj_intensity", tonc.}
  ## Adjust intensity by `intensity`. 
  ## Operation: `color = (1+dI)*color`.
  ## 
  ## **Parameters:**
  ## 
  ## dst
  ##   Destination color array
  ## 
  ## src
  ##   Source color array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## intensity
  ##   Intensity difference, dI (in .8f)

proc palGradient*(pal: ptr Color; first: int; last: int) {.importc: "pal_gradient", tonc.}
  ## Create a gradient between `pal[first]` and `pal[last]`.
  ## 
  ## **Parameters:**
  ## 
  ## pal
  ##   Palette to work on.
  ## 
  ## first
  ##   First index of gradient.
  ## 
  ## last
  ##   Last index of gradient.

proc palGradient*(pal: ptr Color; first: int; last: int; clr_first: Color; clr_last: Color) {.importc: "pal_gradient_ex", tonc.}
  ## Create a gradient between `pal[first]` and `pal[last]`.
  ## 
  ## **Parameters:**
  ## 
  ## pal
  ##   Palette to work on.
  ## 
  ## first
  ##   First index of gradient.
  ## 
  ## last
  ##   Last index of gradient.
  ## 
  ## clr_first
  ##   Color of first index.
  ## 
  ## clr_last
  ##   Color of last index.

proc clrBlendFast*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs: uint; alpha: uint32) {.importc: "clr_blend_fast", tonc.}
  ## Blends color arrays `srca` and `srcb` into `dst`.
  ## 
  ## **Parameters:**
  ## 
  ## srca
  ##   Source array A.
  ## 
  ## srcb
  ##   Source array B
  ## 
  ## dst
  ##   Destination array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## alpha
  ##   Blend weight (range: 0-32).
  ## .. note:: Handles 2 colors per loop. Very fast.

proc clrFadeFast*(src: ptr Color; clr: Color; dst: ptr Color; nclrs: uint; alpha: uint32) {.importc: "clr_fade_fast", tonc.}
  ## Fades color arrays `srca` to `clr` into `dst`.
  ## 
  ## **Parameters:**
  ## 
  ## src
  ##   Source array.
  ## 
  ## clr
  ##   Final color (at alpha=32).
  ## 
  ## dst
  ##   Destination array.
  ## 
  ## nclrs
  ##   Number of colors.
  ## 
  ## alpha
  ##   Blend weight (range: 0-32).
  ## .. note:: Handles 2 colors per loop. Very fast.

proc bgIsAffine*(n: int): bool {.importc: "BG_IS_AFFINE", toncinl.}
proc bgIsAvailable*(n: int): bool {.importc: "BG_IS_AVAIL", toncinl.}

proc bmp8_plot(x, y: int; clrid: uint8; dstBase: pointer; dstP: uint) {.importc:"bmp8_plot", tonc.}
proc bmp8_hline(x1, y, x2: int; clrid: uint8; dstBase: pointer; dstP: uint) {.importc:"bmp8_hline", tonc.}
proc bmp8_vline(x, y1, y2: int; clrid: uint8; dstBase: pointer; dstP: uint) {.importc:"bmp8_vline", tonc.}
proc bmp8_line(x1, y1, x2: int; y2: int; clrid: uint8; dstBase: pointer; dstP: uint) {.importc:"bmp8_line", tonc.}
proc bmp8_rect(left, top, right, bottom: int; clrid: uint8; dstBase: pointer; dstP: uint) {.importc:"bmp8_rect", tonc.}
proc bmp8_frame(left, top, right, bottom: int; clrid: uint8; dstBase: pointer; dstP: uint) {.importc:"bmp8_frame", tonc.}
proc bmp16_plot(x, y, clr: Color; dstBase: pointer; dstP: uint) {.importc:"bmp16_plot", tonc.}
proc bmp16_hline(x1, y, x2: int; clr: Color; dstBase: pointer; dstP: uint) {.importc:"bmp16_hline", tonc.}
proc bmp16_vline(x, y1, y2: int; clr: Color; dstBase: pointer; dstP: uint) {.importc:"bmp16_vline", tonc.}
proc bmp16_line(x1, y1, x2, y2: int; clr: Color; dstBase: pointer; dstP: uint) {.importc:"bmp16_line", tonc.}
proc bmp16_rect(left, top, right, bottom: int; clr: Color; dstBase: pointer; dstP: uint) {.importc:"bmp16_rect", tonc.}
proc bmp16_frame(left, top, right, bottom: int; clr: Color; dstBase: pointer; dstP: uint) {.importc:"bmp16_frame", tonc.}


proc clear*[T: Screenblock | Charblock | Charblock8 | Tile | Tile8 | M3Mem | M4Mem | M5Mem](dst: var T) {.inline.} =
  ## Clear a region of VRAM (i.e. map, tiles or framebuffer).
  memset32(addr dst, 0, sizeof(T) div 4)

# Screenblock tile plotting
# -------------------------

{.push inline.}

proc fill*(sbb: var Screenblock; se: ScrEntry) =
  ## Fill screenblock `sbb` with `se`.
  memset32(addr sbb, dup16(se.uint16), sizeof(sbb) div 4)

proc plot*(sbb: var Screenblock; x, y: int; se: ScrEntry) =
  ## Plot a screen entry at (`x`,`y`) of screenblock `sbb`.
  sbb[x,y] = se

proc hline*(sbb: var Screenblock; x0, x1, y: int; se: ScrEntry) =
  ## Draw a horizontal line on screenblock `sbb` with `se`.
  bmp16_hline(x0, y, x1, se.Color, addr sbb, 32*2)

proc vline*(sbb: var Screenblock; x, y0, y1: int; se: ScrEntry) =
  ## Draw a vertical line on screenblock `sbb` with `se`.
  bmp16_vline(x, y0, y1, se.Color, addr sbb, 32*2)

proc rect*(sbb: var Screenblock; left, top, right, bottom: int; se: ScrEntry) =
  ## Fill a rectangle on `sbb` with `se`.
  bmp16_rect(left, top, right, bottom, se.Color, addr sbb, 32*2)

proc frame*(sbb: var Screenblock; left, top, right, bottom: int; se: ScrEntry) =
  ## Create a border on `sbb` with `se`.
  bmp16_frame(left, top, right, bottom, se.Color, addr sbb, 32*2)

proc window*(sbb: var Screenblock; left, top, right, bottom: int; se0: ScrEntry) {.importc: "se_window", tonc.}
  ## Create a fancy rectangle.
  ## 
  ## In contrast to `frame`, this uses nine tiles starting at `se0` for the frame,
  ## which indicate the borders and center for the window.
  ## 
  ## .. note::
  ##    The rectangle is not normalized.
  ##    You should ensure that ``left < right`` and ``bottom < top``.

proc clearRow*(sbb: var Screenblock, row: range[0..31]) =
  memset32(addr sbb[row*32], 0, 32 div sizeof(ScrEntry))

{.pop.}


# Mode 3 drawing routines
# -----------------------

{.push inline.}

proc fill*(m: var M3Mem; clr: Color) =
  ## Fill the mode 3 background with color `clr`.
  memset32(addr m, dup16(clr.uint16), sizeof(m) div 4)

proc plot*(m: var M3Mem; x, y: int; clr: Color) =
  ## Plot a single colored pixel in mode 3 at (`x`, `y`).
  m[y][x] = clr

proc hline*(m: var M3Mem; x1, y, x2: int; clr: Color) =
  ## Draw a colored horizontal line in mode 3.
  bmp16_hline(x1, y, x2, clr, addr m, Mode3Width*2)

proc vline*(m: var M3Mem; x, y1, y2: int; clr: Color) =
  ## Draw a colored vertical line in mode 3.
  bmp16_vline(x, y1, y2, clr, addr m, Mode3Width*2)

proc line*(m: var M3Mem; x1, y1, x2, y2: int; clr: Color) =
  ## Draw a colored line in mode 3.
  bmp16_line(x1, y1, x2, y2, clr, addr m, Mode3Width*2)

proc rect*(m: var M3Mem; left, top, right, bottom: int; clr: Color) =
  ## Draw a colored rectangle in mode 3.
  ## 
  ## **Parameters:**
  ## 
  ## left
  ##   Left side, inclusive.
  ## 
  ## top
  ##   Top size, inclusive.
  ## 
  ## right
  ##   Right size, exclusive.
  ## 
  ## bottom
  ##   Bottom size, exclusive.
  ## 
  ## clr
  ##   Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_rect(left, top, right, bottom, clr, addr m, Mode3Width*2)

proc frame*(m: var M3Mem; left, top, right, bottom: int; clr: Color) =
  ## Draw a colored frame in mode 3.
  ## 
  ## **Parameters:**
  ## 
  ## left
  ##   Left side, inclusive.
  ## 
  ## top
  ##   Top size, inclusive.
  ## 
  ## right
  ##   Right size, exclusive.
  ## 
  ## bottom
  ##   Bottom size, exclusive.
  ## 
  ## clr
  ##   Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_frame(left, top, right, bottom, clr, addr m, Mode3Width*2)

{.pop.}


{.push inline.}

proc fill*(m: var M4Mem; clrid: uint8) =
  ## Fill the given mode 4 buffer with `clrid`.
  memset32(addr m, quad8(clrid), sizeof(m) div 4)

proc plot*(m: var M4Mem; x, y: int; clrid: uint8) =
  ## Plot a `clrid` pixel on the given mode 4 buffer.
  let p = cast[ptr UncheckedArray[uint16]](addr m)
  let dst = addr p[(y * Mode4Width + x) shr 1]
  if (x and 0b1) != 0:
    dst[] = (dst[] and 0x00ff) or (clrid shl 8)
  else:
    dst[] = (dst[] and 0xff00) or (clrid)

proc hline*(m: var M4Mem; x1, y, x2: int; clrid: uint8) =
  ## Draw a `clrid` colored horizontal line in mode 4.
  bmp8_hline(x1, y, x2, clrid, addr m, Mode4Width)

proc vline*(m: var M4Mem; x, y1, y2: int; clrid: uint8) =
  ## Draw a `clrid` colored vertical line in mode 4.
  bmp8_vline(x, y1, y2, clrid, addr m, Mode4Width)

proc line*(m: var M4Mem; x1, y1, x2, y2: int; clrid: uint8) =
  ## Draw a `clrid` colored line in mode 4.
  bmp8_line(x1, y1, x2, y2, clrid, addr m, Mode4Width)

proc rect*(m: var M4Mem; left, top, right, bottom: int; clrid: uint8) =
  ## Draw a `clrid` colored rectangle in mode 4.
  ## 
  ## **Parameters:**
  ## 
  ## left
  ##   Left side, inclusive.
  ## 
  ## top
  ##   Top size, inclusive.
  ## 
  ## right
  ##   Right size, exclusive.
  ## 
  ## bottom
  ##   Bottom size, exclusive.
  ## 
  ## clrid
  ##   Color index.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp8_rect(left, top, right, bottom, clrid, addr m, Mode4Width)

proc frame*(m: var M4Mem; left, top, right, bottom: int; clrid: uint8) =
  ## Draw a `clrid` colored frame in mode 4.
  ## 
  ## **Parameters:**
  ## 
  ## left
  ##   Left side, inclusive.
  ## 
  ## top
  ##   Top size, inclusive.
  ## 
  ## right
  ##   Right size, exclusive.
  ## 
  ## bottom
  ##   Bottom size, exclusive.
  ## 
  ## clrid
  ##   Color index.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp8_frame(left, top, right, bottom, clrid, addr m, Mode4Width)

{.pop.}

{.push inline.}

proc fill*(m: var M5Mem; clr: Color) =
  ## Fill the given mode 5 buffer with `clr`.
  memset32(addr m, dup16(clr.uint16), sizeof(m) div 4)

proc plot*(m: var M5Mem; x, y: int; clr: Color) =
  ## Plot a `clrid` pixel on the given mode 5 buffer.
  m[y][x] = clr

proc hline*(m: var M5Mem; x1, y, x2: int; clr: Color) =
  ## Draw a colored horizontal line in mode 5.
  bmp16_hline(x1, y, x2, clr, addr m, Mode5Width*2)

proc vline*(m: var M5Mem; x, y1, y2: int; clr: Color) =
  ## Draw a colored vertical line in mode 5.
  bmp16_vline(x, y1, y2, clr, addr m, Mode5Width*2)

proc line*(m: var M5Mem; x1, y1, x2, y2: int; clr: Color) =
  ## Draw a colored line in mode 5.
  bmp16_line(x1, y1, x2, y2, clr, addr m, Mode5Width*2)

proc rect*(m: var M5Mem; left, top, right, bottom: int; clr: Color) =
  ## Draw a colored rectangle in mode 5.
  ## 
  ## **Parameters:**
  ## 
  ## left
  ##   Left side, inclusive.
  ## 
  ## top
  ##   Top size, inclusive.
  ## 
  ## right
  ##   Right size, exclusive.
  ## 
  ## bottom
  ##   Bottom size, exclusive.
  ## 
  ## clr
  ##   Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_rect(left, top, right, bottom, clr, addr m, Mode5Width*2)

proc frame*(m: var M5Mem; left, top, right, bottom: int; clr: Color) =
  ## Draw a colored frame in mode 5.
  ## 
  ## **Parameters:**
  ## 
  ## left
  ##   Left side, inclusive.
  ## 
  ## top
  ##   Top size, inclusive.
  ## 
  ## right
  ##   Right size, exclusive.
  ## 
  ## bottom
  ##   Bottom size, exclusive.
  ## 
  ## clr
  ##   Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_frame(left, top, right, bottom, clr, addr m, Mode5Width*2)

{.pop.}


# Extras
# ------

# Convenience procs for working with tile map entries

{.push inline.}

func tileId*(se: ScrEntry): int = (se and SE_ID_MASK).int
func palId*(se: ScrEntry): int = ((se and SE_PALBANK_MASK) shr SE_PALBANK_SHIFT).int
func hflip*(se: ScrEntry): bool = (se and SE_HFLIP) != 0
func vflip*(se: ScrEntry): bool = (se and SE_VFLIP) != 0

func `tileId=`*(se: var ScrEntry, val: int) =  se = ((val.uint16 shl SE_ID_SHIFT) and SE_ID_MASK) or (se and not SE_ID_MASK)
func `palId=`*(se: var ScrEntry, val: int) =   se = ((val.uint16 shl SE_PALBANK_SHIFT) and SE_PALBANK_MASK) or (se and not SE_PALBANK_MASK)
func `hflip=`*(se: var ScrEntry, val: bool) =  se = (val.uint16 shl 10) or (se and not SE_HFLIP)
func `vflip=`*(se: var ScrEntry, val: bool) =  se = (val.uint16 shl 11) or (se and not SE_VFLIP)

# shorthands:

func tid*(se: ScrEntry): int = se.tileId
func pal*(se: ScrEntry): int = se.palId

func `tid=`*(se: var ScrEntry, tid: int) =  se.tileId = tid
func `pal=`*(se: var ScrEntry, pal: int) =  se.palId = pal

{.pop.}


# BG affine matrix functions
# -------------------------- 

proc setTo*(bgaff: var BgAffine; pa, pb, pc, pd: Fixed) {.importc: "bg_aff_set", toncinl.}
  ## Set the elements of a bg affine matrix.

proc setToIdentity*(bgaff: var BgAffine) {.importc: "bg_aff_identity", toncinl.}
  ## Set an bg affine matrix to the identity matrix

proc setToScale*(bgaff: var BgAffine; sx, sy: Fixed) {.importc: "bg_aff_scale", toncinl.}
  ## Set an bg affine matrix for scaling.

proc setToShearX*(bgaff: var BgAffine; hx: Fixed) {.importc: "bg_aff_shearx", toncinl.}
proc setToShearY*(bgaff: var BgAffine; hy: Fixed) {.importc: "bg_aff_sheary", toncinl.}

proc setToRotation*(bgaff: var BgAffine; alpha: uint16) {.importc: "bg_aff_rotate", tonc.}
  ## Set bg matrix to counter-clockwise rotation.
  ## 
  ## **Parameters:**
  ## 
  ## bgaff
  ##   BG affine struct to set.
  ## 
  ## alpha
  ##   CCW angle. full-circle is 10000h.

proc setToScaleAndRotation*(bgaff: var BgAffine; sx, sy: int; alpha: uint16) {.importc: "bg_aff_rotscale", tonc.}
  ## Set bg matrix to 2d scaling, then counter-clockwise rotation.
  ## 
  ## **Parameters:**
  ## 
  ## bgaff
  ##   BG affine struct to set.
  ## 
  ## sx
  ##   Horizontal scale (zoom). .8 fixed point.
  ## 
  ## sy
  ##   Vertical scale (zoom). .8 fixed point.
  ## 
  ## alpha
  ##   CCW angle. full-circle is 10000h.

proc setToScaleAndRotation*(bgaff: var BgAffine; affSrc: ptr AffSrc) {.importc: "bg_aff_rotscale2", tonc.}
  ## Set bg matrix to 2d scaling, then counter-clockwise rotation.
  ## 
  ## **Parameters:**
  ## 
  ## bgaff
  ##   BG affine struct to set.
  ## 
  ## affSrc
  ##   Struct with scales and angle.

proc premul*(dst: var BgAffine; src: ptr BgAffine) {.importc: "bg_aff_premul", tonc.}
  ## Pre-multiply the matrix `dst` by `src`
  ## 
  ## i.e. ::
  ##   dst = src * dst
  ## 
  ## .. warning::
  ##    Don't use this on `bgaff`_ registers, as they are write-only.

proc postmul*(dst: var BgAffine; src: ptr BgAffine) {.importc: "bg_aff_postmul", tonc.}
  ## Post-multiply the matrix `dst` by `src`
  ## 
  ## i.e. ::
  ##   dst = dst * src
  ## 
  ## .. warning::
  ##    Don't use this on `bgaff`_ registers, as they are write-only.

proc rotscaleEx*(bgaff: var BgAffine; asx: ptr AffSrcEx) {.importc: "bg_rotscale_ex", tonc.}
  ## Set bg affine matrix to a rot/scale around an arbitrary point.
  ## 
  ## **Parameters:**
  ## 
  ## bgaff
  ##   BG affine data to set.
  ## 
  ## asx
  ##   Affine source data: screen and texture origins, scales and angle.


# Miscellaneous
# -------------

proc setWindow*(winId: range[0..1]; bounds: Rect) {.inline.} =
  ## Apply a rectangular window to one of the window registers.
  ## 
  ## The rectangle is clamped to the bounds of the screen.
  winh[winId] = WinH(right: bounds.right.clamp(0, ScreenWidth).uint8, left: bounds.left.clamp(0, ScreenWidth).uint8)
  winv[winId] = WinV(bottom: bounds.bottom.clamp(0, ScreenHeight).uint8, top: bounds.top.clamp(0, ScreenHeight).uint8)
