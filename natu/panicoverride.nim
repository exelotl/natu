# This module is required for --os:standalone to work
# In the event of a runtime error, send a fatal log to mGBA

import volatile

{.push stack_trace: off, profiler:off.}

when nimvm:
  discard
  
  # Doesn't compile on Nim >= 0.20
  # Is there any situation where it's needed?
  #[
  proc rawoutput(s: string) =
    echo s
    
  proc panic(s: string) {.noreturn.} =
    raise newException(Exception, s)
  ]#
  
else:
  let REG_DEBUG_ENABLE = cast[ptr uint16](0x4FFF780)
  let REG_DEBUG_FLAGS = cast[ptr uint16](0x4FFF700)
  let REG_DEBUG_STRING = cast[cstring](0x4FFF600)
  
  proc mgbaLog(level: int, s: cstring) =
    for i in 0..<256:
      let c = s[i]
      if c == '\0': break
      volatileStore(unsafeAddr REG_DEBUG_STRING[i], c)
    #copyMem(REG_DEBUG_STRING, s, 256)
    volatileStore(REG_DEBUG_FLAGS, (0x100 or level).uint16)

  proc rawoutput(s: cstring) =
    mgbaLog(1, s)
    
  proc panic(s: cstring) {.noreturn.} =
    volatileStore(REG_DEBUG_ENABLE, 0xC0DE)
    mgbaLog(0, s)
    while true: discard

{.pop.}
