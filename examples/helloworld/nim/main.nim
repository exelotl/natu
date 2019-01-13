import tonc

proc main() =
  
  # show background 0
  REG_DISPCNT = DCNT_MODE0 or DCNT_BG0 or DCNT_OBJ

  # initialise text
  tteInitSeDefault(0, BG_CBB(0) or BG_SBB(31))

  tteWrite("#{P:72,64}")   # move to 72, 64
  tteWrite("Hello World!")
  
  while true:
    VBlankIntrWait()

main()
  