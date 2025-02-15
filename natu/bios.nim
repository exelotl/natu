## This module exposes the GBA system calls (aka. BIOS functions).
## 
## The function names are `PascalCase` as is the convention used by Tonc,
## GBATek and others, which also conveniently helps to avoid clashing with
## Nim's reserved keywords such as `div` and `mod`.
## 
## .. attention::
##   These aren't fully documented yet - please refer to
##   `GBATek <https://rust-console.github.io/gbatek-gbaonly/#biosfunctions>`_
##   in the meantime.

import ./private/[types, common]

from ./irq import IrqIndex
from ./math import FixedT
import ./bits

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


type 
  CpuSetOptions* = distinct uint32
  CpuFastSetOptions* = distinct uint32

bitdef CpuSetOptions, 0..20, count, uint32      # Number of words/halfwords to process.
bitdef CpuSetOptions, 24, mode, CpuSetMode      # Whether to copy or fill.
bitdef CpuSetOptions, 26, stride, CpuSetStride  # Whether to step by words or halfwords.

bitdef CpuFastSetOptions, 0..20, count, uint32  # Number of words, rounded up to nearest multiple of 8 words.
bitdef CpuFastSetOptions, 24, mode, CpuSetMode      # Whether to copy or fill.

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

when natuPlatform == "gba":
    
  type
    BitUnpackOptions* {.byref.} = object
      srcLen*: uint16  ## Source length (bytes)
      srcBpp*: uint8   ## Source bitdepth (1,2,4,8)
      dstBpp*: uint8   ## Destination bitdepth (1,2,4,8,16,32)
      dstOffset* {.bitsize:31.}: cuint ## Value added to all non-zero elements.
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
    
    MultibootMode* {.size: 4.} = enum
      mbNormal = 0x00
      mbMulti = 0x01
      mbFast = 0x02

else:
  
  # TODO: unify with above?
  type
    BitUnpackOptionsObj* {.importc: "BUP", header: "tonc_bios.h".} = object
    BitUnpackOptions* {.importc: "const BUP *", header: "tonc_bios.h".} = ptr BitUnpackOptionsObj
    MultibootOptionsObj* {.importc: "MultiBootParam", header: "tonc_bios.h".} = object
    MultibootOptions* = ptr MultibootOptionsObj
    MultibootMode* = uint32

# Annotation to indicate which software interrupt is used.
template swi(n: string) {.pragma.}

# Platform-specific pragma:
when natuPlatform == "gba": {.pragma: tonc, importc.}
elif natuPlatform == "sdl": {.pragma: tonc, importc.}

else: {.error: "Unknown platform " & natuPlatform.}


# Reset Functions
# ---------------

proc SoftReset*() {.swi:"0x00", tonc, noreturn.}

proc RegisterRamReset*(flags: ResetFlags) {.swi:"0x01", tonc.}
  ## Performs a selective reset of memory and I/O registers.
  ## 
  ## .. note::
  ##    This also enables the "forced blank" bit of the display control register
  ##    (:xref:`dispcnt.blank`), which will turn the screen white until you set
  ##    it to `false`.

# Halt functions
# --------------

proc Halt*() {.swi:"0x02", tonc.}
  ## Halts the CPU until any enabled interrupt occurs.

proc Stop*() {.swi:"0x03", tonc.}
  ## Stops the CPU and turns off the LCD until an enabled keypad, cartridge or serial interrupt occurs.

proc IntrWait*(clear: bool; irq: set[IrqIndex]) {.swi:"0x04", tonc.}
  ## Wait until any one of the specified interrupts occurs.
  ## 
  ## :clear:
  ##   If true, pre-acknowledged interrupts will be disregarded and the routine
  ##   will wait for them to be acknowledged again.
  ## 
  ## :irq:
  ##   Which interrupt(s) to wait for.

proc VBlankIntrWait*() {.swi:"0x05", tonc.}
  ## Wait for the next VBlank period.
  ## 
  ## This is equivalent to `IntrWait(true, {iiVBlank})`.
  ## 
  ## If the VBlank interrupt is not enabled, then this will hang.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##    
  ##    import natu/[irq, bios]
  ##    
  ##    irq.enable(iiVBlank)
  ##    
  ##    while true:
  ##      VBlankIntrWait()


# Arithmetic
# ----------

proc Div*(num, den: cint): cint {.swi:"0x06", tonc.}
  ## Basic integer division.
  ## 
  ## :num: Numerator.
  ## :den: Denominator.
  ## 
  ## Returns ``num / den``.
  ## 
  ## .. note:: Dividing by zero results in an infinite loop. Try :xref:`DivSafe` instead.

proc DivArm*(den, num: cint): cint {.swi:"0x07", tonc.}
  ## Basic integer division, but with switched arguments.
  ## 
  ## :den: Denominator.
  ## :num: Numerator.
  ## 
  ## Returns ``num / den``.
  ## 
  ## .. note:: Dividing by 0 results in an infinite loop.

proc Sqrt*(num: cuint): cuint {.swi:"0x08", tonc.}
  ## Integer Square root.

proc ArcTan*(dydx: FixedT[int16,14]): int16 {.swi:"0x09", tonc.}
  ## Arctangent of dy/dx.
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

proc ArcTan2*(x, y: int16): uint16 {.swi:"0x0A", tonc.}
  ## Full-circle arctangent of a coordinate pair.
  ## 
  ## .. code-block:: text
  ##   
  ##             +Y
  ##              │  . (x,y)
  ##              │ /
  ##              │/╮θ
  ##   -X ────────┼──────── +X
  ##              │
  ##              │
  ##              │
  ##             -Y
  ## 
  ## This calculates the angle between the positive X axis and the point `(x, y)`.
  ## 
  ## The value returned is in the range `0x0000..0xffff` (0 to 2𝜋).
  ## 
  ## .. warning::
  ##    In most mathematical libraries the parameters to atan2 are ordered as `y, x`, but here they're `x, y`.


# Memory copiers/fillers
# ----------------------

proc CpuSet*(src: pointer; dst: pointer; opts: CpuSetOptions) {.swi:"0x0B", tonc.}
  ## Transfer via CPU in word/halfword chunks.
  ## 
  ## The default mode is 16-bit copies.
  ## 
  ## When `opts.mode == cmFill` it will keep the source address constant, effectively
  ## performing fills instead of copies.
  ## 
  ## When `opts.stride == csWords` it will copy or fill in 32-bit steps instead.
  ## 
  ## :src:  Source address.
  ## :dst:  Destination address.
  ## :opts: Number of transfers, mode and stride.
  ## 
  ## .. note:: This basically does a straightforward loop-copy, and is not particularly fast.
  ##    
  ##    In fill-mode, the source is still an address, not a value.

proc CpuFastSet*(src: pointer; dst: pointer; opts: CpuFastSetOptions) {.swi:"0x0C", tonc.}
  ## A fast transfer via CPU in 32 byte chunks.
  ## 
  ## This uses ARM's ldmia/stmia instructions to copy 8 words at a time,
  ## making it rival DMA transfers in speed.
  ## 
  ## When `opts.mode == cmFill` it will keep the source address constant, effectively
  ## performing fills instead of copies.
  ## 
  ## :src:  Source address. Must be word aligned.
  ## :dst:  Destination address. Must be word aligned.
  ## :opts: Number of words to transfer, and mode.
  ## 
  ## .. note:: Both source and destination must be word aligned; the number of copies must be a multiple of 8.
  ##    
  ##    In fill-mode, the source is still an address, not a value.
  ##    
  ##    ``memcpy32``/``16`` and ``memset32``/``16`` basically do the same things, but safer. Use those instead.


proc BiosCheckSum*(): uint32 {.swi:"0x0D", tonc.}
  ## Calculate the checksum of the BIOS.
  ## 
  ## Returns:
  ## 
  ## * `0xbaae187f` for GBA / GBA SP / Game Boy Micro / Game Boy Player
  ## * `0xbaae1880` for DS / DS Lite / DSi / 3DS Family.


# Rot/scale functions
# -------------------
#  These functions are misnomers, because ObjAffineSet is merely
#  a special case of / precursor to BgAffineSet. Results from either
#  can be used for both objs and bgs. Oh well.

const
  BgAffOffset* = 2    ## To be used with `ObjAffineSet` when the destination type is `BgAffineDest`.
  ObjAffOffset* = 8   ## To be used with `ObjAffineSet` when the destination type is `ObjAffineDest`.

proc ObjAffineSet*(src: ptr ObjAffineSource; dst: pointer; num: cint; offset: cint) {.swi:"0x0E", tonc.}
  ## Sets up a simple scale-then-rotate affine transformation.
  ## Uses a single :xref:`ObjAffineSource` struct to set up an array of affine
  ## matrices (either BG or Object) with a certain transformation. The
  ## matrix created is::
  ## 
  ##   ┌───────────┬────────────┐
  ##   | sx·cos(α) | -sx·sin(α) |
  ##   ├───────────┼────────────┤
  ##   | sy·sin(α) | sy·cos(α)  |
  ##   └───────────┴────────────┘
  ## 
  ## :src:    Array with scale and angle information.
  ## :dst:    Array of affine matrices, starting at a `pa` element.
  ## :num:    Number of matrices to set.
  ## :offset: Offset between affine elements. Use 2 for BG and 8 for object matrices.
  ## 
  ## .. note::
  ##   Each element in `src` needs to be word aligned.

proc BgAffineSet*(src: ptr BgAffineSource; dst: ptr BgAffineDest; num: cint) {.swi:"0x0F", tonc.}
  ## Sets up a simple scale-then-rotate affine transformation.
  ## See `ObjAffineSet` for more information.


# Decompression
# -------------
# (see GBATek for format details)

proc BitUnPack*(src: pointer; dst: pointer; bup: BitUnpackOptions) {.swi:"0x10", tonc.}

proc LZ77UnCompWram*(src: pointer; dst: pointer) {.swi:"0x11", tonc.}

proc LZ77UnCompVram*(src: pointer; dst: pointer) {.swi:"0x12", tonc.}

proc HuffUnComp*(src: pointer; dst: pointer) {.swi:"0x13", tonc.}

proc RLUnCompWram*(src: pointer; dst: pointer) {.swi:"0x14", tonc.}

proc RLUnCompVram*(src: pointer; dst: pointer) {.swi:"0x15", tonc.}

proc Diff8bitUnFilterWram*(src: pointer; dst: pointer) {.swi:"0x16", tonc.}

proc Diff8bitUnFilterVram*(src: pointer; dst: pointer) {.swi:"0x17", tonc.}

proc Diff16bitUnFilter*(src: pointer; dst: pointer) {.swi:"0x18", tonc.}


# Sound
# -----

proc SoundBias*(bias: uint32) {.swi:"0x19", tonc.}

proc SoundDriverInit*(src: pointer) {.swi:"0x1A", tonc.}

proc SoundDriverMode*(mode: uint32) {.swi:"0x1B", tonc.}

proc SoundDriverMain*() {.swi:"0x1C", tonc.}

proc SoundDriverVSync*() {.swi:"0x1D", tonc.}

proc SoundChannelClear*() {.swi:"0x1E", tonc.}

proc MidiKey2Freq*(wa: pointer; mk: uint8; fp: uint8): uint32 {.swi:"0x1F", tonc.}

# TODO:
# swi 0x20: MusicPlayerOpen
# swi 0x21: MusicPlayerStart
# swi 0x22: MusicPlayerStop
# swi 0x23: MusicPlayerContinue
# swi 0x24: MusicPlayerFadeOut 

proc MultiBoot*(mb: MultibootOptions; mode: MultibootMode): cint {.swi:"0x25", tonc.}
  ## Multiboot handshake

proc HardReset*() {.swi:"0x26", tonc, noreturn.}
  ## Reboots the GBA, including playing through the GBA boot intro.

proc SoundDriverVSyncOff*() {.swi:"0x28", tonc.}

proc SoundDriverVSyncOn*() {.swi:"0x29", tonc.}



# EXTRA BIOS ROUTINES
# -------------------
# Additional utilities from Tonc which are built atop the BIOS routines.
# You can find these in ``tonc_bios_ex.s``

proc VBlankIntrDelay*(count: cuint) {.tonc.}
  ## Wait for `count` frames.

proc DivSafe*(num, den: cint): cint {.tonc.}
  ## Divide-by-zero safe division.
  ## 
  ## The standard :xref:`Div` hangs when `den == 0`. This version will return `cint.high` or `cint.low`,
  ## depending on the sign of `num`.
  ## 
  ## :num: Numerator.
  ## :den: Denominator.
  ## 
  ## Returns `num / den`.

proc Mod*(num, den: cint): cint {.tonc.}
  ## Modulo: `num % den`.

proc DivMod*(num, den: cint): cint {.tonc.}
  ## Modulo: `num % den`.

proc DivAbs*(num, den: cint): cuint {.tonc.}
  ## Absolute value of `num / den`.

proc DivArmMod*(den, num: cint): cint {.tonc.}
  ## Modulo: `num % den`.

proc DivArmAbs*(den, num: cint): cuint {.tonc.}
  ## Absolute value of `num / den`.

proc CpuFastFill*(wd: uint32; dst: pointer; words: cuint) {.tonc.}
  ## A fast word fill.
  ## 
  ## While you can perform fills with :xref:`CpuFastSet`, the fact that
  ## swi `0x01` requires a source address makes it awkward to use.
  ## This function is more like the traditional memset formulation.
  ## 
  ## :wd: Fill word.
  ## :dst: Destination address.
  ## :words: Number of words to transfer.


# Platform specific code
# ----------------------

when natuPlatform == "gba": include ./private/gba/bios 
elif natuPlatform == "sdl": import ./private/sdl/bios
else: {.error: "Unknown platform " & natuPlatform.}
