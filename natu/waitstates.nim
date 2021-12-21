## 
## This module exposes the `waitcnt <#waitcnt_2>`_ register, which controls the number of
## CPU cycles taken to access cart memory (ROM and SRAM).
## 
## The "standard" setting (used by most commercial games) is as follows:
## 
## .. code-block:: nim
##   waitcnt.init(
##     sram = wss_8,      # 8 cycles to access SRAM.
##     rom0 = ws0_n3s1,   # 3 cycles to access ROM, or 1 cycle for sequential access.
##     rom2 = ws2_n8s8,   # 8 cycles to access ROM (mirror #2) which may be used for flash storage.
##     prefetch = true    # prefetch buffer enabled.
##   )
## 
## In this example, `waitcnt.rom0` determines the access time for the default view into ROM.
## 
## The preferred access time of "3,1" works on every flashcart *except* for
## the SuperCard SD and its derivatives. If you want to support the SuperCard
## without compromising performance for all, you can try something like this:
## 
## .. code-block:: nim
##   if slowGamePak():
##     waitcnt.init(rom0 = ws0_n4s2)
##   else:
##     waitcnt.init(rom0 = ws0_n3s1)
## 
## There are two additional ROM mirrors located at `0x0A000000` and `0x0C000000`,
## which have access times determined by `waitcnt.rom1` and `waitcnt.rom2`.
## 
## The mirrors may be useful for carts containing multiple ROM chips. For example
## on some carts the upper 128KiB of ROM is mapped to flash storage which would
## require different access timings.

import ./core
import ./private/utils
import std/volatile

type
  WsSram* = enum
    ## SRAM access timings
    wss_4  ## SRAM access takes 4 cycles
    wss_3  ## SRAM access takes 3 cycles
    wss_2  ## SRAM access takes 2 cycles
    wss_8  ## SRAM access takes 8 cycles
  
  WsRom0* = enum
    ## ROM access timings.
    ## 
    ## Initial access to ROM takes `n` cycles, sequential access takes `s` cycles.
    ws0_n4s2
    ws0_n3s2
    ws0_n2s2
    ws0_n8s2
    ws0_n4s1
    ws0_n3s1
    ws0_n2s1
    ws0_n8s1
  
  WsRom1* = enum
    ## Access timings for ROM mirror starting at `0x0A000000`.
    ws1_n4s4
    ws1_n3s4
    ws1_n2s4
    ws1_n8s4
    ws1_n4s1
    ws1_n3s1
    ws1_n2s1
    ws1_n8s1
  
  WsRom2* = enum
    ## Access timings for ROM mirror starting at `0x0C000000`.
    ws2_n4s8
    ws2_n3s8
    ws2_n2s8
    ws2_n8s8
    ws2_n4s1
    ws2_n3s1
    ws2_n2s1
    ws2_n8s1
  
  WsPhi* = enum
    ## PHI Terminal Output
    wsPhiOff    ## Disabled (recommended because I have no idea what this is)
    wsPhi4MHz   ## 4.19MHz 
    wsPhi8MHz   ## 8.38MHz
    wsPhi17MHz  ## 16.78MHz
  
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

template init*(r: WaitCnt, args: varargs[untyped]) =
  var tmp: WaitCnt
  writeFields(tmp, args)
  r = tmp

template edit*(r: WaitCnt, args: varargs[untyped]) =
  var tmp = r
  writeFields(tmp, args)
  r = tmp


let data = [305419896'u32, 270441'u32, 3735928559'u32]  # Some arbitrary data in ROM.

proc slowGamePak*: bool {.codegenDecl:EWRAM_CODE.} =
  ## Check if the cartridge does not support fast ROM access, which might
  ## be the case if the game is running on the SuperCard MiniSD.
  
  let old = waitcnt
  var a, b, c: array[3, uint32]
  
  # Read forwards with slow access:
  waitcnt.init(rom0 = ws0_n4s2)
  for i in countup(0,2):
    a[i] = volatileLoad(unsafeAddr data[i])
  
  # Read forwards with fast access:
  waitcnt.init(rom0 = ws0_n3s1)
  for i in countup(0,2):
    b[i] = volatileLoad(unsafeAddr data[i])
  
  # Read backwards with fast access:
  waitcnt.init(rom0 = ws0_n3s1)
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
