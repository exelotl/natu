import ./applib

# Register definitions
# --------------------
# The registers are exposed directly, but for most purposes you don't need to
# worry about them as the IRQ management procs can take care of everything.

template ie*: IrqIndices     = cast[ptr IrqIndices](addr natuMem.regs[0x200 shr 1])[]
template `if`*: IrqIndices   = cast[ptr IrqIndices](addr natuMem.regs[0x202 shr 1])[]
template ime*: bool          = cast[ptr bool](addr natuMem.regs[0x208 shr 1])[]
template ifbios*: IrqIndices = cast[ptr IrqIndices](addr natuMem.regs[0x1f8 shr 1])[]  # just uses a random unused index.
template isr*: FnPtr         = cast[ptr FnPtr](addr natuMem.regs[0x1fc shr 1])[]  # ditto


# Interrupt management procedures
# -------------------------------

type
  IrqSender = object
    ## Address of register (relative to 0x04000000) along with the bit that
    ## should be set in order for the desired interrupt to be fired.
    ofs, bit: uint16

const senders: array[IrqIndex, IrqSender] = [
  iiVBlank:  IrqSender(ofs: 0x0004, bit: 0x0008),
  iiHBlank:  IrqSender(ofs: 0x0004, bit: 0x0010),
  iiVCount:  IrqSender(ofs: 0x0004, bit: 0x0020),
  iiTimer0:  IrqSender(ofs: 0x0102, bit: 0x0040),
  iiTimer1:  IrqSender(ofs: 0x0106, bit: 0x0040),
  iiTimer2:  IrqSender(ofs: 0x010A, bit: 0x0040),
  iiTimer3:  IrqSender(ofs: 0x010E, bit: 0x0040),
  iiSerial:  IrqSender(ofs: 0x0128, bit: 0x4000),
  iiDma0:    IrqSender(ofs: 0x00BA, bit: 0x4000),
  iiDma1:    IrqSender(ofs: 0x00C6, bit: 0x4000),
  iiDma2:    IrqSender(ofs: 0x00D2, bit: 0x4000),
  iiDma3:    IrqSender(ofs: 0x00DE, bit: 0x4000),
  iiKeypad:  IrqSender(ofs: 0x0132, bit: 0x4000),
  iiGamepak: IrqSender(), # N/A
]

template doEnable(i: IrqIndex) =
  let sender = senders[i]
  let reg = addr natuMem.regs[sender.ofs]
  poke(reg, peek(reg) or sender.bit)
  ie.incl(i)

template doDisable(i: IrqIndex) =
  let sender = senders[i]
  let reg = addr natuMem.regs[sender.ofs]
  poke(reg, peek(reg) and not sender.bit)
  ie.excl(i)

proc masterIsr =
  assert(false, "master isr not implemented")
  discard

proc startInterruptManager() =
  ## Initialize the interrupt manager. This is called automatically if the module is imported.
  ## You don't usually need to call it yourself.
  ## 
  ime = false
  
  # Clear IE and IF
  ie = {}
  `if` = {IrqIndex.low .. IrqIndex.high}

  # Clear interrupt table
  memset32(addr irqVectorTable, 0, irqVectorTable.len)
  
  # Set master ISR
  isr = masterIsr
  
  # Enable interrupts
  ime = true

proc putIrq*(irqId: IrqIndex; handler: FnPtr) =
  ## 
  ## Enable an interrupt, and register a handler for it.
  ## 
  ## If the interrupt already has a handler it will be replaced.
  ## 
  let tmp = ime
  ime = false
  doEnable(irqId)
  irqVectorTable[irqId] = handler
  ime = tmp

proc delIrq*(irqId: IrqIndex) =
  ## 
  ## Disable an interrupt, and remove its handler.
  ## 
  let tmp = ime
  ime = false
  doDisable(irqId)
  irqVectorTable[irqId] = nil
  ime = tmp

proc enableIrq*(irqId: IrqIndex) =
  ## 
  ## Enable an interrupt.
  ## 
  let tmp = ime
  ime = false
  doEnable(irqId)
  ime = tmp

proc disableIrq*(irqId: IrqIndex) =
  ## 
  ## Disable an interrupt.
  ## 
  let tmp = ime
  ime = false
  doDisable(irqId)
  ime = tmp
