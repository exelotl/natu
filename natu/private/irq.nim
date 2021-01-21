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
    ## IRQ indices, to be used in most functions.
    II_VBLANK=0, II_HBLANK,  II_VCOUNT,  II_TIMER0,
    II_TIMER1,   II_TIMER2,  II_TIMER3,  II_SERIAL,
    II_DMA0,     II_DMA1,    II_DMA2,    II_DMA3,
    II_KEYPAD,   II_GAMEPAK, II_MAX

# Options for `irqSet`
const
  ISR_LAST*:uint32 = 0x0040      ## Last isr in line (Lowest priority)
  ISR_REPLACE*:uint32 = 0x0080   ## Replace old isr if existing (prio ignored)

const
  ISR_PRIO_MASK*:uint32 = 0x003F
  ISR_PRIO_SHIFT*:uint32 = 0

template ISR_PRIO*(n: uint32): uint32 =
  ((n) shl ISR_PRIO_SHIFT)

const
  ISR_DEF*:uint32 = (ISR_LAST or ISR_REPLACE)


type
  IRQ_REC* {.importc: "struct IRQ_REC", header: "tonc.h", bycopy.} = object
    ## Struct for prioritized irq table
    flag* {.importc: "flag".}: uint32  ## Flag for interrupt in REG_IF, etc
    isr* {.importc: "isr".}: FnPtr     ## Pointer to interrupt routine


proc isrMaster*() {.importc: "isr_master", header: "tonc.h".}
proc isrMasterNest*() {.importc: "isr_master_nest", header: "tonc.h".}

proc irqInit*(isr: FnPtr = nil) {.importc: "irq_init", header: "tonc.h".}
  ## Initialize irq business
  ## Clears ISR table and sets up a master isr.
  ## `isr` Master ISR. If NULL, `isrMasterNest` is used

proc irqSetMaster*(isr: FnPtr = nil): FnPtr {.importc: "irq_set_master", header: "tonc.h", discardable.}
  ## Set a master ISR
  ## `isr` Master ISR. If NULL, `isrMasterMulti` is used
  ## Returns: Previous master ISR

proc irqAdd*(irqId: IrqIndex; isr: FnPtr = nil): FnPtr {.importc: "irq_add", header: "tonc.h", discardable.}
  ## Add a specific ISR
  ## Special case of `irqSet`. If the interrupt has an ISR already it'll be replaced; if not it will add it in the back.
  ## `irqId` Index of irq.
  ## `isr`   Interrupt service routine for this irq; can be NULL
  ## Returns: Previous ISR
  ## Note: `irqId` is *NOT* a bit-mask, it is an index!

proc irqDelete*(irqId: IrqIndex): FnPtr {.importc: "irq_delete", header: "tonc.h", discardable.}
  ## Remove an ISR
  ## It'll be replaced; if not it will add it in the back.
  ## `irqId` Index of irq.
  ## Returns: Previous ISR
  ## Note: `irqId` is *NOT* a bit-mask, it is an index!

proc irqSet*(irqId: IrqIndex; isr: FnPtr = nil; opts: uint32 = ISR_DEF): FnPtr {.importc: "irq_set", header: "tonc.h", discardable.}
  ## General IRQ manager
  ## This routine manages the ISRs of interrupts and their priorities.
  ## `irqId` Index of irq.
  ## `isr`   Interrupt service routine for this irq; can be NULL
  ## `opts`  ISR options
  ## Returns: Previous specific ISR
  ## Note:	`irqId` is *NOT* a bit-mask, it is an index!

proc irqEnable*(irqId: IrqIndex) {.importc: "irq_enable", header: "tonc.h".}
proc irqDisable*(irqId: IrqIndex) {.importc: "irq_disable", header: "tonc.h".}