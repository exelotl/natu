import ./applib

const
  DataInIwram* = "$# $#"         ## Put variable in IWRAM (default).
  DataInEwram* = "$# $#"         ## Put variable in EWRAM
  ArmCodeInIwram* = "$# $#$#"    ## Put procedure in IWRAM.
  ThumbCodeInEwram* = "$# $#$#"  ## Put procedure in EWRAM.

var romMem*: array[1, uint16]
var sramMem*: array[0x10000, uint8]

template waitcnt*: WaitCnt = cast[ptr WaitCnt](addr natuMem.regs[0x204 shr 1])[]
