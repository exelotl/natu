{.used.}

import natu/[core, bios, irq, tte, video]

proc panic*(msg1: cstring; msg2: cstring = nil) {.exportc: "natuPanic", noreturn.} =
  
  ime = false
  
  RegisterRamReset({ rsVram, rsSound, rsRegisters })
  
  dispcnt.init(bg0 = true)
  
  tte.initChr4c(bgnr = 0, bgcnt = initBgCnt(cbb=0, sbb=31))
  bgColorMem[0] = rgb5(0,0,4)
  tte.setPos(8, 8)
  tte.setMargins(8, 8, 232, 152)
  tte.write("AN ERROR OCCURRED:\n\n")
  tte.write(msg1)
  if msg2 != nil:
    tte.write(msg2)
  
  while true:
    asm "nop"
