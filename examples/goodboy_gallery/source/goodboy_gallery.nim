## Gallery Demo
## ------------
## This example demonstrates the use of Natu's asset system.
## 
## A `Graphic` enum is generated based on the "graphics.nims" config file.
## Graphics can be used at compile time and at runtime.
## 
## Similarly, enums are generated for backgrounds, music modules and samples.
## 
## While this example is still rather direct and low-level, it uses allocators
## to make managing sprite tiles and palettes easier. The Graphic enum is set
## up to work with these allocators directly.

import natu/[video, oam, bios, irq, input, math]
import natu/[graphics, backgrounds]
import audio, simple_anim

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

proc initCurrentSprite(g: Graphic) =
  graphic = g
  anim = initAnim(anims[g])
  obj.init(
    pos = vec2i(120, 80) - vec2i(g.width, g.height) / 2,
    size = g.size,
    tid = allocObjTiles(g),  # Reserve enough tiles in VRAM for 1 frame of animation.
    pal = acquireObjPal(g),  # Load the palette into a slot in the PAL RAM buffer
  )

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
  
  if anim.dirty:
    # copy a new frame into VRAM only if we're on a different
    # frame of animation than previously.
    copyFrame(addr objTileMem[obj.tid], graphic, anim.frame)
  
  # Copy palette buffers into PAL RAM.
  flushPals()


proc onVBlank =
  audio.vblank()
  draw()
  audio.frame()


proc main =
  
  # setup
  
  irq.put(iiVBlank, onVBlank)
  
  audio.init()
  
  dispcnt.init(layers = { lBg0, lObj }, obj1d = true)
  
  # Init BG0
  bgcnt[0].init(cbb = 0, sbb = 31)
  
  # Copy the tiles, map and palette
  bgcnt[0].load(bgDarkClouds)
  
  # Hide all sprites
  for obj in mitems(objMem):
    obj.hide()
  
  playSong(modSubway)
  initCurrentSprite(gfxPlayer)
  
  while true:
    keyPoll()
    update()
    VBlankIntrWait()


main()
