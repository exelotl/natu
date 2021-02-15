## Interrupts
## ----------
## Hardware interrupt management.
## 
## For details, see http://www.coranac.com/tonc/text/interrupts.htm

{.warning[UnusedImport]: off.}

import common
import types, core

{.compile(toncPath & "/src/tonc_irq.c", toncCFlags).}
{.compile(toncPath & "/asm/tonc_isr_master.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_isr_nest.s", toncAsmFlags).}

type
  IrqIndex* {.size: sizeof(cint).} = enum
    ## IRQ indices, used to enable/disable and register handlers for interrupts.
    iiVBlank=0, iiHBlank,  iiVCount,  iiTimer0,
    iiTimer1,   iiTimer2,  iiTimer3,  iiSerial,
    iiDma0,     iiDma1,    iiDma2,    iiDma3,
    iiKeypad,   iiGamepak

# TODO: clean up below?

# Options for ``irq.put``
const
  ISR_LAST:uint32 = 0x0040      ## Last isr in line (Lowest priority)
  ISR_REPLACE:uint32 = 0x0080   ## Replace old isr if existing (prio ignored)

# const
#   ISR_PRIO_MASK*:uint32 = 0x003F
#   ISR_PRIO_SHIFT*:uint32 = 0

# template ISR_PRIO*(n: uint32): uint32 =
#   ((n) shl ISR_PRIO_SHIFT)

# const
#   ISR_DEF*:uint32 = (ISR_LAST or ISR_REPLACE)

# type
#   IRQ_REC* {.importc: "struct IRQ_REC", header: "tonc.h", bycopy.} = object
#     ## Struct for prioritized irq table
#     flag* {.importc: "flag".}: uint32  ## Flag for interrupt in REG_IF, etc
#     isr* {.importc: "isr".}: FnPtr     ## Pointer to interrupt routine


proc isrMaster*() {.importc: "isr_master", header: "tonc.h".}
proc isrMasterNest*() {.importc: "isr_master_nest", header: "tonc.h".}

proc init*(isr: FnPtr = nil) {.importc: "irq_init", header: "tonc.h".}
  ## Initialize irq business
  ## Clears ISR table and sets up a master isr.
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master ISR. If nil, ``isrMaster`` is used
  ## 

proc setMaster*(isr: FnPtr = nil): FnPtr {.importc: "irq_set_master", header: "tonc.h", discardable.}
  ## Set a master ISR
  ## 
  ## **Parameters:**
  ## 
  ## isr
  ##   Master ISR. If nil, ``isrMaster`` is used
  ## 
  ## Returns: Previous master ISR

proc add*(irqId: IrqIndex; isr: FnPtr = nil): FnPtr {.importc: "irq_add", header: "tonc.h", discardable.}
  ## Add a specific ISR
  ## Special case of ``irq.set``. If the interrupt has an ISR already it'll be replaced; if not it will add it in the back.
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Index of irq.
  ## 
  ## isr
  ##   Interrupt service routine for this irq; can be nil
  ## 
  ## Returns: Previous ISR

proc delete*(irqId: IrqIndex): FnPtr {.importc: "irq_delete", header: "tonc.h", discardable.}
  ## Remove an ISR
  ## 
  ## **Parameters:**
  ## 
  ## irqId
  ##   Index of irq.
  ## 
  ## Returns: Previous ISR


proc irqSet(irqId: IrqIndex; isr: FnPtr; opts: uint32): FnPtr {.importc: "irq_set", header: "tonc.h", discardable.}


template put*(irqId: IrqIndex; isr: FnPtr = nil; prio: range[0..64] = 64; replace = false): FnPtr =
  {.warning:"put() is potentially buggy, recommend to instead use irq.add, irq.delete, irq.enable, irq.disable".}
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
  ## Returns: previous specific ISR    # TODO what does this mean?
  ## 
  var opts = cast[uint32](prio)
  if replace:
    opts = opts or ISR_REPLACE
  irqSet(irqId, isr, opts)
  

proc enable*(irqId: IrqIndex) {.importc: "irq_enable", header: "tonc.h".}
  ## Enable an interrupt.

proc disable*(irqId: IrqIndex) {.importc: "irq_disable", header: "tonc.h".}
  ## Disable an interrupt.
