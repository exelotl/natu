import natu/[video, memory, utils]

# Palette buffers
# ---------------
# These are targeted by gfx and bg operations such as `acquireObjPal`
# and `bg.loadPal`, or you can write directly to them.
# 
# Be sure to call `flushPals` during vblank to update the real palettes.
# Or you can use `clrFadeFast` from the `video` module to blend in a certain colour while copying.

var palBuf: array[2, array[16, Palette]]

template colorBuf: ptr array[2, array[256, Color]] =
  cast[ptr array[2, array[256, Color]]](addr palBuf)


template bgPalBuf*: array[16, Palette] = palBuf[0]
  ## Access the BG PAL RAM buffer as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp backgrounds.

template objPalBuf*: array[16, Palette] = palBuf[1]
  ## Access the OBJ PAL RAM buffer as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp sprites.

template bgColorBuf*: array[256, Color] = colorBuf[0]
  ## Access the BG PAL RAM buffer as a single array of colors.
  ## 
  ## This is useful when working with 8bpp backgrounds, or display mode 4.

template objColorBuf*: array[256, Color] = colorBuf[1]
  ## Access the OBJ PAL RAM buffer as a single array of colors.
  ## 
  ## This is useful when working with 8bpp sprites.

proc flushPals* {.inline.} =
  ## 
  ## Copy the palette buffers into PAL RAM.
  ## 
  ## This should be called every frame during VBlank.
  ## 
  memcpy32(addr bgPalMem, addr palBuf, sizeof(palBuf) div sizeof(uint32))


# Obj PAL RAM allocator
# ---------------------
# This lets you allocate or free palettes for sprites.

type
  PalState {.size: 1.} = enum
    palUnused = 0
    palUsed = 1

var objPals {.codegenDecl:EWRAM_DATA.}: array[16, PalState]

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

