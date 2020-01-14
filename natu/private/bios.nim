## BIOS call functions
## ===================
## Interfaces and constants for the GBA BIOS routines.
##
## NOTES
## -----
## Pretty much copied verbatim from Pern and dkARM's libgba
## (which in turn is copied from CowBite Spec (which got its info from
##   GBATek))
## 
## While the speeds of the routines are fair, there
## 	is a large overhead in calling the functions.
##
## * Make SURE your data is aligned to 32bit boundaries. Defining data
##   as uint32 (and I do mean define; not merely cast) ensures this. Either
##   that or use __attribute__(( aligned(4) ))
## * There is a large (70 cycle in and out) overhead for SWIs. If you
##   know what they do, consider creating replacement code
## * div by 0 locks up GBA.
## * Cpu(Fast)Set's count is in chunks, not bytes. CpuFastSet REQUIRES
##   n*32 byte data
## * SoftReset is funky with interrupts on.
## * VBlankIntrWait is your friend. If you have a VBlank isr that clears
##   REG_IFBIOS as well. Use this instead of REG_VCOUNT polling for VSync.
## * I haven't tested many of these functions. The ones that are have a
##   plus (+) behind their numbers.
## * I've switched to the standard BIOS names.
##
## 	For details, see
## 	`tonc:keys <http://www.coranac.com/tonc/text/keys.htm>`_
## 	and especially
## 	`gbatek:bios <http://nocash.emubase.de/gbatek.htm#biosfunctions>`_.
##

# SoftReset flags ?
const
  ROM_RESTART*:uint32 = 0x00   ## Restart from ROM entry point.
  RAM_RESTART*:uint32 = 0x01   ## Restart from RAM entry point.

# RegisterRamReset flags
const
  RESET_EWRAM*:uint32 = 0x00000001      ## Clear 256K on-board WRAM
  RESET_IWRAM*:uint32 = 0x00000002      ## Clear 32K in-chip WRAM
  RESET_PALETTE*:uint32 = 0x00000004    ## Clear Palette
  RESET_VRAM*:uint32 = 0x00000008       ## Clear VRAM
  RESET_OAM*:uint32 = 0x00000010        ## Clear OAM. does NOT disable OBJs!
  RESET_REG_SIO*:uint32 = 0x00000020    ## Switches to general purpose mode
  RESET_REG_SOUND*:uint32 = 0x00000040  ## Reset Sound registers
  RESET_REG*:uint32 = 0x00000080        ## All other registers

const
  RESET_MEM_MASK*:uint32 = 0x0000001F
  RESET_REG_MASK*:uint32 = 0x000000E0

const
  RESET_GFX*:uint32 = 0x0000001C  ## Clear all gfx-related memory

# Cpu(Fast)Set flags

const
  CS_CPY*:uint32 = 0              ## Copy mode
  CS_FILL*:uint32 = (1 shl 24)    ## Fill mode
  CS_CPY16*:uint32 = 0            ## Copy in halfwords
  CS_CPY32*:uint32 = (1 shl 26)   ## Copy words
  CS_FILL32*:uint32 = (5 shl 24)  ## Fill words
  CFS_CPY*:uint32 = CS_CPY        ## Copy words
  CFS_FILL*:uint32 = CS_FILL      ## Fill words

# ObjAffineSet P-element offsets

const
  BG_AFF_OFS*:int32 = 2    ## BgAffineDest offsets
  OBJ_AFF_OFS*:int32 = 8   ## ObjAffineDest offsets

## Decompression routines
const
  BUP_ALL_OFS* = (1 shl 31)
  LZ_TYPE* = 0x00000010
  LZ_SIZE_MASK* = 0xFFFFFF00
  LZ_SIZE_SHIFT* = 8
  HUF_BPP_MASK* = 0x0000000F
  HUF_TYPE* = 0x00000020
  HUF_SIZE_MASK* = 0xFFFFFF00
  HUF_SIZE_SHIFT* = 8
  RL_TYPE* = 0x00000030
  RL_SIZE_MASK* = 0xFFFFFF00
  RL_SIZE_SHIFT* = 8
  DIF_8* = 0x00000001
  DIF_16* = 0x00000002
  DIF_TYPE* = 0x00000080
  DIF_SIZE_MASK* = 0xFFFFFF00
  DIF_SIZE_SHIFT* = 8

# Multiboot modes
const
  MBOOT_NORMAL* = 0x00
  MBOOT_MULTI* = 0x01
  MBOOT_FAST* = 0x02


# Data structures for affine functions 0x0E and 0x0F
#
#  Notational convention: postfix underscore is 2d vector
#
# 	p_ = (px, py)		= texture coordinates
# 	q_ = (qx, qy)		= screen coordinates
# 	P  = | pa pb |  = affine matrix
# 	     | pc pd |
# 	d_ = (dx, dy)		= background displacement
#
#  Then:
#
# (1)	p_ = P*q_ + d_
#
#  For transformation around a different point
#  (texture point p0_ and screen point q0_), do
#
# (2)	p_ - p0_ = P*(q_-q0_)
#
#  Subtracting eq 2 from eq1 we immediately find:
#
# (3)	_d = p0_ - P*q0_
#
#  For the special case of a texture->screen scale-then-rotate
#  transformation with
# 	s_ = (sx, sy)	= inverse scales (s>1 shrinks)
# 	a = alpha		= Counter ClockWise (CCW) angle
#
# (4)	P  = | sx*cos(a) -sx*sin(a) |
#          | sy*sin(a)  sy*cos(a) |
#
#
#  ObjAffineSet takes a and s_ as input and gives P
#  BgAffineSet does that and fills in d_ as well
#
#
# affine types in tonc_types.h

type
  BUP* {.importc: "BUP", header: "tonc.h", bycopy.} = object
    ## BitUpPack (for swi 10h)
    srcLen* {.importc: "src_len".}: uint16  ## source length (bytes)
    srcBpp* {.importc: "src_bpp".}: uint8   ## source bitdepth (1,2,4,8)
    dstBpp* {.importc: "dst_bpp".}: uint8   ## destination bitdepth (1,2,4,8,16,32)
    dstOfs* {.importc: "dst_ofs".}: uint32  ## {0-30}: added offset {31}: zero-data offset flag
    
type
  MultiBootParam* {.importc: "MultiBootParam", header: "tonc.h", bycopy.} = object
    ## Multiboot struct
    reserved1* {.importc: "reserved1".}: array[5, uint32]
    handshakeData* {.importc: "handshake_data".}: uint8
    padding* {.importc: "padding".}: uint8
    handshakeTimeout* {.importc: "handshake_timeout".}: uint16
    probeCount* {.importc: "probe_count".}: uint8
    clientData* {.importc: "client_data".}: array[3, uint8]
    paletteData* {.importc: "palette_data".}: uint8
    responseBit* {.importc: "response_bit".}: uint8
    clientBit* {.importc: "client_bit".}: uint8
    reserved2* {.importc: "reserved2".}: uint8
    bootSrcp* {.importc: "boot_srcp".}: ptr uint8
    bootEndp* {.importc: "boot_endp".}: ptr uint8
    masterp* {.importc: "masterp".}: ptr uint8
    reserved3* {.importc: "reserved3".}: array[3, ptr uint8]
    systemWork2* {.importc: "system_work2".}: array[4, uint32]
    sendflag* {.importc: "sendflag".}: uint8
    probeTargetBit* {.importc: "probe_target_bit".}: uint8
    checkWait* {.importc: "check_wait".}: uint8
    serverType* {.importc: "server_type".}: uint8


## BASIC BIOS ROUTINES
## -------------------

# Reset Functions

proc SoftReset*() {.importc: "SoftReset", header: "tonc.h".}
  ##  swi 00h

proc RegisterRamReset*(flags: uint32) {.importc: "RegisterRamReset", header: "tonc.h".}
  ##  swi 01h

# Halt functions
# --------------

proc Halt*() {.importc: "Halt", header: "tonc.h".}
  ##  swi 02h

proc Stop*() {.importc: "Stop", header: "tonc.h".}
  ##  swi 03h

proc IntrWait*(flagClear: uint32; irq: uint32) {.importc: "IntrWait", header: "tonc.h".}
  ##  swi 04h

proc VBlankIntrWait*() {.importc: "VBlankIntrWait", header: "tonc.h".}
  ## Wait for the next VBlank (swi 05h).
  ## Note: Requires clearing of REG_IFBIOS bit 0 at the interrupt
  ## 	  tonc's master interrupt handler does this for you.


# Arithmetic
# ----------

proc Div*(num: int32; den: int32): int32 {.importc: "Div", header: "tonc.h".}
  ## Basic integer division (swi 06h).
  ## `num` Numerator.
  ## `den` Denominator.
  ## Returns num / den
  ## Note:	div/0 results in an infinite loop. Try `DivSafe` instead


proc DivArm*(den: int32; num: int32): int32 {.importc: "DivArm", header: "tonc.h".}
  ## Basic integer division, but with switched arguments (swi 07h).
  ## `num` Numerator.
  ## `den` Denominator.
  ## Returns num / den
  ## Note: div/0 results in an infinite loop.

proc Sqrt*(num: uint32): uint32 {.importc: "Sqrt", header: "tonc.h".}
  ## Integer Square root (swi 08h).

proc ArcTan*(dydx: int16): int16 {.importc: "ArcTan", header: "tonc.h".}
  ## Arctangent of dydx (swi 08h)
  ## `dydx` Slope to get the arctangent of.
  ## Returns the arctangent of dydx in the range <-4000h, 4000h>,
  ## corresponding to	<-PI/2, PI/2>.
  ## Note: Said to be inaccurate near the range's limits.

proc ArcTan2*(x: int16; y: int16): int16 {.importc: "ArcTan2", header: "tonc.h".}
  ## Arctangent of a coordinate pair (swi 09h).
  ## This is the full-circle arctan, with an angle range of [0,FFFFh].


# Memory copiers/fillers
# ----------------------
# Technically, these are misnomers. The convention is that
# xxxset is used for fills (comp memset, strset). Or perhaps
# the C library functions are misnomers, since set can be applied
# to both copies and fills.

proc CpuSet*(src: pointer; dst: pointer; mode: uint32) {.importc: "CpuSet", header: "tonc.h".}
  ## Transfer via CPU in (half)word chunks.
  ## The default mode is 16bit copies. With bit 24 set, it copies
  ##   words; with bit 26 set it will keep the source address constant,
  ##   effectively performing fills instead of copies.
  ## `src`  Source address.
  ## `dst`  Destination address.
  ## `mode` Number of transfers, and mode bits.
  ## 	Note: This basically does a straightforward loop-copy, and is not particularly fast.
  ## 	Note:	In fill-mode (bit 26), the source is \e still an address, not a value.

proc CpuFastSet*(src: pointer; dst: pointer; mode: uint32) {.importc: "CpuFastSet", header: "tonc.h".}
  ## A fast transfer via CPU in 32 byte chunks.
  ## This uses ARM's ldmia/stmia instructions to copy 8 words at a time,
  ##  making it rival DMA transfers in speed. With bit 26 set it will
  ##  keep the source address constant, effectively performing fills
  ##  instead of copies.
  ## `src`  Source address.
  ## `dst`  Destination address.
  ## `mode` Number of words to transfer, and mode bits.
  ## Note: Both source and destination must be word aligned; the
  ## 		   number of copies must be a multiple of 8.
  ## Note: In fill-mode (bit 26), the source is \e still an address,
  ## 	     not a value.
  ## Note: memcpy32/16 and memset32/16 basically do the same things, but
  ## 	     safer. Use those instead.


proc BiosCheckSum*(): uint32 {.importc: "BiosCheckSum", header: "tonc.h".}



# Rot/scale functions
# -------------------
#  These functions are misnomers, because ObjAffineSet is merely
#  a special case of / precursor to BgAffineSet. Results from either
#  can be used for both objs and bgs. Oh well.

proc ObjAffineSet*(src: ptr ObjAffineSource; dst: pointer; num: int32; offset: int32) {.importc: "ObjAffineSet", header: "tonc.h".}
  ## Sets up a simple scale-then-rotate affine transformation (swi 0Eh).
  ## Uses a single `ObjAffineSource` struct to set up an array of affine
  ## 	matrices (either BG or Object) with a certain transformation. The
  ## 	matrix created is
  ## +-----------+------------+
  ## | sx·cos(α) | -sx·sin(α) |
  ## +-----------+------------+
  ## | sy·sin(α) | sy·cos(α)  |
  ## +-----------+------------+
  ##
  ## `src`    Array with scale and angle information.
  ## `dst`    Array of affine matrices, starting at a \a pa element.
  ## `num`    Number of matrices to set.
  ## `offset` Offset between affine elements. Use 2 for BG and 8 for object matrices.
  ## Note: Each element in `src` needs to be word aligned, which
  ## 	     devkitPro doesn't do anymore by itself.

proc BgAffineSet*(src: ptr BgAffineSource; dst: ptr BgAffineDest; num: int32) {.importc: "BgAffineSet", header: "tonc.h".}
  ## Sets up a simple scale-then-rotate affine transformation (swi 0Fh).
  ## See `ObjAffineSet` for more information.


# Decompression
# -------------
# (see GBATek for format details)

proc BitUnPack*(src: pointer; dst: pointer; bup: ptr BUP) {.importc: "BitUnPack", header: "tonc.h".}
  ##  swi 10h +

proc LZ77UnCompWram*(src: pointer; dst: pointer) {.importc: "LZ77UnCompWram", header: "tonc.h".}
  ##  swi 11h +

proc LZ77UnCompVram*(src: pointer; dst: pointer) {.importc: "LZ77UnCompVram", header: "tonc.h".}
  ##  swi 12h +

proc HuffUnComp*(src: pointer; dst: pointer) {.importc: "HuffUnComp", header: "tonc.h".}
  ##  swi 13h +

proc RLUnCompWram*(src: pointer; dst: pointer) {.importc: "RLUnCompWram", header: "tonc.h".}
  ##  swi 14h

proc RLUnCompVram*(src: pointer; dst: pointer) {.importc: "RLUnCompVram", header: "tonc.h".}
  ##  swi 15h +

proc Diff8bitUnFilterWram*(src: pointer; dst: pointer) {.importc: "Diff8bitUnFilterWram", header: "tonc.h".}
  ##  swi 16h

proc Diff8bitUnFilterVram*(src: pointer; dst: pointer) {.importc: "Diff8bitUnFilterVram", header: "tonc.h".}
  ##  swi 17h

proc Diff16bitUnFilter*(src: pointer; dst: pointer) {.importc: "Diff16bitUnFilter", header: "tonc.h".}
  ##  swi 18h


# Sound
# -----

proc SoundBias*(bias: uint32) {.importc: "SoundBias", header: "tonc.h".}
  ##  swi 19h

proc SoundDriverInit*(src: pointer) {.importc: "SoundDriverInit", header: "tonc.h".}
  ##  swi 1Ah

proc SoundDriverMode*(mode: uint32) {.importc: "SoundDriverMode", header: "tonc.h".}
  ##  swi 1Bh

proc SoundDriverMain*() {.importc: "SoundDriverMain", header: "tonc.h".}
  ##  swi 1Ch

proc SoundDriverVSync*() {.importc: "SoundDriverVSync", header: "tonc.h".}
  ##  swi 1Dh

proc SoundChannelClear*() {.importc: "SoundChannelClear", header: "tonc.h".}
  ##  swi 1Eh

proc MidiKey2Freq*(wa: pointer; mk: uint8; fp: uint8): uint32 {.importc: "MidiKey2Freq", header: "tonc.h".}
  ##  swi 1Fh

proc SoundDriverVSyncOff*() {.importc: "SoundDriverVSyncOff", header: "tonc.h".}
  ##  swi 28h

proc SoundDriverVSyncOn*() {.importc: "SoundDriverVSyncOn", header: "tonc.h".}
  ##  swi 29h


proc MultiBoot*(mb: ptr MultiBootParam; mode: uint32): cint {.importc: "MultiBoot", header: "tonc.h".}
  ## Multiboot handshake (swi 25h)


# EXTRA BIOS ROUTINES
# -------------------
# More BIOS functions.
# You can find these in swi_ex.s

proc VBlankIntrDelay*(count: uint32) {.importc: "VBlankIntrDelay", header: "tonc.h".}
  ## Wait for `count` frames

proc DivSafe*(num: cint; den: cint): cint {.importc: "DivSafe", header: "tonc.h".}
  ## Div/0-safe division
  ## The standard Div hangs if `den` = 0. This version will return
  ## 	`INT_MAX/MIN` in that case, depending on the sign of `num`,
  ## 	or just `num / den` if `den` is not 0.
  ## `num` Numerator.
  ## `den` Denominator.

proc Mod*(num: cint; den: cint): cint {.importc: "Mod", header: "tonc.h".}
  ## Modulo: `num % den`.

proc DivMod*(num: cint; den: cint): cint {.importc: "DivMod", header: "tonc.h".}
  ## Modulo: `num % den`.

proc DivAbs*(num: cint; den: cint): uint32 {.importc: "DivAbs", header: "tonc.h".}
  ## Absolute value of `num / den`

proc DivArmMod*(den: cint; num: cint): cint {.importc: "DivArmMod", header: "tonc.h".}
  ## Modulo: `num % den`.

proc DivArmAbs*(den: cint; num: cint): uint32 {.importc: "DivArmAbs", header: "tonc.h".}
  ## Absolute value of `num / den`

proc CpuFastFill*(wd: uint32; dst: pointer; mode: uint32) {.importc: "CpuFastFill", header: "tonc.h".}
  ## A fast word fill
  ## While you can perform fills with CpuFastSet(), the fact that
  ##  swi 12 requires a source address makes it awkward to use.
  ## This function is more like the traditional memset formulation.
  ## `wd`   Fill word.
  ## `dst`  Destination address.
  ## `mode` Number of words to transfer
