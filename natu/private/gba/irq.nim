
{.compile("./irq_handler.s", toncAsmFlags).}

proc IRQ_GlobalInterruptHandler {.importc.}

proc startInterruptManager()
startInterruptManager()         # auto-init the module on import.


# Register definitions
# --------------------
# The registers are exposed directly, but for most purposes you don't need to
# worry about them as the IRQ management procs can take care of everything.

var ie* {.importc:"(*(volatile NU16*)(0x4000200))", nodecl.}: IrqIndices
  ## "Interrupt Enable" register.
  ## 
  ## Setting a bit allows an interrupt to be received. But nothing will
  ## happen unless the relevant bit to request the interrupt is also set,
  ## e.g. `dispcnt.vblankIrq = true`.
  ## 
  ## .. note::
  ##   `irq.put <#put>`_ or `irq.enable <#enable>`_ will take care of this for you.

var `if`* {.importc:"(*(volatile NU16*)(0x4000202))", nodecl.}: IrqIndices
  ## "Interrupt Flags" register.
  ## 
  ## When an interrupt occurs, the corresponding bit in `if` will be set.
  ## 
  ## Once the interrupt has been handled, it is acknowledged by setting
  ## the bit again (even though it's already set)! After doing so, the bit
  ## will be automatically cleared by the hardware.
  ## 
  ## .. note::
  ##   The master ISR will take care of this for you.

var ime* {.importc:"(*(volatile NU8*)(0x4000208))", nodecl.}: bool
  ## "Interrupt Master Enable" register.
  ## 
  ## Setting this to `false` will disable all interrupts.
  ## 
  ## .. note::
  ##   This is automatically set to `true` when the module is initialised, and
  ##   temporarily set to `false` while one of your handlers is being called.
  ##   
  ##   Setting `ime = true` within a handler will allow that handler to be
  ##   interrupted by another interrupt. i.e. nested interrupts are supported.

var ifbios* {.importc:"(*(volatile NU16*)(0x03FFFFF8))", nodecl.}: IrqIndices
  ## "BIOS Interrupt Flags" register.
  ## 
  ## In addition to the `if` register, this must be acknowledged in order to
  ## wake up from the `IntrWait` and `VBlankIntrWait` system calls.
  ## 
  ## .. note::
  ##   The master ISR will take care of this for you.

var isr* {.importc:"(*(volatile FnPtr*)(0x03FFFFFC))", nodecl.}: FnPtr
  ## Contains the address of the master interrupt service routine.


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
  let reg = cast[ptr uint16](0x4000000'u32 + sender.ofs.uint32)
  poke(reg, peek(reg) or sender.bit)
  ie.incl(i)

template doDisable(i: IrqIndex) =
  let sender = senders[i]
  let reg = cast[ptr uint16](0x4000000'u32 + sender.ofs.uint32)
  poke(reg, peek(reg) and not sender.bit)
  ie.excl(i)

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
  isr = IRQ_GlobalInterruptHandler
  
  # Enable interrupts
  ime = true

proc put*(irqId: IrqIndex; handler: FnPtr) =
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

proc delete*(irqId: IrqIndex) =
  ## 
  ## Disable an interrupt, and remove its handler.
  ## 
  let tmp = ime
  ime = false
  doDisable(irqId)
  irqVectorTable[irqId] = nil
  ime = tmp

proc enable*(irqId: IrqIndex) =
  ## 
  ## Enable an interrupt.
  ## 
  let tmp = ime
  ime = false
  doEnable(irqId)
  ime = tmp

proc disable*(irqId: IrqIndex) =
  ## 
  ## Disable an interrupt.
  ## 
  let tmp = ime
  ime = false
  doDisable(irqId)
  ime = tmp

proc putIrq*(irqId: IrqIndex; handler: FnPtr) {.inline, deprecated:"use irq.put instead".} = put(irqId, handler)
proc delIrq*(irqId: IrqIndex) {.inline, deprecated:"use irq.delete instead".} = delete(irqId)
proc enableIrq*(irqId: IrqIndex) {.inline, deprecated:"use irq.enable instead".} = enable(irqId)
proc disableIrq*(irqId: IrqIndex) {.inline, deprecated:"use irq.disable instead".} = disable(irqId)
