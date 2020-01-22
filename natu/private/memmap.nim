# GBA Memory map
# ==============

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

var palBgMem* {.importc:"pal_bg_mem", header:"tonc.h".}: array[256, Color]
  ## Background palette.
  ## ::
  ##   palBgMem[i] = color i

var palObjMem* {.importc:"pal_obj_mem", header:"tonc.h".}: array[256, Color]
  ## Object palette.
  ## ::
  ##   palObjMem[i] = color i

var palBgBank* {.importc:"pal_bg_bank", header:"tonc.h".}: array[16, Palbank]
  ## Background palette matrix.
  ## ::
  ##   palBgBank[y] = bank y
  ##   palBgBank[y][x] = color y*16+x

var palObjBank* {.importc:"pal_obj_bank", header:"tonc.h".}: array[16, Palbank]
  ## Object palette matrix.
  ## ::
  ##   palObjBank[y] = bank y
  ##   palObjBank[y][x] = color y*16+x


# VRAM

var tileMem* {.importc:"tile_mem", header:"tonc.h".}: array[4, Charblock]
  ## Charblocks, 4bpp tiles.
  ## ::
  ##   tileMem[y] = charblock y         (Tile[])
  ##   tileMem[y][x] = block y, tile x  (Tile)

var tile8Mem* {.importc:"tile8_mem", header:"tonc.h".}: array[4, Charblock8]
  ## Charblocks, 8bpp tiles.
  ## ::
  ##   tile8Mem[y] = charblock y         (Tile[])
  ##   tile8Mem[y][x] = block y, tile x  (Tile)

var tileMemObj* {.importc:"tile_mem_obj", header:"tonc.h".}: array[2, Charblock]
  ## Object charblocks, 4bpp tiles.
  ## ::
  ##   tileMemObj[y] = charblock y         (Tile[])
  ##   tileMemObj[y][x] = block y, tile x  (Tile)

var tile8MemObj* {.importc:"tile8_mem_obj", header:"tonc.h".}: array[2, Charblock8]
  ## Object charblocks, 8bpp tiles.
  ## ::
  ##   tile8MemObj[y] = charblock y         (Tile[])
  ##   tile8MemObj[y][x] = block y, tile x  (Tile)

var seMem* {.importc:"se_mem", header:"tonc.h".}: array[32, Screenblock]
  ## Screenblocks as arrays
  ## ::
  ##   se_mem[y] = screenblock y              (ScrEntry[])
  ##   se_mem[y][x] = screenblock y, entry x  (ScrEntry)

var seMat* {.importc:"se_mat", header:"tonc.h".}: array[32, ScreenMat]
  ## Screenblock as matrices
  ## ::
  ##   se_mat[s] = screenblock s                     (ScrEntry[][])
  ##   se_mat[s][y][x] = screenblock s, entry (x,y)  (ScrEntry)

var vidMem* {.importc:"vid_mem", header:"tonc.h".}: array[240*160, Color]
  ## Main mode 3/5 frame as an array
  ## ::
  ##   vid_mem[i] = pixel i   (Color)

var m3Mem* {.importc:"m3_mem", header:"tonc.h".}: array[160, M3Line]
  ## Mode 3 frame as a matrix
  ## ::
  ##   m3_mem[y][x]  = pixel (x, y)          ( Color )

var m4Mem* {.importc:"m4_mem", header:"tonc.h".}: array[160, M4Line]
  ## Mode 4 first page as a matrix
  ## Note: This is a byte-buffer. Not to be used for writing.
  ## ::
  ##   m4_mem[y][x]  = pixel (x, y)          ( u8 )

var m5Mem* {.importc:"m5_mem", header:"tonc.h".}: array[128, M5Line]
  ## Mode 5 first page as a matrix
  ## ::
  ##   m5_mem[y][x]  = pixel (x, y)          ( Color )

var vidMemFront* {.importc:"vid_mem_front", header:"tonc.h".}: array[160*128, uint16]
  ## First page array

var vidMemBack* {.importc:"vid_mem_back", header:"tonc.h".}: array[160*128, uint16]
  ## Second page array

var m4MemBack* {.importc:"m4_mem_back", header:"tonc.h".}: array[160, M4Line]
  ## Mode 4 second page as a matrix
  ## This is a byte-buffer. Not to be used for writing.
  ## ::
  ##   m4_mem[y][x]  = pixel (x, y)          ( u8 )

var m5MemBack* {.importc:"m5_mem_back", header:"tonc.h".}: array[128, M5Line]
  ## Mode 5 second page as a matrix
  ## ::
  ##   m5_mem[y][x]  = pixel (x, y)          ( Color )


# OAM

var oamMem* {.importc:"oam_mem", header:"tonc.h".}: array[128, ObjAttr]
  ## Object attribute memory
  ## ::
  ##   oamMem[i] = object i            (ObjAttr)

var objMem* {.importc:"obj_mem", header:"tonc.h".}: array[128, ObjAttr]
  ## Alias for ``oamMem``

var objAffMem* {.importc:"obj_aff_mem", header:"tonc.h".}: array[32, ObjAffine]
  ## Object affine memory
  ## ::
  ##   objAffMem[i] = object matrix i      ( OBJ_AFFINE )  


# ROM

const maxRomSize = 0x2000000  # 32MB
var romMem* {.importc:"rom_mem", header:"tonc.h".}: array[maxRomSize div sizeof(uint16), uint16]
  ## ROM pointer

# SRAM

const maxSramSize = 0x10000  # 64KB
var sramMem* {.importc:"sram_mem", header:"tonc.h".}: array[maxSramSize, uint8]
  ## SRAM pointer


# REGISTER LIST

# IWRAM 'registers'
# 0300:7ff[y] is mirrored at 03ff:fff[y], which is why this works out:

var REG_IFBIOS* {.importc:"REG_IFBIOS", header:"tonc.h".}: uint16        ## IRQ ack for IntrWait functions (REG_BASE - 0x00000008)
var REG_RESET_DST* {.importc:"REG_RESET_DST", header:"tonc.h".}: uint16  ## Destination for after SoftReset (REG_BASE - 0x00000006)
var REG_ISR_MAIN* {.importc:"REG_ISR_MAIN", header:"tonc.h".}: FnPtr     ## IRQ handler address (REG_BASE - 0x00000004)

# Display registers
var REG_DISPCNT* {.importc:"REG_DISPCNT", header:"tonc.h".}: uint32    ## Display control (REG_BASE + 0x00000000)
var REG_DISPSTAT* {.importc:"REG_DISPSTAT", header:"tonc.h".}: uint16  ## Display status (REG_BASE + 0x00000004)
var REG_VCOUNT* {.importc:"REG_VCOUNT", header:"tonc.h".}: uint16      ## Scanline count (REG_BASE + 0x00000006)

# Background control registers
var REG_BGCNT* {.importc:"REG_BGCNT", header:"tonc.h".}: array[4, uint16]   ## Bg control array (REG_BASE + 0x00000008)
var REG_BG0CNT* {.importc:"REG_BG0CNT", header:"tonc.h".}: uint16         ## Bg0 control (REG_BASE + 0x00000008)
var REG_BG1CNT* {.importc:"REG_BG1CNT", header:"tonc.h".}: uint16         ## Bg1 control (REG_BASE + 0x0000000A)
var REG_BG2CNT* {.importc:"REG_BG2CNT", header:"tonc.h".}: uint16         ## Bg2 control (REG_BASE + 0x0000000C)
var REG_BG3CNT* {.importc:"REG_BG3CNT", header:"tonc.h".}: uint16         ## Bg3 control (REG_BASE + 0x0000000E)

# Regular background scroll registers. (write only!)
var REG_BG_OFS* {.importc:"REG_BG_OFS", header:"tonc.h".}: array[4, BgPoint]  ## Bg scroll array (REG_BASE + 0x00000010)
var REG_BG0HOFS* {.importc:"REG_BG0HOFS", header:"tonc.h".}: uint16       ## Bg0 horizontal scroll (REG_BASE + 0x00000010)
var REG_BG0VOFS* {.importc:"REG_BG0VOFS", header:"tonc.h".}: uint16       ## Bg0 vertical scroll (REG_BASE + 0x00000012)
var REG_BG1HOFS* {.importc:"REG_BG1HOFS", header:"tonc.h".}: uint16       ## Bg1 horizontal scroll (REG_BASE + 0x00000014)
var REG_BG1VOFS* {.importc:"REG_BG1VOFS", header:"tonc.h".}: uint16       ## Bg1 vertical scroll (REG_BASE + 0x00000016)
var REG_BG2HOFS* {.importc:"REG_BG2HOFS", header:"tonc.h".}: uint16       ## Bg2 horizontal scroll (REG_BASE + 0x00000018)
var REG_BG2VOFS* {.importc:"REG_BG2VOFS", header:"tonc.h".}: uint16       ## Bg2 vertical scroll (REG_BASE + 0x0000001A)
var REG_BG3HOFS* {.importc:"REG_BG3HOFS", header:"tonc.h".}: uint16       ## Bg3 horizontal scroll (REG_BASE + 0x0000001C)
var REG_BG3VOFS* {.importc:"REG_BG3VOFS", header:"tonc.h".}: uint16       ## Bg3 vertical scroll (REG_BASE + 0x0000001E)

# Affine background parameters. (write only!)
var REG_BG_AFFINE* {.importc:"REG_BG_AFFINE", header:"tonc.h".}: array[2, BgAffine] ## Bg affine array (REG_BASE + 0x00000000)
var REG_BG2PA* {.importc:"REG_BG2PA", header:"tonc.h".}: int16  ## Bg2 matrix.pa (REG_BASE + 0x00000020)
var REG_BG2PB* {.importc:"REG_BG2PB", header:"tonc.h".}: int16  ## Bg2 matrix.pb (REG_BASE + 0x00000022)
var REG_BG2PC* {.importc:"REG_BG2PC", header:"tonc.h".}: int16  ## Bg2 matrix.pc (REG_BASE + 0x00000024)
var REG_BG2PD* {.importc:"REG_BG2PD", header:"tonc.h".}: int16  ## Bg2 matrix.pd (REG_BASE + 0x00000026)
var REG_BG2X* {.importc:"REG_BG2X", header:"tonc.h".}: int32  ## Bg2 x scroll (REG_BASE + 0x00000028)
var REG_BG2Y* {.importc:"REG_BG2Y", header:"tonc.h".}: int32  ## Bg2 y scroll (REG_BASE + 0x0000002C)
var REG_BG3PA* {.importc:"REG_BG3PA", header:"tonc.h".}: int16  ## Bg3 matrix.pa (REG_BASE + 0x00000030)
var REG_BG3PB* {.importc:"REG_BG3PB", header:"tonc.h".}: int16  ## Bg3 matrix.pb (REG_BASE + 0x00000032)
var REG_BG3PC* {.importc:"REG_BG3PC", header:"tonc.h".}: int16  ## Bg3 matrix.pc (REG_BASE + 0x00000034)
var REG_BG3PD* {.importc:"REG_BG3PD", header:"tonc.h".}: int16  ## Bg3 matrix.pd (REG_BASE + 0x00000036)
var REG_BG3X* {.importc:"REG_BG3X", header:"tonc.h".}: int32  ## Bg3 x scroll (REG_BASE + 0x00000038)
var REG_BG3Y* {.importc:"REG_BG3Y", header:"tonc.h".}: int32  ## Bg3 y scroll (REG_BASE + 0x0000003C)

# Windowing registers
var REG_WIN0H* {.importc:"REG_WIN0H", header:"tonc.h".}: uint16  ## win0 right, left (0xLLRR) (REG_BASE + 0x00000040)
var REG_WIN1H* {.importc:"REG_WIN1H", header:"tonc.h".}: uint16  ## win1 right, left (0xLLRR) (REG_BASE + 0x00000042)
var REG_WIN0V* {.importc:"REG_WIN0V", header:"tonc.h".}: uint16  ## win0 bottom, top (0xTTBB) (REG_BASE + 0x00000044)
var REG_WIN1V* {.importc:"REG_WIN1V", header:"tonc.h".}: uint16  ## win1 bottom, top (0xTTBB) (REG_BASE + 0x00000046)
var REG_WININ* {.importc:"REG_WININ", header:"tonc.h".}: uint16  ## win0, win1 control (REG_BASE + 0x00000048)
var REG_WINOUT* {.importc:"REG_WINOUT", header:"tonc.h".}: uint16  ## winOut, winObj control (REG_BASE + 0x0000004A)

# Alternate Windowing registers
var REG_WIN0R* {.importc:"REG_WIN0R", header:"tonc.h".}: uint8  ## Win 0 right (REG_BASE + 0x00000040)
var REG_WIN0L* {.importc:"REG_WIN0L", header:"tonc.h".}: uint8  ## Win 0 left (REG_BASE + 0x00000041)
var REG_WIN1R* {.importc:"REG_WIN1R", header:"tonc.h".}: uint8  ## Win 1 right (REG_BASE + 0x00000042)
var REG_WIN1L* {.importc:"REG_WIN1L", header:"tonc.h".}: uint8  ## Win 1 left (REG_BASE + 0x00000043)
var REG_WIN0B* {.importc:"REG_WIN0B", header:"tonc.h".}: uint8  ## Win 0 bottom (REG_BASE + 0x00000044)
var REG_WIN0T* {.importc:"REG_WIN0T", header:"tonc.h".}: uint8  ## Win 0 top (REG_BASE + 0x00000045)
var REG_WIN1B* {.importc:"REG_WIN1B", header:"tonc.h".}: uint8  ## Win 1 bottom (REG_BASE + 0x00000046)
var REG_WIN1T* {.importc:"REG_WIN1T", header:"tonc.h".}: uint8  ## Win 1 top (REG_BASE + 0x00000047)
var REG_WIN0CNT* {.importc:"REG_WIN0CNT", header:"tonc.h".}: uint8  ## window 0 control (REG_BASE + 0x00000048)
var REG_WIN1CNT* {.importc:"REG_WIN1CNT", header:"tonc.h".}: uint8  ## window 1 control (REG_BASE + 0x00000049)
var REG_WINOUTCNT* {.importc:"REG_WINOUTCNT", header:"tonc.h".}: uint8  ## Out window control (REG_BASE + 0x0000004A)
var REG_WINOBJCNT* {.importc:"REG_WINOBJCNT", header:"tonc.h".}: uint8  ## Obj window control (REG_BASE + 0x0000004B)

# Graphic effects
var REG_MOSAIC* {.importc:"REG_MOSAIC", header:"tonc.h".}: uint32  ## Mosaic control (REG_BASE + 0x0000004C)
var REG_BLDCNT* {.importc:"REG_BLDCNT", header:"tonc.h".}: uint16  ## Alpha control (REG_BASE + 0x00000050)
var REG_BLDALPHA* {.importc:"REG_BLDALPHA", header:"tonc.h".}: uint16  ## Fade level (REG_BASE + 0x00000052)
var REG_BLDY* {.importc:"REG_BLDY", header:"tonc.h".}: uint16  ## Blend levels (REG_BASE + 0x00000054)

# === SOUND REGISTERS ===
# sound regs, partially following pin8gba's nomenclature
# Channel 1: Square wave with sweep
var REG_SND1SWEEP* {.importc:"REG_SND1SWEEP", header:"tonc.h".}: uint16  ## Channel 1 Sweep (REG_BASE + 0x00000060)
var REG_SND1CNT* {.importc:"REG_SND1CNT", header:"tonc.h".}: uint16  ## Channel 1 Control (REG_BASE + 0x00000062)
var REG_SND1FREQ* {.importc:"REG_SND1FREQ", header:"tonc.h".}: uint16  ## Channel 1 frequency (REG_BASE + 0x00000064)

# Channel 2: Simple square wave
var REG_SND2CNT* {.importc:"REG_SND2CNT", header:"tonc.h".}: uint16  ## Channel 2 control (REG_BASE + 0x00000068)
var REG_SND2FREQ* {.importc:"REG_SND2FREQ", header:"tonc.h".}: uint16  ## Channel 2 frequency (REG_BASE + 0x0000006C)

# Channel 3: Wave player
var REG_SND3SEL* {.importc:"REG_SND3SEL", header:"tonc.h".}: uint16  ## Channel 3 wave select (REG_BASE + 0x00000070)
var REG_SND3CNT* {.importc:"REG_SND3CNT", header:"tonc.h".}: uint16  ## Channel 3 control (REG_BASE + 0x00000072)
var REG_SND3FREQ* {.importc:"REG_SND3FREQ", header:"tonc.h".}: uint16  ## Channel 3 frequency (REG_BASE + 0x00000074)

# Channel 4: Noise generator
var REG_SND4CNT* {.importc:"REG_SND4CNT", header:"tonc.h".}: uint16  ## Channel 4 control (REG_BASE + 0x00000078)
var REG_SND4FREQ* {.importc:"REG_SND4FREQ", header:"tonc.h".}: uint16  ## Channel 4 frequency (REG_BASE + 0x0000007C)

# Sound control
var REG_SNDCNT* {.importc:"REG_SNDCNT", header:"tonc.h".}: uint32  ## Main sound control (REG_BASE + 0x00000080)
var REG_SNDDMGCNT* {.importc:"REG_SNDDMGCNT", header:"tonc.h".}: uint16  ## DMG channel control (REG_BASE + 0x00000080)
var REG_SNDDSCNT* {.importc:"REG_SNDDSCNT", header:"tonc.h".}: uint16  ## Direct Sound control (REG_BASE + 0x00000082)
var REG_SNDSTAT* {.importc:"REG_SNDSTAT", header:"tonc.h".}: uint16  ## Sound status (REG_BASE + 0x00000084)
var REG_SNDBIAS* {.importc:"REG_SNDBIAS", header:"tonc.h".}: uint16  ## Sound bias (REG_BASE + 0x00000088)

# Sound buffers
var REG_WAVE_RAM* {.importc:"REG_WAVE_RAM", header:"tonc.h".}: uint32  ## Channel 3 wave buffer (REG_BASE + 0x00000090))
var REG_WAVE_RAM0* {.importc:"REG_WAVE_RAM0", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000090)
var REG_WAVE_RAM1* {.importc:"REG_WAVE_RAM1", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000094)
var REG_WAVE_RAM2* {.importc:"REG_WAVE_RAM2", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000098)
var REG_WAVE_RAM3* {.importc:"REG_WAVE_RAM3", header:"tonc.h".}: uint32  ## (REG_BASE + 0x0000009C)
var REG_FIFO_A* {.importc:"REG_FIFO_A", header:"tonc.h".}: uint32  ## DSound A FIFO (REG_BASE + 0x000000A0)
var REG_FIFO_B* {.importc:"REG_FIFO_B", header:"tonc.h".}: uint32  ## DSound B FIFO (REG_BASE + 0x000000A4)

# DMA registers
var REG_DMA* {.importc:"REG_DMA", header:"tonc.h".}: array[4, DmaRec] ## DMA as DMA_REC array (REG_BASE + 0x000000B0)
var REG_DMA0SAD* {.importc:"REG_DMA0SAD", header:"tonc.h".}: uint32  ## DMA 0 Source address (REG_BASE + 0x000000B0)
var REG_DMA0DAD* {.importc:"REG_DMA0DAD", header:"tonc.h".}: uint32  ## DMA 0 Destination address (REG_BASE + 0x000000B4)
var REG_DMA0CNT* {.importc:"REG_DMA0CNT", header:"tonc.h".}: uint32  ## DMA 0 Control (REG_BASE + 0x000000B8)
var REG_DMA1SAD* {.importc:"REG_DMA1SAD", header:"tonc.h".}: uint32  ## DMA 1 Source address (REG_BASE + 0x000000BC)
var REG_DMA1DAD* {.importc:"REG_DMA1DAD", header:"tonc.h".}: uint32  ## DMA 1 Destination address (REG_BASE + 0x000000C0)
var REG_DMA1CNT* {.importc:"REG_DMA1CNT", header:"tonc.h".}: uint32  ## DMA 1 Control (REG_BASE + 0x000000C4)
var REG_DMA2SAD* {.importc:"REG_DMA2SAD", header:"tonc.h".}: uint32  ## DMA 2 Source address (REG_BASE + 0x000000C8)
var REG_DMA2DAD* {.importc:"REG_DMA2DAD", header:"tonc.h".}: uint32  ## DMA 2 Destination address (REG_BASE + 0x000000CC)
var REG_DMA2CNT* {.importc:"REG_DMA2CNT", header:"tonc.h".}: uint32  ## DMA 2 Control (REG_BASE + 0x000000D0)
var REG_DMA3SAD* {.importc:"REG_DMA3SAD", header:"tonc.h".}: uint32  ## DMA 3 Source address (REG_BASE + 0x000000D4)
var REG_DMA3DAD* {.importc:"REG_DMA3DAD", header:"tonc.h".}: uint32  ## DMA 3 Destination address (REG_BASE + 0x000000D8)
var REG_DMA3CNT* {.importc:"REG_DMA3CNT", header:"tonc.h".}: uint32  ## DMA 3 Control (REG_BASE + 0x000000DC)

# Timer registers
var REG_TM* {.importc:"REG_TM", header:"tonc.h".}: array[4, TmrRec] ## Timers as TMR_REC array (REG_BASE + 0x00000100)
var REG_TM0D* {.importc:"REG_TM0D", header:"tonc.h".}: uint16      ## Timer 0 data (REG_BASE + 0x00000100)
var REG_TM0CNT* {.importc:"REG_TM0CNT", header:"tonc.h".}: uint16  ## Timer 0 control (REG_BASE + 0x00000102)
var REG_TM1D* {.importc:"REG_TM1D", header:"tonc.h".}: uint16      ## Timer 1 data (REG_BASE + 0x00000104)
var REG_TM1CNT* {.importc:"REG_TM1CNT", header:"tonc.h".}: uint16  ## Timer 1 control (REG_BASE + 0x00000106)
var REG_TM2D* {.importc:"REG_TM2D", header:"tonc.h".}: uint16      ## Timer 2 data (REG_BASE + 0x00000108)
var REG_TM2CNT* {.importc:"REG_TM2CNT", header:"tonc.h".}: uint16  ## Timer 2 control (REG_BASE + 0x0000010A)
var REG_TM3D* {.importc:"REG_TM3D", header:"tonc.h".}: uint16      ## Timer 3 data (REG_BASE + 0x0000010C)
var REG_TM3CNT* {.importc:"REG_TM3CNT", header:"tonc.h".}: uint16  ## Timer 3 control (REG_BASE + 0x0000010E)

# Serial communication
var REG_SIOCNT* {.importc:"REG_SIOCNT", header:"tonc.h".}: uint16  ## Serial IO control (Normal/MP/UART) (REG_BASE + 0x00000128)
var REG_SIODATA* {.importc:"REG_SIODATA", header:"tonc.h".}: array[1, uint32] ## ????? [[I don't get how this differs from REG_SIODATA32. Why is it an array? How big should it be?]] ## (REG_BASE + 0x00000120)
var REG_SIODATA32* {.importc:"REG_SIODATA32", header:"tonc.h".}: uint32  ## Normal/UART 32bit data (REG_BASE + 0x00000120)
var REG_SIODATA8* {.importc:"REG_SIODATA8", header:"tonc.h".}: uint16    ## Normal/UART 8bit data (REG_BASE + 0x0000012A)
var REG_SIOMULTI* {.importc:"REG_SIOMULTI", header:"tonc.h".}: array[4, uint16] # Multiplayer data array (REG_BASE + 0x00000120)
var REG_SIOMULTI0* {.importc:"REG_SIOMULTI0", header:"tonc.h".}: uint16      ## MP master data (REG_BASE + 0x00000120)
var REG_SIOMULTI1* {.importc:"REG_SIOMULTI1", header:"tonc.h".}: uint16      ## MP Slave 1 data (REG_BASE + 0x00000122)
var REG_SIOMULTI2* {.importc:"REG_SIOMULTI2", header:"tonc.h".}: uint16      ## MP Slave 2 data (REG_BASE + 0x00000124)
var REG_SIOMULTI3* {.importc:"REG_SIOMULTI3", header:"tonc.h".}: uint16      ## MP Slave 3 data (REG_BASE + 0x00000126)
var REG_SIOMLT_RECV* {.importc:"REG_SIOMLT_RECV", header:"tonc.h".}: uint16  ## MP data receiver (REG_BASE + 0x00000120)
var REG_SIOMLT_SEND* {.importc:"REG_SIOMLT_SEND", header:"tonc.h".}: uint16  ## MP data sender (REG_BASE + 0x0000012A)

#  Keypad registers
var REG_KEYINPUT* {.importc:"REG_KEYINPUT", header:"tonc.h".}: uint16  ## Key status (read only??) (REG_BASE + 0x00000130)
var REG_KEYCNT* {.importc:"REG_KEYCNT", header:"tonc.h".}: uint16      ## Key IRQ control (REG_BASE + 0x00000132)

# Joybus communication
var REG_RCNT* {.importc:"REG_RCNT", header:"tonc.h".}: uint16            ## SIO Mode Select/General Purpose Data (REG_BASE + 0x00000134)
var REG_JOYCNT* {.importc:"REG_JOYCNT", header:"tonc.h".}: uint16        ## JOY bus control (REG_BASE + 0x00000140)
var REG_JOY_RECV* {.importc:"REG_JOY_RECV", header:"tonc.h".}: uint32    ## JOY bus receiever (REG_BASE + 0x00000150)
var REG_JOY_TRANS* {.importc:"REG_JOY_TRANS", header:"tonc.h".}: uint32  ## JOY bus transmitter (REG_BASE + 0x00000154)
var REG_JOYSTAT* {.importc:"REG_JOYSTAT", header:"tonc.h".}: uint16      ## JOY bus status (REG_BASE + 0x00000158)

#  Interrupt / System registers
var REG_IE* {.importc:"REG_IE", header:"tonc.h".}: uint16            ## IRQ enable (REG_BASE + 0x00000200)
var REG_IF* {.importc:"REG_IF", header:"tonc.h".}: uint16            ## IRQ status/acknowledge (REG_BASE + 0x00000202)
var REG_WAITCNT* {.importc:"REG_WAITCNT", header:"tonc.h".}: uint16  ## Waitstate control (REG_BASE + 0x00000204)
var REG_IME* {.importc:"REG_IME", header:"tonc.h".}: uint16          ## IRQ master enable (REG_BASE + 0x00000208)
var REG_PAUSE* {.importc:"REG_PAUSE", header:"tonc.h".}: uint16      ## Pause system (?) (REG_BASE + 0x00000300)

# ALT REGISTERS
# Alternate names for some of the registers

var REG_BLDMOD* {.importc:"REG_BLDMOD", header:"tonc.h".}: uint16  ##  alpha control (REG_BASE + 0x00000050)
var REG_COLEV* {.importc:"REG_COLEV", header:"tonc.h".}: uint16    ##  fade level (REG_BASE + 0x00000052)
var REG_COLEY* {.importc:"REG_COLEY", header:"tonc.h".}: uint16    ##  blend levels (REG_BASE + 0x00000054)

##  sound regs as in belogic and GBATek (mostly for compatability)
var REG_SOUND1CNT* {.importc:"REG_SOUND1CNT", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000060)
var REG_SOUND1CNT_L* {.importc:"REG_SOUND1CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000060)
var REG_SOUND1CNT_H* {.importc:"REG_SOUND1CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000062)
var REG_SOUND1CNT_X* {.importc:"REG_SOUND1CNT_X", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000064)
var REG_SOUND2CNT_L* {.importc:"REG_SOUND2CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000068)
var REG_SOUND2CNT_H* {.importc:"REG_SOUND2CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x0000006C)
var REG_SOUND3CNT* {.importc:"REG_SOUND3CNT", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000070)
var REG_SOUND3CNT_L* {.importc:"REG_SOUND3CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000070)
var REG_SOUND3CNT_H* {.importc:"REG_SOUND3CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000072)
var REG_SOUND3CNT_X* {.importc:"REG_SOUND3CNT_X", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000074)
var REG_SOUND4CNT_L* {.importc:"REG_SOUND4CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000078)
var REG_SOUND4CNT_H* {.importc:"REG_SOUND4CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x0000007C)
var REG_SOUNDCNT* {.importc:"REG_SOUNDCNT", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000080)
var REG_SOUNDCNT_L* {.importc:"REG_SOUNDCNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000080)
var REG_SOUNDCNT_H* {.importc:"REG_SOUNDCNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000082)
var REG_SOUNDCNT_X* {.importc:"REG_SOUNDCNT_X", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000084)
var REG_SOUNDBIAS* {.importc:"REG_SOUNDBIAS", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000088)
var REG_WAVE* {.importc:"REG_WAVE", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000090))
var REG_DMA0CNT_L* {.importc:"REG_DMA0CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000B8)  count
var REG_DMA0CNT_H* {.importc:"REG_DMA0CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000BA)  flags
var REG_DMA1CNT_L* {.importc:"REG_DMA1CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000C4)
var REG_DMA1CNT_H* {.importc:"REG_DMA1CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000C6)
var REG_DMA2CNT_L* {.importc:"REG_DMA2CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000D0)
var REG_DMA2CNT_H* {.importc:"REG_DMA2CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000D2)
var REG_DMA3CNT_L* {.importc:"REG_DMA3CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000DC)
var REG_DMA3CNT_H* {.importc:"REG_DMA3CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x000000DE)
var REG_TM0CNT_L* {.importc:"REG_TM0CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000100)
var REG_TM0CNT_H* {.importc:"REG_TM0CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000102)
var REG_TM1CNT_L* {.importc:"REG_TM1CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000104)
var REG_TM1CNT_H* {.importc:"REG_TM1CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000106)
var REG_TM2CNT_L* {.importc:"REG_TM2CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000108)
var REG_TM2CNT_H* {.importc:"REG_TM2CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x0000010A)
var REG_TM3CNT_L* {.importc:"REG_TM3CNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x0000010C)
var REG_TM3CNT_H* {.importc:"REG_TM3CNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x0000010E)
var REG_KEYS* {.importc:"REG_KEYS", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000130)  Key status
var REG_P1* {.importc:"REG_P1", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000130)  for backward combatibility
var REG_P1CNT* {.importc:"REG_P1CNT", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000132)  ditto
var REG_SCD0* {.importc:"REG_SCD0", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000120)
var REG_SCD1* {.importc:"REG_SCD1", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000122)
var REG_SCD2* {.importc:"REG_SCD2", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000124)
var REG_SCD3* {.importc:"REG_SCD3", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000126)
var REG_SCCNT* {.importc:"REG_SCCNT", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000128)
var REG_SCCNT_L* {.importc:"REG_SCCNT_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000128)
var REG_SCCNT_H* {.importc:"REG_SCCNT_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x0000012A)
var REG_R* {.importc:"REG_R", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000134)
var REG_HS_CTRL* {.importc:"REG_HS_CTRL", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000140)
var REG_JOYRE* {.importc:"REG_JOYRE", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000150)
var REG_JOYRE_L* {.importc:"REG_JOYRE_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000150)
var REG_JOYRE_H* {.importc:"REG_JOYRE_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000152)
var REG_JOYTR* {.importc:"REG_JOYTR", header:"tonc.h".}: uint32  ## (REG_BASE + 0x00000154)
var REG_JOYTR_L* {.importc:"REG_JOYTR_L", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000154)
var REG_JOYTR_H* {.importc:"REG_JOYTR_H", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000156)
var REG_JSTAT* {.importc:"REG_JSTAT", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000158)
var REG_WSCNT* {.importc:"REG_WSCNT", header:"tonc.h".}: uint16  ## (REG_BASE + 0x00000204)
