# GBA Memory map
# ==============

import types

{.pragma: tonc, header: "tonc_memmap.h".}

# Main sections
const
  MEM_EWRAM*:uint32 = 0x02000000  ## External work RAM
  MEM_IWRAM*:uint32 = 0x03000000  ## Internal work RAM
  MEM_IO*:uint32    = 0x04000000  ## I/O registers
  MEM_PAL*:uint32   = 0x05000000  ## Palette. Note: no 8bit write !!
  MEM_VRAM*:uint32  = 0x06000000  ## Video RAM. Note: no 8bit write !!
  MEM_OAM*:uint32   = 0x07000000  ## Object Attribute Memory (OAM) Note: no 8bit write !!
  MEM_ROM*:uint32   = 0x08000000  ## ROM. No write at all (duh)
  MEM_SRAM*:uint32   = 0x0E000000  ## Static RAM. 8bit write only

# Main section sizes
const
  EWRAM_SIZE*:uint32 = 0x40000
  IWRAM_SIZE*:uint32 = 0x08000
  PAL_SIZE*:uint32   = 0x00400
  VRAM_SIZE*:uint32  = 0x18000
  OAM_SIZE*:uint32   = 0x00400
  SRAM_SIZE*:uint32  = 0x10000

# Sub section sizes
const
  PAL_BG_SIZE*:uint32    = 0x00200  ## BG palette size
  PAL_OBJ_SIZE*:uint32   = 0x00200  ## Object palette size
  CBB_SIZE*:uint32       = 0x04000  ## Charblock size (single)
  SBB_SIZE*:uint32       = 0x00800  ## Screenblock size (single)
  VRAM_BG_SIZE*:uint32   = 0x10000  ## BG VRAM size
  VRAM_OBJ_SIZE*:uint32  = 0x08000  ## Object VRAM size
  M3_SIZE*:uint32        = 0x12C00  ## Mode 3 buffer size
  M4_SIZE*:uint32        = 0x09600  ## Mode 4 buffer size
  M5_SIZE*:uint32        = 0x0A000  ## Mode 5 buffer size
  VRAM_PAGE_SIZE*:uint32 = 0x0A000  ## Bitmap page size

# Sub sections
const
  REG_BASE* = MEM_IO
  MEM_PAL_BG* = (MEM_PAL)                      ## Background palette address
  MEM_PAL_OBJ* = (MEM_PAL + PAL_BG_SIZE)       ## Object palette address
  MEM_VRAM_FRONT* = (MEM_VRAM)                 ## Front page address
  MEM_VRAM_BACK* = (MEM_VRAM + VRAM_PAGE_SIZE) ## Back page address
  MEM_VRAM_OBJ* = (MEM_VRAM + VRAM_BG_SIZE)    ## Object VRAM address

# STRUCTURED MEMORY MAP
# ---------------------
# These are some defines for easier access of various
#  memory sections. They're all arrays or matrices, using the
#  types that would be the most natural for the concept.

# Palette


var bgColorMem* {.importc:"pal_bg_mem", tonc.}: array[256, Color]
  ## Access to BG PAL RAM as a single array of colors.
  ## 
  ## This is useful when working with 8bpp backgrounds, or display mode 4.

var bgPalMem* {.importc:"pal_bg_bank", tonc.}: array[16, Palette]
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


var objColorMem* {.importc:"pal_obj_mem", tonc.}: array[256, Color]
  ## Access to OBJ PAL RAM as a single array of colors.
  ## 
  ## This is useful when working with 8bpp sprites.

var objPalMem* {.importc:"pal_obj_bank", tonc.}: array[16, Palette]
  ## Access to OBJ PAL RAM as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp sprites.

var palBgMem* {.deprecated:"Use bgColorMem instead", importc:"pal_bg_mem", tonc.}: array[256, Color]
  ## Background palette.
  ## 
  ## .. code-block:: nim
  ## 
  ##   palBgMem[i] = color i

var palObjMem* {.deprecated:"Use objColorMem instead", importc:"pal_obj_mem", tonc.}: array[256, Color]
  ## Object palette.
  ## 
  ## .. code-block:: nim
  ## 
  ##   palObjMem[i] = color i

{.push warning[Deprecated]: off.}

var palBgBank* {.deprecated:"Use bgPalMem instead", importc:"pal_bg_bank", tonc.}: array[16, Palette]
  ## Background palette matrix.
  ## 
  ## .. code-block:: nim
  ## 
  ##   palBgBank[i] = bank i
  ##   palBgBank[i][j] = color i*16+j

var palObjBank* {.deprecated:"Use objPalMem instead", importc:"pal_obj_bank", tonc.}: array[16, Palette]
  ## Object palette matrix.
  ## 
  ## .. code-block:: nim
  ## 
  ##   palObjBank[i] = bank i
  ##   palObjBank[i][j] = color i*16+j

{.pop.}

# VRAM

var bgTileMem* {.importc:"tile_mem", tonc.}: array[4, UnboundedCharblock]
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

var bgTileMem8* {.importc:"tile8_mem", tonc.}: array[4, UnboundedCharblock8]
  ## BG charblocks, 8bpp tiles.
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgTileMem8[i]      # charblock i
  ##   bgTileMem8[i][j]   # charblock i, tile j

var objTileMem* {.importc:"tile_mem_obj[0]", tonc.}: array[1024, Tile]
  ## Object (sprite) image data, as 4bpp tiles.
  ## 
  ## This is 2 charblocks in size, and is separate from BG tile memory.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   objTileMem[n] = Tile()   # Clear the image data for a tile.

var objTileMem8* {.importc:"tile8_mem_obj[0]", tonc.}: array[512, Tile8]
  ## Object (sprite) tiles, 8bpp

var seMem* {.importc:"se_mem", tonc.}: array[32, Screenblock]
  ## Screenblocks as arrays
  ## 
  ## .. code-block:: nim
  ## 
  ##   seMem[i]       # screenblock i
  ##   seMem[i][j]    # screenblock i, entry j
  ##   seMem[i][x,y]  # screenblock i, entry x + y*32


var vidMem* {.importc:"vid_mem", tonc.}: array[240*160, Color]
  ## Main mode 3/5 frame as an array
  ## 
  ## .. code-block:: nim
  ## 
  ##   vidMem[i]    # pixel i

var m3Mem* {.importc:"m3_mem", tonc.}: array[160, M3Line]
  ## Mode 3 frame as a matrix
  ## 
  ## .. code-block:: nim
  ## 
  ##   m3Mem[y][x]  # pixel (x, y)

var m4Mem* {.importc:"m4_mem", tonc.}: array[160, M4Line]
  ## Mode 4 first page as a matrix
  ## Note: This is a byte-buffer. Not to be used for writing.
  ## 
  ## .. code-block:: nim
  ## 
  ##   m4Mem[y][x]  # pixel (x, y)

var m5Mem* {.importc:"m5_mem", tonc.}: array[128, M5Line]
  ## Mode 5 first page as a matrix
  ## 
  ## .. code-block:: nim
  ## 
  ##   m5Mem[y][x]  # pixel (x, y)

var vidMemFront* {.importc:"vid_mem_front", tonc.}: array[160*128, uint16]
  ## First page array

var vidMemBack* {.importc:"vid_mem_back", tonc.}: array[160*128, uint16]
  ## Second page array

var m4MemBack* {.importc:"m4_mem_back", tonc.}: array[160, M4Line]
  ## Mode 4 second page as a matrix
  ## This is a byte-buffer. Not to be used for writing.
  ## 
  ## .. code-block:: nim
  ## 
  ##   m4MemBack[y][x]  = pixel (x, y)          ( u8 )

var m5MemBack* {.importc:"m5_mem_back", tonc.}: array[128, M5Line]
  ## Mode 5 second page as a matrix
  ## 
  ## .. code-block:: nim
  ## 
  ##   m5MemBack[y][x]  = pixel (x, y)          ( Color )


# OAM

var objMem* {.importc:"oam_mem", tonc.}: array[128, ObjAttr]
  ## Object attribute memory
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[i] = object i            (ObjAttr)

var objAffMem* {.importc:"obj_aff_mem", tonc.}: array[32, ObjAffine]
  ## Object affine memory
  ## 
  ## .. code-block:: nim
  ## 
  ##   objAffMem[i] = object matrix i      ( OBJ_AFFINE )  


# ROM

const maxRomSize = 0x2000000  # 32MB
var romMem* {.importc:"rom_mem", tonc.}: array[maxRomSize div sizeof(uint16), uint16]
  ## ROM pointer

# SRAM

const maxSramSize = 0x10000  # 64KB
var sramMem* {.importc:"sram_mem", tonc.}: array[maxSramSize, uint8]
  ## SRAM pointer

# deprecated
var tileMem* {.deprecated:"Use bgTileMem", importc:"tile_mem", tonc.}: array[6, Charblock]
var tile8Mem* {.deprecated:"Use bgTileMem8", importc:"tile8_mem", tonc.}: array[6, Charblock8]
var tileMemObj* {.deprecated:"Use objTileMem[i] instead of tileMemObj[0][i]", importc:"tile_mem_obj", tonc.}: array[2, Charblock]
var tile8MemObj* {.deprecated:"Use objTileMem8[i] instead of tile8MemObj[0][i]", importc:"tile8_mem_obj", tonc.}: array[2, Charblock8]
var seMat* {.deprecated:"Use seMem[s][x,y] instead", importc:"se_mat", tonc.}: array[32, ScreenMat]
var oamMem* {.deprecated:"Use `objMem` instead", importc:"oam_mem", tonc.}: array[128, ObjAttr]


# REGISTER LIST

# IWRAM 'registers'
# 0300:7ff[y] is mirrored at 03ff:fff[y], which is why this works out:

var REG_IFBIOS* {.importc:"REG_IFBIOS", tonc.}: uint16        ## IRQ ack for IntrWait functions (REG_BASE - 0x00000008)
var REG_RESET_DST* {.importc:"REG_RESET_DST", tonc.}: uint16  ## Destination for after SoftReset (REG_BASE - 0x00000006)
var REG_ISR_MAIN* {.importc:"REG_ISR_MAIN", tonc.}: FnPtr     ## IRQ handler address (REG_BASE - 0x00000004)

# Display registers
var REG_DISPCNT* {.importc:"REG_DISPCNT", tonc.}: uint32    ## Display control (REG_BASE + 0x00000000)
var REG_DISPSTAT* {.importc:"REG_DISPSTAT", tonc.}: uint16  ## Display status (REG_BASE + 0x00000004)
var REG_VCOUNT* {.importc:"REG_VCOUNT", tonc.}: uint16      ## Scanline count (REG_BASE + 0x00000006)

# Background control registers
var REG_BGCNT* {.importc:"REG_BGCNT", tonc.}: array[4, uint16]   ## Bg control array (REG_BASE + 0x00000008)
var REG_BG0CNT* {.importc:"REG_BG0CNT", tonc.}: uint16         ## Bg0 control (REG_BASE + 0x00000008)
var REG_BG1CNT* {.importc:"REG_BG1CNT", tonc.}: uint16         ## Bg1 control (REG_BASE + 0x0000000A)
var REG_BG2CNT* {.importc:"REG_BG2CNT", tonc.}: uint16         ## Bg2 control (REG_BASE + 0x0000000C)
var REG_BG3CNT* {.importc:"REG_BG3CNT", tonc.}: uint16         ## Bg3 control (REG_BASE + 0x0000000E)

# Regular background scroll registers. (write only!)
var REG_BG_OFS* {.importc:"REG_BG_OFS", tonc.}: array[4, BgPoint]  ## Bg scroll array (REG_BASE + 0x00000010)
var REG_BG0HOFS* {.importc:"REG_BG0HOFS", tonc.}: uint16       ## Bg0 horizontal scroll (REG_BASE + 0x00000010)
var REG_BG0VOFS* {.importc:"REG_BG0VOFS", tonc.}: uint16       ## Bg0 vertical scroll (REG_BASE + 0x00000012)
var REG_BG1HOFS* {.importc:"REG_BG1HOFS", tonc.}: uint16       ## Bg1 horizontal scroll (REG_BASE + 0x00000014)
var REG_BG1VOFS* {.importc:"REG_BG1VOFS", tonc.}: uint16       ## Bg1 vertical scroll (REG_BASE + 0x00000016)
var REG_BG2HOFS* {.importc:"REG_BG2HOFS", tonc.}: uint16       ## Bg2 horizontal scroll (REG_BASE + 0x00000018)
var REG_BG2VOFS* {.importc:"REG_BG2VOFS", tonc.}: uint16       ## Bg2 vertical scroll (REG_BASE + 0x0000001A)
var REG_BG3HOFS* {.importc:"REG_BG3HOFS", tonc.}: uint16       ## Bg3 horizontal scroll (REG_BASE + 0x0000001C)
var REG_BG3VOFS* {.importc:"REG_BG3VOFS", tonc.}: uint16       ## Bg3 vertical scroll (REG_BASE + 0x0000001E)

# Affine background parameters. (write only!)
var REG_BG_AFFINE* {.importc:"REG_BG_AFFINE", tonc.}: array[2, BgAffine] ## Bg affine array (REG_BASE + 0x00000020)
var REG_BG2PA* {.importc:"REG_BG2PA", tonc.}: int16  ## Bg2 matrix.pa (REG_BASE + 0x00000020)
var REG_BG2PB* {.importc:"REG_BG2PB", tonc.}: int16  ## Bg2 matrix.pb (REG_BASE + 0x00000022)
var REG_BG2PC* {.importc:"REG_BG2PC", tonc.}: int16  ## Bg2 matrix.pc (REG_BASE + 0x00000024)
var REG_BG2PD* {.importc:"REG_BG2PD", tonc.}: int16  ## Bg2 matrix.pd (REG_BASE + 0x00000026)
var REG_BG2X* {.importc:"REG_BG2X", tonc.}: int32  ## Bg2 x scroll (REG_BASE + 0x00000028)
var REG_BG2Y* {.importc:"REG_BG2Y", tonc.}: int32  ## Bg2 y scroll (REG_BASE + 0x0000002C)
var REG_BG3PA* {.importc:"REG_BG3PA", tonc.}: int16  ## Bg3 matrix.pa (REG_BASE + 0x00000030)
var REG_BG3PB* {.importc:"REG_BG3PB", tonc.}: int16  ## Bg3 matrix.pb (REG_BASE + 0x00000032)
var REG_BG3PC* {.importc:"REG_BG3PC", tonc.}: int16  ## Bg3 matrix.pc (REG_BASE + 0x00000034)
var REG_BG3PD* {.importc:"REG_BG3PD", tonc.}: int16  ## Bg3 matrix.pd (REG_BASE + 0x00000036)
var REG_BG3X* {.importc:"REG_BG3X", tonc.}: int32  ## Bg3 x scroll (REG_BASE + 0x00000038)
var REG_BG3Y* {.importc:"REG_BG3Y", tonc.}: int32  ## Bg3 y scroll (REG_BASE + 0x0000003C)

# Windowing registers
var REG_WIN0H* {.importc:"REG_WIN0H", tonc.}: uint16  ## win0 right, left (0xLLRR) (REG_BASE + 0x00000040)
var REG_WIN1H* {.importc:"REG_WIN1H", tonc.}: uint16  ## win1 right, left (0xLLRR) (REG_BASE + 0x00000042)
var REG_WIN0V* {.importc:"REG_WIN0V", tonc.}: uint16  ## win0 bottom, top (0xTTBB) (REG_BASE + 0x00000044)
var REG_WIN1V* {.importc:"REG_WIN1V", tonc.}: uint16  ## win1 bottom, top (0xTTBB) (REG_BASE + 0x00000046)
var REG_WININ* {.importc:"REG_WININ", tonc.}: uint16  ## win0, win1 control (REG_BASE + 0x00000048)
var REG_WINOUT* {.importc:"REG_WINOUT", tonc.}: uint16  ## winOut, winObj control (REG_BASE + 0x0000004A)

# Alternate Windowing registers
var REG_WIN0R* {.importc:"REG_WIN0R", tonc.}: uint8  ## Win 0 right (REG_BASE + 0x00000040)
var REG_WIN0L* {.importc:"REG_WIN0L", tonc.}: uint8  ## Win 0 left (REG_BASE + 0x00000041)
var REG_WIN1R* {.importc:"REG_WIN1R", tonc.}: uint8  ## Win 1 right (REG_BASE + 0x00000042)
var REG_WIN1L* {.importc:"REG_WIN1L", tonc.}: uint8  ## Win 1 left (REG_BASE + 0x00000043)
var REG_WIN0B* {.importc:"REG_WIN0B", tonc.}: uint8  ## Win 0 bottom (REG_BASE + 0x00000044)
var REG_WIN0T* {.importc:"REG_WIN0T", tonc.}: uint8  ## Win 0 top (REG_BASE + 0x00000045)
var REG_WIN1B* {.importc:"REG_WIN1B", tonc.}: uint8  ## Win 1 bottom (REG_BASE + 0x00000046)
var REG_WIN1T* {.importc:"REG_WIN1T", tonc.}: uint8  ## Win 1 top (REG_BASE + 0x00000047)
var REG_WIN0CNT* {.importc:"REG_WIN0CNT", tonc.}: uint8  ## window 0 control (REG_BASE + 0x00000048)
var REG_WIN1CNT* {.importc:"REG_WIN1CNT", tonc.}: uint8  ## window 1 control (REG_BASE + 0x00000049)
var REG_WINOUTCNT* {.importc:"REG_WINOUTCNT", tonc.}: uint8  ## Out window control (REG_BASE + 0x0000004A)
var REG_WINOBJCNT* {.importc:"REG_WINOBJCNT", tonc.}: uint8  ## Obj window control (REG_BASE + 0x0000004B)

# Graphic effects
var REG_MOSAIC* {.importc:"REG_MOSAIC", tonc.}: uint32  ## Mosaic control (REG_BASE + 0x0000004C)
var REG_BLDCNT* {.importc:"REG_BLDCNT", tonc.}: uint16  ## Alpha control (REG_BASE + 0x00000050)
var REG_BLDALPHA* {.importc:"REG_BLDALPHA", tonc.}: uint16  ## Fade level (REG_BASE + 0x00000052)
var REG_BLDY* {.importc:"REG_BLDY", tonc.}: uint16  ## Blend levels (REG_BASE + 0x00000054)

# === SOUND REGISTERS ===
# sound regs, partially following pin8gba's nomenclature
# Channel 1: Square wave with sweep
var REG_SND1SWEEP* {.importc:"REG_SND1SWEEP", tonc.}: uint16  ## Channel 1 Sweep (REG_BASE + 0x00000060)
var REG_SND1CNT* {.importc:"REG_SND1CNT", tonc.}: uint16  ## Channel 1 Control (REG_BASE + 0x00000062)
var REG_SND1FREQ* {.importc:"REG_SND1FREQ", tonc.}: uint16  ## Channel 1 frequency (REG_BASE + 0x00000064)

# Channel 2: Simple square wave
var REG_SND2CNT* {.importc:"REG_SND2CNT", tonc.}: uint16  ## Channel 2 control (REG_BASE + 0x00000068)
var REG_SND2FREQ* {.importc:"REG_SND2FREQ", tonc.}: uint16  ## Channel 2 frequency (REG_BASE + 0x0000006C)

# Channel 3: Wave player
var REG_SND3SEL* {.importc:"REG_SND3SEL", tonc.}: uint16  ## Channel 3 wave select (REG_BASE + 0x00000070)
var REG_SND3CNT* {.importc:"REG_SND3CNT", tonc.}: uint16  ## Channel 3 control (REG_BASE + 0x00000072)
var REG_SND3FREQ* {.importc:"REG_SND3FREQ", tonc.}: uint16  ## Channel 3 frequency (REG_BASE + 0x00000074)

# Channel 4: Noise generator
var REG_SND4CNT* {.importc:"REG_SND4CNT", tonc.}: uint16  ## Channel 4 control (REG_BASE + 0x00000078)
var REG_SND4FREQ* {.importc:"REG_SND4FREQ", tonc.}: uint16  ## Channel 4 frequency (REG_BASE + 0x0000007C)

# Sound control
var REG_SNDCNT* {.importc:"REG_SNDCNT", tonc.}: uint32  ## Main sound control (REG_BASE + 0x00000080)
var REG_SNDDMGCNT* {.importc:"REG_SNDDMGCNT", tonc.}: uint16  ## DMG channel control (REG_BASE + 0x00000080)
var REG_SNDDSCNT* {.importc:"REG_SNDDSCNT", tonc.}: uint16  ## Direct Sound control (REG_BASE + 0x00000082)
var REG_SNDSTAT* {.importc:"REG_SNDSTAT", tonc.}: uint16  ## Sound status (REG_BASE + 0x00000084)
var REG_SNDBIAS* {.importc:"REG_SNDBIAS", tonc.}: uint16  ## Sound bias (REG_BASE + 0x00000088)

# Sound buffers
var REG_WAVE_RAM* {.importc:"REG_WAVE_RAM", tonc.}: uint32  ## Channel 3 wave buffer (REG_BASE + 0x00000090))
var REG_WAVE_RAM0* {.importc:"REG_WAVE_RAM0", tonc.}: uint32  ## (REG_BASE + 0x00000090)
var REG_WAVE_RAM1* {.importc:"REG_WAVE_RAM1", tonc.}: uint32  ## (REG_BASE + 0x00000094)
var REG_WAVE_RAM2* {.importc:"REG_WAVE_RAM2", tonc.}: uint32  ## (REG_BASE + 0x00000098)
var REG_WAVE_RAM3* {.importc:"REG_WAVE_RAM3", tonc.}: uint32  ## (REG_BASE + 0x0000009C)
var REG_FIFO_A* {.importc:"REG_FIFO_A", tonc.}: uint32  ## DSound A FIFO (REG_BASE + 0x000000A0)
var REG_FIFO_B* {.importc:"REG_FIFO_B", tonc.}: uint32  ## DSound B FIFO (REG_BASE + 0x000000A4)

# DMA registers
var REG_DMA* {.importc:"REG_DMA", tonc.}: array[4, DmaRec] ## DMA as DMA_REC array (REG_BASE + 0x000000B0)
var REG_DMA0SAD* {.importc:"REG_DMA0SAD", tonc.}: uint32  ## DMA 0 Source address (REG_BASE + 0x000000B0)
var REG_DMA0DAD* {.importc:"REG_DMA0DAD", tonc.}: uint32  ## DMA 0 Destination address (REG_BASE + 0x000000B4)
var REG_DMA0CNT* {.importc:"REG_DMA0CNT", tonc.}: uint32  ## DMA 0 Control (REG_BASE + 0x000000B8)
var REG_DMA1SAD* {.importc:"REG_DMA1SAD", tonc.}: uint32  ## DMA 1 Source address (REG_BASE + 0x000000BC)
var REG_DMA1DAD* {.importc:"REG_DMA1DAD", tonc.}: uint32  ## DMA 1 Destination address (REG_BASE + 0x000000C0)
var REG_DMA1CNT* {.importc:"REG_DMA1CNT", tonc.}: uint32  ## DMA 1 Control (REG_BASE + 0x000000C4)
var REG_DMA2SAD* {.importc:"REG_DMA2SAD", tonc.}: uint32  ## DMA 2 Source address (REG_BASE + 0x000000C8)
var REG_DMA2DAD* {.importc:"REG_DMA2DAD", tonc.}: uint32  ## DMA 2 Destination address (REG_BASE + 0x000000CC)
var REG_DMA2CNT* {.importc:"REG_DMA2CNT", tonc.}: uint32  ## DMA 2 Control (REG_BASE + 0x000000D0)
var REG_DMA3SAD* {.importc:"REG_DMA3SAD", tonc.}: uint32  ## DMA 3 Source address (REG_BASE + 0x000000D4)
var REG_DMA3DAD* {.importc:"REG_DMA3DAD", tonc.}: uint32  ## DMA 3 Destination address (REG_BASE + 0x000000D8)
var REG_DMA3CNT* {.importc:"REG_DMA3CNT", tonc.}: uint32  ## DMA 3 Control (REG_BASE + 0x000000DC)

# Timer registers
var REG_TM* {.importc:"REG_TM", tonc.}: array[4, TmrRec] ## Timers as TMR_REC array (REG_BASE + 0x00000100)
var REG_TM0D* {.importc:"REG_TM0D", tonc.}: uint16      ## Timer 0 data (REG_BASE + 0x00000100)
var REG_TM0CNT* {.importc:"REG_TM0CNT", tonc.}: uint16  ## Timer 0 control (REG_BASE + 0x00000102)
var REG_TM1D* {.importc:"REG_TM1D", tonc.}: uint16      ## Timer 1 data (REG_BASE + 0x00000104)
var REG_TM1CNT* {.importc:"REG_TM1CNT", tonc.}: uint16  ## Timer 1 control (REG_BASE + 0x00000106)
var REG_TM2D* {.importc:"REG_TM2D", tonc.}: uint16      ## Timer 2 data (REG_BASE + 0x00000108)
var REG_TM2CNT* {.importc:"REG_TM2CNT", tonc.}: uint16  ## Timer 2 control (REG_BASE + 0x0000010A)
var REG_TM3D* {.importc:"REG_TM3D", tonc.}: uint16      ## Timer 3 data (REG_BASE + 0x0000010C)
var REG_TM3CNT* {.importc:"REG_TM3CNT", tonc.}: uint16  ## Timer 3 control (REG_BASE + 0x0000010E)

# Serial communication
var REG_SIOCNT* {.importc:"REG_SIOCNT", tonc.}: uint16  ## Serial IO control (Normal/MP/UART) (REG_BASE + 0x00000128)
var REG_SIODATA* {.importc:"REG_SIODATA", tonc.}: array[1, uint32] ## ????? [[I don't get how this differs from REG_SIODATA32. Why is it an array? How big should it be?]] ## (REG_BASE + 0x00000120)
var REG_SIODATA32* {.importc:"REG_SIODATA32", tonc.}: uint32  ## Normal/UART 32bit data (REG_BASE + 0x00000120)
var REG_SIODATA8* {.importc:"REG_SIODATA8", tonc.}: uint16    ## Normal/UART 8bit data (REG_BASE + 0x0000012A)
var REG_SIOMULTI* {.importc:"REG_SIOMULTI", tonc.}: array[4, uint16] # Multiplayer data array (REG_BASE + 0x00000120)
var REG_SIOMULTI0* {.importc:"REG_SIOMULTI0", tonc.}: uint16      ## MP master data (REG_BASE + 0x00000120)
var REG_SIOMULTI1* {.importc:"REG_SIOMULTI1", tonc.}: uint16      ## MP Slave 1 data (REG_BASE + 0x00000122)
var REG_SIOMULTI2* {.importc:"REG_SIOMULTI2", tonc.}: uint16      ## MP Slave 2 data (REG_BASE + 0x00000124)
var REG_SIOMULTI3* {.importc:"REG_SIOMULTI3", tonc.}: uint16      ## MP Slave 3 data (REG_BASE + 0x00000126)
var REG_SIOMLT_RECV* {.importc:"REG_SIOMLT_RECV", tonc.}: uint16  ## MP data receiver (REG_BASE + 0x00000120)
var REG_SIOMLT_SEND* {.importc:"REG_SIOMLT_SEND", tonc.}: uint16  ## MP data sender (REG_BASE + 0x0000012A)

#  Keypad registers
var REG_KEYINPUT* {.importc:"REG_KEYINPUT", tonc.}: uint16  ## Key status (read only??) (REG_BASE + 0x00000130)
var REG_KEYCNT* {.importc:"REG_KEYCNT", tonc.}: uint16      ## Key IRQ control (REG_BASE + 0x00000132)

# Joybus communication
var REG_RCNT* {.importc:"REG_RCNT", tonc.}: uint16            ## SIO Mode Select/General Purpose Data (REG_BASE + 0x00000134)
var REG_JOYCNT* {.importc:"REG_JOYCNT", tonc.}: uint16        ## JOY bus control (REG_BASE + 0x00000140)
var REG_JOY_RECV* {.importc:"REG_JOY_RECV", tonc.}: uint32    ## JOY bus receiever (REG_BASE + 0x00000150)
var REG_JOY_TRANS* {.importc:"REG_JOY_TRANS", tonc.}: uint32  ## JOY bus transmitter (REG_BASE + 0x00000154)
var REG_JOYSTAT* {.importc:"REG_JOYSTAT", tonc.}: uint16      ## JOY bus status (REG_BASE + 0x00000158)

#  Interrupt / System registers
var REG_IE* {.importc:"REG_IE", tonc.}: uint16            ## IRQ enable (REG_BASE + 0x00000200)
var REG_IF* {.importc:"REG_IF", tonc.}: uint16            ## IRQ status/acknowledge (REG_BASE + 0x00000202)
var REG_WAITCNT* {.importc:"REG_WAITCNT", tonc.}: uint16  ## Waitstate control (REG_BASE + 0x00000204)
var REG_IME* {.importc:"REG_IME", tonc.}: uint16          ## IRQ master enable (REG_BASE + 0x00000208)
var REG_PAUSE* {.importc:"REG_PAUSE", tonc.}: uint16      ## Pause system (?) (REG_BASE + 0x00000300)

# ALT REGISTERS
# Alternate names for some of the registers

var REG_BLDMOD* {.importc:"REG_BLDMOD", tonc.}: uint16  ##  alpha control (REG_BASE + 0x00000050)
var REG_COLEV* {.importc:"REG_COLEV", tonc.}: uint16    ##  fade level (REG_BASE + 0x00000052)
var REG_COLEY* {.importc:"REG_COLEY", tonc.}: uint16    ##  blend levels (REG_BASE + 0x00000054)

##  sound regs as in belogic and GBATek (mostly for compatability)
var REG_SOUND1CNT* {.importc:"REG_SOUND1CNT", tonc.}: uint32  ## (REG_BASE + 0x00000060)
var REG_SOUND1CNT_L* {.importc:"REG_SOUND1CNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000060)
var REG_SOUND1CNT_H* {.importc:"REG_SOUND1CNT_H", tonc.}: uint16  ## (REG_BASE + 0x00000062)
var REG_SOUND1CNT_X* {.importc:"REG_SOUND1CNT_X", tonc.}: uint16  ## (REG_BASE + 0x00000064)
var REG_SOUND2CNT_L* {.importc:"REG_SOUND2CNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000068)
var REG_SOUND2CNT_H* {.importc:"REG_SOUND2CNT_H", tonc.}: uint16  ## (REG_BASE + 0x0000006C)
var REG_SOUND3CNT* {.importc:"REG_SOUND3CNT", tonc.}: uint32  ## (REG_BASE + 0x00000070)
var REG_SOUND3CNT_L* {.importc:"REG_SOUND3CNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000070)
var REG_SOUND3CNT_H* {.importc:"REG_SOUND3CNT_H", tonc.}: uint16  ## (REG_BASE + 0x00000072)
var REG_SOUND3CNT_X* {.importc:"REG_SOUND3CNT_X", tonc.}: uint16  ## (REG_BASE + 0x00000074)
var REG_SOUND4CNT_L* {.importc:"REG_SOUND4CNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000078)
var REG_SOUND4CNT_H* {.importc:"REG_SOUND4CNT_H", tonc.}: uint16  ## (REG_BASE + 0x0000007C)
var REG_SOUNDCNT* {.importc:"REG_SOUNDCNT", tonc.}: uint32  ## (REG_BASE + 0x00000080)
var REG_SOUNDCNT_L* {.importc:"REG_SOUNDCNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000080)
var REG_SOUNDCNT_H* {.importc:"REG_SOUNDCNT_H", tonc.}: uint16  ## (REG_BASE + 0x00000082)
var REG_SOUNDCNT_X* {.importc:"REG_SOUNDCNT_X", tonc.}: uint16  ## (REG_BASE + 0x00000084)
var REG_SOUNDBIAS* {.importc:"REG_SOUNDBIAS", tonc.}: uint16  ## (REG_BASE + 0x00000088)
var REG_WAVE* {.importc:"REG_WAVE", tonc.}: uint32  ## (REG_BASE + 0x00000090))
var REG_DMA0CNT_L* {.importc:"REG_DMA0CNT_L", tonc.}: uint16  ## (REG_BASE + 0x000000B8)  count
var REG_DMA0CNT_H* {.importc:"REG_DMA0CNT_H", tonc.}: uint16  ## (REG_BASE + 0x000000BA)  flags
var REG_DMA1CNT_L* {.importc:"REG_DMA1CNT_L", tonc.}: uint16  ## (REG_BASE + 0x000000C4)
var REG_DMA1CNT_H* {.importc:"REG_DMA1CNT_H", tonc.}: uint16  ## (REG_BASE + 0x000000C6)
var REG_DMA2CNT_L* {.importc:"REG_DMA2CNT_L", tonc.}: uint16  ## (REG_BASE + 0x000000D0)
var REG_DMA2CNT_H* {.importc:"REG_DMA2CNT_H", tonc.}: uint16  ## (REG_BASE + 0x000000D2)
var REG_DMA3CNT_L* {.importc:"REG_DMA3CNT_L", tonc.}: uint16  ## (REG_BASE + 0x000000DC)
var REG_DMA3CNT_H* {.importc:"REG_DMA3CNT_H", tonc.}: uint16  ## (REG_BASE + 0x000000DE)
var REG_TM0CNT_L* {.importc:"REG_TM0CNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000100)
var REG_TM0CNT_H* {.importc:"REG_TM0CNT_H", tonc.}: uint16  ## (REG_BASE + 0x00000102)
var REG_TM1CNT_L* {.importc:"REG_TM1CNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000104)
var REG_TM1CNT_H* {.importc:"REG_TM1CNT_H", tonc.}: uint16  ## (REG_BASE + 0x00000106)
var REG_TM2CNT_L* {.importc:"REG_TM2CNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000108)
var REG_TM2CNT_H* {.importc:"REG_TM2CNT_H", tonc.}: uint16  ## (REG_BASE + 0x0000010A)
var REG_TM3CNT_L* {.importc:"REG_TM3CNT_L", tonc.}: uint16  ## (REG_BASE + 0x0000010C)
var REG_TM3CNT_H* {.importc:"REG_TM3CNT_H", tonc.}: uint16  ## (REG_BASE + 0x0000010E)
var REG_KEYS* {.importc:"REG_KEYS", tonc.}: uint16  ## (REG_BASE + 0x00000130)  Key status
var REG_P1* {.importc:"REG_P1", tonc.}: uint16  ## (REG_BASE + 0x00000130)  for backward combatibility
var REG_P1CNT* {.importc:"REG_P1CNT", tonc.}: uint16  ## (REG_BASE + 0x00000132)  ditto
var REG_SCD0* {.importc:"REG_SCD0", tonc.}: uint16  ## (REG_BASE + 0x00000120)
var REG_SCD1* {.importc:"REG_SCD1", tonc.}: uint16  ## (REG_BASE + 0x00000122)
var REG_SCD2* {.importc:"REG_SCD2", tonc.}: uint16  ## (REG_BASE + 0x00000124)
var REG_SCD3* {.importc:"REG_SCD3", tonc.}: uint16  ## (REG_BASE + 0x00000126)
var REG_SCCNT* {.importc:"REG_SCCNT", tonc.}: uint32  ## (REG_BASE + 0x00000128)
var REG_SCCNT_L* {.importc:"REG_SCCNT_L", tonc.}: uint16  ## (REG_BASE + 0x00000128)
var REG_SCCNT_H* {.importc:"REG_SCCNT_H", tonc.}: uint16  ## (REG_BASE + 0x0000012A)
var REG_R* {.importc:"REG_R", tonc.}: uint16  ## (REG_BASE + 0x00000134)
var REG_HS_CTRL* {.importc:"REG_HS_CTRL", tonc.}: uint16  ## (REG_BASE + 0x00000140)
var REG_JOYRE* {.importc:"REG_JOYRE", tonc.}: uint32  ## (REG_BASE + 0x00000150)
var REG_JOYRE_L* {.importc:"REG_JOYRE_L", tonc.}: uint16  ## (REG_BASE + 0x00000150)
var REG_JOYRE_H* {.importc:"REG_JOYRE_H", tonc.}: uint16  ## (REG_BASE + 0x00000152)
var REG_JOYTR* {.importc:"REG_JOYTR", tonc.}: uint32  ## (REG_BASE + 0x00000154)
var REG_JOYTR_L* {.importc:"REG_JOYTR_L", tonc.}: uint16  ## (REG_BASE + 0x00000154)
var REG_JOYTR_H* {.importc:"REG_JOYTR_H", tonc.}: uint16  ## (REG_BASE + 0x00000156)
var REG_JSTAT* {.importc:"REG_JSTAT", tonc.}: uint16  ## (REG_BASE + 0x00000158)
var REG_WSCNT* {.importc:"REG_WSCNT", tonc.}: uint16  ## (REG_BASE + 0x00000204)
