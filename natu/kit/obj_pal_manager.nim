# Obj PAL RAM allocator
# ---------------------
# This lets you allocate or free palettes for sprites.

import natu/core

type
  PalState {.size: 1.} = enum
    palUnused = 0
    palUsed = 1

var objPals {.codegenDecl:EWRAM_DATA.}: array[16, PalState]

proc allocObjPal*: int =
  ## Allocate a 4bpp palette in Obj PAL RAM.
  for i, v in objPals:
    if v == palUnused:
      objPals[i] = palUsed
      return i
  assert(false, "Ran out of obj palettes")
  objPals.len-1

proc freeObjPal*(i: int) =
  ## Deallocate a 4bpp palette in Obj PAL RAM.
  objPals[i] = palUnused
  when defined(natuShowFreePals):
    objPalMem[i][0] = clrRed
