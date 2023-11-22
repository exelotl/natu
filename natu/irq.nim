## Hardware interrupt manager from `libugba <https://github.com/AntonioND/libugba>`_.
## 
## .. note::
##    Importing this module will automatically enable interrupts
##    and set up the master :abbr:`ISR (Interrupt Service Routine)`.

{.warning[UnusedImport]: off.}

import private/[common, types]
import ./utils

type
  IrqIndex* {.size: 4.} = enum
    ## IRQ indices, used to enable/disable and register handlers for interrupts.
    iiVBlank,   iiHBlank,  iiVCount,  iiTimer0,
    iiTimer1,   iiTimer2,  iiTimer3,  iiSerial,
    iiDma0,     iiDma1,    iiDma2,    iiDma3,
    iiKeypad,   iiGamepak
  
  IrqIndices* {.size: 2.} = set[IrqIndex]
  
var irqVectorTable {.exportc:"IRQ_VectorTable".}: array[IrqIndex, FnPtr]


# Platform specific code
# ----------------------

when natuPlatform == "gba": include ./private/gba/irq 
elif natuPlatform == "sdl": include ./private/sdl/irq
else: {.error: "Unknown platform " & natuPlatform.}
