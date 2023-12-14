import ./applib

# I/O registers
# -------------

template dispcnt*: DispCnt   = cast[ptr DispCnt](addr natuMem.regs[0x00])[]
template dispstat*: DispStat = cast[ptr DispStat](addr natuMem.regs[0x04])[]
template vcount*: uint16 = cast[ptr uint16](addr natuMem.regs[0x06])[]
template bgcnt*: array[4, BgCnt] = cast[ptr array[4, BgCnt]](addr natuMem.regs[0x08])[]
template bgofs*: array[4, BgOfs] = cast[ptr array[4, BgOfs]](addr natuMem.regs[0x10])[]
template bgaff*: array[4, BgAffine] = cast[ptr array[2..3, BgAffine]](addr natuMem.regs[0x20])[]

template winh*: array[2, WinH] = cast[ptr array[2, WinH]](addr natuMem.regs[0x40])[]
template winv*: array[2, WinV] = cast[ptr array[2, WinV]](addr natuMem.regs[0x44])[]

template win0cnt*: WinCnt   = cast[ptr WinCnt](addr natuMem.regs[0x48])[]
template win1cnt*: WinCnt   = cast[ptr WinCnt](addr natuMem.regs[0x49])[]
template winoutcnt*: WinCnt = cast[ptr WinCnt](addr natuMem.regs[0x4A])[]
template winobjcnt*: WinCnt = cast[ptr WinCnt](addr natuMem.regs[0x4B])[]

template mosaic*: Mosaic        = cast[ptr Mosaic](addr natuMem.regs[0x4C])[]
template bldcnt*: BldCnt        = cast[ptr BldCnt](addr natuMem.regs[0x50])[]
template bldalpha*: BlendAlpha  = cast[ptr BlendAlpha](addr natuMem.regs[0x52])[]
template bldy*: BlendBrightness = cast[ptr BlendBrightness](addr natuMem.regs[0x54])[]


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

{.compile(toncPath & "/src/tonc_obj_affine.c", toncCFlags).}

proc clrBlendFast*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs: int; alpha: int) =
  clrBlend(srca, srcb, dst, nclrs, alpha)
  
proc clrFadeFast*(src: ptr Color; clr: Color; dst: ptr Color; nclrs: int; alpha: int) =
  clrFade(src, clr, dst, nclrs, alpha)
