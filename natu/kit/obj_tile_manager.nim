import natu/[memory, utils, video]

type ObjTileState {.size: 1.} = enum
  otUnused
  otUsed
  otContinue

const MaxObjTiles = 1024

var objTiles {.codegenDecl:DataInEwram.}: array[MaxObjTiles+1, ObjTileState]  # length+1 for "null terminator"

# Potential optimisation - keep track of the lowest guaranteed 'free' tile and only begin searching from there.
# If some memory is freed that is lower than that tile, set it to be equal to that

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
  while n < MaxObjTiles:
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
  
  when defined(natuPanicWhenOutOfObjTiles):
    doAssert(false, "Ran out of obj tiles")
  else:
    MaxObjTiles - tiles

proc paintUnused(i: int, len = 1) =
  when defined(natuShowUnusedObjTiles):
    memset32(
      dst = addr objTileMem[i],
      wd = 0x10101010,
      wcount = (len * sizeof(Tile)) div 4
    )

proc freeObjTiles*(tileId: int) =
  ## 
  ## Free tiles from Obj VRAM
  ## 
  objTiles[tileId] = otUnused
  paintUnused(tileId)
  var i = tileId + 1
  while objTiles[i] == otContinue:
    objTiles[i] = otUnused
    paintUnused(i)
    inc(i)


# initialise OBJ VRAM (if we're rendering unused tiles for debug purposes.)

paintUnused(0, MaxObjTiles)
