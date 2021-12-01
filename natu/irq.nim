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

import private/[common, types]
import ./core

{.compile(toncPath & "/src/tonc_irq.c", toncCFlags).}
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

proc init*(isr: FnPtr = isrMaster) {.importc: "irq_init".}
  ## Initialize the interrupt manager.
  ## 
  ## Clears the list of handlers, and sets up a master ISR.
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master interrupt service routine.

proc setMasterIsr*(isr: FnPtr = isrMaster): FnPtr {.importc: "irq_set_master", header: "tonc.h", discardable.}
  ## Set a master ISR
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master interrupt service routine.
  ## 
  ## Returns: Previous master ISR

proc put*(irqId: IrqIndex; handler: FnPtr): FnPtr {.importc: "irq_add", header: "tonc.h", discardable.} =
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
  ## Returns: The previous handler, if any.
  ## 

proc add*(irqId: IrqIndex; handler: FnPtr): FnPtr {.
  importc: "irq_add", header: "tonc.h", discardable, deprecated:"irq.add has been renamed to irq.put".}


proc irqSet(irqId: IrqIndex; handler: FnPtr; opts: uint32): FnPtr {.importc: "irq_set", header: "tonc.h".}

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
  ## Returns: The previous handler, if any.
  ## 
  var opts = cast[uint32](prio)
  if keepOldPrio:
    opts = opts or 0x0080'u32  # Set flag to directly replace old ISR if existing (prio ignored)
  irqSet(irqId, handler, opts)

proc delete*(irqId: IrqIndex): FnPtr {.importc: "irq_delete", header: "tonc.h", discardable.}
  ## 
  ## Disable an interrupt, and remove its handler.
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Interrupt request index.
  ## 
  ## Returns: The handler that was removed.


proc enable*(irqId: IrqIndex) {.importc: "irq_enable", header: "tonc.h".}
  ## Enable an interrupt.

proc disable*(irqId: IrqIndex) {.importc: "irq_disable", header: "tonc.h".}
  ## Disable an interrupt.
