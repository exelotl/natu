import natu

# show background 0
dispcnt = initDispCnt(bg0 = true)

# initialise text
tteInitChr4cDefault(bgnr = 0, initBgCnt(cbb = 0, sbb = 31))
tteSetPos(92, 68)
tteWrite("Hello World!")

while true:
  discard
