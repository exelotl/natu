
# I/O registers
# -------------

var dispcnt* {.importc:"(*(volatile NU16*)(0x04000000))", nodecl.}: DispCnt              ## Display control register
var dispstat* {.importc:"(*(volatile NU16*)(0x04000004))", nodecl.}: DispStat           ## Display status register
let vcount* {.importc:"(*(volatile NU16*)(0x04000006))", nodecl.}: uint16                   ## Scanline count (read only)
var bgcnt* {.importc:"((volatile NU16*)(0x04000008))", nodecl.}: array[4, BgCnt]           ## BG control registers
var bgofs* {.importc:"((volatile BG_POINT*)(0x04000010))", header:"tonc_types.h".}: array[4, BgOfs]        ## [Write only!] BG scroll registers
var bgaff* {.importc:"((volatile BG_AFFINE*)(0x04000020))", header:"tonc_types.h".}: array[2..3, BgAffine] ## [Write only!] Affine parameters (matrix and scroll offset) for BG2 and BG3, depending on display mode.

var winh* {.importc:"((volatile WinH*)(0x04000040))", nodecl.}: array[2, WinH]  ## [Write only!] Sets the left and right bounds of a window
var winv* {.importc:"((volatile WinV*)(0x04000044))", nodecl.}: array[2, WinV]  ## [Write only!] Sets the upper and lower bounds of a window

var win0cnt* {.importc:"REG_WIN0CNT", header:"tonc_memmap.h".}: WinCnt  ## Window 0 control
var win1cnt* {.importc:"REG_WIN1CNT", header:"tonc_memmap.h".}: WinCnt  ## Window 1 control
var winoutcnt* {.importc:"REG_WINOUTCNT", header:"tonc_memmap.h".}: WinCnt  ## Out window control
var winobjcnt* {.importc:"REG_WINOBJCNT", header:"tonc_memmap.h".}: WinCnt  ## Object window control

var mosaic* {.importc:"(*(volatile NU16*)(0x0400004C))", nodecl.}: Mosaic        ## [Write only!] Mosaic size register

var bldcnt* {.importc:"(*(volatile NU16*)(0x04000050))", nodecl.}: BldCnt        ## Blend control register
var bldalpha* {.importc:"(*(volatile NU16*)(0x04000052))", nodecl.}: BlendAlpha  ## Alpha blending fade coefficients
var bldy* {.importc:"(*(volatile NU16*)(0x04000054))", nodecl.}: BlendBrightness ## [Write only!] Brightness (fade in/out) coefficient


# Memory mapped arrays
# --------------------

# Palette

var bgColorMem* {.importc:"pal_bg_mem", header:"tonc_memmap.h".}: array[256, Color]
  ## Access to BG PAL RAM as a single array of colors.
  ## 
  ## This is useful when working with 8bpp backgrounds, or display mode 4.

var bgPalMem* {.importc:"pal_bg_bank", header:"tonc_memmap.h".}: array[16, Palette]
  ## Access to BG PAL RAM as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp backgrounds.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   
  ##   # set all colors of the first palette in memory to white.
  ##   for color in bgPalMem[0].mitems:
  ##     color = clrWhite


var objColorMem* {.importc:"pal_obj_mem", header:"tonc_memmap.h".}: array[256, Color]
  ## Access to OBJ PAL RAM as a single array of colors.
  ## 
  ## This is useful when working with 8bpp sprites.

var objPalMem* {.importc:"pal_obj_bank", header:"tonc_memmap.h".}: array[16, Palette]
  ## Access to OBJ PAL RAM as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp sprites.


# VRAM

var bgTileMem* {.importc:"tile_mem", header:"tonc_memmap.h".}: array[4, UnboundedCharblock]
  ## BG charblocks, 4bpp tiles.
  ## 
  ## .. note::
  ##    While `bgTileMem[0]` has 512 elements, it's valid to reach across
  ##    into the neighbouring charblock, for example `bgTileMem[0][1000]`.
  ## 
  ## For this reason, no bounds checking is performed on these charblocks even when
  ## compiling with `--checks:on`.
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgTileMem[i]      # charblock i
  ##   bgTileMem[i][j]   # charblock i, tile j

var bgTileMem8* {.importc:"tile8_mem", header:"tonc_memmap.h".}: array[4, UnboundedCharblock8]
  ## BG charblocks, 8bpp tiles.
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgTileMem8[i]      # charblock i
  ##   bgTileMem8[i][j]   # charblock i, tile j

var objTileMem* {.importc:"tile_mem_obj[0]", header:"tonc_memmap.h".}: array[1024, Tile]
  ## Object (sprite) image data, as 4bpp tiles.
  ## 
  ## This is 2 charblocks in size, and is separate from BG tile memory.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   objTileMem[n] = Tile()   # Clear the image data for a tile.

var objTileMem8* {.importc:"tile8_mem_obj[0]", header:"tonc_memmap.h".}: array[512, Tile8]
  ## Object (sprite) tiles, 8bpp

var seMem* {.importc:"se_mem", header:"tonc_memmap.h".}: array[32, Screenblock]
  ## Screenblocks as arrays
  ## 
  ## .. code-block:: nim
  ## 
  ##   seMem[i]       # screenblock i
  ##   seMem[i][j]    # screenblock i, entry j
  ##   seMem[i][x,y]  # screenblock i, entry x + y*32


var vidMem* {.importc:"vid_mem", header:"tonc_memmap.h".}: array[240*160, Color]
  ## Main mode 3/5 frame as an array
  ## 
  ## .. code-block:: nim
  ## 
  ##   vidMem[i]    # pixel i

var m3Mem* {.importc:"m3_mem", header:"tonc_memmap.h".}: array[160, M3Line]
  ## Mode 3 frame as a matrix
  ## 
  ## .. code-block:: nim
  ## 
  ##   m3Mem[y][x]  # pixel (x, y)

var m4Mem* {.importc:"m4_mem", header:"tonc_memmap.h".}: array[160, M4Line]
  ## Mode 4 first page as a matrix
  ## Note: This is a byte-buffer. Not to be used for writing.
  ## 
  ## .. code-block:: nim
  ## 
  ##   m4Mem[y][x]  # pixel (x, y)

var m5Mem* {.importc:"m5_mem", header:"tonc_memmap.h".}: array[128, M5Line]
  ## Mode 5 first page as a matrix
  ## 
  ## .. code-block:: nim
  ## 
  ##   m5Mem[y][x]  # pixel (x, y)

var vidMemFront* {.importc:"vid_mem_front", header:"tonc_memmap.h".}: array[160*128, uint16]
  ## First page array

var vidMemBack* {.importc:"vid_mem_back", header:"tonc_memmap.h".}: array[160*128, uint16]
  ## Second page array

var m4MemBack* {.importc:"m4_mem_back", header:"tonc_memmap.h".}: array[160, M4Line]
  ## Mode 4 second page as a matrix
  ## This is a byte-buffer. Not to be used for writing.
  ## 
  ## .. code-block:: nim
  ## 
  ##   m4MemBack[y][x]  = pixel (x, y)          ( u8 )

var m5MemBack* {.importc:"m5_mem_back", header:"tonc_memmap.h".}: array[128, M5Line]
  ## Mode 5 second page as a matrix
  ## 
  ## .. code-block:: nim
  ## 
  ##   m5MemBack[y][x]  = pixel (x, y)          ( Color )


# OAM

var objMem* {.importc:"oam_mem", header:"tonc_memmap.h".}: array[128, ObjAttr]
  ## Object attribute memory
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[i] = object i            (ObjAttr)

var objAffMem* {.importc:"obj_aff_mem", header:"tonc_memmap.h".}: array[32, ObjAffine]
  ## Object affine memory
  ## 
  ## .. code-block:: nim
  ## 
  ##   objAffMem[i] = object matrix i      ( OBJ_AFFINE )  



{.compile(toncPath & "/src/tonc_video.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg_affine.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp8.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp16.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_color.c", toncCFlags).}
{.compile(toncPath & "/asm/clr_blend_fast.s", toncAsmFlags).}
{.compile(toncPath & "/asm/clr_fade_fast.s", toncAsmFlags).}
{.compile(toncPath & "/src/tonc_obj_affine.c", toncCFlags).}


proc clrBlendFast*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs: cint; alpha: cint) {.importc: "clr_blend_fast", tonc.}
  ## Blends color arrays `srca` and `srcb` into `dst`.
  ## 
  ## :srca: Source array A.
  ## :srcb: Source array B.
  ## :dst: Destination array.
  ## :nclrs: Number of colors.
  ## :alpha: Blend weight (range: 0-32).
  ## 
  ## .. note::
  ##    This is an ARM assembly routine placed in IWRAM, which makes it very fast, but keep in mind that IWRAM is a limited resource.


proc clrFadeFast*(src: ptr Color; clr: Color; dst: ptr Color; nclrs: cint; alpha: cint) {.importc: "clr_fade_fast", tonc.}
  ## Fades color arrays `srca` to `clr` into `dst`.
  ## 
  ## :src: Source array.
  ## :clr: Final color (at alpha=32).
  ## :dst: Destination array.
  ## :nclrs: Number of colors.
  ## :alpha: Blend weight (range: 0-32).
  ## 
  ## .. note::
  ##    This is an ARM assembly routine placed in IWRAM, which makes it very fast, but keep in mind that IWRAM is a limited resource.
