## Exports all libtonc constants and register defintions 
## 
## To allow e.g.
## ::
##   REG_DISPCNT = DCNT_BG0 or DCNT_OBJ or DCNT_OBJ_1D
## 
## Currently this is useful for dealing with registers that haven't yet
## been exposed via a nicer interface, such as REG_DMA, REG_TM
## 
import ./private/[memmap, memdef, common]
export memmap, memdef

when natuPlatform == "gba":

  # DMA
  # ---
  {.pragma: toncinl, header: "tonc_core.h".}

  proc dmaCpy*(dst: pointer; src: pointer; count: SomeInteger; ch: uint; mode: uint32) {.importc: "dma_cpy", toncinl.}
    ## Generic DMA copy routine.
    ## `dst`   Destination address.
    ## `src`   Source address.
    ## `count` Number of copies to perform.
    ## `ch`    DMA channel.
    ## `mode`  DMA transfer mode.
    ## Note: `count` is the number of copies, not the size in bytes.

  proc dmaFill*(dst: pointer; src: uint32; count: SomeInteger; ch: uint; mode: uint32) {.importc: "dma_fill", toncinl.}
    ## Generic DMA fill routine.
    ## `dst`   Destination address.
    ## `src`   Source value.
    ## `count` Number of copies to perform.
    ## `ch`    DMA channel.
    ## `mode`  DMA transfer mode.
    ## Note: `count` is the number of copies, not the size in bytes.
    
  proc dma3Cpy*(dst: pointer; src: pointer; size: SomeInteger) {.importc: "dma3_cpy", toncinl.}
    ## Specific DMA copier, using channel 3, word transfers.
    ## `dst`  Destination address.
    ## `src`  Source address.
    ## `size` Number of bytes to copy
    ## Note: `size` is the number of bytes

  proc dma3Fill*(dst: pointer; src: uint32; size: SomeInteger) {.importc: "dma3_fill", toncinl.}
    ## Specific DMA filler, using channel 3, word transfers.
    ## `dst`  Destination address.
    ## `src`  Source value.
    ## `size` Number of bytes to copy
    ## Note: `size` is the number of bytes

elif natuPlatform == "sdl":
  
  proc dmaCpy*(dst: pointer; src: pointer; count: SomeInteger; ch: uint; mode: uint32) {.deprecated.} =
    discard

else:
  {.error: "Unknown platform " & natuPlatform.}
