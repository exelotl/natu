## Video functions
## ===============
## Basic video-IO, color, background and object functionality

{.warning[UnusedImport]: off.}

{.pragma: tonc, header:"tonc_video.h".}
{.pragma: toncinl, header:"tonc_video.h".}  # inline from header.

import std/macros
import ./private/[common, types]
from ./private/privutils import writeFields
import ./math
import ./utils
import ./bits

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

export ObjAttr, ObjAffine, ObjAttrPtr, ObjAffinePtr

# Constants
# ---------

const natuLcdWidth {.intdefine.} = 240
const natuLcdHeight {.intdefine.} = 160

when natuPlatform == "gba":
  static:
    assert(natuLcdWidth == 240 and natuLcdHeight == 160, "Can't change screen size on a real GBA.")

# Sizes in pixels
const
  ScreenWidth* = natuLcdWidth        ## Width in pixels
  ScreenHeight* = natuLcdHeight      ## Height in pixels
  ScreenLines* = natuLcdHeight + 68  ## Total number of scanlines (max vcount value)
  Mode3Width* = ScreenWidth
  Mode3Height* = ScreenHeight
  Mode4Width* = ScreenWidth
  Mode4Height* = ScreenHeight
  Mode5Width* = 160
  Mode5Height* = 128

# Size in tiles
const
  ScreenWidthInTiles* = (ScreenWidth+7) div 8    ## Width in tiles
  ScreenHeightInTiles* = (ScreenHeight+7) div 8  ## Height in tiles


# Display Control Register
# ------------------------

type
  DisplayLayer* {.size:4.} = enum
    lBg0, lBg1, lBg2, lBg3, lObj
  
  DisplayLayers* {.size:4.} = set[DisplayLayer]
  
  DispCnt* = distinct uint16

bitdef DispCnt, 0..3, mode, uint16
  # Video mode. `0`, `1`, `2` are tiled modes; `3`, `4`, `5` are bitmap modes. 
  # 
  # ===== ===============================================================
  # Mode  Description
  # ===== ===============================================================
  # 0     Tile mode: BG0 = text, BG1 = text, BG2 = text,   BG3 = text
  # 1     Tile mode: BG0 = text, BG1 = text, BG2 = affine, BG3 = off
  # 2     Tile mode: BG0 = off,  BG1 = off,  BG2 = affine, BG3 = affine
  # 3     Bitmap mode: 240x160, BGR555 color
  # 4     Bitmap mode: 240x160, 256 color palette
  # 5     Bitmap mode: 160x128, BGR555 color
  # ===== ===============================================================

bitdef DispCnt, 3, gb, bool, {ReadOnly}
  # True if cartridge is a GBC game. Read-only. 

bitdef DispCnt, 4, page, bool
  # Page select. Modes 4 and 5 can use page flipping for smoother animation.
  # This bit selects the displayed page (and allowing the other one to be drawn on without artifacts). 

bitdef DispCnt, 5, oamHbl, bool
  # Allows access to OAM during HBlank. Supposedly OAM is locked in VDraw, but that
  # doesn't seem to be true in practise. Therefore this flag does nothing, except reduce
  # the maximum amount of sprite pixels that can be rendered per scanline.

bitdef DispCnt, 6, obj1d, bool
  # Determines whether OBJ-VRAM is treated like an array or a matrix when drawing sprites.

bitdef DispCnt, 7, blank, bool
  # Forced Blank: When set, the GBA will display a white screen.
  # This allows fast access to VRAM, PAL RAM, OAM.

bitdef DispCnt, 8, bg0, bool
bitdef DispCnt, 9, bg1, bool
bitdef DispCnt, 10, bg2, bool
bitdef DispCnt, 11, bg3, bool
bitdef DispCnt, 12, obj, bool
bitdef DispCnt, 13, win0, bool
bitdef DispCnt, 14, win1, bool
bitdef DispCnt, 15, winObj, bool

bitdef DispCnt, 8..12, layers_u8, uint8, {Private}

func layers*(dcnt: DispCnt): DisplayLayers =
  ## Get the currently enabled display layers as a bit-set.
  cast[DisplayLayers](dcnt.layers_u8)

func `layers=`*(dcnt: var DispCnt, layers: DisplayLayers) =
  ## Update the currently enabled display layers.
  dcnt.layers_u8 = cast[uint8](layers)

const allDisplayLayers* = { lBg0, lBg1, lBg2, lBg3, lObj }


# Display Status Register
# -----------------------

type DispStat* = distinct uint16

bitdef DispStat, 0, inVBlank, bool, {ReadOnly}
  # VBlank status, read only.
  # True during VBlank, false during VDraw.

bitdef DispStat, 1, inHBlank, bool, {ReadOnly}
  # HBlank status, read-only (see getter proc).

bitdef DispStat, 2, inVCountTrigger, bool, {ReadOnly}
  # VCount trigger status, read-only (see getter proc).

bitdef DispStat, 3, vblankIrq, bool
  # VBlank interrupt request.
  # If set, an interrupt will be fired at VBlank.

bitdef DispStat, 4, hblankIrq, bool
  # HBlank interrupt request.
  # If set, an interrupt will be fired at HBlank.

bitdef DispStat, 5, vcountIrq, bool
  # VCount interrupt request.
  # If set, an interrupt will be fired when current scanline matches the scanline trigger (`vcount` == `dispstat.vcountTrigger`)

bitdef DispStat, 8..15, vcountTrigger, uint16
  # VCount trigger value.
  # If the current scanline is at this value, bit 2 is set and an interrupt is fired if requested. 


# Background Control Registers
# ----------------------------

type
  BgSize* = distinct uint16
  
  RegBgSize* {.size:2.} = enum
    ## Size of a regular background in tiles.
    ## Implicitly convertible to type `BgSize`.
    reg32x32
    reg64x32
    reg32x64
    reg64x64
  
  AffBgSize* {.size:2.} = enum
    ## Size of an affine background in tiles.
    ## Implicitly convertible to type `BgSize`.
    aff16x16
    aff32x32
    aff64x64
    aff128x128
  
  BgCnt* {.exportc.} = distinct uint16
    ## Background control register value.


bitdef BgCnt, 0..1, prio, uint16
  # Priority value (0..3)
  # Lower priority BGs will be drawn on top of higher priority BGs.

bitdef BgCnt, 2..3, cbb, uint16
  # Character Base Block (0..3)
  # Determines the base block for tile pixel data

bitdef BgCnt, 6, mos, bool
  # Enables mosaic effect.

bitdef BgCnt, 7, is8bpp, bool
  # Specifies the color mode of the BG: 4bpp (16 colors) or 8bpp (256 colors)
  # Has no effect on affine BGs, which are always 8bpp.

bitdef BgCnt, 8..12, sbb, uint16
  # Screen Base Block (0..31)
  # Determines the base block for the tilemap

bitdef BgCnt, 13, wrap, bool
  # Affine Wrapping flag.
  # If set, affine background wrap around at their edges.
  # Has no effect on regular backgrounds as they wrap around by default. 

bitdef BgCnt, 14..15, size, BgSize
  # Value representing the size of the background in tiles.
  # Regular and affine backgrounds have different sizes available to them, hence
  # the two different types assignable to this field (`RegBgSize`, `AffBgSize`)
    
converter toBgSize*(r: RegBgSize): BgSize = (r.BgSize)
converter toBgSize*(a: AffBgSize): BgSize = (a.BgSize)


# Window Registers
# ----------------

when natuPlatform == "gba":
  type
    WinH* {.exportc:"WinH".} = object
      ## Defines the horizontal bounds of a window (left ..< right)
      right*: uint8
      left*: uint8
    WinV* {.exportc:"WinV".} = object
      ## Defines the vertical bounds of a window (top ..< bottom)
      bottom*: uint8
      top*: uint8
else:
  type
    WinH* {.exportc:"WinH".} = object
      ## Defines the horizontal bounds of a window (left ..< right)
      right*: uint16
      left*: uint16
    WinV* {.exportc:"WinV".} = object
      ## Defines the vertical bounds of a window (top ..< bottom)
      bottom*: uint16
      top*: uint16
  
type
  WindowLayer* {.size:1.} = enum
    wlBg0, wlBg1, wlBg2, wlBg3, wlObj, wlBlend
  
  WinCnt* = set[WindowLayer]
    ## Allows to make changes to one half of a window control register.

const
  allWindowLayers* = { wlBg0, wlBg1, wlBg2, wlBg3, wlObj, wlBlend }


# Mosaic
# ------

type Mosaic* = distinct uint16

bitdef Mosaic, 0..3, bgh, uint16, {WriteOnly}
bitdef Mosaic, 4..7, bgv, uint16, {WriteOnly}
bitdef Mosaic, 8..11, objh, uint16, {WriteOnly}
bitdef Mosaic, 12..15, objv, uint16, {WriteOnly}


# Color Special Effects
# ---------------------

type
  BldCnt* = distinct uint16
    ## Blend control register
  
  BlendMode* {.size:2.} = enum
    ## Color special effects modes
    bmOff    ## Blending disabled
    bmAlpha  ## Alpha blend both A and B (using the weights from ``bldalpha``).
    bmWhite  ## Blend A with white using the weight from ``bldy``
    bmBlack  ## Blend A with black using the weight from ``bldy``
  
  BlendLayer* {.size:2.} = enum
    blBg0, blBg1, blBg2, blBg3, blObj, blBd
  
  BlendLayers* {.size:2.} = set[BlendLayer]

const allBlendLayers* = { blBg0, blBg1, blBg2, blBg3, blObj, blBd }

bitdef BldCnt, 0..5, a_u16, uint16, {Private}   # Upper layer of color special effects.
bitdef BldCnt, 6..7, mode, BlendMode            # Color special effects mode
bitdef BldCnt, 8..13, b_u16, uint16, {Private}  # Lower layer of color special effects.

func a*(bld: BldCnt): BlendLayers = cast[BlendLayers](bld.a_u16)
func b*(bld: BldCnt): BlendLayers = cast[BlendLayers](bld.b_u16)
func `a=`*(bld: var BldCnt, a: BlendLayers) = bld.a_u16 = cast[uint16](a)
func `b=`*(bld: var BldCnt, b: BlendLayers) = bld.b_u16 = cast[uint16](b)

type
  BlendAlpha* = distinct uint16
    ## Alpha blending levels.
    ## Features two coefficients: ``eva`` for layer ``a``, ``evb`` for layer ``b``.
  
  BlendBrightness* = distinct uint16
    ## Brightness level (fade to black or white).
    ## Has a single coefficient ``evy``.

bitdef BlendAlpha, 0..7, eva, uint16
  # Upper layer alpha blending coefficient.
  # Values from 17..31 are treated the same as 16.

bitdef BlendAlpha, 8..15, evb, uint16
  # Lower layer alpha blending coefficient
  # Values from 17..31 are treated the same as 16.


proc `evy=`*(bldy: var BlendBrightness, v: uint16) =
  ## Brightness coefficient (write-only!)
  ## Values from 17..31 are treated the same as 16.
  bldy = v.BlendBrightness


# TODO: improve how BG scroll registers are exposed.
# You should be able to write to them _and_ take their address, just not read them
type BgOfs = BgPoint



# Init/edit macros
# ----------------

type
  ReadWriteRegister = DispCnt | DispStat | BgCnt | WinCnt | BldCnt | BlendAlpha
  WriteOnlyRegister = BgOfs | BgAffine | WinH | WinV | BlendBrightness | Mosaic
  WritableRegister = ReadWriteRegister | WriteOnlyRegister


template init*[T:WritableRegister](r: T, args: varargs[untyped]) =
  ## Initialise an IO register to some combination of flags/values.
  ## E.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##   dispcnt.init:
  ##     mode = mode1
  ##     bg0 = true
  ##
  ## Can also be written as a one-liner:
  ## 
  ## .. code-block:: nim
  ## 
  ##   dispcnt.init(mode = mode1, bg0 = true)
  ## 
  ## These are both shorthand for:
  ## 
  ## .. code-block:: nim
  ## 
  ##   var tmp: DispCnt
  ##   tmp.mode = mode1
  ##   tmp.bg0 = true
  ##   dispcnt = tmp
  ## 
  ## Note that we could instead set each field on `dispcnt` directly:
  ## 
  ## .. code-block:: nim
  ## 
  ##   dispcnt.clear()
  ##   dispcnt.mode = mode1
  ##   dispcnt.bg0 = true
  ## 
  ## But this would be slower because `dispcnt` is *volatile*, so the C compiler can't optimise these lines into a single assignment.
  ## 
  var tmp: T
  writeFields(tmp, args)
  r = tmp

template clear*[T:WritableRegister](r: T) =
  ## Set all bits in a register to zero.
  r = default(T)

template edit*[T:ReadWriteRegister](r: T, args: varargs[untyped]) =
  ## Update the value of some fields in a register.
  ## This works similarly to `init`, but preserves all other fields besides the ones that are specified.
  ##
  ## E.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##   dispcnt.edit:
  ##     bg0 = false
  ##     obj = true
  ##     obj1d = true
  ##
  ## Is shorthand for:
  ## 
  ## .. code-block:: nim
  ## 
  ##   var tmp = dispcnt
  ##   tmp.bg0 = false
  ##   tmp.obj = true
  ##   tmp.obj1d = true
  ##   dispcnt = tmp
  ##
  var tmp = r
  writeFields(tmp, args)
  r = tmp

template dup*[T:ReadWriteRegister](r: T, args: varargs[untyped]): T =
  ## Copy the value of a register, modifying and returning the copy.
  ## 
  ## E.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##   # Make BG1 use the same tiles as BG0, but different map data.
  ##   bgcnt[1] = bgcnt[0].dup(sbb = 29)
  var res = r
  writeFields(res, args)
  res

template initDispCnt*(args: varargs[untyped]): DispCnt =
  ## Create a new display control register value.
  ## Omitted fields default to zero.
  var dcnt: DispCnt
  writeFields(dcnt, args)
  dcnt

template initBgCnt*(args: varargs[untyped]): BgCnt =
  ## Create a new background control register value.
  ## Omitted fields default to zero.
  var bg: BgCnt
  writeFields(bg, args)
  bg


# Set operation fixes

type LayerEnum = DisplayLayer | BlendLayer | WindowLayer

macro incl*[T:LayerEnum](x: set[T], y: T) =
  expectKind(x, nnkCall)
  let (field, reg) = (x[0], x[1])
  quote do:
    `reg`.`field` = `reg`.`field` + {y}

macro incl*[T:LayerEnum](x: set[T], y: set[T]) =
  expectKind(x, nnkCall)
  let (field, reg) = (x[0], x[1])
  quote do:
    `reg`.`field` = `reg`.`field` + y

macro excl*[T:LayerEnum](x: set[T], y: T) =
  expectKind(x, nnkCall)
  let (field, reg) = (x[0], x[1])
  quote do:
    `reg`.`field` = `reg`.`field` - {y}

macro excl*[T:LayerEnum](x: set[T], y: set[T]) =
  expectKind(x, nnkCall)
  let (field, reg) = (x[0], x[1])
  quote do:
    `reg`.`field` = `reg`.`field` - y



## Colors
## ------

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

proc clrRotate*(clrs: ptr Color; nclrs: cint; ror: cint) {.importc: "clr_rotate", tonc.}
  ## Rotate `nclrs` colors at `clrs` to the right by `ror`.

proc clrBlend*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs: cint; alpha: cint) {.importc: "clr_blend", tonc.}
  ## Blends color arrays `srca` and `srcb` into `dst`.
  ## Specific transitional blending effects can be created by making a 'target' color array
  ## with other routines, then using `alpha` to morph into it.
  ## 
  ## :srca: Source array A.
  ## :srcb: Source array B.
  ## :dst: Destination array.
  ## :nclrs: Number of colors.
  ## :alpha: Blend weight (range: 0-32). 0 Means full `srca`

proc clrFade*(src: ptr Color; clr: Color; dst: ptr Color; nclrs: cint; alpha: cint) {.importc: "clr_fade", tonc.}
  ## Fades color arrays `srca` to `clr` into `dst`.
  ## 
  ## :src: Source array.
  ## :clr: Final color (at alpha=32).
  ## :dst: Destination array.
  ## :nclrs: Number of colors.
  ## :alpha: Blend weight (range: 0-32). 0 Means full `srca`

proc clrGrayscale*(dst: ptr Color; src: ptr Color; nclrs: cint) {.importc: "clr_grayscale", tonc.}
  ## Transform colors to grayscale.
  ## 
  ## :dst: Destination color array
  ## :src: Source color array.
  ## :nclrs: Number of colors.

proc clrRgbscale*(dst: ptr Color; src: ptr Color; nclrs: cint; clr: Color) {.importc: "clr_rgbscale", tonc.}
  ## Transform colors to an rgb-scale.
  ## .. note::
  ##    `clr` indicates a color vector in RGB-space. Each source color is converted to a brightness value (i.e. grayscale)
  ##    and then mapped onto that color vector. A grayscale is a special case of this, using a color with R=G=B.
  ## 
  ## :dst: Destination color array
  ## :src: Source color array.
  ## :nclrs: Number of colors.
  ## :clr: Destination color vector.

proc clrAdjBrightness*(dst: ptr Color; src: ptr Color; nclrs: cint; bright: Fixed) {.importc: "clr_adj_brightness", tonc.}
  ## Adjust brightness by `bright`
  ## Operation: `color= color+dB`;
  ## 
  ## :dst: Destination color array
  ## :src: Source color array.
  ## :nclrs: Number of colors.
  ## :bright: Brightness difference, dB (in 24.8f)

proc clrAdjContrast*(dst: ptr Color; src: ptr Color; nclrs: cint; contrast: Fixed) {.importc: "clr_adj_contrast", tonc.}
  ## Adjust contrast by `contrast`
  ## Operation: `color = color*(1+dC) - MAX*dC/2`
  ## 
  ## :dst: Destination color array
  ## :src: Source color array.
  ## :nclrs: Number of colors.
  ## :contrast: Contrast difference, dC (in 24.8f)

proc clrAdjIntensity*(dst: ptr Color; src: ptr Color; nclrs: cint; intensity: Fixed) {.importc: "clr_adj_intensity", tonc.}
  ## Adjust intensity by `intensity`. 
  ## Operation: `color = (1+dI)*color`.
  ## 
  ## :dst: Destination color array
  ## :src: Source color array.
  ## :nclrs: Number of colors.
  ## :intensity: Intensity difference, dI (in 24.8f)

proc palGradient*(pal: ptr Color; first: cint; last: cint) {.importc: "pal_gradient", tonc.}
  ## Create a gradient between `pal[first]` and `pal[last]`.
  ## 
  ## :pal: Palette to work on.
  ## :first: First index of gradient.
  ## :last: Last index of gradient.

proc palGradient*(pal: ptr Color; first, last: cint; clrFirst, clrLast: Color) {.importc: "pal_gradient_ex", tonc.}
  ## Create a gradient between `pal[first]` and `pal[last]`.
  ## 
  ## :pal: Palette to work on.
  ## :first: First index of gradient.
  ## :last: Last index of gradient.
  ## :clrFirst: Color of first index.
  ## :clrLast: Color of last index.


# Objects (sprites)
# -----------------

type
  ObjMode* {.size:2.} = enum
    omRegular
    omAffine
    omHidden
    omAffineDouble
  
  ObjFxMode* {.size:2.} = enum
    fxNone
      ## Normal object, no special effects.
    fxBlend
      ## Alpha blending enabled.
      ## The object is effectively placed into the `bldcnt.a` layer to be blended
      ## with the `bldcnt.b` layer using the coefficients from `bldalpha`,
      ## regardless of the current `bldcnt.mode` setting.
    fxWindow
      ## The sprite becomes part of the object window.
  
  ObjSize* {.size:2.} = enum
    ## Sprite size constants, high-level interface.
    ## Each corresponds to a pair of fields (`size` in attr0, `shape` in attr1)
    s8x8, s16x16, s32x32, s64x64,
    s16x8, s32x8, s32x16, s64x32,
    s8x16, s8x32, s16x32, s32x64


# Platform specific code
# ----------------------

when natuPlatform == "gba": include ./private/gba/video 
elif natuPlatform == "sdl": include ./private/sdl/video
else: {.error: "Unknown platform " & natuPlatform.}


# ID shorthands:

func aff*(obj: ObjAttr): int = obj.affId
func tid*(obj: ObjAttr): int = obj.tileId
func pal*(obj: ObjAttr): int = obj.palId

func `aff=`*(obj: var ObjAttr; aff: int) = obj.affId = aff
func `tid=`*(obj: var ObjAttr; tid: int) = obj.tileId = tid
func `pal=`*(obj: var ObjAttr; pal: int) = obj.palId = pal


template initObj*(args: varargs[untyped]): ObjAttr =
  ## Create a new ObjAttr value.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[0] = initObj(
  ##     pos = vec2i(100, 100),
  ##     size = s32x32,
  ##     tileId = 0,
  ##     palId = 3
  ##   )
  var obj: ObjAttr
  writeFields(obj, args)
  obj

template init*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Initialise an object in-place.
  ## 
  ## Omitted fields will default to zero.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[0].init(
  ##     pos = vec2i(100, 100),
  ##     size = s32x32,
  ##     tileId = 0,
  ##     palId = 3
  ##   )
  obj.setAttr(0, 0, 0)
  writeFields(obj, args)

template edit*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Change some fields of an object.
  ## 
  ## Like `obj.init`, but omitted fields will be left unchanged.
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[0].edit(
  ##     pos = vec2i(100, 100),
  ##     size = s32x32,
  ##     tileId = 0,
  ##     palId = 3
  ##   )
  ## 
  writeFields(obj, args)


template dup*(obj: ObjAttr, args: varargs[untyped]): ObjAttr =
  ## Duplicate an object, modifying some fields and returning the copy.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##    
  ##    # Make a copy of Obj 0, but change some properties:
  ##    objMem[1] = objMem[0].dup(x = 100, hflip = true)
  ##    
  var tmp = obj
  writeFields(tmp, args)
  tmp


# Size helpers:

const oamSizes: array[ObjSize, array[2, uint8]] = [
  [ 8'u8, 8'u8], [16'u8,16'u8], [32'u8,32'u8], [64'u8,64'u8], 
  [16'u8, 8'u8], [32'u8, 8'u8], [32'u8,16'u8], [64'u8,32'u8],
  [ 8'u8,16'u8], [ 8'u8,32'u8], [16'u8,32'u8], [32'u8,64'u8],
]

func getSize*(size: ObjSize): tuple[w, h: int] =
  ## Get the width and height in pixels of an `ObjSize` enum value.
  let arr = oamSizes[size]
  (arr[0].int, arr[1].int)
  
func getWidth*(size: ObjSize): int =
  ## Get the width in pixels of an `ObjSize` enum value.
  oamSizes[size][0].int

func getHeight*(size: ObjSize): int =
  ## Get the height in pixels of an `ObjSize` enum value.
  oamSizes[size][1].int

func getSize*(obj: ObjAttr | ObjAttrPtr): tuple[w, h: int] =
  ## Get the width and height of an object in pixels.
  getSize(obj.size)
  
func getWidth*(obj: ObjAttr | ObjAttrPtr): int =
  ## Get the width of an object in pixels.
  getWidth(obj.size)
  
func getHeight*(obj: ObjAttr | ObjAttrPtr): int =
  ## Get the height of an object in pixels.
  getHeight(obj.size)


func hide*(obj: var ObjAttr) =
  ## Hide an object.
  ## 
  ## Equivalent to ``obj.mode = omHidden``
  ## 
  obj.mode = omHidden

func unhide*(obj: var ObjAttr; mode = omRegular) =
  ## Unhide an object.
  ## 
  ## Equivalent to ``obj.mode = mode``
  ## 
  ## **Parameters:**
  ## 
  ## obj
  ##   Object to unhide.
  ## 
  ## mode
  ##   Object mode to unhide to. Necessary because this affects the affine-ness of the object.
  ## 
  obj.mode = mode

{.pop.}


# proc bgIsAffine*(n: int): bool {.importc: "BG_IS_AFFINE", toncinl.}
# proc bgIsAvailable*(n: int): bool {.importc: "BG_IS_AVAIL", toncinl.}

proc bmp8_plot(x, y: cint; clrid: uint8; dstBase: pointer; dstP: cuint) {.importc:"bmp8_plot", tonc.}
proc bmp8_hline(x1, y, x2: cint; clrid: uint8; dstBase: pointer; dstP: cuint) {.importc:"bmp8_hline", tonc.}
proc bmp8_vline(x, y1, y2: cint; clrid: uint8; dstBase: pointer; dstP: cuint) {.importc:"bmp8_vline", tonc.}
proc bmp8_line(x1, y1, x2: cint; y2: cint; clrid: uint8; dstBase: pointer; dstP: cuint) {.importc:"bmp8_line", tonc.}
proc bmp8_rect(left, top, right, bottom: cint; clrid: uint8; dstBase: pointer; dstP: cuint) {.importc:"bmp8_rect", tonc.}
proc bmp8_frame(left, top, right, bottom: cint; clrid: uint8; dstBase: pointer; dstP: cuint) {.importc:"bmp8_frame", tonc.}
proc bmp16_plot(x, y, clr: Color; dstBase: pointer; dstP: cuint) {.importc:"bmp16_plot", tonc.}
proc bmp16_hline(x1, y, x2: cint; clr: Color; dstBase: pointer; dstP: cuint) {.importc:"bmp16_hline", tonc.}
proc bmp16_vline(x, y1, y2: cint; clr: Color; dstBase: pointer; dstP: cuint) {.importc:"bmp16_vline", tonc.}
proc bmp16_line(x1, y1, x2, y2: cint; clr: Color; dstBase: pointer; dstP: cuint) {.importc:"bmp16_line", tonc.}
proc bmp16_rect(left, top, right, bottom: cint; clr: Color; dstBase: pointer; dstP: cuint) {.importc:"bmp16_rect", tonc.}
proc bmp16_frame(left, top, right, bottom: cint; clr: Color; dstBase: pointer; dstP: cuint) {.importc:"bmp16_frame", tonc.}


proc clear*[T: Screenblock | Charblock | Charblock8 | Tile | Tile8 | M3Mem | M4Mem | M5Mem](dst: var T) {.inline.} =
  ## Clear a region of VRAM (i.e. map, tiles or framebuffer).
  memset32(addr dst, 0, sizeof(T) div 4)

# Screenblock tile plotting
# -------------------------

{.push inline.}

proc fill*(sbb: var Screenblock; se: ScrEntry) =
  ## Fill screenblock `sbb` with `se`.
  memset32(addr sbb, dup16(se.uint16), sizeof(sbb) div 4)

proc plot*(sbb: var Screenblock; x, y: cint; se: ScrEntry) =
  ## Plot a screen entry at (`x`,`y`) of screenblock `sbb`.
  sbb[x,y] = se

proc hline*(sbb: var Screenblock; x0, x1, y: cint; se: ScrEntry) =
  ## Draw a horizontal line on screenblock `sbb` with `se`.
  bmp16_hline(x0, y, x1, se.Color, addr sbb, 32*2)

proc vline*(sbb: var Screenblock; x, y0, y1: cint; se: ScrEntry) =
  ## Draw a vertical line on screenblock `sbb` with `se`.
  bmp16_vline(x, y0, y1, se.Color, addr sbb, 32*2)

proc rect*(sbb: var Screenblock; left, top, right, bottom: cint; se: ScrEntry) =
  ## Fill a rectangle on `sbb` with `se`.
  bmp16_rect(left, top, right, bottom, se.Color, addr sbb, 32*2)

proc frame*(sbb: var Screenblock; left, top, right, bottom: cint; se: ScrEntry) =
  ## Create a border on `sbb` with `se`.
  bmp16_frame(left, top, right, bottom, se.Color, addr sbb, 32*2)

proc window*(sbb: var Screenblock; left, top, right, bottom: cint; se0: ScrEntry) {.importc: "se_window", tonc.}
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

proc plot*(m: var M3Mem; x, y: cint; clr: Color) =
  ## Plot a single colored pixel in mode 3 at (`x`, `y`).
  m[y][x] = clr

proc hline*(m: var M3Mem; x1, y, x2: cint; clr: Color) =
  ## Draw a colored horizontal line in mode 3.
  bmp16_hline(x1, y, x2, clr, addr m, Mode3Width*2)

proc vline*(m: var M3Mem; x, y1, y2: cint; clr: Color) =
  ## Draw a colored vertical line in mode 3.
  bmp16_vline(x, y1, y2, clr, addr m, Mode3Width*2)

proc line*(m: var M3Mem; x1, y1, x2, y2: cint; clr: Color) =
  ## Draw a colored line in mode 3.
  bmp16_line(x1, y1, x2, y2, clr, addr m, Mode3Width*2)

proc rect*(m: var M3Mem; left, top, right, bottom: cint; clr: Color) =
  ## Draw a colored rectangle in mode 3.
  ## 
  ## **Parameters:**
  ## :left: Left side, inclusive.
  ## :top: Top size, inclusive.
  ## :right: Right size, exclusive.
  ## :bottom: Bottom size, exclusive.
  ## :clr: Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_rect(left, top, right, bottom, clr, addr m, Mode3Width*2)

proc frame*(m: var M3Mem; left, top, right, bottom: cint; clr: Color) =
  ## Draw a colored frame in mode 3.
  ## 
  ## :left: Left side, inclusive.
  ## :top: Top size, inclusive.
  ## :right: Right size, exclusive.
  ## :bottom: Bottom size, exclusive.
  ## :clr: Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_frame(left, top, right, bottom, clr, addr m, Mode3Width*2)

{.pop.}


{.push inline.}

proc fill*(m: var M4Mem; clrid: uint8) =
  ## Fill the given mode 4 buffer with `clrid`.
  memset32(addr m, quad8(clrid), sizeof(m) div 4)

proc plot*(m: var M4Mem; x, y: cint; clrid: uint8) =
  ## Plot a `clrid` pixel on the given mode 4 buffer.
  bmp8_plot(x, y, clrid, addr m, Mode4Width)

proc hline*(m: var M4Mem; x1, y, x2: cint; clrid: uint8) =
  ## Draw a `clrid` colored horizontal line in mode 4.
  bmp8_hline(x1, y, x2, clrid, addr m, Mode4Width)

proc vline*(m: var M4Mem; x, y1, y2: cint; clrid: uint8) =
  ## Draw a `clrid` colored vertical line in mode 4.
  bmp8_vline(x, y1, y2, clrid, addr m, Mode4Width)

proc line*(m: var M4Mem; x1, y1, x2, y2: cint; clrid: uint8) =
  ## Draw a `clrid` colored line in mode 4.
  bmp8_line(x1, y1, x2, y2, clrid, addr m, Mode4Width)

proc rect*(m: var M4Mem; left, top, right, bottom: cint; clrid: uint8) =
  ## Draw a `clrid` colored rectangle in mode 4.
  ## 
  ## :left: Left side, inclusive.
  ## :top: Top size, inclusive.
  ## :right: Right size, exclusive.
  ## :bottom: Bottom size, exclusive.
  ## :clrid: Color index.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp8_rect(left, top, right, bottom, clrid, addr m, Mode4Width)

proc frame*(m: var M4Mem; left, top, right, bottom: cint; clrid: uint8) =
  ## Draw a `clrid` colored frame in mode 4.
  ## 
  ## :left: Left side, inclusive.
  ## :top: Top size, inclusive.
  ## :right: Right size, exclusive.
  ## :bottom: Bottom size, exclusive.
  ## :clrid: Color index.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp8_frame(left, top, right, bottom, clrid, addr m, Mode4Width)

{.pop.}

{.push inline.}

proc fill*(m: var M5Mem; clr: Color) =
  ## Fill the given mode 5 buffer with `clr`.
  memset32(addr m, dup16(clr.uint16), sizeof(m) div 4)

proc plot*(m: var M5Mem; x, y: cint; clr: Color) =
  ## Plot a `clrid` pixel on the given mode 5 buffer.
  m[y][x] = clr

proc hline*(m: var M5Mem; x1, y, x2: cint; clr: Color) =
  ## Draw a colored horizontal line in mode 5.
  bmp16_hline(x1, y, x2, clr, addr m, Mode5Width*2)

proc vline*(m: var M5Mem; x, y1, y2: cint; clr: Color) =
  ## Draw a colored vertical line in mode 5.
  bmp16_vline(x, y1, y2, clr, addr m, Mode5Width*2)

proc line*(m: var M5Mem; x1, y1, x2, y2: cint; clr: Color) =
  ## Draw a colored line in mode 5.
  bmp16_line(x1, y1, x2, y2, clr, addr m, Mode5Width*2)

proc rect*(m: var M5Mem; left, top, right, bottom: cint; clr: Color) =
  ## Draw a colored rectangle in mode 5.
  ## 
  ## :left: Left side, inclusive.
  ## :top: Top size, inclusive.
  ## :right: Right size, exclusive.
  ## :bottom: Bottom size, exclusive.
  ## :clr: Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_rect(left, top, right, bottom, clr, addr m, Mode5Width*2)

proc frame*(m: var M5Mem; left, top, right, bottom: cint; clr: Color) =
  ## Draw a colored frame in mode 5.
  ## 
  ## :left: Left side, inclusive.
  ## :top: Top size, inclusive.
  ## :right: Right size, exclusive.
  ## :bottom: Bottom size, exclusive.
  ## :clr: Color.
  ## 
  ## .. note::
  ##    The rectangle is normalized, but not clipped.
  bmp16_frame(left, top, right, bottom, clr, addr m, Mode5Width*2)

{.pop.}


# Extras
# ------

# Convenience procs for working with tile map entries

bitdef ScrEntry, 0..9, tileId, int
bitdef ScrEntry, 10, hflip, bool
bitdef ScrEntry, 11, vflip, bool
bitdef ScrEntry, 12..15, palId, int

# shorthands:
bitdef ScrEntry, 0..9, tid, int
bitdef ScrEntry, 12..15, pal, int


# BG affine matrix functions
# -------------------------- 

proc init*(bgaff: var BgAffine; pa, pb, pc, pd: Fixed) {.importc: "bg_aff_set", toncinl.}
  ## Set the elements of a bg affine matrix.

proc setToIdentity*(bgaff: var BgAffine) {.importc: "bg_aff_identity", toncinl.}
  ## Set a bg affine matrix to the identity matrix

proc setToScaleRaw*(bgaff: var BgAffine; sx, sy: Fixed) {.importc: "bg_aff_scale", toncinl.}
proc setToShearXRaw*(bgaff: var BgAffine; hx: Fixed) {.importc: "bg_aff_shearx", toncinl.}
proc setToShearYRaw*(bgaff: var BgAffine; hy: Fixed) {.importc: "bg_aff_sheary", toncinl.}
proc setToRotationRaw*(bgaff: var BgAffine; alpha: uint16) {.importc: "bg_aff_rotate", tonc.}
proc setToScaleAndRotationRaw*(bgaff: var BgAffine; sx, sy: Fixed; alpha: uint16) {.importc: "bg_aff_rotscale", tonc.}

proc setToScale*(bgaff: var BgAffine; sx: Fixed, sy = sx) {.inline.} =
  ## Set an bg affine matrix for scaling.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  bgaff.setToScaleRaw(x.Fixed, y.Fixed)

proc setToRotation*(bgaff: var BgAffine; theta: uint16) {.inline.} =
  ## Set bg matrix to counter-clockwise rotation.
  ## 
  ## :bgaff: BG affine struct to set.
  ## :alpha: CCW angle. full-circle is 0x10000.
  bgaff.setToRotationRaw(0'u16 - theta)

proc setToShearX*(bgaff: var BgAffine; hx: Fixed) {.inline.} =
  bgaff.setToShearXRaw(-hx)

proc setToShearY*(bgaff: var BgAffine; hy: Fixed) {.inline.} =
  bgaff.setToShearYRaw(-hy)

proc setToScaleAndRotation*(bgaff: var BgAffine; sx, sy: Fixed; theta: uint16) {.inline.} =
  ## Set bg matrix to 2d scaling, then counter-clockwise rotation.
  ## 
  ## :bgaff: BG affine struct to set.
  ## :sx:    Horizontal scale (zoom). 24.8 fixed point.
  ## :sy:    Vertical scale (zoom). 24.8 fixed point.
  ## :alpha: CCW angle. full-circle is 0x10000.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  bgaff.setToScaleAndRotationRaw(x.Fixed, y.Fixed, 0'u16 - theta)

proc premul*(dst: var BgAffine; src: ptr BgAffine) {.importc: "bg_aff_premul", tonc.}
  ## Pre-multiply the matrix `dst` by `src`
  ## 
  ## i.e. ``dst = src * dst``
  ## 
  ## .. warning::
  ##    Don't use this on `bgaff <#bgaff>`_ registers, as they are write-only.

proc postmul*(dst: var BgAffine; src: ptr BgAffine) {.importc: "bg_aff_postmul", tonc.}
  ## Post-multiply the matrix `dst` by `src`
  ## 
  ## i.e. ``dst = dst * src``
  ## 
  ## .. warning::
  ##    Don't use this on `bgaff`_ registers, as they are write-only.

proc rotscaleEx*(bgaff: var BgAffine; asx: ptr AffSrcEx) {.importc: "bg_rotscale_ex", tonc.}
  ## Set bg affine matrix to a rot/scale around an arbitrary point.
  ## 
  ## :bgaff: BG affine data to set.
  ## :asx:   Affine source data: screen and texture origins, scales and angle.


# Miscellaneous
# -------------

proc setWindow*(winId: range[0..1]; bounds: Rect) {.inline.} =
  ## Apply a rectangular window to one of the window registers.
  ## 
  ## The rectangle is clamped to the bounds of the screen.
  winh[winId] = WinH(right: bounds.right.clamp(0, ScreenWidth).uint8, left: bounds.left.clamp(0, ScreenWidth).uint8)
  winv[winId] = WinV(bottom: bounds.bottom.clamp(0, ScreenHeight).uint8, top: bounds.top.clamp(0, ScreenHeight).uint8)

proc busyWaitForVBlank* {.inline.} =
  while vcount >= 160: discard
  while vcount < 160: discard
