
const
  DataInIwram* = "__attribute__((section(\".iwram.data\"))) $# $#"    ## Put variable in IWRAM (default).
  DataInEwram* = "__attribute__((section(\".ewram.data\"))) $# $#"    ## Put variable in EWRAM
  ArmCodeInIwram* = "__attribute__((section(\".iwram.text\"), target(\"arm\"), long_call)) $# $#$#"      ## Put procedure in IWRAM.
  ThumbCodeInEwram* = "__attribute__((section(\".ewram.text\"), target(\"thumb\"), long_call)) $# $#$#"  ## Put procedure in EWRAM.

# ROM
export romMem

# SRAM
export sramMem

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
  ##   without compromising performance for all, use the :ref:`slowGamePak` proc.
  ## 
  ## There are two additional ROM mirrors located at `0x0A000000` and `0x0C000000`,
  ## which have access times determined by `waitcnt.rom1` and `waitcnt.rom2`.
  ## 
  ## The mirrors may be useful for carts containing multiple ROM chips. For example
  ## on some carts the upper 128KiB of ROM is mapped to flash storage which would
  ## require different access timings.