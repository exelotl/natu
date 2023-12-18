import std/[parseopt]
import sdl2_nim/sdl
import ./natu/private/sdl/appcommon
import ./natu/sdl/xatu_app
import ./natu/sdl/xatu_loader

const helpMsg = """
Runner for natu PC games.

Usage:
  xatu your_game.so|dll|dylib
"""

var sharedlib = ""
var p = initOptParser()

for kind, k, v in p.getopt():
  case kind
  of cmdArgument:
    if sharedlib == "":
      sharedlib = k
    else:
      quit("Too many arguments.\n" & helpMsg)
  of cmdLongOption, cmdShortOption:
    case k
    of "h","help": quit(helpMsg, 0)
    else: quit("Unrecognised option '" & k & "'\n" & helpMsg)
  of cmdEnd:
    if sharedlib == "":
      quit(helpMsg, 0)


let app = App()
app.start()
assert(app.running)

proc xatuPanic(msg1, msg2: cstring) {.exportc.} =
  raise newException(Exception, "Panic!\n" & $msg1 & "\n" & $msg2)

mem.panic = xatuPanic

loadNatuGame(sharedlib)
natuAppInit(addr mem)

while app.running:
  
  # Clear screen with draw color
  if app.renderer.renderClear() != 0:
    sdl.logWarn(sdl.LogCategoryVideo, "Can't clear screen: %s", sdl.getError())
  
  natuAppUpdate()
  natuAppDraw()
  app.draw()
  app.handleEvents()

app.exit()
