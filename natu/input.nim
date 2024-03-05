import ./private/common

type
  KeyIndex* = enum
    ## Bit positions for `keyinput` and `keycnt`.
    ## Used with input functions such as `keyIsDown`.
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
  
  KeyState* {.size:2.} = set[KeyIndex]

  KeyInput* {.exportc.} = object
    invertedState*: KeyState
  
  KeyIntrOp* = enum
    opOr   ## Raise interrupt if any of the specified keys are pressed.
    opAnd  ## Raise interrupt if *all* specified keys are pressed at the same time.
  
  KeyCnt* {.exportc.} = object
    keys* {.bitsize:10.}: KeyState  ## The set of keys that fire the keypad interrupt.
    _ {.bitsize:4.}: uint16
    irq* {.bitsize:1.}: bool        ## Enables the keypad interrupt.
    op* {.bitsize:1.}: KeyIntrOp    ## The condition under which the interrupt will be raised (`opOr` vs `opAnd`)
  
  KeyRepeater* = object
    keys*, mask*: KeyState
    timer*, delay*, period*: uint8


# Platform specific code
# ----------------------

when natuPlatform == "gba":
  
  let keyinput* {.importc:"(*(volatile KeyInput*)(0x04000130))", nodecl.}: KeyInput
    ## Keypad status register (read only).
    ## 
    ## This can be used to obtain the current state (up or down) of
    ## all the buttons on the GBA. Note that the state is inverted.
    ## 
    ## It is generally preferable to call `keyPoll` and use the various input
    ## procedures (`keyIsDown` etc.) rather than reading this directly.
  
  var keycnt* {.importc:"(*(volatile KeyCnt*)(0x04000132))", nodecl.}: KeyCnt
    ## Key interrupt control register.
    ## 
    ## See the `irq <irq.html>`_ module for details.

elif natuPlatform == "sdl":
  include ./private/sdl/input

else:
  {.error: "Unknown platform " & natuPlatform.}



var keyCurrState*: KeyState
  ## The set of keys that are currently down on this frame.

var keyPrevState*: KeyState
  ## The set of keys that were down on the previous frame.

const allKeys*: KeyState = {kiA..kiL}


var keyRepeater* = KeyRepeater(mask: allKeys, timer: 20, delay: 20, period: 10)

template repeat: KeyRepeater = keyRepeater  # internal alias.

proc `^`[T](a, b: set[T]): set[T] {.inline.} =
  ## Symmetric difference between two sets, analogous to XOR.
  when nimvm or sizeof(a) > sizeof(uint): (a + b) - (a * b)
  else: cast[set[T]](cast[uint](a) xor cast[uint](b))


{.push inline.}

proc state*(keyinput: KeyInput): KeyState =
  ## Flip the `keyinput` register to obtain the set of keys which are currently pressed.
  {KeyIndex.low .. KeyIndex.high} - cast[KeyState](keyinput)

proc keyPoll* =
  ## Should be called once per frame to update the current key state.
  keyPrevState = keyCurrState
  keyCurrState = keyinput.state
  
  repeat.keys = {}
  
  if repeat.mask != {}:
    if (keyCurrState ^ keyPrevState) * repeat.mask != {}:
      repeat.timer = repeat.delay
      repeat.keys = keyCurrState
    else:
      dec repeat.timer
    
    if repeat.timer == 0:
      repeat.timer = repeat.period
      repeat.keys = keyCurrState * repeat.mask
      
proc keysDown*: KeyState =
  ## Get all the keys which are currently down.
  keyCurrState

proc keysUp*: KeyState =
  ## Get all the keys which are currently up.
  allKeys - keyCurrState

proc keysHit*: KeyState =
  ## Get all the keys which were just pressed on this frame.
  keyCurrState - keyPrevState

proc keysReleased*: KeyState =
  ## Get all the keys which were previously pressed but are no longer pressed.
  keyPrevState - keyCurrState

proc keyIsDown*(k: KeyIndex): bool =
  ## True if the given key is currently down.
  k in keyCurrState

proc keyIsUp*(k: KeyIndex): bool =
  ## True if the given key is currently up.
  k notin keyCurrState

proc keyWasDown*(k: KeyIndex): bool =
  ## True if the given key was previously down.
  k in keyPrevState

proc keyWasUp*(k: KeyIndex): bool =
  ## True if the given key was previously up.
  k notin keyPrevState

proc keyHit*(k: KeyIndex): bool =
  ## True if the given key was just pressed on this frame.
  k in (keyCurrState - keyPrevState)

proc keyReleased*(k: KeyIndex): bool =
  ## True if the given key was just released on this frame.
  k in (keyPrevState - keyCurrState)

proc anyKeyHit*(s: KeyState): bool =
  ## True if any of the given keys were just pressed on this frame.
  s * (keyCurrState - keyPrevState) != {}


proc keysRepeated*(): KeyState =
  ## Get the keys that just repeated or were newly pressed.
  repeat.keys

proc keyRepeated*(k: KeyIndex): bool =
  ## Check if a key just repeated or was newly pressed.
  k in repeat.keys

proc setKeyRepeatMask*(mask: KeyState) =
  ## Set which keys will be considered for repeats.
  repeat.mask = mask

proc setKeyRepeatDelay*(delay: uint8) =
  ## Set the initial delay from when a key is first pressed to when it starts repeating.
  ## 
  ## If keys are already repeating, this will delay them again.
  repeat.delay = delay
  repeat.timer = delay

proc setKeyRepeatPeriod*(period: uint8) =
  ## Set the interval between repeated keys.
  repeat.period = period

{.pop.}
