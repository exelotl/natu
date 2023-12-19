import ./applib

# I/O registers
# -------------

template dispcnt*: DispCnt   = cast[ptr DispCnt](addr natuMem.regs[0x00 shr 1])[]
template dispstat*: DispStat = cast[ptr DispStat](addr natuMem.regs[0x04 shr 1])[]
template vcount*: uint16     = cast[ptr uint16](addr natuMem.regs[0x06 shr 1])[]
template bgcnt*: array[4, BgCnt] = cast[ptr array[4, BgCnt]](addr natuMem.regs[0x08 shr 1])[]
template bgofs*: array[4, BgOfs] = cast[ptr array[4, BgOfs]](addr natuMem.regs[0x10 shr 1])[]
template bgaff*: array[4, BgAffine] = cast[ptr array[2..3, BgAffine]](addr natuMem.regs[0x20 shr 1])[]

template winh*: array[2, WinH] = cast[ptr array[2, WinH]](addr natuMem.regs[0x040 shr 1])[]
template winv*: array[2, WinV] = cast[ptr array[2, WinV]](addr natuMem.regs[0x048 shr 1])[]

template win0cnt*: WinCnt   = cast[ptr array[2, WinCnt]](addr natuMem.regs[0x50 shr 1])[0]
template win1cnt*: WinCnt   = cast[ptr array[2, WinCnt]](addr natuMem.regs[0x50 shr 1])[1]
template winoutcnt*: WinCnt = cast[ptr array[2, WinCnt]](addr natuMem.regs[0x52 shr 1])[0]
template winobjcnt*: WinCnt = cast[ptr array[2, WinCnt]](addr natuMem.regs[0x52 shr 1])[1]

template mosaic*: Mosaic        = cast[ptr Mosaic](addr natuMem.regs[0x54 shr 1])[]
template bldcnt*: BldCnt        = cast[ptr BldCnt](addr natuMem.regs[0x56 shr 1])[]
template bldalpha*: BlendAlpha  = cast[ptr BlendAlpha](addr natuMem.regs[0x58 shr 1])[]
template bldy*: BlendBrightness = cast[ptr BlendBrightness](addr natuMem.regs[0x5A shr 1])[]


# Memory mapped arrays
# --------------------

const CbSize = 0x4000
const PageSize = 0x0A000

template bgColorMem*: array[256, Color]             = cast[ptr array[256, Color]](addr natuMem.palram)[]
template bgPalMem*: array[16, Palette]              = cast[ptr array[16, Palette]](addr natuMem.palram)[]
template objColorMem*: array[256, Color]            = cast[ptr array[256, Color]](addr natuMem.palram[256])[]
template objPalMem*: array[16, Palette]             = cast[ptr array[16, Palette]](addr natuMem.palram[256])[]
template bgTileMem*: array[4, UnboundedCharblock]   = cast[ptr array[4, UnboundedCharblock]](addr natuMem.vram)[]
template bgTileMem8*: array[4, UnboundedCharblock8] = cast[ptr array[4, UnboundedCharblock8]](addr natuMem.vram)[]
template objTileMem*: array[1024, Tile]             = cast[ptr array[1024, Tile]](addr natuMem.vram[CbSize*4 div 2])[]
template objTileMem8*: array[512, Tile8]            = cast[ptr array[512, Tile8]](addr natuMem.vram[CbSize*4 div 2])[]
template seMem*: array[32, Screenblock]             = cast[ptr array[32, Screenblock]](addr natuMem.vram)[]
template vidMem*: array[240*160, Color]             = cast[ptr array[240*160, Color]](addr natuMem.vram)[]
template m3Mem*: array[160, M3Line]                 = cast[ptr array[160, M3Line]](addr natuMem.vram)[]
template m4Mem*: array[160, M4Line]                 = cast[ptr array[160, M4Line]](addr natuMem.vram)[]
template m5Mem*: array[128, M5Line]                 = cast[ptr array[128, M5Line]](addr natuMem.vram)[]
template vidMemFront*: array[160*128, uint16]       = cast[ptr array[160*128, uint16]](addr natuMem.vram)[]
template vidMemBack*: array[160*128, uint16]        = cast[ptr array[160*128, uint16]](addr natuMem.vram[PageSize div 2])[]
template m4MemBack*: array[160, M4Line]             = cast[ptr array[160, M4Line]](addr natuMem.vram[PageSize div 2])[]
template m5MemBack*: array[128, M5Line]             = cast[ptr array[128, M5Line]](addr natuMem.vram[PageSize div 2])[]
template objMem*: array[128, ObjAttr]               = cast[ptr array[128, ObjAttr]](addr natuMem.oam)[]
template objAffMem*: array[32, ObjAffine]           = cast[ptr array[32, ObjAffine]](addr natuMem.oam)[]

{.compile(toncPath & "/src/tonc_video.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg_affine.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp8.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp16.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_color.c", toncCFlags).}

{.pragma: tonc, header:"tonc_video.h".}
{.pragma: toncinl, header:"tonc_video.h".}  # inline from header.

{.compile(toncPath & "/src/tonc_obj_affine.c", toncCFlags).}  # muffin - obj field size

proc clrBlendFast*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs: int; alpha: int) =
  clrBlend(srca, srcb, dst, nclrs, alpha)
  
proc clrFadeFast*(src: ptr Color; clr: Color; dst: ptr Color; nclrs: int; alpha: int) =
  clrFade(src, clr, dst, nclrs, alpha)


func setAttr*(obj: ObjAttrPtr; a0, a1, a2: uint32) {.inline.} =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2

func setAttr*(obj: var ObjAttr; a0, a1, a2: uint32) {.inline.} =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2


# Obj affine procedures
# ---------------------

proc init*(oaff: var ObjAffine; pa, pb, pc, pd: Fixed) {.inline.} =
  ## Set the elements of an object affine matrix.
  oaff.pa = pa.int32
  oaff.pb = pb.int32
  oaff.pc = pc.int32
  oaff.pd = pd.int32

proc setToIdentity*(oaff: var ObjAffine) {.inline.} =
  ## Set an object affine matrix to the identity matrix.
  oaff.pa = 0x0100
  oaff.pb = 0
  oaff.pc = 0
  oaff.pd = 0x0100

proc setToScaleRaw*(oaff: var ObjAffine; sx, sy: Fixed) {.inline.} =
  ## Mathematically correct version of `setToScale`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  oaff.pa = sx.int32
  oaff.pb = 0
  oaff.pc = 0
  oaff.pd = sy.int32

proc setToShearXRaw*(oaff: var ObjAffine; hx: Fixed) {.inline.} =
  oaff.pa = 0x0100
  oaff.pb = hx.int32
  oaff.pc = 0
  oaff.pd = 0x0100

proc setToShearYRaw*(oaff: var ObjAffine; hy: Fixed) {.inline.} =
  oaff.pa = 0x0100
  oaff.pb = 0
  oaff.pc = hy.int32
  oaff.pd = 0x0100

proc setToRotationRaw*(oaff: var ObjAffine; alpha: uint16) {.inline.} =
  ## Mathematically correct version of `setToRotation`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  let ss = luSin(alpha.Angle).fp
  let cc = luCos(alpha.Angle).fp
  oaff.pa = (cc).int32
  oaff.pb = (-ss).int32
  oaff.pc = (ss).int32
  oaff.pd = (cc).int32

proc premul*(dst: var ObjAffine, src: ObjAffine) =
  ## Pre-multiply the matrix `dst` by `src`.
  ## i.e.
  ## 
  ## .. code-block::
  ## 
  ##   dst = src * dst
  let tmp_a = dst.pa.int
  let tmp_b = dst.pb.int
  let tmp_c = dst.pc.int
  let tmp_d = dst.pd.int
  dst.pa = ((src.pa.int * tmp_a + src.pb.int * tmp_c) shr 8).int32
  dst.pb = ((src.pa.int * tmp_b + src.pb.int * tmp_d) shr 8).int32
  dst.pc = ((src.pc.int * tmp_a + src.pd.int * tmp_c) shr 8).int32
  dst.pd = ((src.pc.int * tmp_b + src.pd.int * tmp_d) shr 8).int32

proc postmul*(dst: var ObjAffine, src: ObjAffine) =
  ## Post-multiply the matrix `dst` by `src`.
  ## i.e.
  ## 
  ## .. code-block::
  ## 
  ##   dst = dst * src
  let tmpa = dst.pa.int
  let tmpb = dst.pb.int
  let tmpc = dst.pc.int
  let tmpd = dst.pd.int
  dst.pa = ((tmp_a * src.pa.int + tmp_b * src.pc.int) shr 8).int32
  dst.pb = ((tmp_a * src.pb.int + tmp_b * src.pd.int) shr 8).int32
  dst.pc = ((tmp_c * src.pa.int + tmp_d * src.pc.int) shr 8).int32
  dst.pd = ((tmp_c * src.pb.int + tmp_d * src.pd.int) shr 8).int32

proc setToScaleAndRotationRaw*(oaff: var ObjAffine; sx, sy: Fixed; alpha: uint16) =
  ## Mathematically correct version of `setToScaleAndRotation`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  let ss = luSin(alpha.Angle).int
  let cc = luCos(alpha.Angle).int
  oaff.pa = ((cc*sx) shr 12).int32
  oaff.pb = ((-ss*sx) shr 12).int32
  oaff.pc = ((ss*sy) shr 12).int32
  oaff.pd = ((cc*sy) shr 12).int32

proc rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: ptr AffSrcEx) {.importc: "obj_rotscale_ex", header: "tonc_oam.h".}
  ## Rot/scale an object around an arbitrary point.
  ## Sets up `obj` and `oaff` for rot/scale transformation around an arbitrary point using the `asx` data.
  ## 
  ## :obj:  Object to set.
  ## :oaff: Object affine data to set.
  ## :asx:  Affine source data: screen and texture origins, scales and angle.

template rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: AffSrcEx) =
  rotscaleEx(obj, oaff, unsafeAddr asx)

proc setToScale*(oa: var ObjAffine; sx: Fixed, sy = sx) {.inline.} =
  ## Set an object affine matrix for scaling.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  oa.setToScaleRaw(x.Fixed, y.Fixed)

proc setToRotation*(oa: var ObjAffine; theta: uint16) {.inline.} =
  ## Set obj matrix to counter-clockwise rotation.
  ## 
  ## :oaff:  Object affine matrix to set.
  ## :alpha: CCW angle. full-circle is `0x10000`.
  oa.setToRotationRaw(0'u16 - theta)

proc setToShearX*(oa: var ObjAffine; hx: Fixed) {.inline.} =
  oa.setToShearXRaw(-hx)

proc setToShearY*(oa: var ObjAffine; hy: Fixed) {.inline.} =
  oa.setToShearYRaw(-hy)

proc setToScaleAndRotation*(oa: var ObjAffine; sx, sy: Fixed; theta: uint16) {.inline.} =
  ## Set obj matrix to 2d scaling, then counter-clockwise rotation.
  ## 
  ## :oaff:  Object affine matrix to set.
  ## :sx:    Horizontal scale (zoom). .8 fixed point.
  ## :sy:    Vertical scale (zoom). .8 fixed point.
  ## :alpha: CCW angle. full-circle is `0x10000`.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  oa.setToScaleAndRotationRaw(x.Fixed, y.Fixed, 0'u16 - theta)


# SPRITE GETTERS/SETTERS
# ----------------------

{.push inline.}

# copy attr0,1,2 from one object into another
func setAttr*(obj: ObjAttrPtr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)
func setAttr*(obj: var ObjAttr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)

# getters

func x*(obj: ObjAttr): int = ((obj.attr1 shr 16) and 0xFFFF'u32).int
func y*(obj: ObjAttr): int = ((obj.attr0 shr 16) and 0xFFFF'u32).int
func pos*(obj: ObjAttr): Vec2i = vec2i(obj.x, obj.y)
func mode*(obj: ObjAttr): ObjMode = ((obj.attr0 and 0x0300'u32) shr 8).ObjMode
func fx*(obj: ObjAttr): ObjFxMode = ((obj.attr0 and 0x0C00'u32) shr 10).ObjFxMode
func mos*(obj: ObjAttr): bool = (obj.attr0 and 0x1000'u32) != 0
func is8bpp*(obj: ObjAttr): bool = (obj.attr0 and 0x2000'u32) != 0
func affId*(obj: ObjAttr): int = ((obj.attr1 and 0x3E00'u32) shr 9).int
func size*(obj: ObjAttr): ObjSize = (((obj.attr0 and 0xC000'u32) shr 12) or ((obj.attr1 and 0xC000'u32) shr 14)).ObjSize
func hflip*(obj: ObjAttr): bool = (obj.attr1 and 0x1000'u32) != 0
func vflip*(obj: ObjAttr): bool = (obj.attr1 and 0x2000'u32) != 0
func tileId*(obj: ObjAttr): int = (obj.attr2 and 0x03FF'u32).int
func palId*(obj: ObjAttr): int = ((obj.attr2 and 0xF000'u32) shr 12).int
func prio*(obj: ObjAttr): int = ((obj.attr2 and 0x0C00'u32) shr 10).int

# setters

func `x=`*(obj: var ObjAttr; x: int) =
  obj.attr1 = ((x.uint32 shl 16) and 0xFFFF0000'u32) or (obj.attr1 and not 0xFFFF0000'u32)

func `y=`*(obj: var ObjAttr; y: int) =
  obj.attr0 = ((y.uint32 shl 16) and 0xFFFF0000'u32) or (obj.attr0 and not 0xFFFF0000'u32)

func `pos=`*(obj: var ObjAttr; v: Vec2i) =
  obj.x = v.x
  obj.y = v.y

func `tileId=`*(obj: var ObjAttr; tileId: int) =
  obj.attr2 = (tileId.uint32 and 0x03FF'u32) or (obj.attr2 and not 0x03FF'u32)

func `palId=`*(obj: var ObjAttr; palId: int) =
  obj.attr2 = ((palId.uint32 shl 12) and 0xF000'u32) or (obj.attr2 and not 0xF000'u32)

func `hflip=`*(obj: var ObjAttr; v: bool) =
  obj.attr1 = (v.uint32 shl 12) or (obj.attr1 and not 0x1000'u32)
  
func `vflip=`*(obj: var ObjAttr; v: bool) =
  obj.attr1 = (v.uint32 shl 13) or (obj.attr1 and not 0x2000'u32)

func `mode=`*(obj: var ObjAttr; v: ObjMode) =
  obj.attr0 = (v.uint32 shl 8) or (obj.attr0 and not 0x0300'u32)

func `fx=`*(obj: var ObjAttr; v: ObjFxMode) =
  obj.attr0 = (v.uint32 shl 10) or (obj.attr0 and not 0x0C00'u32)

func `mos=`*(obj: var ObjAttr; v: bool) =
  obj.attr0 = (v.uint32 shl 12) or (obj.attr0 and not 0x1000'u32)

func `is8bpp=`*(obj: var ObjAttr; v: bool) =
  obj.attr0 = (v.uint32 shl 13) or (obj.attr0 and not 0x2000'u32)

func `affId=`*(obj: var ObjAttr; affId: int) =
  obj.attr1 = ((affId.uint32 shl 9) and 0x3E00'u32) or (obj.attr1 and not 0x3E00'u32)

func `size=`*(obj: var ObjAttr; v: ObjSize) =
  let shape = (v.uint32 shl 12) and 0xC000'u32
  let size = (v.uint32 shl 14)
  obj.attr0 = shape or (obj.attr0 and not 0xC000'u32)
  obj.attr1 = size or (obj.attr1 and not 0xC000'u32)
  
func `prio=`*(obj: var ObjAttr; prio: int) =
  obj.attr2 = ((prio.uint32 shl 10) and 0x0C00'u32) or (obj.attr2 and not 0x0C00'u32)
