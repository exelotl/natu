import tonc

proc main() =
  
  # show background 0
  REG_DISPCNT = DCNT_BG0
  
  # initialise text
  tteInitChr4cDefault(0, BG_CBB(0) or BG_SBB(31))
  tteWrite("#{P:92,68}")   # move to 92, 68
  tteWrite("Hello World!")
  
  while true:
    discard

main()
