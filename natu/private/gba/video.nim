
var dispcnt* {.importc:"(*(volatile NU16*)(0x04000000))", nodecl.}: DispCnt              ## Display control register
var dispstat* {.importc:"(*(volatile NU16*)(0x04000004))", nodecl.}: DispStat           ## Display status register
let vcount* {.importc:"(*(volatile NU16*)(0x04000006))", nodecl.}: uint16                   ## Scanline count (read only)
var bgcnt* {.importc:"((volatile NU16*)(0x04000008))", nodecl.}: array[4, BgCnt]           ## BG control registers
var bgofs* {.importc:"((volatile BG_POINT*)(0x04000010))", header:"tonc_types.h".}: array[4, BgOfs]        ## [Write only!] BG scroll registers
var bgaff* {.importc:"((volatile BG_AFFINE*)(0x04000020))", header:"tonc_types.h".}: array[2..3, BgAffine] ## [Write only!] Affine parameters (matrix and scroll offset) for BG2 and BG3, depending on display mode.

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

var mosaic* {.importc:"(volatile NU16*)(0x0400004C)", nodecl.}: Mosaic        ## [Write only!] Mosaic size register

var bldcnt* {.importc:"(volatile NU16*)(0x04000050)", nodecl.}: BldCnt        ## Blend control register
var bldalpha* {.importc:"(volatile NU16*)(0x04000052)", nodecl.}: BlendAlpha  ## Alpha blending fade coefficients
var bldy* {.importc:"(volatile NU16*)(0x04000054)", nodecl.}: BlendBrightness ## [Write only!] Brightness (fade in/out) coefficient

# Palette
export
  bgColorMem,
  bgPalMem,
  objColorMem,
  objPalMem

# VRAM
export
  bgTileMem,
  bgTileMem8,
  objTileMem,
  objTileMem8,
  seMem,
  vidMem,
  m3Mem,
  m4Mem,
  m5Mem,
  vidMemFront,
  vidMemBack,
  m4MemBack,
  m5MemBack
  
export objMem, objAffMem

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

{.compile(toncPath & "/src/tonc_obj_affine.c", toncCFlags).}
