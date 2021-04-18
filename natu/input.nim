import private/[types, reg]
  
export KeyIndex, KeyState

const allKeys*: KeyState = {kiA..kiL}

var
  keyCurrState*: KeyState  ## The set of keys that are currently down on this frame
  keyPrevState*: KeyState  ## The set of keys that were down on the previous frame

proc keyPoll* =
  ## Should be called once per frame.
  keyPrevState = keyCurrState
  keyCurrState = keyinput.state

{.push inline.}

proc keysDown*: KeyState =
  ## Get all the keys which are currently down
  keyCurrState

proc keysUp*: KeyState =
  ## Get all the keys which are currently up
  allKeys - keyCurrState

proc keysHit*: KeyState =
  ## Get all the keys which were just pressed on this frame
  keyCurrState - keyPrevState

proc keysReleased*: KeyState =
  ## Get all the keys which were previously pressed but are no longer pressed
  keyPrevState - keyCurrState

proc keyIsDown*(k: KeyIndex): bool =
  ## True if the given key is currently down
  k in keyCurrState

proc keyIsUp*(k: KeyIndex): bool =
  ## True if the given key is currently up
  k notin keyCurrState

proc keyWasDown*(k: KeyIndex): bool =
  ## True if the given key was previously down
  k in keyPrevState

proc keyWasUp*(k: KeyIndex): bool =
  ## True if the given key was previously up
  k notin keyPrevState

proc keyHit*(k: KeyIndex): bool =
  ## True if the given key was just pressed on this frame
  k in (keyCurrState - keyPrevState)

proc keyReleased*(k: KeyIndex): bool =
  ## True if the given key was just released on this frame
  k in (keyPrevState - keyCurrState)

proc anyKeyHit*(s: KeyState): bool =
  ## True if any of the given keys are currently down
  s * (keyCurrState - keyPrevState) != {}

{.pop.}
