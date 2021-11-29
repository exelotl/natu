## Hardware interrupt manager from Tonc (see `the chapter on interrupts <https://www.coranac.com/tonc/text/interrupts.htm>`_).
## 
## This module does expose the registers directly, but for most purposes you don't need to
## worry about them as the IRQ management procs can take care of everything:
## 
## =================================== ================================================
## Procedure                           Description
## =================================== ================================================
## `irq.init <#init,FnPtr>`_           Initialise the interrupt manager.
## `irq.enable <#enable,IrqIndex>`_    Enable an interrupt.
## `irq.put <#put,IrqIndex,FnPtr>`_    Enable an interrupt and register a handler for it.
## `irq.disable <#disable,IrqIndex>`_  Disable an interrupt.
## `irq.delete <#delete,IrqIndex>`_    Disable an interrupt and remove its handler.
## =================================== ================================================

{.warning[UnusedImport]: off.}

import std/volatile
import private/[common, types]
import ./core

{.compile(toncPath & "/asm/tonc_isr_master.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_isr_nest.s", toncAsmFlags).}

type
  IrqIndex* {.size: 4.} = enum
    ## IRQ indices, used to enable/disable and register handlers for interrupts.
    iiVBlank,   iiHBlank,  iiVCount,  iiTimer0,
    iiTimer1,   iiTimer2,  iiTimer3,  iiSerial,
    iiDma0,     iiDma1,    iiDma2,    iiDma3,
    iiKeypad,   iiGamepak
  
  IrqPriority* = range[0..14]
    ## The desired position of a handler in the list of interrupt handlers.
    ## 
    ## Earlier handlers take less time to resolve, and will be resolved first
    ## in the event that two interrupts are both waiting to be acknowledged.
  
  IrqSender = object
    ## Address of register (relative to 0x04000000) along with the bit that
    ## should be set in order for the desired interrupt to be fired.
    ofs, bit: uint16
  
  IrqIndexes32 {.size: 4.} = set[IrqIndex]
  
  IrqRecord {.importc:"IRQ_REC", header:"tonc_irq.h".} = object
    flag {.importc:"flag".}: IrqIndexes32
    handler {.importc:"isr".}: FnPtr

# Register definitions
# --------------------

var ie* {.importc:"(*(volatile NU16*)(0x4000200))", nodecl.}: set[IrqIndex]
  ## "Interrupt Enable" register.
  ## 
  ## Setting a bit allows an interrupt to be received. But nothing will
  ## happen unless the relevant bit to request the interrupt is also set,
  ## e.g. `dispcnt.vblankIrq = true`.
  ## 
  ## .. note::
  ##   `irq.put <#put,IrqIndex,FnPtr>`_ or `irq.enable <#enable,IrqIndex>`_ will take care of this for you.

var `if`* {.importc:"(*(volatile NU16*)(0x4000202))", nodecl.}: set[IrqIndex]
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
  ##   Calling `irq.init()` will set this to true.

var ifbios* {.importc:"(*(volatile NU16*)(0x03FFFFF8))", nodecl.}: set[IrqIndex]
  ## "BIOS Interrupt Flags" register.
  ## 
  ## In addition to the `if` register, this must be acknowledged in order to
  ## wake up from the `IntrWait` and `VBlankIntrWait` system calls.
  ## 
  ## .. note::
  ##   The master ISR will take care of this for you.

var `isr`* {.importc:"(*(volatile FnPtr*)(0x03FFFFFC))", nodecl.}: FnPtr
  ## Contains the address of the master Interrupt Service Routine.


# Available interrupt service routines
# ------------------------------------

proc isrMaster* {.importc: "isr_master", codegenDecl: ArmCodeInIwram.}
proc isrMasterNest* {.importc: "isr_master_nest", codegenDecl: ArmCodeInIwram.}


# Interrupt management procedures
# -------------------------------

var records {.exportc:"__isr_table".}: array[ord(IrqIndex.high) + 2, IrqRecord]

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

# TODO: move into some utils module
proc peek[T](address: ptr T): T {.inline.} = volatileLoad(address)
proc poke[T](address: ptr T, value: T) {.inline.} = volatileStore(address, value)

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

proc init*(isr: FnPtr = isrMaster) =
  ## Initialize the interrupt manager.
  ## 
  ## Clears the list of handlers, and sets up a master ISR.
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master interrupt service routine.
  ## 
  ime = false
  
  # Clear interrupt table (just in case)
  memset32(addr records, 0, sizeof(records) div sizeof(uint32))
  
  assert(isr != nil)
  irq.isr = isr
  ime = true

proc setMasterIsr*(isr: FnPtr = isrMaster) =
  ## Set a master ISR
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master interrupt service routine.
  ##
  let tmp = ime
  ime = false
  
  assert(isr != nil)
  irq.isr = isr
  
  ime = tmp

proc put*(irqId: IrqIndex; handler: FnPtr) =
  ## 
  ## Enable an interrupt, and register a handler for it.
  ## 
  ## If the interrupt already has a handler it will be replaced, otherwise it will
  ## be added to the end of the list.
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Interrupt request index.
  ## 
  ## handler
  ##   The specific interrupt service routine to be registered for the given interrupt.
  ##   Can be `nil`, which is equivalent to adding a handler that does nothing.
  ## 
  let tmp = ime
  ime = false
  
  doEnable(irqId)
  
  for r in mitems(records):
    if r.flag == {} or r.flag == {irqId}:
      r.flag = {irqId}
      r.handler = handler
      break
  
  ime = tmp

proc add*(irqId: IrqIndex; handler: FnPtr) {.error:"irq.add has been renamed to irq.put".}

proc putImpl(irqId: IrqIndex; handler: FnPtr; opts: uint32) =
  let tmp = ime
  ime = false
  
  let desiredPos = (opts and 0x7f).int
  let keepOldPos = (opts and 0x80).bool
  let flag = {irqId}
  
  doEnable(irqId)
  
  var i = 0
  
  # find a record which is empty *or* already using this irq
  while records[i].flag - flag != {}:
    inc i
  
  if records[i].flag == flag:
    # irq already in use
    
    if i == desiredPos or keepOldPos:
      # replace existing handler
      records[i].handler = handler
      ime = tmp
      # nothing more to do.
      return
    
    else:
      # remove existing handler by shifting the rest left.
      while true:
        records[i] = records[i+1]
        if records[i].flag == {}:
          break
        inc i
  
  # now we have an index to an empty record.
  # if the desired position is earlier in the list,
  # shift everything right to make room.
  while i > desiredPos:
    records[i] = records[i-1]
    dec i
  
  records[i].flag = flag
  records[i].handler = handler
  
  ime = tmp

proc put*(irqId: IrqIndex; handler: FnPtr; prio: IrqPriority; keepOldPrio = false): FnPtr {.inline, discardable.} =
  ## 
  ## Enable an interrupt, and register a handler for it, with priority control.
  ## 
  ## If the interrupt already has a handler it will be replaced. 
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Interrupt request index.
  ## 
  ## handler
  ##   The specific interrupt service routine to be registered for the given interrupt.
  ##   Can be `nil`, which is equivalent to adding a handler that does nothing.
  ## 
  ## prio
  ##   The desired position of the handler in the list.
  ##   `0` = highest priority, `14` = lowest priority.
  ## 
  ## keepOldPrio
  ##   If true and we're replacing an existing handler, then `prio` will be ignored.
  ## 
  var opts = cast[uint32](prio)
  if keepOldPrio:
    opts = opts or 0x0080'u32  # Set flag to directly replace old ISR if existing (prio ignored)
  putImpl(irqId, handler, opts)

proc delete*(irqId: IrqIndex) =
  ## 
  ## Disable an interrupt, and remove its handler.
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Interrupt request index.
  ## 
  let tmp = ime
  ime = false
  
  let flag = {irqId}
  
  doDisable(irqId)
  
  # find a record which is using this irq (or is empty)
  var i = 0
  while records[i].flag - flag != {}:
    inc i
  
  # remove record by shifting the rest left
  while records[i].flag != {}:
    records[i] = records[i+1]
    inc i
  
  ime = tmp


proc enable*(irqId: IrqIndex) =
  ## Enable an interrupt.
  let tmp = ime
  ime = false
  doEnable(irqId)
  ime = tmp

proc disable*(irqId: IrqIndex) =
  ## Disable an interrupt.
  let tmp = ime
  ime = false
  doDisable(irqId)
  ime = tmp
