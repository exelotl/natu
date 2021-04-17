# Implementation of useful graphic operations below:

template data*(g: Graphic): GraphicData = staticGfxData[g]
template w*(g: Graphic): int = g.data.w
template h*(g: Graphic): int = g.data.h
template bpp*(g: Graphic): int = g.data.bpp
template size*(g: Graphic): ObjSize = g.data.size

const tileWords = (sizeof(Tile4) div sizeof(uint32))

template frameTiles*(g: Graphic): int =
  ## How many 4bpp tiles does a single frame of animation occupy in VRAM?
  ## Note, 8bpp graphics take up twice as many tiles.
  g.data.frameWords div tileWords

template allTiles*(g: Graphic): int =
  ## How many 4bpp tiles does the entire spritesheet occupy in VRAM?
  ## Note, 8bpp graphics take up twice as many tiles.
  g.data.imgWords div tileWords

template numFrames*(g: Graphic): int =
  ## How many frames exist in the sprite sheet?
  g.data.frames

template copyPal*(dest: ptr Palette, g: Graphic) =
  # static:
  #   doAssert(g.bpp == 4, "copyPal is only implemented for 4bpp graphics")
  #   doAssert(g.data.palHalfwords <= 16, "Exceeded maximum size for a single 4bpp palette")
  memcpy16(dest, unsafeAddr palData[g.data.palPos], g.data.palHalfwords)

template copyAllFrames*(dest: ptr Tile4 | ptr Tile8, g: Graphic) =
  ## Copy all frames of animation to a location in object VRAM
  memcpy32(dest, unsafeAddr imgData[g.data.imgPos], g.data.imgWords div sizeof(uint32))

template copyFrame*(dest: ptr Tile4, g: Graphic, frame: int) =
  ## Copy a single frame of animation to a location in object VRAM
  memcpy32(dest, unsafeAddr imgData[g.data.imgPos + g.data.frameWords * sizeof(uint32) * frame], g.data.frameWords)

template onscreen*(g: Graphic, pos: Vec2i): bool =
  ## Check if a graphic would be onscreen when drawn at a given location
  pos.x + g.w >= 0 and pos.y + g.h >= 0 and pos.x < ScreenWidth and pos.y < ScreenHeight

template onscreen*(r: Rect): bool =
  ## Check if a rectangle is on-screen
  r.right >= 0 and r.bottom >= 0 and r.left < ScreenWidth and r.top < ScreenHeight
