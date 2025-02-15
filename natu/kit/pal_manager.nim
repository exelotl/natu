import natu/[video, memory, utils]
import natu/private/common

when natuPlatform == "gba":
  const numBgPals = 16
  const numObjPals = 16
elif natuPlatform == "sdl":
  const numBgPals = 16
  const numObjPals = 32
else:
  {.error: "Unknown platform " & natuPlatform.}

const numBgColors = numBgPals*16
const numObjColors = numObjPals*16
const numTotalColors = numBgColors + numObjColors

# Palette buffers
# ---------------
# These are targeted by gfx and bg operations such as `acquireObjPal`
# and `bg.loadPal`, or you can write directly to them.
# 
# Be sure to call `flushPals` during vblank to update the real palettes.
# Or you can use `clrFadeFast` from the `video` module to blend in a certain colour while copying.

var colorBuf: array[numTotalColors, Color]

template bgPalBuf*: array[numBgPals, Palette] =
  ## Access the BG PAL RAM buffer as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp backgrounds.
  cast[ptr array[numBgPals, Palette]](addr colorBuf[0])[]

template objPalBuf*: array[numObjPals, Palette] =
  ## Access the OBJ PAL RAM buffer as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp sprites.
  cast[ptr array[numObjPals, Palette]](addr colorBuf[numBgColors])[]

template bgColorBuf*: array[numBgColors, Color] =
  ## Access the BG PAL RAM buffer as a single array of colors.
  ## 
  ## This is useful when working with 8bpp backgrounds, or display mode 4.
  cast[ptr array[numBgColors, Color]](addr colorBuf[0])[]

template objColorBuf*: array[numObjColors, Color] =
  ## Access the OBJ PAL RAM buffer as a single array of colors.
  ## 
  ## This is useful when working with 8bpp sprites.
  cast[ptr array[numObjColors, Color]](addr colorBuf[numBgColors])[]

proc flushPals* {.inline.} =
  ## 
  ## Copy the palette buffers into PAL RAM.
  ## 
  ## This should be called every frame during VBlank.
  ## 
  memcpy32(addr bgPalMem, addr colorBuf, sizeof(colorBuf) div sizeof(uint32))


# Obj PAL RAM allocator
# ---------------------
# This lets you allocate or free palettes for sprites.

type
  PalState {.size: 1.} = enum
    palUnused = 0
    palUsed = 1

var objPals {.codegenDecl:DataInEwram.}: array[numObjPals, PalState]

proc allocObjPal*: int =
  ## Allocate a 4bpp palette in Obj PAL RAM.
  for i in countdown(objPals.len-1, 0):
    if objPals[i] == palUnused:
      objPals[i] = palUsed
      return i
  assert(false, "Ran out of obj palettes")
  0

proc freeObjPal*(i: int) =
  ## Deallocate a 4bpp palette in Obj PAL RAM.
  objPals[i] = palUnused
  when defined(natuShowFreePals):
    objPalBuf[i][0] = clrRed
    for j in 1..15:
      objPalBuf[i][j] = clrBlack

# initialisation:
when defined(natuShowFreePals):
  for i in 0..<objPalMem.len:
    objPalBuf[i][0] = clrRed

