# This module is required for --os:standalone to work
# In the event of a runtime error, send a fatal log to mGBA

import volatile

{.push stack_trace: off, profiler:off.}

proc mgbaLog(level: int, s: cstring) =
  let REG_DEBUG_FLAGS = cast[ptr uint16](0x4FFF700)
  let REG_DEBUG_STRING = cast[cstring](0x4FFF600)
  # copy message:
  for i in 0..<256:
    if s[i] == '\0': break
    volatileStore(unsafeAddr REG_DEBUG_STRING[i], s[i])
  volatileStore(REG_DEBUG_FLAGS, (0x100 or level).uint16)

proc rawoutput(s: cstring) =
  mgbaLog(1, s)
    
proc gbaPanic(s: cstring) {.noreturn.} =
  let REG_DEBUG_ENABLE = cast[ptr uint16](0x4FFF780)
  volatileStore(REG_DEBUG_ENABLE, 0xC0DE)
  mgbaLog(0, s)
  while true: discard

template panic(s: string) =
  when nimvm:
    raise (ref AssertionDefect)(msg: s)
  else:
    gbaPanic(s)

{.pop.}
