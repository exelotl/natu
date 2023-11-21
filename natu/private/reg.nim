
## High level wrappers over register definitions from memmap.nim

import ./types
import ./memdef
from ./privutils import writeFields
import ../bits

{.push inline.}

# raw cast helper
template `as`[T](a: typed; t: typedesc[T]): T =
  cast[ptr T](unsafeAddr a)[]


# Display Control Register
# ------------------------

type
  DisplayLayer* {.size:4.} = enum
    lBg0, lBg1, lBg2, lBg3, lObj
  
  DisplayLayers* {.size:4.} = set[DisplayLayer]
  
  DispCnt* = distinct uint16

defineBits DispCnt, 0..3, mode, uint16
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

defineBit DispCnt, 3, gb, bool, {ReadOnly}
  # True if cartridge is a GBC game. Read-only. 

defineBit DispCnt, 4, page, bool
  # Page select. Modes 4 and 5 can use page flipping for smoother animation.
  # This bit selects the displayed page (and allowing the other one to be drawn on without artifacts). 

defineBit DispCnt, 5, oamHbl, bool
  # Allows access to OAM in during HBlank. OAM is normally locked in VDraw.
  # Will reduce the amount of sprite pixels rendered per line. 

defineBit DispCnt, 6, obj1d, bool
  # Determines whether OBJ-VRAM is treated like an array or a matrix when drawing sprites.

defineBit DispCnt, 7, blank, bool
  # Forced Blank: When set, the GBA will display a white screen.
  # This allows fast access to VRAM, PAL RAM, OAM.

defineBit DispCnt, 8, bg0, bool
defineBit DispCnt, 9, bg1, bool
defineBit DispCnt, 10, bg2, bool
defineBit DispCnt, 11, bg3, bool
defineBit DispCnt, 12, obj, bool
defineBit DispCnt, 13, win0, bool
defineBit DispCnt, 14, win1, bool
defineBit DispCnt, 15, winObj, bool

defineBits DispCnt, 8..12, layersU8, uint8, {Private}

func layers*(dcnt: DispCnt): DisplayLayers =
  ## Get the currently enabled display layers as a bit-set.
  cast[DisplayLayers](dcnt.layersU8)

func `layers=`*(dcnt: var DispCnt, layers: DisplayLayers) =
  ## Update the currently enabled display layers.
  dcnt.layersU8 = cast[uint8](layers)

const allDisplayLayers* = { lBg0, lBg1, lBg2, lBg3, lObj }


# Display Status Register
# -----------------------

type DispStat* = distinct uint16

defineBit DispStat, 0, inVBlank, bool, {ReadOnly}
  # VBlank status, read only.
  # True during VBlank, false during VDraw.

defineBit DispStat, 1, inHBlank, bool, {ReadOnly}
  # HBlank status, read-only (see getter proc).

defineBit DispStat, 2, inVCountTrigger, bool, {ReadOnly}
  # VCount trigger status, read-only (see getter proc).

defineBit DispStat, 3, vblankIrq, bool
  # VBlank interrupt request.
  # If set, an interrupt will be fired at VBlank.

defineBit DispStat, 4, hblankIrq, bool
  # HBlank interrupt request.
  # If set, an interrupt will be fired at HBlank.

defineBit DispStat, 5, vcountIrq, bool
  # VCount interrupt request.
  # If set, an interrupt will be fired when current scanline matches the scanline trigger (`vcount` == `dispstat.vcountTrigger`)

defineBits DispStat, 8..15, vcountTrigger, uint16
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


defineBits BgCnt, 0..1, prio, uint16
  # Priority value (0..3)
  # Lower priority BGs will be drawn on top of higher priority BGs.

defineBits BgCnt, 2..3, cbb, uint16
  # Character Base Block (0..3)
  # Determines the base block for tile pixel data

defineBit BgCnt, 6, mos, bool
  # Enables mosaic effect.

defineBit BgCnt, 7, is8bpp, bool
  # Specifies the color mode of the BG: 4bpp (16 colors) or 8bpp (256 colors)
  # Has no effect on affine BGs, which are always 8bpp.

defineBits BgCnt, 8..12, sbb, uint16
  # Screen Base Block (0..31)
  # Determines the base block for the tilemap

defineBit BgCnt, 13, wrap, bool
  # Affine Wrapping flag.
  # If set, affine background wrap around at their edges.
  # Has no effect on regular backgrounds as they wrap around by default. 

defineBits BgCnt, 14..15, size, BgSize
  # Value representing the size of the background in tiles.
  # Regular and affine backgrounds have different sizes available to them, hence
  # the two different types assignable to this field (`RegBgSize`, `AffBgSize`)
    
converter toBgSize*(r: RegBgSize): BgSize = (r.BgSize)
converter toBgSize*(a: AffBgSize): BgSize = (a.BgSize)


# Window Registers
# ----------------

type
  WinH* {.exportc:"WinH".} = object
    ## Defines the horizontal bounds of a window (left ..< right)
    right* {.bitsize:8.}: uint8
    left* {.bitsize:8.}: uint8
  WinV* {.exportc:"WinV".} = object
    ## Defines the vertical bounds of a window (top ..< bottom)
    bottom* {.bitsize:8.}: uint8
    top* {.bitsize:8.}: uint8
  
  WindowLayer* {.size:1.} = enum
    wlBg0, wlBg1, wlBg2, wlBg3, wlObj, wlBlend
  
  WinCnt* = set[WindowLayer]
    ## Allows to make changes to one half of a window control register.

const
  allWindowLayers* = { wlBg0, wlBg1, wlBg2, wlBg3, wlObj, wlBlend }

# Mosaic
# ------

type Mosaic* = distinct uint32

# Once again, hiding these since the register is write-only.
# template bgh*(mos: Mosaic): uint32 = (mos.uint32 and MOS_BH_MASK) shr MOS_BH_SHIFT
# template bgv*(mos: Mosaic): uint32 = (mos.uint32 and MOS_BV_MASK) shr MOS_BV_SHIFT
# template objh*(mos: Mosaic): uint32 = (mos.uint32 and MOS_OH_MASK) shr MOS_OH_SHIFT
# template objv*(mos: Mosaic): uint32 = (mos.uint32 and MOS_OV_MASK) shr MOS_OV_SHIFT

template `bgh=`*(mos: Mosaic, v: SomeInteger) = mos = (((v.uint32 and 0x000f) shl MOS_BH_SHIFT) or (mos.uint32 and not MOS_BH_MASK)).Mosaic
template `bgv=`*(mos: Mosaic, v: SomeInteger) = mos = (((v.uint32 and 0x000f) shl MOS_BV_SHIFT) or (mos.uint32 and not MOS_BV_MASK)).Mosaic
template `objh=`*(mos: Mosaic, v: SomeInteger) = mos = (((v.uint32 and 0x000f) shl MOS_OH_SHIFT) or (mos.uint32 and not MOS_OH_MASK)).Mosaic
template `objv=`*(mos: Mosaic, v: SomeInteger) = mos = (((v.uint32 and 0x000f) shl MOS_OV_SHIFT) or (mos.uint32 and not MOS_OV_MASK)).Mosaic


# Color Special Effects
# ---------------------

type
  BldCnt* = distinct uint16
    ## Blend control register
  
  BlendMode* {.size:2.} = enum
    ## Color special effects modes
    bmOff = BLD_OFF       ## Blending disabled
    bmAlpha = BLD_STD     ## Alpha blend both A and B (using the weights from ``bldalpha``)
    bmWhite = BLD_WHITE   ## Blend A with white using the weight from ``bldy``
    bmBlack = BLD_BLACK   ## Blend A with black using the weight from ``bldy``
  
  BlendLayer* {.size:2.} = enum
    blBg0, blBg1, blBg2, blBg3, blObj, blBd
  
  BlendLayers* {.size:2.} = set[BlendLayer]

const allBlendLayers* = { blBg0, blBg1, blBg2, blBg3, blObj, blBd }

proc a*(bld: BldCnt): BlendLayers =
  ## Upper layer of color special effects.
  cast[BlendLayers](bld.uint16 and BLD_TOP_MASK)

proc `a=`*(bld: var BldCnt, layers: BlendLayers) =
  bld = ((bld.uint16 and not BLD_TOP_MASK) or (cast[uint16](layers))).BldCnt

proc b*(bld: BldCnt): BlendLayers =
  ## Lower layer of color special effects.
  cast[BlendLayers]((bld.uint16 and BLD_BOT_MASK) shr BLD_BOT_SHIFT)

proc `b=`*(bld: var BldCnt, layers: BlendLayers) =
  bld = ((bld.uint16 and not BLD_BOT_MASK) or (cast[uint16](layers) shl BLD_BOT_SHIFT)).BldCnt


# Old names - I think `a` and `b` are way better because they correspond to `eva` and `evb` and cannot be confused with window positions.

proc top*(bld: BldCnt): BlendLayers {.inline, deprecated:"Use bldcnt.a instead".} =
  cast[BlendLayers](bld.uint16 and BLD_TOP_MASK)
proc `top=`*(bld: var BldCnt, layers: BlendLayers) {.inline, deprecated:"Use bldcnt.a instead".} =
  bld = ((bld.uint16 and not BLD_TOP_MASK) or (cast[uint16](layers))).BldCnt
proc bottom*(bld: BldCnt): BlendLayers {.inline, deprecated:"Use bldcnt.b instead".} =
  cast[BlendLayers]((bld.uint16 and BLD_BOT_MASK) shr BLD_BOT_SHIFT)
proc `bottom=`*(bld: var BldCnt, layers: BlendLayers) {.inline, deprecated:"Use bldcnt.b instead".} =
  bld = ((bld.uint16 and not BLD_BOT_MASK) or (cast[uint16](layers) shl BLD_BOT_SHIFT)).BldCnt


proc mode*(bld: BldCnt): BlendMode =
  ## Color special effects mode
  (bld.uint16 and BLD_MODE_MASK).BlendMode

proc `mode=`*(bld: var BldCnt, v: BlendMode) =
  bld = (v.uint16 or (bld.uint16 and not BLD_MODE_MASK)).BldCnt

type
  BlendCoefficient* = uint16
    ## A blend value ranging from 0..16.
    ## Values from 17..31 are treated the same as 16.
  
  BlendAlpha* = distinct uint16
    ## Alpha blending levels.
    ## Features two coefficients: ``eva`` for the top layer, ``evb`` for the bottom layer.
  
  BlendBrightness* = distinct uint16
    ## Brightness level (fade to black or white).
    ## Has a single coefficient ``evy``.

proc eva*(bldalpha: BlendAlpha): BlendCoefficient =
  ## Upper layer alpha blending coefficient
  (bldalpha.uint16 and BLD_EVA_MASK).BlendCoefficient

proc `eva=`*(bldalpha: var BlendAlpha, v: BlendCoefficient) =
  bldalpha = ((bldalpha.uint16 and not BLD_EVA_MASK) or (v.uint16)).BlendAlpha

proc evb*(bldalpha: BlendAlpha): BlendCoefficient =
  ## Lower layer alpha blending coefficient
  ((bldalpha.uint16 and BLD_EVB_MASK) shr BLD_EVB_SHIFT).BlendCoefficient

proc `evb=`*(bldalpha: var BlendAlpha, v: BlendCoefficient) =
  bldalpha = ((bldalpha.uint16 and not BLD_EVB_MASK) or (v.uint16 shl BLD_EVB_SHIFT)).BlendAlpha


proc `evy=`*(bldy: var BlendBrightness, v: BlendCoefficient) =
  ## Brightness coefficient (write-only!)
  bldy = v.BlendBrightness


# TODO: improve how BG scroll registers are exposed.
# You should be able to write to them _and_ take their address, just not read them
type BgOfs = BgPoint

#[
type BgOfs = distinct BgPoint
  ## Like BgPoint but write-only

template `x=`*(ofs: BgOfs, v: int16) =
  cast[ptr BgPoint](addr ofs).x = v

template `y=`*(ofs: BgOfs, v: int16) =
  cast[ptr BgPoint](addr ofs).y = v

template x*(ofs: BgOfs): int16 =
  {.error: "BG scroll registers are write-only!".}

template y*(ofs: BgOfs): int16 =
  {.error: "BG scroll registers are write-only!".}

converter toBgOfs*(p: BgPoint): BgOfs =
  p.BgOfs
]#


var dispcnt* {.importc:"(*(volatile NU16*)(0x04000000))", nodecl.}: DispCnt              ## Display control register
var dispstat* {.importc:"(*(volatile NU16*)(0x04000004))", nodecl.}: DispStat           ## Display status register
let vcount* {.importc:"(*(volatile NU16*)(0x04000006))", nodecl.}: uint16                   ## Scanline count (read only)
var bgcnt* {.importc:"((volatile NU16*)(0x04000008))", nodecl.}: array[4, BgCnt]           ## BG control registers
var bgofs* {.importc:"((volatile BG_POINT*)(0x04000010))", nodecl.}: array[4, BgOfs]        ## [Write only!] BG scroll registers
var bgaff* {.importc:"((volatile BG_AFFINE*)(0x04000020))", nodecl.}: array[2..3, BgAffine] ## [Write only!] Affine parameters (matrix and scroll offset) for BG2 and BG3, depending on display mode.

var winh* {.importc:"((volatile WinH*)(0x04000040))", nodecl.}: array[2, WinH]  ## [Write only!] Sets the left and right bounds of a window
var winv* {.importc:"((volatile WinV*)(0x04000044))", nodecl.}: array[2, WinV]  ## [Write only!] Sets the upper and lower bounds of a window

var win0h* {.importc:"(*(volatile WinH*)(0x04000040))", nodecl.}: WinH  ## [Write only!] Sets the left and right bounds of window 0
var win1h* {.importc:"(*(volatile WinH*)(0x04000042))", nodecl.}: WinH  ## [Write only!] Sets the left and right bounds of window 1 
var win0v* {.importc:"(*(volatile WinV*)(0x04000044))", nodecl.}: WinV  ## [Write only!] Sets the upper and lower bounds of window 0
var win1v* {.importc:"(*(volatile WinV*)(0x04000046))", nodecl.}: WinV  ## [Write only!] Sets the upper and lower bounds of window 1

var win0cnt* {.importc:"REG_WIN0CNT", header:"tonc_memmap.h".}: WinCnt  ## Window 0 control
var win1cnt* {.importc:"REG_WIN1CNT", header:"tonc_memmap.h".}: WinCnt  ## Window 1 control
var winoutcnt* {.importc:"REG_WINOUTCNT", header:"tonc_memmap.h".}: WinCnt  ## Out window control
var winobjcnt* {.importc:"REG_WINOBJCNT", header:"tonc_memmap.h".}: WinCnt  ## Object window control

var mosaic* {.importc:"REG_MOSAIC", header:"tonc_memmap.h".}: Mosaic   ## [Write only!] Mosaic size register

var bldcnt* {.importc:"REG_BLDCNT", header:"tonc_memmap.h".}: BldCnt          ## Blend control register
var bldalpha* {.importc:"REG_BLDALPHA", header:"tonc_memmap.h".}: BlendAlpha  ## Alpha blending fade coefficients
var bldy* {.importc:"REG_BLDY", header:"tonc_memmap.h".}: BlendBrightness     ## [Write only!] Brightness (fade in/out) coefficient


import macros

type
  ReadWriteRegister = DispCnt | DispStat | BgCnt | WinCnt | BldCnt | BlendAlpha
  WriteOnlyRegister = BgOfs | BgAffine | WinH | WinV | BlendBrightness
  WritableRegister = ReadWriteRegister | WriteOnlyRegister


template init*[T:WritableRegister](r: T, args: varargs[untyped]) =
  ## Initialise an IO register to some combination of flags/values.
  ## E.g.
  ## :: 
  ##   dispcnt.init:
  ##     mode = mode1
  ##     bg0 = true
  ##
  ## Can also be written as a one-liner:
  ## ::
  ##   dispcnt.init(mode = mode1, bg0 = true)
  ## 
  ## These are both shorthand for:
  ## ::
  ##   var tmp: DispCnt
  ##   tmp.mode = mode1
  ##   tmp.bg0 = true
  ##   dispcnt = tmp
  ## 
  ## Note that we could instead set each field on `dispcnt` directly:
  ## ::
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
  ## ::
  ##   dispcnt.edit:
  ##     bg0 = false
  ##     obj = true
  ##     obj1d = true
  ##
  ## Is shorthand for:
  ## ::
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
  ## ::
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

