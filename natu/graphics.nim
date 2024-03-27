import natu/[video, math, utils]
import natu/kit/[pal_manager, obj_tile_manager]
from natu/private/common import doInclude, natuOutputDir

export pal_manager
export obj_tile_manager
export ObjSize

type
  GraphicFlag* = enum
    StrictPal
    PalOnly
  GraphicData* = object
    imgPos*: int
    palPos*: int
    imgWords*: int
    palNum: uint16
    frames: uint16
    frameWords: uint16
    palHalfwords: uint8
    bpp: uint8
    w, h: uint8
    size*: ObjSize
    flags*: set[GraphicFlag]

doInclude natuOutputDir & "/graphics.nim"


# Implementation of useful graphic operations below:

template width*(g: Graphic): int = g.data.w.int
  ## The width of the graphic in pixels.

template height*(g: Graphic): int = g.data.h.int
  ## The height of the graphic in pixels.

# shorthands
template w*(g: Graphic): int = g.data.w.int
template h*(g: Graphic): int = g.data.h.int

template size*(g: Graphic): ObjSize = g.data.size
  ## The size value for the graphic, as required by hardware sprites.
  ## 
  ## For example a 16x32 sprite will have a size value of `s16x32`.

template bpp*(g: Graphic): int = g.data.bpp.int
  ## The number of bits-per-pixel used by the sprite's gfx data.
  ## 
  ## This will be either 2, 4 or 8.

const tileWords = (sizeof(Tile4) div sizeof(uint32))

template frameTiles*(g: Graphic): int =
  ## 
  ## How many 4bpp tiles does a single frame of animation occupy in VRAM?
  ## Note, 8bpp graphics take up twice as many tiles.
  ## 
  g.data.frameWords.int div tileWords

template allTiles*(g: Graphic): int =
  ## 
  ## How many 4bpp tiles does the entire spritesheet occupy in VRAM?
  ## Note, 8bpp graphics take up twice as many tiles.
  ## 
  g.data.imgWords div tileWords

template numFrames*(g: Graphic): int =
  ## 
  ## How many frames exist in the sprite sheet?
  ## 
  g.data.frames.int

template copyPal*(dest: var Palette, g: Graphic) =
  ## 
  ## Copy palette data from a graphic into some destination, 4bpp version.
  ## 
  when g is static:
    static:
      doAssert(g.bpp != 8, "Can't copy 8bpp palettes to a `var Palette`")
      doAssert(g.data.palHalfwords <= 16, "Exceeded maximum size for a single 4bpp palette.")
  else:
    assert(g.bpp != 8, "Can't copy 8bpp palettes to a `var Palette`")
    assert(g.data.palHalfwords <= 16, "Exceeded maximum size for a single 4bpp palette.")
  memcpy16(addr dest, g.palDataPtr, g.data.palHalfwords)

template copyPal*(dest: ptr Color | ptr Palette, g: Graphic) =
  ## 
  ## Copy palette data from a graphic into some destination (unsafe version, works with 8bpp)
  ## 
  memcpy16(dest, g.palDataPtr, g.data.palHalfwords)

template copyAllFrames*(dest: ptr Tile4 | ptr Tile8, g: Graphic) =
  ## 
  ## Copy all frames of animation to a location in Object VRAM
  ## 
  memcpy32(dest, g.imgDataPtr, g.data.imgWords)

template copyFrame*(dest: ptr Tile4, g: Graphic, frame: int) =
  ## 
  ## Copy a single frame of animation to a location in Object VRAM
  ## 
  let img = cast[ptr UncheckedArray[uint32]](g.imgDataPtr)
  memcpy32(dest, addr img[g.data.frameWords.int * frame], g.data.frameWords)

template onscreen*(g: Graphic, pos: Vec2i): bool =
  ## 
  ## Check if a graphic would be onscreen when drawn at a given location
  ## 
  pos.x + g.width >= 0 and pos.y + g.height >= 0 and pos.x < ScreenWidth and pos.y < ScreenHeight

func onscreen*(r: Rect): bool {.inline.} =
  ## 
  ## Check if a rectangle is on-screen
  ## 
  r.right >= 0 and r.bottom >= 0 and r.left < ScreenWidth and r.top < ScreenHeight


# Graphic palette allocation
# --------------------------
# Every graphic in your `graphics.nims` gets an associated palNum.
# Graphics defined under a `sharePal` block will have the same palNum.

type
  PalUsage {.size: sizeof(uint16).} = object
    index {.bitsize: 5.}: uint    ## Which slot in Obj PAL RAM is this palNum assigned to? (can refer to 32 obj palettes, for PC support.)
    count {.bitsize: 11.}: uint   ## How many times is it used?

proc acquireObjPal(u: var PalUsage, palData: pointer, palHalfwords: int): int {.discardable.} =
  if u.count == 0:
    let palId = allocObjPal()
    u.index = palId.uint
    memcpy16(addr objPalBuf[palId], palData, palHalfwords)
    result = palId
  else:
    result = u.index.int
  inc u.count

proc releaseObjPal(u: var PalUsage) =
  var count = u.count
  if count > 0'u:
    dec count
    if count == 0'u:
      freeObjPal(u.index.int)
    u.count = count
  else:
    assert(false, "Tried to release an obj palette not in use")

template acquireObjPal*(g: Graphic): int =
  ## 
  ## Increase the reference count for a graphic's palette data.
  ## 
  ## If the count was zero, a slot in Obj PAL RAM will be allocated
  ## using :ref:`allocObjPal`, and the palette data will be copied into
  ## the corresponding slot in :ref:`objPalBuf`.
  ## 
  ## Returns which slot in Obj PAL RAM was used, but you don't have
  ## to use the returned value, as you can always check it later
  ## with `getPalId`.
  ## 
  let u = cast[ptr PalUsage](addr palUsage(g))
  acquireObjPal(u[], g.palDataPtr, g.data.palHalfwords.int)

template releaseObjPal*(g: Graphic) =
  ## 
  ## Decrease the reference count for a graphic's palette data.
  ## 
  ## If the count reaches zero, the palette will be freed.
  ## 
  let u = cast[ptr PalUsage](addr palUsage(g))
  releaseObjPal(u[])

template getPalId*(g: Graphic): int =
  ## 
  ## Get the current slot in Obj PAL RAM used by a graphic.
  ## 
  let u = cast[PalUsage](palUsage(g))
  assert(u.count > 0, "Tried to get palId of graphic whose palette is not in use.")
  u.index.int

template loadPal*(g: Graphic) =
  ## 
  ## Load palette data from a graphic into the correct slot in the Obj PAL RAM buffer.
  ## 
  memcpy16(addr objPalBuf[getPalId(g)], g.palDataPtr, g.data.palHalfwords)


# Graphic tile allocation
# -----------------------

template allocObjTiles*(g: Graphic): int =
  ## Allocate tiles for 1 frame of animation with the ideal snap amount
  when g is static:
    const snap = logPowerOfTwo(g.frameTiles.uint).int
  else:
    let snap = logPowerOfTwo(g.frameTiles.uint).int
  allocObjTiles(g.frameTiles, snap)


# Expose gfx internal fields as int for convenience.

template palNum*(gd: GraphicData): int = int(gd.palNum)
template palHalfwords*(gd: GraphicData): int = int(gd.palHalfwords)
template frames*(gd: GraphicData): int = int(gd.frames)
template frameWords*(gd: GraphicData): int = int(gd.frameWords)
template bpp*(gd: GraphicData): int = int(gd.bpp)
template w*(gd: GraphicData): int = int(gd.w)
template h*(gd: GraphicData): int = int(gd.h)
