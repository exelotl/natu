## Gallery Demo
## ------------
## This example demonstrates the use of Natu's asset system.
## 
## A `Graphic` enum is generated based on the "graphics.nims" config file.
## Graphics can be used at compile time and at runtime.
## 
## While this example is still rather direct and low-level, it uses allocators
## to make managing sprite tiles and palettes easier. The Graphic enum is set
## up to work with these allocators directly.

import natu/[core, irq, oam, input]
import graphics, audio, simple_anim

const anims: array[Graphic, AnimData] = [
  gfxBarrier:   AnimData(first: 0, len: 10, speed: 3),
  gfxGem:       AnimData(first: 0, len: 8, speed: 4),
  gfxPlayer:    AnimData(first: 0, len: 8, speed: 5),
  gfxSacrificedItems: AnimData(first: 0, len: 8, speed: 3),
  gfxBullet:    AnimData(first: 0, len: 4, speed: 3),
  gfxMuzzle:    AnimData(first: 0, len: 8, speed: 2),
  gfxBreakable: AnimData(first: 7, len: 7, speed: 3),
  gfxShield:    AnimData(first: 0, len: 4, speed: 2),
]

var graphic: Graphic     # Current image to show
var anim: Anim           # Animation state
var obj: ObjAttr         # Sprite fields
var dirty = false        # True if palette and tiles need to be updated on next VBlank

proc initCurrentSprite(g: Graphic) =
  graphic = g
  anim = initAnim(anims[g])
  obj.init(
    pos = vec2i(120, 80) - vec2i(g.w, g.h) / 2,
    size = g.size,
    tid = allocObjTiles(g),  # Reserve enough tiles in VRAM for 1 frame of animation.
    pal = acquireObjPal(g),  # Use a slot in PAL RAM.
  )
  dirty = true

proc destroyCurrentSprite() =
  freeObjTiles(obj.tid)    # Free the tiles.
  releaseObjPal(graphic)   # Palette will also be freed only if nobody else is using it.


proc update =
  ## Run game logic
  
  if keyHit(kiLeft):
    if graphic > Graphic.low:
      playSound(sfxChanged)
      destroyCurrentSprite()
      initCurrentSprite(graphic.pred)
    else:
      playSound(sfxBlocked)
  
  if keyHit(kiRight):
    if graphic < Graphic.high:
      playSound(sfxChanged)
      destroyCurrentSprite()
      initCurrentSprite(graphic.succ)
    else:
      playSound(sfxBlocked)
  
  anim.update()


proc draw =
  ## Do graphical updates
  
  # update OAM entry
  # note: unlike in C, we can do this assignment without clobbering the affine data.
  objMem[0] = obj
  
  if dirty:
    # copy palette & frame into VRAM
    copyPal(addr objPalMem[obj.pal], graphic)
    copyFrame(addr objTileMem[obj.tid], graphic, anim.frame)
    dirty = false
  
  elif anim.dirty:
    # copy a new frame into VRAM only if we're on a different
    # frame of animation than previously.
    copyFrame(addr objTileMem[obj.tid], graphic, anim.frame)


proc onVBlank =
  audio.vblank()
  draw()
  audio.frame()


proc main =
  
  # setup
  
  irq.init()
  irq.enable(iiVBlank)
  irq.add(iiVBlank, onVBlank)
  
  audio.init()
  
  dispcnt.init(obj = true, obj1d = true)
  
  for obj in mitems(objMem):
    obj.hide()
  
  playSong(modSubway)
  initCurrentSprite(gfxPlayer)

  while true:
    keyPoll()
    update()
    VBlankIntrWait()


main()
