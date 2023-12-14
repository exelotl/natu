## 
## 

import ./private/[memmap, privutils, common]
import std/volatile

when (NimMajor, NimMinor) >= (1, 6):
  {.experimental: "overloadableEnums".}
  {.pragma: overloadable.}
else:
  {.pragma: overloadable, pure.}


# ROM
export romMem

# SRAM
export sramMem


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
    ## 
    ## For more information on `N` cycles and `S` cycles, see the `asm chapter
    ## <https://www.coranac.com/tonc/text/asm.htm#ssec-misc-cycles>`_ of Tonc.
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
  
  WaitCnt* {.bycopy, exportc.} = object
    ## Waitstate control
    sram* {.bitsize:2.}: WsSram   ## SRAM access time
    rom0* {.bitsize:3.}: WsRom0   ## ROM access time
    rom1* {.bitsize:3.}: WsRom1   ## ROM access time (alt. #1)
    rom2* {.bitsize:3.}: WsRom2   ## ROM access time (alt. #2)
    phi* {.bitsize:2.}: WsPhi
    unused {.bitsize:1.}: bool
    prefetch* {.bitsize:1.}: bool ## Prefetch buffer enabled.
    gb {.bitsize:1.}: bool


# Platform specific code
# ----------------------

when natuPlatform == "gba": include ./private/gba/memory 
elif natuPlatform == "sdl": include ./private/sdl/memory
else: {.error: "Unknown platform " & natuPlatform.}



template init*(r: WaitCnt, args: varargs[untyped]) =
  var tmp: WaitCnt
  writeFields(tmp, args)
  r = tmp

template edit*(r: WaitCnt, args: varargs[untyped]) =
  var tmp = r
  writeFields(tmp, args)
  r = tmp


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
