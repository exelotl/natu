## mGBA Debug Logging
## ==================
## Output text to the debug console in mGBA

import posprintf
import volatile

let REG_DEBUG_ENABLE = cast[ptr uint16](0x4FFF780)
let REG_DEBUG_FLAGS = cast[ptr uint16](0x4FFF700)
let REG_DEBUG_STRING = cast[cstring](0x4FFF600)

# Wrapper procs to fix bad codegen when volatileLoad / volatileStore are used at the top level.
proc peek[T](address: ptr T): T {.inline.} =
  volatileLoad(address)
proc poke[T](address: ptr T, value: T) {.inline.} =
  volatileStore(address, value)

# Wrapper template to work around compiler bug with empty varargs?
template printfAux(str: cstring, args: varargs[untyped]) =
  posprintf(REG_DEBUG_STRING, str, args)

type LogLevel* {.size: sizeof(uint16).} = enum
  logFatal = 0
  logError = 1
  logWarn = 2
  logInfo = 3
  logDebug = 4

proc open*(): bool {.discardable.} =
  poke(REG_DEBUG_ENABLE, 0xC0DE)
  return peek(REG_DEBUG_ENABLE) == 0x1DEA

proc close*() =
  poke(REG_DEBUG_ENABLE, 0)

template printf*(level: LogLevel, str: cstring, args: varargs[untyped]) =
  ## Output a formatted message to the mGBA log, at a specified level of visibility.
  ## 
  ## Example:
  ## 
  ## .. code-block:: nim
  ## 
  ##   printf(logFatal, "Uh oh, something went wrong!")
  ## 
  printfAux(str, args)
  poke(REG_DEBUG_FLAGS, (level.uint16) or 0x100)

template printf*(str: cstring, args: varargs[untyped]) =
  ## Output a formatted message to the mGBA log.
  ## 
  ## Example:
  ## 
  ## .. code-block:: nim
  ## 
  ##   printf("Spawned item at %d, %d", pos.x, pos.y)
  ## 
  printfAux(str, args)
  poke(REG_DEBUG_FLAGS, (logWarn.uint16) or 0x100)


# Open the debug log by default, just `import natu/mgba` to use.
poke(REG_DEBUG_ENABLE, 0xC0DE)
