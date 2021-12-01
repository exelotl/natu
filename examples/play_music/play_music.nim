## Maxmod Example
## ==============
## This example demonstrates playing music and sfx with maxmod.

import natu/[core, bios, irq, tte, input, maxmod]
include ./output/soundbank

proc main() =
  
  # show text on background 0
  dispcnt.init(bg0 = true)
  tte.initChr4c(bgnr = 0, initBgCnt(cbb = 0, sbb = 31))
  
  tte.write """
    Maxmod Demo
    Press A for sfx
"""
  
  irq.init()
  irq.enable(iiVBlank)
  
  # register maxmod VBlank handler
  irq.add(iiVBlank, maxmod.vblank)
  
  # init with 8 channels
  maxmod.init(soundbankBin, 8)
  
  # play music
  maxmod.start(modSpacecat, mmPlayLoop)
  
  while true:
    keyPoll()
    
    if keyHit(kiA):
      # play sound effect
      let handle = maxmod.effect(sfxShoot)
      
      # invalidate handle (allow effect to be interrupted)
      handle.release()
    
    # update maxmod
    maxmod.frame()
    
    VBlankIntrWait()

main()
