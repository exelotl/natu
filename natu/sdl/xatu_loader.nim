import std/[dynlib, os, strformat]
import ../private/sdl/appcommon

when defined(posix) and not defined(nintendoswitch):
  import posix
  proc getLibError(): string =
    $dlerror()
else:
  proc getLibError(): string = "Error message not available"

var handle: LibHandle = nil

# Must be called as early as possible by the host!
var natuAppInit*: proc (mem: ptr NatuAppMem) {.nimcall.} = nil
var natuAppUpdate*: proc () {.nimcall.} = nil
var natuAppDraw*: proc () {.nimcall.} = nil

template loadSymbol(ident: untyped) =
  ident = cast[type(ident)](checkedSymAddr(handle, astToStr(ident)))

proc loadNatuGame*(sharedlib: string) =
  doAssert handle == nil
  
  handle = loadLib(sharedlib)
  if handle == nil:
    raise newException(LibraryError, &"Failed to load lib: {getLibError()}")
  
  loadSymbol natuAppInit
  loadSymbol natuAppUpdate
  loadSymbol natuAppDraw
