## Input
## =====
## Routines for synchronous and asynchronous button states.
## For details, see http://www.coranac.com/tonc/text/keys.htm

{.warning[UnusedImport]: off.}

import common
import bios

{.compile(toncPath & "/src/tonc_input.c", toncCFlags).}

# [Note: the C functions actually deal with 32-bit values but the underlying 
# registers and associated KEY_XXX constants are all 16-bit. So I've made
# the bindings use 16-bit values. Hopefully this won't cause problems.]

# [Ommitted: KeyIndex enum, some extra macros]

type KeyState* = distinct uint16
  ## 16-bit key state value, allows implicit converstion to bool for when
  ## you don't care *which* of the specified keys are pressed.

converter toKeyState*(k:uint16): KeyState {.inline.} = k.KeyState
converter toU16*(k:KeyState): uint16 {.inline.} = k.uint16
converter toBool*(k:KeyState): bool {.inline.} = (k.uint16 != 0)

# Basic synchonous keystates
# --------------------------

proc keyPoll*() {.importc: "key_poll", header: "tonc.h".}
  ## Poll for keystates and repeated keys.
  ## This should be called once at the start of each frame.
  
proc keyCurrState*(): KeyState {.importc: "key_curr_state", header: "tonc.h".}
  ## Get current keystate

proc keyPrevState*(): KeyState {.importc: "key_prev_state", header: "tonc.h".}
  ## Get previous key state

proc keyIsDown*(key: KeyState): KeyState {.importc: "key_is_down", header: "tonc.h".}
  ## Gives the keys of ``key`` that are currently down

proc keyIsUp*(key: KeyState): KeyState {.importc: "key_is_up", header: "tonc.h".}
  ## Gives the keys of ``key`` that are currently up

proc keyWasDown*(key: KeyState): KeyState {.importc: "key_was_down", header: "tonc.h".}
  ## Gives the keys of ``key`` that were previously down

proc keyWasUp*(key: KeyState): KeyState {.importc: "key_was_up", header: "tonc.h".}
  ## Gives the keys of ``key`` that were previously up


# Transitional keystates
# ----------------------

proc keyTransit*(key: KeyState): KeyState {.importc: "key_transit", header: "tonc.h".}
  ## Gives the keys of ``key`` that are different from before

proc keyHeld*(key: KeyState): KeyState {.importc: "key_held", header: "tonc.h".}
  ## Gives the keys of ``key`` that are being held down

proc keyHit*(key: KeyState): KeyState {.importc: "key_hit", header: "tonc.h".}
  ## Gives the keys of ``key`` that are pressed (down now but not before)

proc keyReleased*(key: KeyState): KeyState {.importc: "key_released", header: "tonc.h".}
  ## Gives the keys of ``key`` that are being released


# Tribools
# --------

proc keyTriHorz*(): int {.importc: "key_tri_horz", header: "tonc.h".}
  ## Horizontal tribool (right,left)=(+,-)

proc keyTriVert*(): int {.importc: "key_tri_vert", header: "tonc.h".}
  ## Vertical tribool (down,up)=(+,-)

proc keyTriShoulder*(): int {.importc: "key_tri_shoulder", header: "tonc.h".}
  ## Shoulder-button tribool (R,L)=(+,-)

proc keyTriFire*(): int {.importc: "key_tri_fire", header: "tonc.h".}
  ## Fire-button tribool (A,B)=(+,-)


# Key repeats
# -----------

proc keyRepeat*(keys: KeyState): KeyState {.importc: "key_repeat", header: "tonc.h".}
  ## Get status of repeated keys.
  
proc keyRepeatMask*(mask: KeyState) {.importc: "key_repeat_mask", header: "tonc.h".}
  ## Set repeat mask. Only these keys will be considered for repeats.
  
proc keyRepeatLimits*(delay: uint; repeat: uint) {.importc: "key_repeat_limits", header: "tonc.h".}
  ## Set the delay and repeat limits for repeated keys
  ## ``delay``  Set first repeat limit. If 0, repeats are off.
  ## ``repeat`` Sets later repeat limit.
  ## Note: Both limits have a range of [0, 255]. If either argument is <0, the old value will be kept.


proc keyWaitTillHit*(key: KeyState) {.importc: "key_wait_till_hit", header: "tonc.h".}
  ## Wait until `key` is hit.