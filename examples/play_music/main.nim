import tonc
import tonc/maxmod

importSoundbank()
# Creates the following definitions:
#[
  var soundbankBin* {.importc:"soundbank_bin", header:"soundbank_bin.h".}: pointer
  var modSpacecat* {.importc:"MOD_SPACECAT", header:"soundbank.h".}: uint
]#

proc main() =
  
  # show text on background 0
  REG_DISPCNT = DCNT_BG0
  tteInitChr4cDefault(0, BG_CBB(0) or BG_SBB(31))
  
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
      maxmod.effect(sfxShoot)
    
    # update maxmod
    maxmod.frame()
    
    VBlankIntrWait()

main()
