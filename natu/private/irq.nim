## Interrupts
## ----------
## Hardware interrupt management.
## 
## For details, see http://www.coranac.com/tonc/text/interrupts.htm

{.warning[UnusedImport]: off.}

import common
import types, core

export types.IrqIndex

{.compile(toncPath & "/src/tonc_irq.c", toncCFlags).}
{.compile(toncPath & "/asm/tonc_isr_master.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_isr_nest.s", toncAsmFlags).}

proc isrMaster*() {.importc: "isr_master", header: "tonc.h".}
proc isrMasterNest*() {.importc: "isr_master_nest", header: "tonc.h".}

proc init*(isr: FnPtr = nil) {.importc: "irq_init", header: "tonc.h".}
  ## Initialize irq business
  ## Clears ISR table and sets up a master isr.
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master ISR. If nil, `isrMaster` is used
  ## 

proc setMaster*(isr: FnPtr = nil): FnPtr {.importc: "irq_set_master", header: "tonc.h", discardable.}
  ## Set a master ISR
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master ISR. If nil, `isrMaster` is used
  ## 
  ## Returns: Previous master ISR

proc add*(irqId: IrqIndex; isr: FnPtr): FnPtr {.importc: "irq_add", header: "tonc.h", discardable.}
  ## 
  ## Enable an interrupt, and register a handler for it.
  ## 
  ## If the interrupt already has a handler it will be replaced.
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Index of irq.
  ## 
  ## isr
  ##   Interrupt service routine for this irq; can be nil
  ## 
  ## Returns: The previous handler, if any.

proc delete*(irqId: IrqIndex): FnPtr {.importc: "irq_delete", header: "tonc.h", discardable.}
  ## 
  ## Disalble an interrupt, and remove its handler.
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Index of irq.
  ## 
  ## Returns: The handler that was removed.


proc irqSet(irqId: IrqIndex; isr: FnPtr; opts: uint32): FnPtr {.importc: "irq_set", header: "tonc.h", discardable.}


template put*(irqId: IrqIndex; isr: FnPtr; prio: range[0..64] = 64; replace = false): FnPtr =
  ## 
  ## Insert or replace a handler for an interrupt.
  ## 
  ## General IRQ manager
  ## 
  ## This routine manages the handlers of interrupts and their priorities.
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Index of irq.
  ## 
  ## isr
  ##   Interrupt service routine for this irq; can be nil
  ## 
  ## prio
  ##   ISR priority, 0 = highest, 64 = lowest.
  ##   
  ## 
  ## replace
  ##   Replace old isr if existing (prio ignored)
  ##   TODO: check that this works? (implementation looks buggy...)
  ## 
  ## Returns: The previous handler, if any.
  ## 
  {.warning:"put() is potentially buggy, recommend to use irq.add and irq.delete instead.".}
  
  const IsrReplace = 0x0080'u32   # Replace old isr if existing (prio ignored)
  
  var opts = cast[uint32](prio)
  if replace:
    opts = opts or IsrReplace
  irqSet(irqId, isr, opts)
  

proc enable*(irqId: IrqIndex) {.importc: "irq_enable", header: "tonc.h".}
  ## Enable an interrupt.

proc disable*(irqId: IrqIndex) {.importc: "irq_disable", header: "tonc.h".}
  ## Disable an interrupt.
