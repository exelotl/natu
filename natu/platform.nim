import ./private/common

when natuPlatform == "gba":
  discard

elif natuPlatform == "sdl":
  
  import ./private/sdl/applib
  
  # File IO (not available on GBA platform)
  
  proc readFile*(path: cstring): tuple[ok: bool, res: string] =
    natuMem.readFile(path)
  
  proc writeFile*(path: cstring; contents: string): tuple[ok: bool, msg: string] =
    natuMem.writeFile(path, contents)
  
  proc fileExists*(path: cstring): bool =
    natuMem.fileExists(path)
  
  proc getEnv*(key: cstring): string =
    natuMem.getEnv(key)

else:
  {.error: "Unknown platform " & natuPlatform.}
