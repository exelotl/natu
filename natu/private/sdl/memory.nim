import ./applib

const
  DataInIwram* = "$# $#"         ## Put variable in IWRAM (default).
  DataInEwram* = "$# $#"         ## Put variable in EWRAM
  ArmCodeInIwram* = "$# $#$#"    ## Put procedure in IWRAM.
  ThumbCodeInEwram* = "$# $#$#"  ## Put procedure in EWRAM.


template waitcnt*: WaitCnt = cast[ptr WaitCnt](addr natuMem.regs[0x204])[]
