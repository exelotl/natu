import ./private/common

when natuPlatform == "gba":
  discard

elif natuPlatform == "sdl":
  
  import ./private/sdl/applib
  import std/strutils
  
  # File IO (not available on GBA platform)
  
  proc readFile*(path: cstring): tuple[ok: bool, res: string] =
    natuMem.readFile(path)
  
  proc writeFile*(path: cstring; contents: string): tuple[ok: bool, msg: string] =
    natuMem.writeFile(path, contents)
  
  proc fileExists*(path: cstring): bool =
    natuMem.fileExists(path)
  
  proc env*(key: cstring): string =
    natuMem.getEnv(key)
  
  proc envi*(k: cstring): int =
    parseInt(env(k))
  
  proc envf*(k: cstring): float32 =
    parseFloat(env(k))
  
  proc envb*(k: cstring): bool =
    parseBool(env(k))

else:
  {.error: "Unknown platform " & natuPlatform.}
