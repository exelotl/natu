import ./applib

const
  DataInIwram* = "$# $#"         ## Put variable in IWRAM (default).
  DataInEwram* = "$# $#"         ## Put variable in EWRAM
  ArmCodeInIwram* = "$# $#$#"    ## Put procedure in IWRAM.
  ThumbCodeInEwram* = "$# $#$#"  ## Put procedure in EWRAM.

var romMem*: array[1, uint16]
var sramMem*: array[0x10000, uint8]

template waitcnt*: WaitCnt = cast[ptr WaitCnt](addr natuMem.regs[0x204 shr 1])[]

template dmach*: array[4, DmaChannel] = cast[ptr array[4, DmaChannel]](addr natuMem.regs[0xB0 shr 1])[]

template stop*(d: DmaChannel) =
  ## Cancels any transfer that may be happening on the given DMA channel.
  d.cnt = DmaCnt(0)
  natuMem.stopDma(addr d)

template dmaStartAux(d: DmaChannel; a, b: pointer; c: uint16) =
  d.src = a
  d.dst = b
  d.count = c

template start*(d: DmaChannel; dst, src: pointer; count: uint16; args: varargs[untyped]) =
  ## Activate DMA on the given channel.
  d.cnt = DmaCnt(0)
  dmaStartAux(d, src, dst, count)
  var cnt: DmaCnt
  cnt.enable = true
  writeFields(cnt, args)
  d.cnt = cnt
  natuMem.startDma(addr d)