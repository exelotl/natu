## 
## 

import ./private/[memmap, privutils]
import std/volatile

# To be used with codegenDecl pragma:
const
  IWRAM_DATA* = "__attribute__((section(\".iwram\"))) $# $#"    ## Put variable in IWRAM (default).
  EWRAM_DATA* = "__attribute__((section(\".ewram\"))) $# $#"    ## Put variable in EWRAM.
  EWRAM_BSS* = "__attribute__((section(\".sbss\"))) $# $#"      ## Put non-initialized variable in EWRAM.
  IWRAM_CODE* = "__attribute__((section(\".iwram\"), target(\"arm\"), long_call)) $# $#$#"  ## Put procedure in IWRAM.
  EWRAM_CODE* = "__attribute__((section(\".ewram\"), long_call)) $# $#$#"  ## Put procedure in EWRAM.

# Newer alternatives:
const
  DataInIwram* = "__attribute__((section(\".data\"))) $# $#"    ## Put variable in IWRAM (default).
  DataInEwram* = "__attribute__((section(\".sbss\"))) $# $#"    ## Put variable in EWRAM
  ArmCodeInIwram* = "__attribute__((section(\".iwram\"), target(\"arm\"), long_call)) $# $#$#"      ## Put procedure in IWRAM.
  ThumbCodeInEwram* = "__attribute__((section(\".ewram\"), target(\"thumb\"), long_call)) $# $#$#"  ## Put procedure in EWRAM.

# ROM
export romMem

# SRAM
export sramMem


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


var waitcnt* {.importc:"(*(volatile WaitCnt*)(0x04000204))", nodecl.}: WaitCnt
  ## Waitstate control register.
  ## 
  ## This controls the number of CPU cycles taken to access cart memory (ROM and SRAM).
  ## 
  ## The "standard" setting (used by most commercial games) is as follows:
  ## 
  ## .. code-block:: nim
  ## 
  ##   waitcnt.init(
  ##     sram = WsSram.N8_S8,   # 8 cycles to access SRAM.
  ##     rom0 = WsRom0.N3_S1,   # 3 cycles to access ROM, or 1 cycle for sequential access.
  ##     rom2 = WsRom2.N8_S8,   # 8 cycles to access ROM (mirror #2) which may be used for flash storage.
  ##     prefetch = true        # prefetch buffer enabled.
  ##   )
  ## 
  ## In this example, `waitcnt.rom0` determines the access time for the default view into ROM.
  ## 
  ## .. warning::
  ##   The preferred access time of "3,1" works on every flashcart *except* for
  ##   the SuperCard SD and its derivatives. If you want to support the SuperCard
  ##   without compromising performance for all, use the `slowGamePak`_ proc.
  ## 
  ## There are two additional ROM mirrors located at `0x0A000000` and `0x0C000000`,
  ## which have access times determined by `waitcnt.rom1` and `waitcnt.rom2`.
  ## 
  ## The mirrors may be useful for carts containing multiple ROM chips. For example
  ## on some carts the upper 128KiB of ROM is mapped to flash storage which would
  ## require different access timings.

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
