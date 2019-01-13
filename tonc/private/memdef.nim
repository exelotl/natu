# Memory Map Constants and helper templates
# -----------------------------------------
# List of all bit(field) definitions of memory mapped items.

# -- Prefixes --
# REG_DISPCNT : DCNT
# REG_DISPSTAT : DSTAT
# REG_BGxCNT : BG
# REG_WIN_x : WIN
# REG_MOSAIC : MOS
# REG_BLDCNT : BLD
# REG_SND1SWEEP : SSW
# REG_SNDxCNT : SSQR
# REG_SNDxFREQ : SFREQ
# REG_SNDDMGCNT : SDMG
# REG_SNDDSCNT : SDS
# REG_SNDSTAT : SSTAT
# REG_DMAxCNT : DMA
# REG_TMxCNT : TM
# REG_SIOCNT : SIO(N/M/U)
# REG_RCNT : R / GPIO
# REG_KEYINPUT : KEY
# REG_KEYCNT : KCNT
# REG_IE, REG_IF : IRQ
# REG_WSCNT : WS
# Regular SE : SE
# OAM attr 0 : ATTR0
# OAM attr 1 : ATTR1
# OAM attr 2 : ATTR2


# Display Control Flags
# Bits for REG_DISPCNT
# Note: DISPCNT is represented as 32 bit but only bits 0-15 are used.
const
  DCNT_MODE0*: uint32 = 0x0000     ## Mode 0; bg 0-4: reg
  DCNT_MODE1*: uint32 = 0x0001     ## Mode 1; bg 0-1: reg; bg 2: affine
  DCNT_MODE2*: uint32 = 0x0002     ## Mode 2; bg 2-3: affine
  DCNT_MODE3*: uint32 = 0x0003     ## Mode 3; bg2: 240x160\@16 bitmap
  DCNT_MODE4*: uint32 = 0x0004     ## Mode 4; bg2: 240x160\@8 bitmap
  DCNT_MODE5*: uint32 = 0x0005     ## Mode 5; bg2: 160x128\@16 bitmap
  DCNT_GB*: uint32 = 0x0008        ## (R) GBC indicator
  DCNT_PAGE*: uint32 = 0x0010      ## Page indicator
  DCNT_OAM_HBL*: uint32 = 0x0020   ## Allow OAM updates in HBlank
  DCNT_OBJ_2D*: uint32 = 0x0000    ## OBJ-VRAM as matrix
  DCNT_OBJ_1D*: uint32 = 0x0040    ## OBJ-VRAM as array
  DCNT_BLANK*: uint32 = 0x0080     ## Force screen blank
  DCNT_BG0*: uint32 = 0x0100       ## Enable bg 0
  DCNT_BG1*: uint32 = 0x0200       ## Enable bg 1
  DCNT_BG2*: uint32 = 0x0400       ## Enable bg 2
  DCNT_BG3*: uint32 = 0x0800       ## Enable bg 3
  DCNT_OBJ*: uint32 = 0x1000       ## Enable objects
  DCNT_WIN0*: uint32 = 0x2000      ## Enable window 0
  DCNT_WIN1*: uint32 = 0x4000      ## Enable window 1
  DCNT_WINOBJ*: uint32 = 0x8000    ## Enable object window
  
  DCNT_MODE_MASK*: uint32 = 0x0007
  DCNT_MODE_SHIFT*: uint32 = 0x0000

template DCNT_MODE*(n: uint32): uint32 =
  (n shl DCNT_MODE_SHIFT)

const
  DCNT_LAYER_MASK*: uint32  = 0x1F00
  DCNT_LAYER_SHIFT*: uint32  = 8

template DCNT_LAYER*(n: uint32): uint32 =
  (n shl DCNT_LAYER_SHIFT)

const
  DCNT_WIN_MASK*: uint32  = 0xE000
  DCNT_WIN_SHIFT*: uint32  = 13

template DCNT_WIN*(n: uint32): uint32 =
  (n shl DCNT_WIN_SHIFT)

template DCNT_BUILD*(mode, layer, win, obj1d, objhbl: uint32): uint32 =
  ((((win) and 7) shl 13) or (((layer) and 31) shl 8) or (((obj1d) and 1) shl 6) or
      (((objhbl) and 1) shl 5) or ((mode) and 7))


#	Display Status Flags
# Bits for REG_DISPSTAT
const
  DSTAT_IN_VBL*:uint16 = 0x0001    ## Now in VBlank
  DSTAT_IN_HBL*:uint16 = 0x0002    ## Now in HBlank
  DSTAT_IN_VCT*:uint16 = 0x0004    ## Now in set VCount
  DSTAT_VBL_IRQ*:uint16 = 0x0008   ## Enable VBlank irq
  DSTAT_HBL_IRQ*:uint16 = 0x0010   ## Enable HBlank irq
  DSTAT_VCT_IRQ*:uint16 = 0x0020   ## Enable VCount irq
  
  DSTAT_VCT_MASK*:uint16 = 0xFF00
  DSTAT_VCT_SHIFT*:uint16 = 8

template DSTAT_VCT*(n: uint16): uint16 =
  (n shl DSTAT_VCT_SHIFT)

## Background Control Flags
## Bits for REG_BGxCNT
const
  BG_MOSAIC*:uint16 = 0x0040   ## Enable Mosaic
  BG_4BPP*:uint16 = 0          ## 4bpp (16 color) bg (no effect on affine bg)
  BG_8BPP*:uint16 = 0x0080     ## 8bpp (256 color) bg (no effect on affine bg)
  BG_WRAP*:uint16 = 0x2000     ## Wrap around edges of affine bgs
  BG_SIZE0*:uint16 = 0
  BG_SIZE1*:uint16 = 0x4000
  BG_SIZE2*:uint16 = 0x8000
  BG_SIZE3*:uint16 = 0xC000
  BG_REG_32x32*:uint16 = 0          ## reg bg, 32x32 (256x256 px)
  BG_REG_64x32*:uint16 = 0x4000     ## reg bg, 64x32 (512x256 px)
  BG_REG_32x64*:uint16 = 0x8000     ## reg bg, 32x64 (256x512 px)
  BG_REG_64x64*:uint16 = 0xC000     ## reg bg, 64x64 (512x512 px)
  BG_AFF_16x16*:uint16 = 0          ## affine bg, 16x16 (128x128 px)
  BG_AFF_32x32*:uint16 = 0x4000     ## affine bg, 32x32 (256x256 px)
  BG_AFF_64x64*:uint16 = 0x8000     ## affine bg, 64x64 (512x512 px)
  BG_AFF_128x128*:uint16 = 0xC000   ## affine bg, 128x128 (1024x1024 px)
  
  BG_PRIO_MASK*:uint16 = 0x0003
  BG_PRIO_SHIFT*:uint16 = 0

# TODO: check that n:uint16 doesn't actually cause problems/performance drops?  may be better off changing to untyped? How about the _SHIFT constants?

template BG_PRIO*(n: uint16): uint16 =
  (n shl BG_PRIO_SHIFT)

const
  BG_CBB_MASK*:uint16 = 0x000C
  BG_CBB_SHIFT*:uint16 = 2

template BG_CBB*(n: uint16): uint16 =
  (n shl BG_CBB_SHIFT)

const
  BG_SBB_MASK*:uint16 = 0x1F00
  BG_SBB_SHIFT*:uint16 = 8

template BG_SBB*(n: uint16): uint16 =
  (n shl BG_SBB_SHIFT)

const
  BG_SIZE_MASK*:uint16 = 0xC000
  BG_SIZE_SHIFT*:uint16 = 14

template BG_SIZE*(n: uint16): uint16 =
  (n shl BG_SIZE_SHIFT)

template BG_BUILD*(cbb, sbb, size, bpp, prio, mos, wrap: uint16): uint16 =
  (((size) shl 14) or (((wrap) and 1) shl 13) or (((sbb) and 31) shl 8) or
      (((bpp) and 8) shl 4) or (((mos) and 1) shl 6) or (((cbb) and 3) shl 2) or ((prio) and 3))


# Graphic effects
# ---------------

# REG_WIN_x
# Window macros
const
  WIN_BG0*:uint16 = 0x0001
  WIN_BG1*:uint16 = 0x0002
  WIN_BG2*:uint16 = 0x0004
  WIN_BG3*:uint16 = 0x0008
  WIN_OBJ*:uint16 = 0x0010
  WIN_ALL*:uint16 = 0x001F
  WIN_BLD*:uint16 = 0x0020
  WIN_LAYER_MASK*:uint16 = 0x003F
  WIN_LAYER_SHIFT*:uint16 = 0

template WIN_LAYER*(n: uint16): uint16 =
  (n shl WIN_LAYER_SHIFT)

template WIN_BUILD*(low, high: uint16): uint16 =
  (((high) shl 8) or (low))

template WININ_BUILD*(win0, win1: uint16): uint16 =
  WIN_BUILD(win0, win1)

template WINOUT_BUILD*(`out`, obj: uint16): uint16 =
  WIN_BUILD(`out`, obj)

# REG_MOSAIC
# Mosaic macros
# NOTE: REG_MOSAIC is is declared 32 bit, but only bits 0-15 are used
const
  MOS_BH_MASK*:uint32 = 0x000F
  MOS_BH_SHIFT*:uint32 = 0

template MOS_BH*(n: uint32): uint32 =
  (n shl MOS_BH_SHIFT)

const
  MOS_BV_MASK*:uint32 = 0x00F0
  MOS_BV_SHIFT*:uint32 = 4

template MOS_BV*(n: uint32): uint32 =
  (n shl MOS_BV_SHIFT)

const
  MOS_OH_MASK*:uint32 = 0x0F00
  MOS_OH_SHIFT*:uint32 = 8

template MOS_OH*(n: uint32): uint32 =
  (n shl MOS_OH_SHIFT)

const
  MOS_OV_MASK*:uint32 = 0xF000
  MOS_OV_SHIFT*:uint32 = 12

template MOS_OV*(n: uint32): uint32 =
  (n shl MOS_OV_SHIFT)

template MOS_BUILD*(bh, bv, oh, ov: uint32): uint32 =
  ((((ov) and 15) shl 12) or (((oh) and 15) shl 8) or (((bv) and 15) shl 4) or ((bh) and 15))


#	Blend Flags
# -----------
# Macros for REG_BLDCNT, REG_BLDY and REG_BLDALPHA

# --- REG_BLDCNT ---
# Blend control
const
  BLD_BG0*:uint16 = 0x0001
  BLD_BG1*:uint16 = 0x0002
  BLD_BG2*:uint16 = 0x0004
  BLD_BG3*:uint16 = 0x0008
  BLD_OBJ*:uint16 = 0x0010
  BLD_ALL*:uint16 = 0x001F
  BLD_BACKDROP*:uint16 = 0x0020
  BLD_OFF*:uint16 = 0
  BLD_STD*:uint16 = 0x0040
  BLD_WHITE*:uint16 = 0x0080
  BLD_BLACK*:uint16 = 0x00C0
  BLD_TOP_MASK*:uint16 = 0x003F
  BLD_TOP_SHIFT*:uint16 = 0

template BLD_TOP*(n: uint16): uint16 =
  (n shl BLD_TOP_SHIFT)

const
  BLD_MODE_MASK*:uint16 = 0x00C0
  BLD_MODE_SHIFT*:uint16 = 6

template BLD_MODE*(n: uint16): uint16 =
  (n shl BLD_MODE_SHIFT)

const
  BLD_BOT_MASK*:uint16 = 0x3F00
  BLD_BOT_SHIFT*:uint16 = 8

template BLD_BOT*(n: uint16): uint16 =
  (n shl BLD_BOT_SHIFT)

template BLD_BUILD*(top, bot, mode: uint16): uint16 =
  ((((bot) and 63) shl 8) or (((mode) and 3) shl 6) or ((top) and 63))

# --- REG_BLDALPHA ---
# Blend weights
const
  BLD_EVA_MASK*:uint16 = 0x001F
  BLD_EVA_SHIFT*:uint16 = 0

template BLD_EVA*(n: uint16): uint16 =
  (n shl BLD_EVA_SHIFT)

const
  BLD_EVB_MASK*:uint16 = 0x1F00
  BLD_EVB_SHIFT*:uint16 = 8

template BLD_EVB*(n: uint16): uint16 =
  (n shl BLD_EVB_SHIFT)

template BLDA_BUILD*(eva, evb: uint16): uint16 =
  (((eva) and 31) or (((evb) and 31) shl 8))

# --- REG_BLDY ---
# Fade levels
const
  BLDY_MASK*:uint16 = 0x001F
  BLDY_SHIFT*:uint16 = 0

template BLDY*(n: uint16): uint16 =
  (n shl BLD_EY_SHIFT)

template BLDY_BUILD*(ey: uint16): uint16 =
  ((ey) and 31)

# REG_SND1SWEEP
# -------------
# Tone Generator, Sweep Flags

# Bits for REG_SND1SWEEP (aka REG_SOUND1CNT_L)
const
  SSW_INC*:uint16 = 0              ## Increasing sweep rate
  SSW_DEC*:uint16 = 0x0008         ## Decreasing sweep rate
  SSW_OFF*:uint16 = 0x0008         ## Disable sweep altogether   TODO: is this correct? these both have the same value...
  SSW_SHIFT_MASK*:uint16 = 0x0007
  SSW_SHIFT_SHIFT*:uint16 = 0

template SSW_SHIFT*(n: uint16): uint16 =
  (n shl SSW_SHIFT_SHIFT)

const
  SSW_TIME_MASK*:uint16 = 0x0070
  SSW_TIME_SHIFT*:uint16 = 4

template SSW_TIME*(n: uint16): uint16 =
  (n shl SSW_TIME_SHIFT)

template SSW_BUILD*(shift, dir, time: uint16): uint16 =
  ((((time) and 7) shl 4) or ((dir) shl 3) or ((shift) and 7))

# REG_SND1CNT, REG_SND2CNT, REG_SND4CNT
# -------------------------------------
# Tone Generator, Square Flags

# Bits for REG_SND{1,2,4}CNT
# (aka REG_SOUND1CNT_H, REG_SOUND2CNT_L, REG_SOUND4CNT_L, respectively)
const
  SSQR_DUTY1_8*:uint16 = 0        ## 12.5% duty cycle (#-------)
  SSQR_DUTY1_4*:uint16 = 0x0040   ## 25% duty cycle (##------)
  SSQR_DUTY1_2*:uint16 = 0x0080   ## 50% duty cycle (####----)
  SSQR_DUTY3_4*:uint16 = 0x00C0   ## 75% duty cycle (######--)
  SSQR_INC*:uint16 = 0            ## Increasing volume
  SSQR_DEC*:uint16 = 0x0800       ## Decreasing volume
  
  SSQR_LEN_MASK*:uint16 = 0x003F
  SSQR_LEN_SHIFT*:uint16 = 0

template SSQR_LEN*(n: uint16): uint16 =
  (n shl SSQR_LEN_SHIFT)

const
  SSQR_DUTY_MASK*:uint16 = 0x00C0
  SSQR_DUTY_SHIFT*:uint16 = 6

template SSQR_DUTY*(n: uint16): uint16 =
  (n shl SSQR_DUTY_SHIFT)

const
  SSQR_TIME_MASK*:uint16 = 0x0700
  SSQR_TIME_SHIFT*:uint16 = 8

template SSQR_TIME*(n: uint16): uint16 =
  (n shl SSQR_TIME_SHIFT)

const
  SSQR_IVOL_MASK*:uint16 = 0xF000
  SSQR_IVOL_SHIFT*:uint16 = 12

template SSQR_IVOL*(n: uint16): uint16 =
  (n shl SSQR_IVOL_SHIFT)

template SSQR_ENV_BUILD*(ivol, dir, time: uint16): uint16 =
  (((ivol) shl 12) or ((dir) shl 11) or (((time) and 7) shl 8))

template SSQR_BUILD*(ivol, dir, step, duty, len: uint16): uint16 =
  (SSQR_ENV_BUILD(ivol, dir, step) or (((duty) and 3) shl 6) or ((len) and 63))

# REG_SND1FREQ, REG_SND2FREQ, REG_SND3FREQ
# ----------------------------------------
# Tone Generator, Frequency Flags

# Bits for REG_SND{1-3}FREQ
# (aka REG_SOUND1CNT_X, REG_SOUND2CNT_H, REG_SOUND3CNT_X)
const
  SFREQ_HOLD*:uint16 = 0x0000   ## Continuous play
  SFREQ_TIMED*:uint16 = 0x4000  ## Timed play
  SFREQ_RESET*:uint16 = 0x8000  ## Reset sound
  
  SFREQ_RATE_MASK*:uint16 = 0x07FF
  SFREQ_RATE_SHIFT*:uint16 = 0

template SFREQ_RATE*(n: uint16): uint16 =
  (n shl SFREQ_RATE_SHIFT)

template SFREQ_BUILD*(rate, timed, reset: uint16): uint16 =
  (((rate) and 0x07FF) or ((timed) shl 14) or ((reset) shl 15))

# REG_SNDDMGCNT
# Tone Generator, Control Flags
# Bits for REG_SNDDMGCNT (aka REG_SOUNDCNT_L)
const
  SDMG_LSQR1*:uint16 = 0x0100    ## Enable channel 1 on left 
  SDMG_LSQR2*:uint16 = 0x0200    ## Enable channel 2 on left
  SDMG_LWAVE*:uint16 = 0x0400    ## Enable channel 3 on left
  SDMG_LNOISE*:uint16 = 0x0800   ## Enable channel 4 on left	
  SDMG_RSQR1*:uint16 = 0x1000    ## Enable channel 1 on right
  SDMG_RSQR2*:uint16 = 0x2000    ## Enable channel 2 on right
  SDMG_RWAVE*:uint16 = 0x4000    ## Enable channel 3 on right
  SDMG_RNOISE*:uint16 = 0x8000   ## Enable channel 4 on right
  
  SDMG_LVOL_MASK*:uint16 = 0x0007
  SDMG_LVOL_SHIFT*:uint16 = 0

template SDMG_LVOL*(n: uint16): uint16 =
  (n shl SDMG_LVOL_SHIFT)

const
  SDMG_RVOL_MASK*:uint16 = 0x0070
  SDMG_RVOL_SHIFT*:uint16 = 4

template SDMG_RVOL*(n: uint16): uint16 =
  (n shl SDMG_RVOL_SHIFT)

# Unshifted values
const
  SDMG_SQR1*:uint16 = 0x0001
  SDMG_SQR2*:uint16 = 0x0002
  SDMG_WAVE*:uint16 = 0x0004
  SDMG_NOISE*:uint16 = 0x0008

template SDMG_BUILD*(lmode, rmode, lvol, rvol: uint16): uint16 =
  (((rmode) shl 12) or ((lmode) shl 8) or (((rvol) and 7) shl 4) or ((lvol) and 7))

template SDMG_BUILD_LR*(mode, vol: uint16): uint16 =
  SDMG_BUILD(mode, mode, vol, vol)

# REG_SNDDSCNT
# ------------
# Direct Sound Flags

# Bits for REG_SNDDSCNT (aka REG_SOUNDCNT_H)
const
  SDS_DMG25*:uint16 = 0x0000    ## Tone generators at 25% volume
  SDS_DMG50*:uint16 = 0x0001    ## Tone generators at 50% volume
  SDS_DMG100*:uint16 = 0x0002   ## Tone generators at 100% volume
  SDS_A50*:uint16 = 0x0000      ## Direct Sound A at 50% volume
  SDS_A100*:uint16 = 0x0004     ## Direct Sound A at 100% volume
  SDS_B50*:uint16 = 0x0000      ## Direct Sound B at 50% volume
  SDS_B100*:uint16 = 0x0008     ## Direct Sound B at 100% volume
  SDS_AR*:uint16 = 0x0100       ## Enable Direct Sound A on right
  SDS_AL*:uint16 = 0x0200       ## Enable Direct Sound A on left
  SDS_ATMR0*:uint16 = 0x0000    ## Direct Sound A to use timer 0
  SDS_ATMR1*:uint16 = 0x0400    ## Direct Sound A to use timer 1
  SDS_ARESET*:uint16 = 0x0800   ## Reset FIFO of Direct Sound A
  SDS_BR*:uint16 = 0x1000       ## Enable Direct Sound B on right
  SDS_BL*:uint16 = 0x2000       ## Enable Direct Sound B on left
  SDS_BTMR0*:uint16 = 0x0000    ## Direct Sound B to use timer 0
  SDS_BTMR1*:uint16 = 0x4000    ## Direct Sound B to use timer 1
  SDS_BRESET*:uint16 = 0x8000   ## Reset FIFO of Direct Sound B

# REG_SNDSTAT
# -----------
# Sound Status Flags

# Bits for REG_SNDSTAT (and REG_SOUNDCNT_X)
const
  SSTAT_SQR1*:uint16 = 0x0001      ## (R) Channel 1 status
  SSTAT_SQR2*:uint16 = 0x0002      ## (R) Channel 2 status
  SSTAT_WAVE*:uint16 = 0x0004      ## (R) Channel 3 status
  SSTAT_NOISE*:uint16 = 0x0008     ## (R) Channel 4 status
  SSTAT_DISABLE*:uint16 = 0x0000   ## Disable sound
  SSTAT_ENABLE*:uint16 = 0x0080    ## Enable sound. NOTE: enable before using any other sound regs

# REG_DMAxCNT
# -----------
# DMA Control Flags

# Bits for REG_DMAxCNT
const
  DMA_DST_INC*:uint32 = 0x00000000      ## Incrementing destination address
  DMA_DST_DEC*:uint32 = 0x00200000      ## Decrementing destination
  DMA_DST_FIXED*:uint32 = 0x00400000    ## Fixed destination 
  DMA_DST_RELOAD*:uint32 = 0x00600000   ## Increment destination, reset after full run
  DMA_SRC_INC*:uint32 = 0x00000000      ## Incrementing source address
  DMA_SRC_DEC*:uint32 = 0x00800000      ## Decrementing source address
  DMA_SRC_FIXED*:uint32 = 0x01000000    ## Fixed source address
  DMA_REPEAT*:uint32 = 0x02000000       ## Repeat transfer at next start condition 
  DMA_16*:uint32 = 0x00000000           ## Transfer by halfword
  DMA_32*:uint32 = 0x04000000           ## Transfer by word
  DMA_AT_NOW*:uint32 = 0x00000000       ## Start transfer now
  DMA_GAMEPAK*:uint32 = 0x08000000      ## Gamepak DRQ
  DMA_AT_VBLANK*:uint32 = 0x10000000    ## Start transfer at VBlank
  DMA_AT_HBLANK*:uint32 = 0x20000000    ## Start transfer at HBlank
  DMA_AT_SPECIAL*:uint32 = 0x30000000   ## Start copy at 'special' condition. Channel dependent
  DMA_AT_FIFO*:uint32 = 0x30000000      ## Start at FIFO empty (DMA0/DMA1)
  DMA_AT_REFRESH*:uint32 = 0x30000000   ## VRAM special; start at VCount=2 (DMA3)
  DMA_IRQ*:uint32 = 0x40000000          ## Enable DMA irq
  DMA_ENABLE*:uint32 = 0x80000000.uint32       ## Enable DMA
  DMA_COUNT_MASK*:uint32 = 0x0000FFFF
  DMA_COUNT_SHIFT*:uint32 = 0

template DMA_COUNT*(n: uint32): uint32 =
  (n shl DMA_COUNT_SHIFT)

# Extra
const
  DMA_NOW*:uint32 = (DMA_ENABLE or DMA_AT_NOW)
  DMA_16NOW*:uint32 = (DMA_NOW or DMA_16)
  DMA_32NOW*:uint32 = (DMA_NOW or DMA_32)

# Copies
const
  DMA_CPY16*:uint32 = (DMA_NOW or DMA_16)
  DMA_CPY32*:uint32 = (DMA_NOW or DMA_32)

##  fills
const
  DMA_FILL16*:uint32 = (DMA_NOW or DMA_SRC_FIXED or DMA_16)
  DMA_FILL32*:uint32 = (DMA_NOW or DMA_SRC_FIXED or DMA_32)
  DMA_HDMA*:uint32 = (DMA_ENABLE or DMA_REPEAT or DMA_AT_HBLANK or DMA_DST_RELOAD)

# REG_TMxCNT
# ----------
# Timer Control Flags

# Bits for REG_TMxCNT
const
  TM_FREQ_SYS*:uint16 = 0x0000    ## System clock timer (16.7 Mhz)
  TM_FREQ_1*:uint16 = 0x0000      ## 1 cycle/tick (16.7 Mhz)
  TM_FREQ_64*:uint16 = 0x0001     ## 64 cycles/tick (262 kHz)
  TM_FREQ_256*:uint16 = 0x0002    ## 256 cycles/tick (66 kHz)
  TM_FREQ_1024*:uint16 = 0x0003   ## 1024 cycles/tick (16 kHz)
  TM_CASCADE*:uint16 = 0x0004     ## Increment when preceding timer overflows
  TM_IRQ*:uint16 = 0x0040         ## Enable timer irq
  TM_ENABLE*:uint16 = 0x0080      ## Enable timer
  
  TM_FREQ_MASK*:uint16 = 0x0003
  TM_FREQ_SHIFT*:uint16 = 0

template TM_FREQ*(n: uint16): uint16 =
  (n shl TM_FREQ_SHIFT)

# REG_SIOCNT
# ----------
# Serial I/O Control

# Bits for REG_TMxCNT
# General SIO bits.
const
  SIO_MODE_8BIT*:uint16 = 0x0000    ## Normal comm mode, 8-bit.
  SIO_MODE_32BIT*:uint16 = 0x1000   ## Normal comm mode, 32-bit.
  SIO_MODE_MULTI*:uint16 = 0x2000   ## Multi-play comm mode.
  SIO_MODE_UART*:uint16 = 0x3000    ## UART comm mode.
  SIO_SI_HIGH*:uint16 = 0x0004
  SIO_IRQ*:uint16 = 0x4000          ## Enable serial irq.
  
  SIO_MODE_MASK*:uint16 = 0x3000
  SIO_MODE_SHIFT*:uint16 = 12

template SIO_MODE*(n: uint16): uint16 =
  (n shl SIO_MODE_SHIFT)

# Normal mode bits. UNTESTED.
const
  SION_CLK_EXT*:uint16 = 0x0000     ## Slave unit; use external clock (default).
  SION_CLK_INT*:uint16 = 0x0001     ## Master unit; use internal clock.
  SION_256KHZ*:uint16 = 0x0000      ## 256 kHz clockspeed (default).
  SION_2MHZ*:uint16 = 0x0002        ## 2 MHz clockspeed.
  SION_RECV_HIGH*:uint16 = 0x0004   ## SI high; opponent ready to receive (R).
  SION_SEND_HIGH*:uint16 = 0x0008   ## SO high; ready to transfer.
  SION_ENABLE*:uint16 = 0x0080      ## Start transfer/transfer enabled.

# Multiplayer mode bits. UNTESTED.
const
  SIOM_9600*:uint16 = 0x0000       ## Baud rate,   9.6 kbps.
  SIOM_38400*:uint16 = 0x0001      ## Baud rate,  38.4 kbps.
  SIOM_57600*:uint16 = 0x0002      ## Baud rate,  57.6 kbps.
  SIOM_115200*:uint16 = 0x0003     ## Baud rate, 115.2 kbps.
  SIOM_SI*:uint16 = 0x0004         ## SI port (R).
  SIOM_SLAVE*:uint16 = 0x0004      ## Not the master (R).
  SIOM_SD*:uint16 = 0x0008         ## SD port (R).
  SIOM_CONNECTED*:uint16 = 0x0008  ## All GBAs connected (R)
  SIOM_ERROR*:uint16 = 0x0040      ## Error in transfer (R).
  SIOM_ENABLE*:uint16 = 0x0080     ## Start transfer/transfer enabled.
  
  SIOM_BAUD_MASK*:uint16 = 0x0003
  SIOM_BAUD_SHIFT*:uint16 = 0

template SIOM_BAUD*(n: uint16): uint16 =
  (n shl SIOM_BAUD_SHIFT)

const
  SIOM_ID_MASK*:uint16 = 0x0030
  SIOM_ID_SHIFT*:uint16 = 4

template SIOM_ID*(n: uint16): uint16 =
  (n shl SIOM_ID_SHIFT)

# UART mode bits. UNTESTED.
const
  SIOU_9600*:uint16 = 0x0000          ##  Baud rate,   9.6 kbps.
  SIOU_38400*:uint16 = 0x0001         ## !< Baud rate,  38.4 kbps.
  SIOU_57600*:uint16 = 0x0002         ## !< Baud rate,  57.6 kbps.
  SIOU_115200*:uint16 = 0x0003        ## !< Baud rate, 115.2 kbps.
  SIOU_CTS*:uint16 = 0x0004           ## !< CTS enable.
  SIOU_PARITY_EVEN*:uint16 = 0x0000   ## !< Use even parity.
  SIOU_PARITY_ODD*:uint16 = 0x0008    ## !< Use odd parity.
  SIOU_SEND_FULL*:uint16 = 0x0010     ## !< Send data is full (R).
  SIOU_RECV_EMPTY*:uint16 = 0x0020    ## !< Receive data is empty (R).
  SIOU_ERROR*:uint16 = 0x0040         ## !< Error in transfer (R).
  SIOU_7BIT*:uint16 = 0x0000          ## !< Data is 7bits long.
  SIOU_8BIT*:uint16 = 0x0080          ## !< Data is 8bits long.
  SIOU_SEND*:uint16 = 0x0100          ## !< Start sending data.
  SIOU_RECV*:uint16 = 0x0200          ## !< Start receiving data.
  
  SIOU_BAUD_MASK*:uint16 = 0x00000003
  SIOU_BAUD_SHIFT*:uint16 = 0

template SIOU_BAUD*(n: uint16): uint16 =
  (n shl SIOU_BAUD_SHIFT)

# Comm control.
# Communication mode select and general purpose I/O (REG_RCNT).

# Communication mode select.
const
  R_MODE_NORMAL*:uint16 = 0x0000
  R_MODE_MULTI*:uint16 = 0x0000
  R_MODE_UART*:uint16 = 0x0000
  R_MODE_GPIO*:uint16 = 0x8000
  R_MODE_JOYBUS*:uint16 = 0xC000
  R_MODE_MASK*:uint16 = 0xC000
  R_MODE_SHIFT*:uint16 = 14

template R_MODE*(n: uint16): uint16 =
  (n shl R_MODE_SHIFT)

# General purpose I/O data
const
  GPIO_SC*:uint16 = 0x0001          # Data
  GPIO_SD*:uint16 = 0x0002
  GPIO_SI*:uint16 = 0x0004
  GPIO_SO*:uint16 = 0x0008
  GPIO_SC_IO*:uint16 = 0x0010       # Select I/O
  GPIO_SD_IO*:uint16 = 0x0020
  GPIO_SI_IO*:uint16 = 0x0040
  GPIO_SO_IO*:uint16 = 0x0080
  GPIO_SC_INPUT*:uint16 = 0x0000    # Input setting
  GPIO_SD_INPUT*:uint16 = 0x0000
  GPIO_SI_INPUT*:uint16 = 0x0000
  GPIO_SO_INPUT*:uint16 = 0x0000
  GPIO_SC_OUTPUT*:uint16 = 0x0010   # Output setting
  GPIO_SD_OUTPUT*:uint16 = 0x0020
  GPIO_SI_OUTPUT*:uint16 = 0x0040
  GPIO_SO_OUTPUT*:uint16 = 0x0080
  
  GPIO_IRQ*:uint16 = 0x0100         # Interrupt on SI

# REG_KEYINPUT
# ------------
# Key Flags

# Bits for REG_KEYINPUT and REG_KEYCNT
const
  KEY_A*:uint16 = 0x0001          ## Button A
  KEY_B*:uint16 = 0x0002          ## Button B
  KEY_SELECT*:uint16 = 0x0004     ## Select button
  KEY_START*:uint16 = 0x0008      ## Start button
  KEY_RIGHT*:uint16 = 0x0010      ## Right D-pad
  KEY_LEFT*:uint16 = 0x0020       ## Left D-pad
  KEY_UP*:uint16 = 0x0040         ## Up D-pad
  KEY_DOWN*:uint16 = 0x0080       ## Down D-pad
  KEY_R*:uint16 = 0x0100          ## Shoulder R
  KEY_L*:uint16 = 0x0200          ## Shoulder L
  
  KEY_ACCEPT*:uint16 = 0x0009     ## Accept buttons: A or start
  KEY_CANCEL*:uint16 = 0x0002     ## Cancel button: B (well, it usually is)
  KEY_RESET*:uint16 = 0x030C      ## Start + Select + L + R
  KEY_FIRE*:uint16 = 0x0003       ## Fire buttons: A or B
  
  KEY_SPECIAL*:uint16 = 0x000C    ## Special buttons: Select or Start
  KEY_DIR*:uint16 = 0x00F0        ## Directions: left, right, up down
  KEY_SHOULDER*:uint16 = 0x0300   ## L or R
  KEY_ANY*:uint16 = 0x03FF        ## Here's the Any key :)
  KEY_MASK*:uint16 = 0x03FF

# REG_KEYCNT
# ----------
# Key Control Flags

# Bits for REG_KEYCNT
const
  KCNT_IRQ*:uint16 = 0x4000   ## Enable key irq
  KCNT_OR*:uint16 = 0x0000    ## Interrupt on any of selected keys
  KCNT_AND*:uint16 = 0x8000   ## Interrupt on all of selected keys

# REG_IE, REG_IF, REG_IF_BIOS
# ---------------------------
# Interrupt Flags

# Bits for REG_IE, REG_IF and REG_IFBIOS
const
  IRQ_VBLANK*:uint16 = 0x0001    ## Catch VBlank irq
  IRQ_HBLANK*:uint16 = 0x0002    ## Catch HBlank irq
  IRQ_VCOUNT*:uint16 = 0x0004    ## Catch VCount irq
  IRQ_TIMER0*:uint16 = 0x0008    ## Catch timer 0 irq
  IRQ_TIMER1*:uint16 = 0x0010    ## Catch timer 1 irq
  IRQ_TIMER2*:uint16 = 0x0020    ## Catch timer 2 irq
  IRQ_TIMER3*:uint16 = 0x0040    ## Catch timer 3 irq
  IRQ_SERIAL*:uint16 = 0x0080    ## Catch serial comm irq
  IRQ_DMA0*:uint16 = 0x0100      ## Catch DMA 0 irq
  IRQ_DMA1*:uint16 = 0x0200      ## Catch DMA 1 irq
  IRQ_DMA2*:uint16 = 0x0400      ## Catch DMA 2 irq
  IRQ_DMA3*:uint16 = 0x0800      ## Catch DMA 3 irq
  IRQ_KEYPAD*:uint16 = 0x1000    ## Catch key irq
  IRQ_GAMEPAK*:uint16 = 0x2000   ## Catch cart irq

# REG_WSCNT
# ---------
# Waitstate Control Flags

# Bits for REG_WAITCNT
const
  WS_SRAM_4*:uint16 = 0x0000
  WS_SRAM_3*:uint16 = 0x0001
  WS_SRAM_2*:uint16 = 0x0002
  WS_SRAM_8*:uint16 = 0x0003
  WS_ROM0_N4*:uint16 = 0x0000
  WS_ROM0_N3*:uint16 = 0x0004
  WS_ROM0_N2*:uint16 = 0x0008
  WS_ROM0_N8*:uint16 = 0x000C
  WS_ROM0_S2*:uint16 = 0x0000
  WS_ROM0_S1*:uint16 = 0x0010
  WS_ROM1_N4*:uint16 = 0x0000
  WS_ROM1_N3*:uint16 = 0x0020
  WS_ROM1_N2*:uint16 = 0x0040
  WS_ROM1_N8*:uint16 = 0x0060
  WS_ROM1_S4*:uint16 = 0x0000
  WS_ROM1_S1*:uint16 = 0x0080
  WS_ROM2_N4*:uint16 = 0x0000
  WS_ROM2_N3*:uint16 = 0x0100
  WS_ROM2_N2*:uint16 = 0x0200
  WS_ROM2_N8*:uint16 = 0x0300
  WS_ROM2_S8*:uint16 = 0x0000
  WS_ROM2_S1*:uint16 = 0x0400
  WS_PHI_OFF*:uint16 = 0x0000
  WS_PHI_4*:uint16 = 0x0800
  WS_PHI_2*:uint16 = 0x1000
  WS_PHI_1*:uint16 = 0x1800
  WS_PREFETCH*:uint16 = 0x4000
  WS_GBA*:uint16 = 0x0000
  WS_CGB*:uint16 = 0x8000
  WS_STANDARD*:uint16 = 0x4317

# Reg screen entries

# Screen-entry Flags
const
  SE_HFLIP*:uint16 = 0x0400   ## Horizontal flip
  SE_VFLIP*:uint16 = 0x0800   ## Vertical flip
  SE_ID_MASK*:uint16 = 0x03FF
  SE_ID_SHIFT*:uint16 = 0

template SE_ID*(n: uint16): uint16 =
  (n shl SE_ID_SHIFT)

const
  SE_FLIP_MASK*:uint16 = 0x0C00
  SE_FLIP_SHIFT*:uint16 = 10

template SE_FLIP*(n: uint16): uint16 =
  (n shl SE_FLIP_SHIFT)

const
  SE_PALBANK_MASK*:uint16 = 0x0000F000
  SE_PALBANK_SHIFT*:uint16 = 12

template SE_PALBANK*(n: uint16): uint16 =
  (n shl SE_PALBANK_SHIFT)

template SE_BUILD*(id, palbank, hflip, vflip: uint16): uint16 =
  (((id) and 0x03FF) or (((hflip) and 1) shl 10) or (((vflip) and 1) shl 11) or
      ((palbank) shl 12))

# OAM attribute 0
# Object Attribute 0 Flags
const
  ATTR0_REG*:uint16 = 0x0000       ## Regular object
  ATTR0_AFF*:uint16 = 0x0100       ## Affine object
  ATTR0_HIDE*:uint16 = 0x0200      ## Inactive object
  ATTR0_AFF_DBL*:uint16 = 0x0300   ## Double-size affine object
  ATTR0_AFF_DBL_BIT*:uint16 = 0x0200
  ATTR0_BLEND*:uint16 = 0x0400     ## Enable blend
  ATTR0_WINDOW*:uint16 = 0x0800    ## Use for object window
  ATTR0_MOSAIC*:uint16 = 0x1000    ## Enable mosaic
  ATTR0_4BPP*:uint16 = 0x0000      ## Use 4bpp (16 color) tiles
  ATTR0_8BPP*:uint16 = 0x2000      ## Use 8bpp (256 color) tiles
  ATTR0_SQUARE*:uint16 = 0x0000    ## Square shape
  ATTR0_WIDE*:uint16 = 0x4000      ## Tall shape (height &gt; width)
  ATTR0_TALL*:uint16 = 0x8000      ## Wide shape (height &lt; width)
  
  ATTR0_Y_MASK*:uint16 = 0x00FF
  ATTR0_Y_SHIFT*:uint16 = 0

template ATTR0_Y*(n: uint16): uint16 =
  (n shl ATTR0_Y_SHIFT)

const
  ATTR0_MODE_MASK*:uint16 = 0x0300
  ATTR0_MODE_SHIFT*:uint16 = 8

template ATTR0_MODE*(n: uint16): uint16 =
  (n shl ATTR0_MODE_SHIFT)

const
  ATTR0_SHAPE_MASK*:uint16 = 0xC000
  ATTR0_SHAPE_SHIFT*:uint16 = 14

template ATTR0_SHAPE*(n: uint16): uint16 =
  (n shl ATTR0_SHAPE_SHIFT)

template ATTR0_BUILD*(y, shape, bpp, mode, mos, bld, win: uint16): uint16 =
  (((y) and 255) or (((mode) and 3) shl 8) or (((bld) and 1) shl 10) or
      (((win) and 1) shl 11) or (((mos) and 1) shl 12) or (((bpp) and 8) shl 10) or
      (((shape) and 3) shl 14))

# OAM attribute 1
# Object Attribute 1 Flags
const
  ATTR1_HFLIP*:uint16 = 0x1000    ## Horizontal flip (reg obj only)
  ATTR1_VFLIP*:uint16 = 0x2000    ## Vertical flip (reg obj only)
  
  # Base sizes
  ATTR1_SIZE_8*:uint16 = 0x0000
  ATTR1_SIZE_16*:uint16 = 0x4000
  ATTR1_SIZE_32*:uint16 = 0x8000
  ATTR1_SIZE_64*:uint16 = 0xC000
  
  # Square sizes
  ATTR1_SIZE_8x8*:uint16 = 0x0000
  ATTR1_SIZE_16x16*:uint16 = 0x4000
  ATTR1_SIZE_32x32*:uint16 = 0x8000
  ATTR1_SIZE_64x64*:uint16 = 0xC000
  
  # Tall sizes
  ATTR1_SIZE_8x16*:uint16 = 0x0000
  ATTR1_SIZE_8x32*:uint16 = 0x4000
  ATTR1_SIZE_16x32*:uint16 = 0x8000
  ATTR1_SIZE_32x64*:uint16 = 0xC000
  
  # Wide sizes
  ATTR1_SIZE_16x8*:uint16 = 0x0000
  ATTR1_SIZE_32x8*:uint16 = 0x4000
  ATTR1_SIZE_32x16*:uint16 = 0x8000
  ATTR1_SIZE_64x32*:uint16 = 0xC000
  
  ATTR1_X_MASK*:uint16 = 0x01FF
  ATTR1_X_SHIFT*:uint16 = 0

template ATTR1_X*(n: uint16): uint16 =
  (n shl ATTR1_X_SHIFT)

const
  ATTR1_AFF_ID_MASK*:uint16 = 0x3E00
  ATTR1_AFF_ID_SHIFT*:uint16 = 9

template ATTR1_AFF_ID*(n: uint16): uint16 =
  (n shl ATTR1_AFF_ID_SHIFT)

const
  ATTR1_FLIP_MASK*:uint16 = 0x3000
  ATTR1_FLIP_SHIFT*:uint16 = 12

template ATTR1_FLIP*(n: uint16): uint16 =
  (n shl ATTR1_FLIP_SHIFT)

const
  ATTR1_SIZE_MASK*:uint16 = 0xC000
  ATTR1_SIZE_SHIFT*:uint16 = 14

template ATTR1_SIZE*(n: uint16): uint16 =
  (n shl ATTR1_SIZE_SHIFT)

template ATTR1_BUILDR*(x, size, hflip, vflip: uint16): uint16 =
  (((x) and 511) or (((hflip) and 1) shl 12) or (((vflip) and 1) shl 13) or
      (((size) and 3) shl 14))

template ATTR1_BUILDA*(x, size, affid: uint16): uint16 =
  (((x) and 511) or (((affid) and 31) shl 9) or (((size) and 3) shl 14))

# OAM attribute 2
# Object Attribute 2 Flags
const
  ATTR2_ID_MASK*:uint16 = 0x03FF
  ATTR2_ID_SHIFT*:uint16 = 0

template ATTR2_ID*(n: uint16): uint16 =
  (n shl ATTR2_ID_SHIFT)

const
  ATTR2_PRIO_MASK*:uint16 = 0x0C00
  ATTR2_PRIO_SHIFT*:uint16 = 10

template ATTR2_PRIO*(n: uint16): uint16 =
  (n shl ATTR2_PRIO_SHIFT)

const
  ATTR2_PALBANK_MASK*:uint16 = 0xF000
  ATTR2_PALBANK_SHIFT*:uint16 = 12

template ATTR2_PALBANK*(n: uint16): uint16 =
  (n shl ATTR2_PALBANK_SHIFT)

template ATTR2_BUILD*(id, pb, prio: uint16): uint16 =
  (((id) and 0x000003FF) or (((pb) and 15) shl 12) or (((prio) and 3) shl 10))
  