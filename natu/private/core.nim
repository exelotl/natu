# Tonc core functionality
# =======================

import common
import types

{.compile(toncPath & "/src/tonc_core.c", toncCFlags).}
{.compile(toncPath & "/asm/tonc_memcpy.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_memset.s", toncAsmFlags).}
# {.compile(toncPath & "/asm/tonc_nocash.s", toncAsmFlags).}  # Natu doesn't do nocash debugging yet.

{.pragma: tonc, header: "tonc_core.h".}
{.pragma: toncinl, header: "tonc_core.h".}  # indicates that the definition is in the header.

# Data
# ----

proc tonccpy*(dst: pointer; src: pointer; size: SomeInteger): pointer {.importc: "tonccpy", tonc, discardable.}
  ## VRAM-safe copy.
  ## This version mimics memcpy in functionality, with the benefit of working for VRAM as well. It is also 
  ## slightly faster than the original memcpy, but faster implementations can be made.
  ## `dst`  Destination pointer.
  ## `src`  Source pointer.
  ## `size` Fill-length in bytes.
  ## Returns `dst`
  ## Note: The pointers and size need not be word-aligned.

proc toncset*(dst: pointer, src: uint8, size: SomeInteger): pointer {.importc: "toncset", toncinl, discardable.}
  ## VRAM-safe memset, byte version. Size in bytes.

proc toncset16*(dst: pointer, src: uint16, size: SomeInteger): pointer {.importc: "toncset16", toncinl, discardable.}
  ## VRAM-safe memset, halfword version. Size in hwords.

proc toncset32*(dst: pointer, src: uint32, size: SomeInteger): pointer {.importc: "toncset32", toncinl, discardable.}
  ## VRAM-safe memset, word version. Size in words.

proc memset16*(dst: pointer, hw: uint16, hwcount: SomeInteger) {.importc: "memset16", tonc.}
  ## Fastfill for halfwords, analogous to memset()
  ## Uses `memset32()` if `hwcount>5`
  ## `dst`     Destination address.
  ## `hw`      Source halfword (not address).
  ## `hwcount` Number of halfwords to fill.
  ## Note: `dst` *must* be halfword aligned.
  ## Note: `r0` returns as `dst + hwcount*2`.

proc memcpy16*(dst: pointer, src: pointer, hwcount: SomeInteger) {.importc: "memcpy16", tonc.}
  ## Copy for halfwords.
  ## Uses `memcpy32()` if `hwn > 6` and `src` and `dst` are aligned equally.
  ## `dst`     Destination address.
  ## `src`     Source address.
  ## `hwcount` Number of halfwords to fill.
  ## Note: `dst` and `src` *must* be halfword aligned.
  ## Note: `r0` and `r1` return as `dst + hwcount*2` and `src + hwcount*2`.

proc memset32*(dst: pointer, wd: uint32, wcount: SomeInteger) {.importc: "memset32", tonc.}
  ## Fast-fill by words, analogous to memset()
  ## Like CpuFastSet(), only without the requirement of 32byte chunks and no awkward store-value-in-memory-first issue.
  ## `dst`     Destination address.
  ## `wd`      Fill word (not address).
  ## `wdcount` Number of words to fill.
  ## Note: `dst` *must* be word aligned.
  ## Note: `r0` returns as `dst + wdcount*4`.

proc memcpy32*(dst: pointer, src: pointer, wcount: SomeInteger) {.importc: "memcpy32", tonc.}
  ## Fast-copy by words.
  ## Like CpuFastFill(), only without the requirement of 32byte chunks
  ## `dst`     Destination address.
  ## `src`     Source address.
  ## `wdcount` Number of words.
  ## Note: `src` and `dst` *must* be word aligned.
  ## Note: `r0` and `r1` return as `dst + wdcount*4` and `src + wdcount*4`.


# Repeated-value creators
# -----------------------
# These take a hex-value and duplicate it to all fields, like 0x88 -> 0x88888888.

template dup8*(x: uint8): uint16 =
  ## Duplicate a byte to form a halfword: 0x12 -> 0x1212.
  x or (x shl 8)

template dup16*(x: uint16): uint32 =
  ## Duplicate a halfword to form a word: 0x1234 -> 0x12341234.
  x or (x shl 16)

template quad8*(x: uint8): uint32 =
  ## Quadruple a byte to form a word: 0x12 -> 0x12121212.
  x * 0x01010101

template octup*(x: uint8): uint32 =
  ## Octuple a nybble to form a word: 0x1 -> 0x11111111
  x * 0x11111111

# Bit packing
# -----------

template bytes2hword*(b0, b1: uint8): uint16 =
  ## Pack 2 bytes into a word. Little-endian order.
  b0 or b1 shl 8

template bytes2word*(b0, b1, b2, b3: uint8): uint32 =
  ## Pack 4 bytes into a word. Little-endian order.
  b0 or b1 shl 8 or b2 shl 16 or b3 shl 24
  
template hword2word*(h0, h1: uint16): uint32 =
  ## Pack 2 halfwords into a word. Little-endian order.
  h0 or h1 shl 16

# DMA
# ---

proc dmaCpy*(dst: pointer; src: pointer; count: SomeInteger; ch: uint; mode: uint32) {.importc: "dma_cpy", toncinl.}
  ## Generic DMA copy routine.
  ## `dst`   Destination address.
  ## `src`   Source address.
  ## `count` Number of copies to perform.
  ## `ch`    DMA channel.
  ## `mode`  DMA transfer mode.
  ## Note: `count` is the number of copies, not the size in bytes.

proc dmaFill*(dst: pointer; src: uint32; count: SomeInteger; ch: uint; mode: uint32) {.importc: "dma_fill", toncinl.}
  ## Generic DMA fill routine.
  ## `dst`   Destination address.
  ## `src`   Source value.
  ## `count` Number of copies to perform.
  ## `ch`    DMA channel.
  ## `mode`  DMA transfer mode.
  ## Note: `count` is the number of copies, not the size in bytes.
  
proc dma3Cpy*(dst: pointer; src: pointer; size: SomeInteger) {.importc: "dma3_cpy", toncinl.}
  ## Specific DMA copier, using channel 3, word transfers.
  ## `dst`  Destination address.
  ## `src`  Source address.
  ## `size` Number of bytes to copy
  ## Note: `size` is the number of bytes

proc dma3Fill*(dst: pointer; src: uint32; size: SomeInteger) {.importc: "dma3_fill", toncinl.}
  ## Specific DMA filler, using channel 3, word transfers.
  ## `dst`  Destination address.
  ## `src`  Source value.
  ## `size` Number of bytes to copy
  ## Note: `size` is the number of bytes


# Timer
# -----

proc profileStart*() {.importc: "profile_start", toncinl.}
  ## Start a profiling run.
  ## 
  ## .. note::
  ##    Routine uses timers 2 and 3; if you're already using these somewhere, chaos is going to ensue.

proc profileStop*(): uint {.importc: "profile_stop", toncinl.}
  ## Stop a profiling run and return the time since its start.
  ## 
  ## Returns number of CPU cycles elapsed since `profileStart` was called.


# TODO, accept string literal, output assembly?
# proc ASM_CMT*(str:string)

proc asmBreak*() {.importc: "ASM_BREAK", toncinl.}
  ## No$gba breakpoint

proc asmNop*() {.importc: "ASM_NOP", toncinl.}
  ## No-op; wait a bit.

proc sndRate*(note, oct: int32) {.importc: "SND_RATE", toncinl.}
  ## Gives the period of a note for the tone-gen registers.
  ## GBA sound range: 8 octaves: ``-2..5``; ``8*12`` = 96 notes (kinda).
  ## `note` ID (range: ``0 ..< 11``). See eSndNoteId.
  ## `oct`  octave (range ``-2 ..< 4``).


# Sector checking
# ---------------

proc octant*(x, y: int): uint {.importc: "octant", tonc.}
  ## Get the octant that (`x`, `y`) is in.
  ## This function divides the circle in 8 parts. The angle starts at the `y=0` line and then moves in the direction
  ## of the `x=0` line. On the screen, this would be like starting at the 3 o'clock position and moving clockwise.

proc octantRot*(x0, y0: int): uint {.importc: "octant_rot", tonc.}
  ## Get the rotated octant that (`x`, `y`) is in.
  ## Like `octant()` but with a twist. The 0-octant starts 22.5° earlier so that 3 o'clock falls in the middle of 
  ## octant 0, instead of at its start. This can be useful for 8 directional pointing.

# Globals
# -------

let oamSizes* {.importc: "oam_sizes", tonc.}: array[3, array[4, array[2, uint8]]]
let bgAffDefault* {.importc: "bg_aff_default", tonc.}: BgAffine
var vidPage* {.importc: "vid_page", tonc.}: ptr Color

# Random
# ------

const
  QRAN_SHIFT* = 15
  QRAN_MASK* = ((1 shl QRAN_SHIFT) - 1)
  QRAN_MAX* = QRAN_MASK

var qranSeed* {.importc: "__qran_seed", tonc.}: int
  ## Current state of the random number generator. 
  
proc sqran*(seed: int): int {.importc: "sqran", tonc.}
  ## Seed the random number generator.
  ## Returns the old seed.
  
proc qran*(): int {.importc: "qran", toncinl.}
  ## Quick (and very dirty) pseudo-random number generator.
  ## Returns: random in range ``0x0000 ..< 0x8000``
  
proc qranRange*(min: int; max: int): int {.importc: "qran_range", toncinl.}
  ## Returns a random number in range ``min ..< max``
  ## Note: ``(max-min)`` must be lower than ``0x8000``

# Compile-time utils
# ------------------

template readBin*(path: static string): untyped =
  ## 
  ## Read a binary file at compile-time as an array of bytes.
  ## 
  ## If assigned to a top-level `let` variable, this data will be placed in ROM.
  ## 
  ## e.g.
  ## 
  ## .. code-block:: nim
  ##   
  ##   let shipPal = readBin("ship.pal.bin")
  ## 
  const data = static:
    const str = staticRead(path)
    var arr: array[str.len, byte]
    for i, c in str:
      arr[i] = c.byte
    arr
  data
