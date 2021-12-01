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

let keyinput* {.importc:"(*(volatile KeyInput*)(0x04000130))", nodecl.}: KeyInput
  ## Keypad status register (read only).
  ## 
  ## Usually you don't want to read this directly.

var keycnt* {.importc:"(*(volatile KeyCnt*)(0x04000132))", nodecl.}: KeyCnt
  ## Key interrupt control register.
  ## 
  ## See the `irq <irq.html>`_ module

var keyCurrState*: KeyState
  ## The set of keys that are currently down on this frame.

var keyPrevState*: KeyState
  ## The set of keys that were down on the previous frame.

const allKeys*: KeyState = {kiA..kiL}

{.push inline.}

proc state*(keyinput: KeyInput): KeyState =
  ## Flip the `keyinput` register to obtain the set of keys which are currently pressed.
  {KeyIndex.low .. KeyIndex.high} - cast[KeyState](keyinput)

proc keyPoll* =
  ## Should be called once per frame to update the current key state.
  keyPrevState = keyCurrState
  keyCurrState = keyinput.state

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
  ## True if any of the given keys are currently down.
  s * (keyCurrState - keyPrevState) != {}

{.pop.}
