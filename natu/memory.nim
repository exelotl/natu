import ./private/[memmap, privutils, common]
import ./bits
import std/volatile


when (NimMajor, NimMinor) >= (1, 6):
  {.experimental: "overloadableEnums".}
  {.pragma: overloadable.}
else:
  {.pragma: overloadable, pure.}

type
  WsSram* {.overloadable.} = enum
    ## SRAM access timings
    N4_S4  ## SRAM access takes 4 cycles
    N3_S3  ## SRAM access takes 3 cycles
    N2_S2  ## SRAM access takes 2 cycles
    N8_S8  ## SRAM access takes 8 cycles
  
  WsRom0* {.overloadable.} = enum
    ## ROM access timings.
    ## 
    ## Initial access to ROM takes `N` cycles, sequential access takes `S` cycles.
    ## 
    ## For more information on `N` cycles and `S` cycles, see the `asm chapter
    ## <https://gbadev.net/tonc/asm.html#ssec-misc-cycles>`_ of Tonc.
    ## 
    N4_S2
    N3_S2
    N2_S2
    N8_S2
    N4_S1
    N3_S1
    N2_S1
    N8_S1
  
  WsRom1* {.overloadable.} = enum
    ## Access timings for ROM mirror starting at `0x0A000000`.
    N4_S4
    N3_S4
    N2_S4
    N8_S4
    N4_S1
    N3_S1
    N2_S1
    N8_S1
  
  WsRom2* {.overloadable.} = enum
    ## Access timings for ROM mirror starting at `0x0C000000`.
    N4_S8
    N3_S8
    N2_S8
    N8_S8
    N4_S1
    N3_S1
    N2_S1
    N8_S1
  
  WsPhi* = enum
    ## PHI Terminal Output. This allows the GBA to supply a clock signal to the
    ## cartridge hardware, but is not used in practise.
    phiOff    ## Disabled (recommended)
    phi4MHz   ## 4.19MHz 
    phi8MHz   ## 8.38MHz
    phi17MHz  ## 16.78MHz
  
  WaitCnt* = distinct uint16
    ## ========== ============== ====== ==================================================
    ## Field      Type           Bits   Description
    ## ========== ============== ====== ==================================================
    ## `sram`     :xref:`WsSram` 0-1    SRAM access time.
    ## `rom0`     :xref:`WsRom0` 2-4    ROM mirror 0 access time.
    ## `rom1`     :xref:`WsRom1` 5-7    ROM mirror 1 access time.
    ## `rom2`     :xref:`WsRom2` 8-10   ROM mirror 2 access time.
    ## `phi`      :xref:`WsPhi`  11-12  Cart clock (don't touch!)
    ## `prefetch` bool           14     Game Pak prefetch. If enabled, the GBA's `prefetch unit <https://mgba.io/2015/06/27/cycle-counting-prefetch/#game-pak-prefetch>`__
    ##                                  will fetch upcoming instructions from ROM, when ROM is not being accessed by the CPU, generally leading to a performance boost.
    ## `gb`       bool           15     True if a Game Boy (Color) cartridge is currently inserted. (Read only!)
    ## ========== ============== ====== ==================================================

bitdef WaitCnt, 0..1, sram, WsSram
bitdef WaitCnt, 2..4, rom0, WsRom0
bitdef WaitCnt, 5..7, rom1, WsRom1
bitdef WaitCnt, 8..10, rom2, WsRom2
bitdef WaitCnt, 11..12, phi, WsPhi
bitdef WaitCnt, 14, prefetch, bool
bitdef WaitCnt, 15, gb, bool, { ReadOnly }


template init*(r: WaitCnt, args: varargs[untyped]) =
  var tmp: WaitCnt
  writeFields(tmp, args)
  r = tmp

template edit*(r: WaitCnt, args: varargs[untyped]) =
  var tmp = r
  writeFields(tmp, args)
  r = tmp


# Direct Memory Access
# --------------------

type
  DmaDstMode* {.overloadable.} = enum
    Inc     ## Increment after each copy.
    Dec     ## Decrement after each copy.
    Fix     ## Remain unchanged.
    Reload  ## Like `Inc` but resets to its initial value after all transfers have been completed.
  DmaSrcMode* {.overloadable.} = enum
    Inc     ## Increment after each copy.
    Dec     ## Decrement after each copy.
    Fix     ## Remain unchanged.
  DmaSize* {.overloadable.} = enum
    Halfwords  ## Copy 16 bits.
    Words      ## Copy 32 bits.
  DmaTime* {.overloadable.} = enum
    AtNow      ## Transfer immediately.
    AtVBlank   ## Transfer on VBlank.
    AtHBlank   ## Transfer on HBlank. Note: HBlank DMA does not occur during VBlank (unlike HBlank interrupts).
    AtSpecial  ## Channels 0/1: start on FIFO empty. Channel 2: start on VCount = 2
  
  DmaCnt* = distinct uint16
    ## DMA control register. (Write only!)
    ## 
    ## ========== ============== ======= ==================================================
    ## Field      Type           Bits    Description
    ## ========== ============== ======= ==================================================
    ## `dstMode`  DmaDstMode     5..6    Type of increment applied to destination address.
    ## `srcMode`  DmaSrcMode     7..8    Type of increment applied to source address.
    ## `repeat`   bool           9       Repeat the transfer for each occurrence specified by `time`.
    ## `size`     DmaSize        10      Whether to transfer 16 or 32 bits at a time.
    ## `time`     DmaTime        12..13  Timing mode, determines when the transfer should occur.
    ## `irq`      bool           14      If true, an interrupt will be raised when finished.
    ## `enable`   bool           15      Enable DMA transfer for this channel. (Invoking `start() <#start>`__ will do this for you.)
    ## ========== ============== ======= ==================================================
  
  DmaChannel* {.bycopy, exportc.} = object
    ## A group of registers for a single DMA channel.
    src*: pointer    ## Source address.
    dst*: pointer    ## Destination address.
    count*: uint16   ## Number of transfers.
    cnt*: DmaCnt     ## DMA control register. (Write only!)

bitdef DmaCnt, 5..6, dstMode, DmaDstMode, {WriteOnly}
bitdef DmaCnt, 7..8, srcMode, DmaSrcMode, {WriteOnly}
bitdef DmaCnt, 9, repeat, bool, {WriteOnly}
bitdef DmaCnt, 10, size, DmaSize, {WriteOnly}
bitdef DmaCnt, 12..13, time, DmaTime, {WriteOnly}
bitdef DmaCnt, 14, irq, bool, {WriteOnly}
bitdef DmaCnt, 15, enable, bool, {WriteOnly}

template `dstMode=`*(d: DmaChannel; val: DmaDstMode) = d.cnt.dstMode = val
template `srcMode=`*(d: DmaChannel; val: DmaSrcMode) = d.cnt.srcMode = val
template `repeat=`*(d: DmaChannel; val: bool) = d.cnt.repeat = val
template `size=`*(d: DmaChannel; val: DmaSize) = d.cnt.size = val
template `time=`*(d: DmaChannel; val: DmaTime) = d.cnt.time = val
template `irq=`*(d: DmaChannel; val: bool) = d.cnt.irq = val
template `enable=`*(d: DmaChannel; val: bool) = d.cnt.enable = val


# Platform specific code
# ----------------------

when natuPlatform == "gba": include ./private/gba/memory 
elif natuPlatform == "sdl": include ./private/sdl/memory
else: {.error: "Unknown platform " & natuPlatform.}


let data = [305419896'u32, 270441'u32, 3735928559'u32]  # Some arbitrary data in ROM.

proc slowGamePak*: bool {.codegenDecl:ThumbCodeInEwram.} =
  ## Check if the cartridge does not support fast ROM access, which might
  ## be the case if the game is running on the SuperCard MiniSD.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   if slowGamePak():
  ##     waitcnt.init(rom0 = WsRom0.N4_S2)
  ##   else:
  ##     waitcnt.init(rom0 = WsRom0.N3_S1)
  
  let old = waitcnt
  var a, b, c: array[3, uint32]
  
  # Read forwards with slow access:
  waitcnt.init(rom0 = WsRom0.N4_S2)
  for i in countup(0,2):
    a[i] = volatileLoad(unsafeAddr data[i])
  
  # Read forwards with fast access:
  waitcnt.init(rom0 = WsRom0.N3_S1)
  for i in countup(0,2):
    b[i] = volatileLoad(unsafeAddr data[i])
  
  # Read backwards with fast access:
  waitcnt.init(rom0 = WsRom0.N3_S1)
  for i in countdown(2,0):
    c[i] = volatileLoad(unsafeAddr data[i])
  
  # Restore state
  waitcnt = old
  
  result = not (
    a[0] == b[0] and
    a[1] == b[1] and
    a[2] == b[2] and
    a[0] == c[0] and
    a[1] == c[1] and
    a[2] == c[2]
  )
