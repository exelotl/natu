import natu
import natu/maxmod
import ./soundbank

proc main() =
  
  # show text on background 0
  dispcnt.init(bg0 = true)
  tteInitChr4cDefault(bgnr = 0, initBgCnt(cbb = 0, sbb = 31))
  
  tteWrite """

    Maxmod Demo
    Press A for sfx
"""
  
  irqInit()
  irqEnable(II_VBLANK)
  
  # register maxmod VBlank handler
  irqAdd(II_VBLANK, maxmod.vblank)
  
  # init with 8 channels
  maxmod.init(soundbankBin, 8)
  
  # play music
  maxmod.start(modSpacecat, MM_PLAY_LOOP)
  
  while true:
    keyPoll()
    
    if keyHit(KEY_A):
      # play sound effect
      let handle = maxmod.effect(sfxShoot)
      
      # invalidate handle (allow effect to be interrupted)
      maxmod.effectRelease(handle)
    
    # update maxmod
    maxmod.frame()
    
    VBlankIntrWait()

main()
