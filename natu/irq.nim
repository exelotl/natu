## Hardware interrupt manager from `libugba <https://github.com/AntonioND/libugba>`_.
## 
## .. note::
##    Importing this module will automatically enable interrupts
##    and set up the master :abbr:`ISR (Interrupt Service Routine)`.
## 
## **Example:**
## 
## .. code-block:: nim
## 
##    import natu/[video, graphics, irq]
##    
##    proc onVBlank() =
##      # Copy palette buffers into PAL RAM:
##      flushPals()
##      
##      # Do other updates to VRAM and video registers here.
##      # ...
##    
##    # Enable vblank interrupt and register our handler:
##    irq.put(iiVBlank, onVBlank)

{.warning[UnusedImport]: off.}

import private/[common, types]
import ./utils

type
  IrqIndex* {.size: 4.} = enum
    ## IRQ indices, used to enable/disable and register handlers for interrupts.
    ## 
    ## Each interrupt fires at a particular moment.
    # iiVBlank,   iiHBlank,  iiVCount,  iiTimer0,
    # iiTimer1,   iiTimer2,  iiTimer3,  iiSerial,
    # iiDma0,     iiDma1,    iiDma2,    iiDma3,
    # iiKeypad,   iiGamepak
    iiVBlank  ## At the start of the VBlank period (when the LCD has finished updating)
    iiHBlank  ## At the start of the HBlank period (when a scanline on the LCD has finished updating)
    iiVCount  ## When :xref:`vcount` matches `dispstat.vcountTrigger` 
    iiTimer0  ## When timer 0 overflows.
    iiTimer1  ## When timer 1 overflows.
    iiTimer2  ## When timer 2 overflows.
    iiTimer3  ## When timer 3 overflows.
    iiSerial  ## On serial transfer complete.
    iiDma0    ## When DMA channel 0 completes a transfer.
    iiDma1    ## When DMA channel 1 completes a transfer.
    iiDma2    ## When DMA channel 2 completes a transfer.
    iiDma3    ## When DMA channel 3 completes a transfer.
    iiKeypad  ## When *any* or *all* of the keys in :xref:`keycnt` are held.
    iiGamepak ## When the game pak is removed.
  
  IrqIndices* {.size: 2.} = set[IrqIndex]
  
var irqVectorTable {.exportc:"IRQ_VectorTable".}: array[IrqIndex, FnPtr]


# Platform specific code
# ----------------------

when natuPlatform == "gba": include ./private/gba/irq 
elif natuPlatform == "sdl": include ./private/sdl/irq
else: {.error: "Unknown platform " & natuPlatform.}
