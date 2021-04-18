## Exports all libtonc constants and register defintions 
## 
## To allow e.g.
## ::
##   REG_DISPCNT = DCNT_BG0 or DCNT_OBJ or DCNT_OBJ_1D
## 
## Currently this is useful for dealing with registers that haven't yet
## been exposed via a nicer interface, such as REG_DMA, REG_TM
## 
import private/[memmap, memdef, old_constants]
export memmap, memdef, old_constants
