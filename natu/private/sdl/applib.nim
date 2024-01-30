import ./appcommon
export appcommon

var natuMem*: ptr NatuAppMem

import ../../bios  # must be linked.
import ../../surfaces
import ../../video
import ./panics

proc natuNimMain() {.importc.}
proc natuUpdate() {.importc.}
proc natuDraw() {.importc.}

# Hacks for certain libtonc code to function properly in non-gba environment - used by tonc_memmap.h
proc natuGetSeMem*: pointer {.exportc.} = addr natuMem.vram
proc natuGetTileMem*: pointer {.exportc.} = addr natuMem.vram
proc natuGetRegBase*: uint {.exportc.} = cast[uint](addr natuMem.regs)
proc natuGetBgPalMem*: pointer {.exportc.} = addr natuMem.palram

# Must be called as early as possible by the host!
proc natuAppInit*(mem: ptr NatuAppMem) {.exportc, dynlib.} =
  natuMem = mem
  m4Surface.palData = cast[ptr Palette](natuGetBgPalMem())  # actually way more to do here if we want Tonc's bitmap mode surfaces to work
  natuNimMain()

proc natuAppGetLcdSize*(): (int, int) {.exportc, dynlib.} =
  const natuLcdWidth {.intdefine.} = 240
  const natuLcdHeight {.intdefine.} = 160
  (natuLcdWidth, natuLcdHeight)

proc natuAppUpdate*() {.exportc, dynlib.} =
  natuUpdate()
  
proc natuAppDraw*() {.exportc, dynlib.} =
  natuDraw()
