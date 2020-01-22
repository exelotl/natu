
## High level wrappers over register definitions from memmap.nim

type DispCnt* = distinct uint32

type DisplayMode* {.size:4.} = enum
  mode0 = 0x0000     ## Tile mode - BG0:text, BG1:text, BG2:text,   BG3:text
  mode1 = 0x0001     ## Tile mode - BG0:text, BG1:text, BG2:affine, BG3:off
  mode2 = 0x0002     ## Tile mode - BG0:off,  BG1:off,  BG2:affine, BG3:affine
  mode3 = 0x0003     ## Bitmap mode - 240x160, BGR555 color
  mode4 = 0x0004     ## Bitmap mode - 240x160, 256 color palette
  mode5 = 0x0005     ## Bitmap mode - 160x128, BGR555 color


# DispCnt getters
# ---------------

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
  ## Forced Blank: Allow fast access to VRAM, Palette, OAM.
  ## If set, the GBA will display a white screen.
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


# DispCnt setters
# ---------------

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



type DispStat* = distinct uint16

# DispStat getters
# ----------------

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

# DispStat setters
# ----------------
# Note: Omitting IRQ flags in favour of using Tonc's IRQ functions.

template `vcountTrigger=`*(dstat: DispStat, v: uint8) =
  dstat = ((v.uint16 shl DSTAT_VCT_SHIFT) or (dcnt.uint32 and not DSTAT_VCT_MASK)).DispStat



type BgCnt* = distinct uint16

type BgBpp* {.size:2.} = enum
  bg4bpp = 0x0000
  bg8bpp = 0x0080

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

template bpp*(bg: BgCnt): BgBpp =
  ## Color mode: 4bpp (16 colors) or 8bpp ()
  ## No effect on affine BGs, which are 
  (bg.uint16 and BG_8BPP).BgBpp

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

template `prio=`*(bg: BgCnt, v: SomeInteger) =
  bg = (v.uint16 or (bg.uint16 and not BG_PRIO_MASK)).BgCnt

template `cbb=`*(bg: BgCnt, v: SomeInteger) =
  bg = ((v.uint16 shl BG_CBB_SHIFT) or (bg.uint16 and not BG_CBB_MASK)).BgCnt

template `sbb=`*(bg: BgCnt, v: SomeInteger) =
  bg = ((v.uint16 shl BG_SBB_SHIFT) or (bg.uint16 and not BG_SBB_MASK)).BgCnt

template `mosaic=`*(bg: BgCnt, v: bool) =
  bg = ((v.uint16 shl 6) or (bg.uint16 and not BG_MOSAIC)).BgCnt

template `bpp=`*(bg: BgCnt, v: BgBpp) =
  bg = (v.uint16 or (bg.uint16 and not BG_8BPP)).BgCnt

template `wrap=`*(bg: BgCnt, v: bool) =
  bg = ((v.uint16 shl 13) or (bg.uint16 and not BG_WRAP)).BgCnt

template `size=`*(bg: BgCnt, v: BgSizeFlag) =
  bg = (v.uint16 or (bg.uint16 and not BG_SIZE_MASK)).BgCnt


var dispcnt* {.importc:"REG_DISPCNT", header:"tonc.h".}: DispCnt     ## Display control (REG_BASE + 0x00000000)
var dispstat* {.importc:"REG_DISPSTAT", header:"tonc.h".}: DispStat  ## Display status (REG_BASE + 0x00000004)
var vcount* {.importc:"REG_VCOUNT", header:"tonc.h".}: uint16        ## Scanline count (REG_BASE + 0x00000006)
var bgcnt* {.importc:"REG_BGCNT", header:"tonc.h".}: array[4, BgCnt]   ## Bg control array (REG_BASE + 0x00000008)



import macros

type SomeReg = DispCnt | DispStat | BgCnt

macro updateRegister(register: SomeReg, clear: static[bool], args: varargs[untyped]) =
  
  let temp = genSym(
    nskVar,
    if register.kind in {nnkSym, nnkIdent}:
      register.strVal
    else:
      "temp"
  )
  
  let regType = getTypeInst(register)
  expectKind(regType, nnkSym)
  doAssert(regType.symKind == nskType)
  
  result = newStmtList()
  if clear:
    result.add quote do:
      var `temp`: `regType`
  else:
    result.add quote do:
      var `temp`: `regType` = `register`
  
  if args.len == 1 and args[0].kind == nnkStmtList:
    for i, node in args[0]:
      if node.kind != nnkAsgn:
        error("Expected assignment, got " & repr(node))
      let (key, val) = (node[0], node[1])
      result.add quote do:
        `temp`.`key` = `val`
  else:
    for i, node in args:
      if node.kind != nnkExprEqExpr:
        error("Expected assignment, got " & repr(node))
      let (key, val) = (node[0], node[1])
      result.add quote do:
        `temp`.`key` = `val`
  
  result.add quote do:
    `register` = `temp`


template init*(r: SomeReg, args: varargs[untyped]) =
  updateRegister(r, clear=true, args)

# note: should disallow this for write-only registers? Though maybe they won't make it into the SomeReg typeclass anyways.
template edit*(r: SomeReg, args: varargs[untyped]) =
  updateRegister(r, clear=false, args)