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
    let s = env(k)
    if s == "": 0
    else: parseInt(s)
  
  proc envf*(k: cstring): float32 =
    let s = env(k)
    if s == "": 0f
    else: parseFloat(s).float32
  
  proc envb*(k: cstring): bool =
    let s = env(k)
    if s == "": false
    else: parseBool(s)

else:
  {.error: "Unknown platform " & natuPlatform.}
