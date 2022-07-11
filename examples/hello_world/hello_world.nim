import natu/[video, tte]

# show background 0
dispcnt = initDispCnt(bg0 = true)

# initialise text
tte.initChr4c(bgnr = 0, initBgCnt(cbb = 0, sbb = 31))
tte.setPos(92, 68)
tte.write("Hello World!")

while true:
  discard
