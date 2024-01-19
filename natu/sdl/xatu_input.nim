import sdl2_nim/sdl
import std/[packedsets, tables]

type
  GbaKeyIndex* = enum
    kiA            ## Button A
    kiB            ## Button B
    kiSelect       ## Select button
    kiStart        ## Start button
    kiRight        ## Right D-pad
    kiLeft         ## Left D-pad
    kiUp           ## Up D-pad
    kiDown         ## Down D-pad
    kiR            ## Shoulder R
    kiL            ## Shoulder L

var prevKeys, currKeys: PackedSet[int32]
var gbaKeys*: set[GbaKeyIndex]
var keyMap*: Table[sdl.Keycode, GbaKeyIndex]

# TODO: add key remapping support:
keyMap = {
  K_Z: kiA,
  K_X: kiB,
  K_BACKSPACE: kiSelect,
  K_RETURN: kiStart,
  K_RIGHT: kiRight,
  K_LEFT: kiLeft,
  K_UP: kiUp,
  K_DOWN: kiDown,
  K_A: kiL,
  K_S: kiR,
}.toTable[:sdl.Keycode, GbaKeyIndex]()

proc pressKey*(key: sdl.KeyboardEventObj) =
  let sym = key.keysym.sym
  currKeys.incl ord(sym)
  if sym in keyMap:
    gbaKeys.incl keyMap[sym]

proc releaseKey*(key: sdl.KeyboardEventObj) =
  let sym = key.keysym.sym
  currKeys.excl ord(sym)
  if sym in keyMap:
    gbaKeys.excl keyMap[sym]

proc updateKeys*() =
  # To be called *after* the game logic for this frame?
  prevKeys = currKeys
  currKeys.clear()

proc keyIsDown*(sym: sdl.Keycode): bool =
  ord(sym) in currKeys

proc keyJustPressed*(sym: sdl.Keycode): bool =
  ord(sym) in currKeys and ord(sym) notin prevKeys

export sdl.Keycode
