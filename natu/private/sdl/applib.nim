import ./appcommon
export appcommon

import ../../bios  # must be linked.

var natuMem*: ptr NatuAppMem

proc natuNimMain() {.importc.}
proc natuUpdate() {.importc.}
proc natuDraw() {.importc.}

# Must be called as early as possible by the host!
proc natuAppInit*(mem: ptr NatuAppMem) {.exportc, dynlib.} =
  natuMem = mem
  natuNimMain()

proc natuAppUpdate*() {.exportc, dynlib.} =
  natuUpdate()
  
proc natuAppDraw*() {.exportc, dynlib.} =
  natuDraw()
