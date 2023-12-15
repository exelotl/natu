{.used.}

import ./applib

proc panic*(msg1: cstring; msg2: cstring = nil) {.exportc: "natuPanic", noreturn.} =
  natuMem.panic(msg1, msg2)
