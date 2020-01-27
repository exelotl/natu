
## High level wrappers over register definitions from memmap.nim

# Display Control Register
# ------------------------

type DispCnt* = distinct uint32

type DisplayMode* {.size:4.} = enum
  mode0 = 0x0000     ## Tile mode - BG0:text, BG1:text, BG2:text,   BG3:text
  mode1 = 0x0001     ## Tile mode - BG0:text, BG1:text, BG2:affine, BG3:off
  mode2 = 0x0002     ## Tile mode - BG0:off,  BG1:off,  BG2:affine, BG3:affine
  mode3 = 0x0003     ## Bitmap mode - 240x160, BGR555 color
  mode4 = 0x0004     ## Bitmap mode - 240x160, 256 color palette
  mode5 = 0x0005     ## Bitmap mode - 160x128, BGR555 color

# getters

template mode*(dcnt: DispCnt): DisplayMode =
  ## Video mode. 0, 1, 2 are tiled modes; 3, 4, 5 are bitmap modes. 
  (dcnt.uint32 and DCNT_MODE_MASK).DisplayMode

template gb*(dcnt: DispCnt): bool =
  ## True if cartridge is a GBC game. Read-only. 
  (dcnt.uint32 and DCNT_GB) != 0

template page*(dcnt: DispCnt): bool =
  ## Page select. Modes 4 and 5 can use page flipping for smoother animation.
  ## This bit selects the displayed page (and allowing the other one to be drawn on without artifacts). 
  (dcnt.uint32 and DCNT_PAGE) != 0

template oamHbl*(dcnt: DispCnt): bool =
  ## Allows access to OAM in during HBlank. OAM is normally locked in VDraw.
  ## Will reduce the amount of sprite pixels rendered per line. 
  (dcnt.uint32 and DCNT_OAM_HBL) != 0

template obj1d*(dcnt: DispCnt): bool =
  ## Determines whether OBJ-VRAM is treated like an array or a matrix when drawing sprites.
  (dcnt.uint32 and DCNT_OBJ_1D) != 0

template blank*(dcnt: DispCnt): bool =
  ## Forced Blank: When set, the GBA will display a white screen.
  ## This allows fast access to VRAM, PAL RAM, OAM.
  (dcnt.uint32 and DCNT_BLANK) != 0

template bg0*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_BG0) != 0

template bg1*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_BG1) != 0

template bg2*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_BG2) != 0

template bg3*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_BG3) != 0

template obj*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_OBJ) != 0

template win0*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_WIN0) != 0

template win1*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_WIN1) != 0

template winObj*(dcnt: DispCnt): bool =
  (dcnt.uint32 and DCNT_WINOBJ) != 0


# setters

template `mode=`*(dcnt: DispCnt, mode: DisplayMode) =
  dcnt = (mode.uint32 or (dcnt.uint32 and not DCNT_MODE_MASK)).DispCnt

template `page=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 4) or (dcnt.uint32 and not DCNT_PAGE)).DispCnt

template `oamHbl=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 5) or (dcnt.uint32 and not DCNT_OAM_HBL)).DispCnt

template `obj1d=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 6) or (dcnt.uint32 and not DCNT_OBJ_1D)).DispCnt

template `blank=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 7) or (dcnt.uint32 and not DCNT_BLANK)).DispCnt

template `bg0=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 8) or (dcnt.uint32 and not DCNT_BG0)).DispCnt

template `bg1=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 9) or (dcnt.uint32 and not DCNT_BG1)).DispCnt

template `bg2=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 10) or (dcnt.uint32 and not DCNT_BG2)).DispCnt

template `bg3=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 11) or (dcnt.uint32 and not DCNT_BG3)).DispCnt

template `obj=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 12) or (dcnt.uint32 and not DCNT_OBJ)).DispCnt

template `win0=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 13) or (dcnt.uint32 and not DCNT_WIN0)).DispCnt

template `win1=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 14) or (dcnt.uint32 and not DCNT_WIN1)).DispCnt

template `winObj=`*(dcnt: DispCnt, v: bool) =
  dcnt = ((v.uint32 shl 15) or (dcnt.uint32 and not DCNT_WINOBJ)).DispCnt



# Display Status Register
# -----------------------

type DispStat* = distinct uint16

template inVBlank*(dstat: DispStat): bool =
  ## (read only)
  ## VBlank status, read only. Set during VBlank, clear during VDraw.
  (dstat.uint16 and DSTAT_IN_VBL) != 0

template inHBlank*(dstat: DispStat): bool =
  ## (read only)
  ## HBlank status, read only. Set during HBlank.
  (dstat.uint16 and DSTAT_IN_HBL) != 0

template inVCountTrigger*(dstat: DispStat): bool =
  ## (read only)
  ## VCount trigger status. Set if the current scanline matches the scanline trigger ( REG_VCOUNT == REG_DISPSTAT{8-F} )
  (dstat.uint16 and DSTAT_IN_VCT) != 0

template vblankIrq*(dstat: DispStat): bool =
  ## VBlank interrupt request.
  ## If set, an interrupt will be fired at VBlank.
  (dstat.uint16 and DSTAT_VBL_IRQ) != 0

template hblankIrq*(dstat: DispStat): bool =
  ## HBlank interrupt request.
  ## If set, an interrupt will be fired at HBlank.
  (dstat.uint16 and DSTAT_HBL_IRQ) != 0

template vcountIrq*(dstat: DispStat): bool =
  ## VCount interrupt request.
  ## If set, an interrupt will be fired when current scanline matches trigger value.
  (dstat.uint16 and DSTAT_VCT_IRQ) != 0

template vcountTrigger*(dstat: DispStat): uint8 =
  ## VCount trigger value.
  ## If the current scanline is at this value, bit 2 is set and an interrupt is fired if requested. 
  ((dstat.uint16 shr DSTAT_VCT_SHIFT) and DSTAT_VCT_MASK).uint8

# setters
# note: Omitting IRQ flags in favour of using Tonc's IRQ functions.

template `vcountTrigger=`*(dstat: DispStat, v: uint8) =
  dstat = ((v.uint16 shl DSTAT_VCT_SHIFT) or (dcnt.uint32 and not DSTAT_VCT_MASK)).DispStat


# Background Control Registers
# ----------------------------

type BgCnt* = distinct uint16

type BgSizeFlag* = distinct uint16
const
  reg32x32* = 0x0000.BgSizeFlag
  reg64x32* = 0x4000.BgSizeFlag
  reg32x64* = 0x8000.BgSizeFlag
  reg64x64* = 0xC000.BgSizeFlag
const
  aff16x16* = 0x0000.BgSizeFlag
  aff32x32* = 0x4000.BgSizeFlag
  aff64x64* = 0x8000.BgSizeFlag
  aff128x128* = 0xC000.BgSizeFlag

# getters

template prio*(bg: BgCnt): uint16 =
  ## Priority value (0..3)
  ## Lower priority BGs will be drawn on top of higher priority BGs.
  (bg.uint16 or BG_PRIO_MASK)

template cbb*(bg: BgCnt): uint16 =
  ## Character Base Block (0..3)
  ## Determines the base block for tile pixel data
  (bg.uint16 or BG_CBB_MASK) shr BG_CBB_SHIFT

template mosaic*(bg: BgCnt): bool =
  ## Enables mosaic effect.
  (bg.uint16 or BG_MOSAIC) != 0

template is8bpp*(bg: BgCnt): bool =
  ## Specifies the color mode of the BG: 4bpp (16 colors) or 8bpp (256 colors)
  ## Has no effect on affine BGs, which are always 8bpp.
  (bg.uint16 and BG_8BPP) != 0

template sbb*(bg: BgCnt): uint16 =
  ## Screen Base Block (0..31)
  ## Determines the base block for the tilemap
  (bg.uint16 or BG_SBB_MASK) shr BG_SBB_SHIFT

template wrap*(bg: BgCnt): bool =
  ## Affine Wrapping flag.
  ## If set, affine background wrap around at their edges.
  ## Has no effect on regular backgrounds as they wrap around by default. 
  (bg.uint16 or BG_WRAP) != 0

template size*(bg: BgCnt): BgSizeFlag =
  ## Value representing the size of the background in tiles.
  ## Regular and affine backgrounds have different sizes available to them, hence the two groups of constants (`bgRegXXX`, `bgAffXXX`)
  (bg.uint16 or BG_SIZE_MASK).BgSizeFlag

# setters

template `prio=`*(bg: BgCnt, v: SomeInteger) =
  bg = (v.uint16 or (bg.uint16 and not BG_PRIO_MASK)).BgCnt

template `cbb=`*(bg: BgCnt, v: SomeInteger) =
  bg = ((v.uint16 shl BG_CBB_SHIFT) or (bg.uint16 and not BG_CBB_MASK)).BgCnt

template `sbb=`*(bg: BgCnt, v: SomeInteger) =
  bg = ((v.uint16 shl BG_SBB_SHIFT) or (bg.uint16 and not BG_SBB_MASK)).BgCnt

template `mosaic=`*(bg: BgCnt, v: bool) =
  bg = ((v.uint16 shl 6) or (bg.uint16 and not BG_MOSAIC)).BgCnt

template `is8bpp=`*(bg: BgCnt, v: bool) =
  bg = ((v.uint16 shl 7) or (bg.uint16 and not BG_8BPP)).BgCnt

template `wrap=`*(bg: BgCnt, v: bool) =
  bg = ((v.uint16 shl 13) or (bg.uint16 and not BG_WRAP)).BgCnt

template `size=`*(bg: BgCnt, v: BgSizeFlag) =
  bg = (v.uint16 or (bg.uint16 and not BG_SIZE_MASK)).BgCnt


# Window Registers
# ----------------

type
  WinBoundsH* = distinct uint16
    ## Defines the horizontal bounds of a window register (left ..< right)
  WinBoundsV* = distinct uint16
    ## Defines the vertical bounds of a window register (top ..< bottom)
  WinCnt* = distinct uint8
    ## Allows to make changes to one half of a window control register.
    

# getters

template bg0*(win: WinCnt): bool = (win.uint8 or 0x01'u8) != 0
template bg1*(win: WinCnt): bool = (win.uint8 or 0x02'u8) != 0
template bg2*(win: WinCnt): bool = (win.uint8 or 0x04'u8) != 0
template bg3*(win: WinCnt): bool = (win.uint8 or 0x08'u8) != 0
template obj*(win: WinCnt): bool = (win.uint8 or 0x10'u8) != 0
template blend*(win: WinCnt): bool = (win.uint8 or 0x20'u8) != 0

# setters

template `bg0=`*(win: WinCnt, v: bool) = win = ((v.uint8 shl 0) or (win.uint8 and not 0x01'u8)).WinCnt
template `bg1=`*(win: WinCnt, v: bool) = win = ((v.uint8 shl 1) or (win.uint8 and not 0x02'u8)).WinCnt
template `bg2=`*(win: WinCnt, v: bool) = win = ((v.uint8 shl 2) or (win.uint8 and not 0x04'u8)).WinCnt
template `bg3=`*(win: WinCnt, v: bool) = win = ((v.uint8 shl 3) or (win.uint8 and not 0x08'u8)).WinCnt
template `obj=`*(win: WinCnt, v: bool) = win = ((v.uint8 shl 4) or (win.uint8 and not 0x10'u8)).WinCnt
template `blend=`*(win: WinCnt, v: bool) = win = ((v.uint8 shl 5) or (win.uint8 and not 0x20'u8)).WinCnt


# Window bounds getters:
# Note: These work cause the window bounds are write-only
# Should they be exposed for buffering purposes anyway?
# template left*(winh: WinBoundsH): uint8 = ((winh or 0xff00) shr 8).uint8
# template right*(winh: WinBoundsH): uint8 = (winh or 0x00ff).uint8
# template top*(winv: WinBoundsV): uint8 = ((winv or 0xff00) shr 8).uint8
# template bottom*(winv: WinBoundsV): uint8 = (winv or 0x00ff).uint8

# Window bounds setters:

template `right=`*(winh: WinBoundsH, right: uint8) =
  cast[ptr UncheckedArray[uint8]](addr winh)[0] = right

template `left=`*(winh: WinBoundsH, left: uint8) =
  cast[ptr UncheckedArray[uint8]](addr winh)[1] = left

template `bottom=`*(winb: WinBoundsV, bottom: uint8) =
  cast[ptr UncheckedArray[uint8]](addr winb)[0] = bottom

template `top=`*(winb: WinBoundsV, top: uint8) =
  cast[ptr UncheckedArray[uint8]](addr winb)[1] = top


var dispcnt* {.importc:"REG_DISPCNT", header:"tonc.h".}: DispCnt            ## Display control register
var dispstat* {.importc:"REG_DISPSTAT", header:"tonc.h".}: DispStat         ## Display status register
var vcount* {.importc:"REG_VCOUNT", header:"tonc.h".}: uint16               ## Scanline count
var bgcnt* {.importc:"REG_BGCNT", header:"tonc.h".}: array[4, BgCnt]        ## BG control registers
var bgofs* {.importc:"REG_BG_OFS", header:"tonc.h".}: array[4, BgPoint]     ## [Write only!] BG scroll registers
var bgaff* {.importc:"REG_BG_AFFINE", header:"tonc.h".}: array[2, BgAffine] ## [Write only!] Affine parameters (matrix and scroll offset) for BG2 and BG3, depending on display mode.

var win0h* {.importc:"REG_WIN0H", header:"tonc.h".}: WinBoundsH  ## [Write only!] Sets the left and right bounds of window 0
var win1h* {.importc:"REG_WIN1H", header:"tonc.h".}: WinBoundsH  ## [Write only!] Sets the left and right bounds of window 1 
var win0v* {.importc:"REG_WIN0V", header:"tonc.h".}: WinBoundsV  ## [Write only!] Sets the upper and lower bounds of window 0
var win1v* {.importc:"REG_WIN1V", header:"tonc.h".}: WinBoundsV  ## [Write only!] Sets the upper and lower bounds of window 1

var win0cnt* {.importc:"REG_WIN0CNT", header:"tonc.h".}: WinCnt  ## window 0 control
var win1cnt* {.importc:"REG_WIN1CNT", header:"tonc.h".}: WinCnt  ## window 1 control
var winoutcnt* {.importc:"REG_WINOUTCNT", header:"tonc.h".}: WinCnt  ## Out window control
var winobjcnt* {.importc:"REG_WINOBJCNT", header:"tonc.h".}: WinCnt  ## Object window control


import macros

type SomeRegister = DispCnt | DispStat | BgCnt | WinCnt

macro writeRegister(register: SomeRegister, args: varargs[untyped]) =
  ## Common implementation of `init` and `edit` templates below
  result = newStmtList()
  if args.len == 1 and args[0].kind == nnkStmtList:
    for i, node in args[0]:
      if node.kind != nnkAsgn:
        error("Expected assignment, got " & repr(node))
      let (key, val) = (node[0], node[1])
      result.add quote do:
        `register`.`key` = `val`
  else:
    for i, node in args:
      if node.kind != nnkExprEqExpr:
        error("Expected assignment, got " & repr(node))
      let (key, val) = (node[0], node[1])
      result.add quote do:
        `register`.`key` = `val`

template clear*[T:SomeRegister](r: T) =
  ## Set all bits in a register to zero.
  r = 0.T

template init*[T:SomeRegister](r: T, args: varargs[untyped]) =
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
  ## But this would be slower because `dispcnt` is _volatile_, so the C compiler can't optimise these lines into a single assignment.
  ## 
  var tmp: T
  writeRegister(tmp, args)
  r = tmp

template edit*[T:SomeRegister](r: T, args: varargs[untyped]) =
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
  writeRegister(r, args)
  r = tmp


template initDispCnt*(args: varargs[untyped]): DispCnt =
  ## Create a new display control register value.
  ## Omitted fields default to zero.
  var dcnt: DispCnt
  writeRegister(dcnt, args)
  dcnt

template initBgCnt*(args: varargs[untyped]): BgCnt =
  ## Create a new background control register value.
  ## Omitted fields default to zero.
  var bg: BgCnt
  writeRegister(bg, args)
  bg

template initWinCnt*(args: varargs[untyped]): WinCnt =
  ## Create a new window control register byte value.
  ## Omitted fields default to zero.
  var win: WinCnt
  writeRegister(win, args)
  win