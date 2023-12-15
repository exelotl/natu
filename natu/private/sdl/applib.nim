import ./appcommon
export appcommon

var natuMem*: ptr NatuAppMem

import ../../bios  # must be linked.
import ./panics

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
