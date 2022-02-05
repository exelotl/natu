## This module exposes the GBA system calls (aka. BIOS functions).
## 
## The function names are `PascalCase` as is the convention used by Tonc, GBATek and others,
## which also helps to avoid clashing with Nim's reserved keywords such as `div` and `mod`.
## 
## .. attention::
##   These aren't fully documented yet - please refer to `GBATek <https://rust-console.github.io/gbatek-gbaonly/#biosfunctions>`_ in the meantime.

import ./private/[types, common]

from ./irq import IrqIndex

{.compile(toncPath & "/asm/tonc_bios.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_bios_ex.s", toncAsmFlags).}

type
  ResetFlag* = enum
    rsEwram      ## Clear 256K on-board RAM.
    rsIwram      ## Clear 32K in-chip RAM, except for the last 0x200 bytes
    rsPalettes   ## Clear palettes
    rsVram       ## Clear VRAM
    rsOam        ## Clear OAM (does not disable OBJs!)
    rsSio        ## Reset serial registers (switches to general purpose mode)
    rsSound      ## Reset sound registers
    rsRegisters  ## Reset all other registers
  
  ResetFlags* {.size:4.} = set[ResetFlag]
    ## A bitset of flags to be passed to `RegisterRamReset`
  
  CpuSetMode* = enum
    csmCopy   ## Copy data
    csmFill   ## Fill data (source pointer remains fixed)
  
  CpuSetStride* = enum
    cssHalfwords  ## Copy/fill by 2 bytes at a time
    cssWords      ## Copy/fill by 4 bytes at a time
  
  CpuSetOptions* {.bycopy.} = object
    count* {.bitsize:24.}: uint          ## Number of words/halfwords to process.
    mode* {.bitsize:2.}: CpuSetMode      ## Whether to copy or fill.
    stride* {.bitsize:2.}: CpuSetStride  ## Whether to step by words or halfwords.
  
  CpuFastSetOptions* {.bycopy.} = object
    count* {.bitsize:24.}: uint       ## Number of words, rounded up to nearest multiple of 8 words.
    mode* {.bitsize:1.}: CpuSetMode   ## Whether to copy or fill.
  

# Decompression-related constants
# TODO: wrap these up into a "header" struct or similar?
# const
#   LzType* = 0x00000010
#   LzSizeMask* = 0xFFFFFF00
#   LzSizeShift* = 8
#   HufBppMask* = 0x0000000F
#   HufType* = 0x00000020
#   HufSizeMask* = 0xFFFFFF00
#   HufSizeShift* = 8
#   RlType* = 0x00000030
#   RlSizeMask* = 0xFFFFFF00
#   RlSizeShift* = 8
#   Diff8* = 0x00000001
#   Diff16* = 0x00000002
#   DiffType* = 0x00000080
#   DifSizeMask* = 0xFFFFFF00
#   DifSizeShift* = 8

type
  BitUnpackOptions* {.byref.} = object
    srcLen*: uint16  ## Source length (bytes)
    srcBpp*: uint8   ## Source bitdepth (1,2,4,8)
    dstBpp*: uint8   ## Destination bitdepth (1,2,4,8,16,32)
    dstOffset* {.bitsize:31.}: uint  ## Value added to all non-zero elements.
    incZeros* {.bitsize:1.}: bool    ## If true, `dstOffset` will also be added to zero elements.
  
  MultibootOptions* {.byref.} = object
    reserved1*: array[5, uint32]
    handshakeData*: uint8
    padding*: uint8
    handshakeTimeout*: uint16
    probeCount*: uint8
    clientData*: array[3, uint8]
    paletteData*: uint8
    responseBit*: uint8
    clientBit*: uint8
    reserved2*: uint8
    bootSrcp*: ptr uint8
    bootEndp*: ptr uint8
    masterp*: ptr uint8
    reserved3*: array[3, ptr uint8]
    systemWork2*: array[4, uint32]
    sendflag*: uint8
    probeTargetBit*: uint8
    checkWait*: uint8
    serverType*: uint8
  
  MultibootMode* = enum
    mbNormal = 0x00
    mbMulti = 0x01
    mbFast = 0x02



# BASIC BIOS ROUTINES
# -------------------

# Reset Functions

proc SoftReset*() {.importc, noreturn.}
  ## swi 0x00

proc RegisterRamReset*(flags: ResetFlags) {.importc.}
  ## swi 0x01

# Halt functions
# --------------

proc Halt*() {.importc.}
  ## swi 0x02

proc Stop*() {.importc.}
  ## swi 0x03

proc IntrWait*(flagClear: bool; irq: IrqIndex) {.importc.}
  ## swi 0x04

proc VBlankIntrWait*() {.importc.}
  ## Wait for the next VBlank (swi 0x05).
  ## 
  ## .. note:: Requires clearing of REG_IFBIOS bit 0 at the interrupt.
  ##    Tonc's master interrupt handler does this for you.


# Arithmetic
# ----------

proc Div*(num, den: int): int {.importc.}
  ## Basic integer division (swi 0x06).
  ## 
  ## **Parameters:**
  ## 
  ## num
  ##   Numerator.
  ## 
  ## den
  ##   Denominator.
  ## 
  ## Returns num / den
  ## 
  ## .. note:: Dividing by zero results in an infinite loop. Try `DivSafe <#DivSafe,int,int>`_ instead.

proc DivArm*(den, num: int): int {.importc.}
  ## Basic integer division, but with switched arguments (swi 0x07).
  ## 
  ## **Parameters:**
  ## 
  ## den
  ##   Denominator.
  ## 
  ## num
  ##   Numerator.
  ## 
  ## Returns `num / den`
  ## 
  ## .. note:: Dividing by 0 results in an infinite loop.

proc Sqrt*(num: uint): uint {.importc.}
  ## Integer Square root (swi 0x08).

proc ArcTan*(dydx: int16): int16 {.importc.}
  ## Arctangent of dy/dx. (swi 0x09)
  ## 
  ## Takes a 2.14 fixed-point value representing the steepness of the slope.
  ## 
  ## Returns an angle in the range `-0x4000..0x4000` (representing -𝜋/2 to 𝜋/2).
  ## 
  ## .. warning::
  ##    This gives completely wrong results for inputs outside the range `-0x2000..0x2000` (-1.0 to 1.0).
  ##    
  ##    As such, it can only *effectively* return angles in the range `-0x2000..0x2000` (-𝜋/4 to 𝜋/4).
  ##    
  ##    Consider using `ArcTan2` instead.
  ## 

proc ArcTan2*(x, y: int16): uint16 {.importc.}
  ## Full-circle arctangent of a coordinate pair (swi 0x0A).
  ## 
  ## ```
  ##           +Y
  ##            │  . (x,y)
  ##            │ ╱
  ##            │╱╮θ
  ## -X ────────┼──────── +X
  ##            │
  ##            │
  ##            │
  ##           -Y
  ## ```
  ## 
  ## This calculates the angle between the positive X axis and the point `(x, y)`.
  ## 
  ## The value returned is in the range `0x0000..0xffff` (0 to 2𝜋).
  ## 


# Memory copiers/fillers
# ----------------------

proc CpuSet*(src: pointer; dst: pointer; opts: CpuSetOptions) {.importc.}
  ## Transfer via CPU in word/halfword chunks.
  ## 
  ## The default mode is 16-bit copies.
  ## 
  ## When `opts.mode == cmFill` it will keep the source address constant, effectively
  ## performing fills instead of copies.
  ## 
  ## When `opts.stride == csWords` it will copy or fill in 32-bit steps instead.
  ## 
  ## **Parameters:**
  ##
  ## src
  ##   Source address.
  ## 
  ## dst
  ##   Destination address.
  ## 
  ## opts
  ##   Number of transfers, mode and stride.
  ## 
  ## .. note:: This basically does a straightforward loop-copy, and is not particularly fast.
  ##    
  ##    In fill-mode, the source is still an address, not a value.

proc CpuFastSet*(src: pointer; dst: pointer; opts: CpuFastSetOptions) {.importc.}
  ## A fast transfer via CPU in 32 byte chunks.
  ## 
  ## This uses ARM's ldmia/stmia instructions to copy 8 words at a time,
  ## making it rival DMA transfers in speed.
  ## 
  ## When `opts.mode == cmFill` it will keep the source address constant, effectively
  ## performing fills instead of copies.
  ## 
  ## **Parameters:**
  ##
  ## src
  ##   Source address. Must be word aligned.
  ## 
  ## dst
  ##   Destination address. Must be word aligned.
  ## 
  ## opts
  ##   Number of words to transfer, and mode.
  ## 
  ## .. note:: Both source and destination must be word aligned; the number of copies must be a multiple of 8.
  ##    
  ##    In fill-mode, the source is still an address, not a value.
  ##    
  ##    ``memcpy32``/``16`` and ``memset32``/``16`` basically do the same things, but safer. Use those instead.


proc BiosCheckSum*(): uint32 {.importc.}



# Rot/scale functions
# -------------------
#  These functions are misnomers, because ObjAffineSet is merely
#  a special case of / precursor to BgAffineSet. Results from either
#  can be used for both objs and bgs. Oh well.

const
  BgAffOffset* = 2    ## To be used with `ObjAffineSet` when the destination type is `BgAffineDest`.
  ObjAffOffset* = 8   ## To be used with `ObjAffineSet` when the destination type is `ObjAffineDest`.

proc ObjAffineSet*(src: ptr ObjAffineSource; dst: pointer; num: int; offset: int) {.importc.}
  ## Sets up a simple scale-then-rotate affine transformation (swi 0x0E).
  ## Uses a single `ObjAffineSource` struct to set up an array of affine
  ## matrices (either BG or Object) with a certain transformation. The
  ## matrix created is:
  ## 
  ## ```
  ## ┌───────────┬────────────┐
  ## | sx·cos(α) | -sx·sin(α) |
  ## ├───────────┼────────────┤
  ## | sy·sin(α) | sy·cos(α)  |
  ## └───────────┴────────────┘
  ## ```
  ## 
  ## **Parameters:**
  ##
  ## src
  ##   Array with scale and angle information.
  ## 
  ## dst
  ##   Array of affine matrices, starting at a `pa` element.
  ## 
  ## num
  ##   Number of matrices to set.
  ## 
  ## offset
  ##   Offset between affine elements. Use 2 for BG and 8 for object matrices.
  ## 
  ## .. note::
  ##   Each element in `src` needs to be word aligned, which
  ##   devkitPro doesn't do anymore by itself.

proc BgAffineSet*(src: ptr BgAffineSource; dst: ptr BgAffineDest; num: int) {.importc.}
  ## Sets up a simple scale-then-rotate affine transformation (swi 0x0F).
  ## See `ObjAffineSet` for more information.


# Decompression
# -------------
# (see GBATek for format details)

proc BitUnPack*(src: pointer; dst: pointer; bup: BitUnpackOptions) {.importc.}
  ## swi 0x10 +

proc LZ77UnCompWram*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x11 +

proc LZ77UnCompVram*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x12 +

proc HuffUnComp*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x13 +

proc RLUnCompWram*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x14

proc RLUnCompVram*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x15 +

proc Diff8bitUnFilterWram*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x16

proc Diff8bitUnFilterVram*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x17

proc Diff16bitUnFilter*(src: pointer; dst: pointer) {.importc.}
  ## swi 0x18


# Sound
# -----

proc SoundBias*(bias: uint32) {.importc.}
  ## swi 0x19

proc SoundDriverInit*(src: pointer) {.importc.}
  ## swi 0x1A

proc SoundDriverMode*(mode: uint32) {.importc.}
  ## swi 0x1B

proc SoundDriverMain*() {.importc.}
  ## swi 0x1C

proc SoundDriverVSync*() {.importc.}
  ## swi 0x1D

proc SoundChannelClear*() {.importc.}
  ## swi 0x1E

proc MidiKey2Freq*(wa: pointer; mk: uint8; fp: uint8): uint32 {.importc.}
  ## swi 0x1F

# TODO:
# swi 0x20: MusicPlayerOpen
# swi 0x21: MusicPlayerStart
# swi 0x22: MusicPlayerStop
# swi 0x23: MusicPlayerContinue
# swi 0x24: MusicPlayerFadeOut 

proc MultiBoot*(mb: MultibootOptions; mode: MultibootMode): int {.importc.}
  ## Multiboot handshake (swi 0x25)

# TODO:
# swi 0x26: HardReset

proc SoundDriverVSyncOff*() {.importc.}
  ## swi 0x28

proc SoundDriverVSyncOn*() {.importc.}
  ## swi 0x29



# EXTRA BIOS ROUTINES
# -------------------
# More BIOS functions.
# You can find these in swi_ex.s

proc VBlankIntrDelay*(count: uint) {.importc.}
  ## Wait for `count` frames

proc DivSafe*(num, den: int): int {.importc.}
  ## Divide-by-zero safe division.
  ## 
  ## The standard `Div <#Div,int,int>`_ hangs when `den == 0`. This version will return `int.high` or `int.low`,
  ## depending on the sign of `num`.
  ## 
  ## **Parameters:**
  ## 
  ## num
  ##   Numerator.
  ## 
  ## den
  ##   Denominator.
  ## 
  ## Returns `num / den`

proc Mod*(num, den: int): int {.importc.}
  ## Modulo: `num % den`.

proc DivMod*(num, den: int): int {.importc.}
  ## Modulo: `num % den`.

proc DivAbs*(num, den: int): uint {.importc.}
  ## Absolute value of `num / den`

proc DivArmMod*(den, num: int): int {.importc.}
  ## Modulo: `num % den`.

proc DivArmAbs*(den, num: int): uint {.importc.}
  ## Absolute value of `num / den`

proc CpuFastFill*(wd: uint32; dst: pointer; words: uint) {.importc.}
  ## A fast word fill.
  ## 
  ## While you can perform fills with `CpuFastSet()`, the fact that
  ## swi 0x01 requires a source address makes it awkward to use.
  ## This function is more like the traditional memset formulation.
  ## 
  ## **Parameters:**
  ## 
  ## wd
  ##   Fill word.
  ## 
  ## dst
  ##   Destination address.
  ## 
  ## words
  ##   Number of words to transfer
