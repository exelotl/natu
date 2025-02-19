## mGBA Debug Logging
## ==================
## Output text to the debug console in mGBA

import ./private/common
import ./posprintf

# TODO: replace with general logging module + `natuLogMode` string define
const natuMgbaLogging {.booldefine.} = true

type
  LogLevel* {.size: sizeof(uint16).} = enum
    logFatal = 0
    logError = 1
    logWarn = 2   ## This will be used if you don't specify a log level, as
                  ## it's the least-severe one that's enabled by default in mGBA.
    logInfo = 3
    logDebug = 4

when natuPlatform == "gba":
  
  # ACSL sprintf seems unstable
  # proc sprintf(s: cstring; format: cstring) {.varargs, importc, header:"stdio.h".}
  
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
  
  proc open*(): bool {.discardable.} =
    poke(REG_DEBUG_ENABLE, 0xC0DE)
    return peek(REG_DEBUG_ENABLE) == 0x1DEA
  
  proc close*() =
    poke(REG_DEBUG_ENABLE, 0)
  
  when natuMgbaLogging:
    
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
  
  else:
    
    template printf*(level: LogLevel, str: cstring, args: varargs[untyped]) =
      discard
      
    template printf*(str: cstring, args: varargs[untyped]) =
      discard

elif natuPlatform == "sdl":
  
  when natuMgbaLogging:
    
    #[
    proc c_printf(format: cstring) {.varargs, importc:"printf", header:"stdio.h".}
    
    var buf: array[1024, char]
    
    # Wrapper template to work around compiler bug with empty varargs?
    template printfAux(str: cstring, args: varargs[untyped]) =
      posprintf(cast[cstring](addr buf), str, args)
      c_printf("%s\n", cast[cstring](addr buf))
    ]#
    
    import ./private/sdl/appcommon
    var natuMem {.importc.}: ptr NatuAppMem
    
    var buf: array[1024, char]
    
    template printfAux(str: cstring, args: varargs[untyped]) =
      posprintf(cast[cstring](addr buf), str, args)
      natuMem.printf(cast[cstring](addr buf))
    
    template printf*(level: LogLevel, str: cstring, args: varargs[untyped]) =
      printfAux(str, args)
    
    template printf*(str: cstring, args: varargs[untyped]) =
      printfAux(str, args)
    
  else:
    
    template printf*(level: LogLevel, str: cstring, args: varargs[untyped]) =
      discard
      
    template printf*(str: cstring, args: varargs[untyped]) =
      discard
