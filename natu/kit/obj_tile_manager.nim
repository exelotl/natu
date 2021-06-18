import natu/core

type ObjTileState {.size: 1.} = enum
  otUnused
  otUsed
  otContinue

var objTiles {.codegenDecl:EWRAM_DATA.}: array[1024, ObjTileState]

proc allocObjTiles*(tiles: range[1..1024], snap: range[0..9] = 0): int =
  ## 
  ## Allocate some tiles in Obj VRAM
  ## 
  ## **Parameters:**
  ## 
  ## tiles
  ##   | How many 4bpp tiles to allocate.
  ##   | If you want 8bpp tiles, you have to ask for twice as many.
  ## 
  ## snap
  ##   Quantise the allocation to the nearest ``2^snap`` tiles.
  ## 
  var start = 0
  var n = 0
  while n < objTiles.len:
    if objTiles[n] == otUnused:
      if (n-start)+1 == tiles:     # do we have enough consecutive unused blocks?
        objTiles[start] = otUsed   # mark the first block as used
        for i in start+1 .. n:     # mark the rest of the blocks as 'continue' i.e. belonging to the start block
          objTiles[i] = otContinue
        return start               # return tile number
      n += 1
    else:
      # broke the chain, let's start again from the next block
      # snap to nearest 2^snap blocks to help prevent fragmentation
      n = n shr snap
      n += 1
      n = n shl snap
      start = n
  
  assert(false, "Ran out of obj tiles")
  0


proc freeObjTiles*(tileId: int) =
  ## 
  ## Free tiles from Obj VRAM
  ## 
  objTiles[tileId] = otUnused
  var i = tileId + 1
  while objTiles[i] == otContinue:
    objTiles[i] = otUnused
    inc(i)
