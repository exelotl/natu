import natu/[core, irq, oam, input]
import graphics

# Simple looping animation:
type
  AnimData = object
    first, len, speed: int
  Anim = object
    data: AnimData
    frame, timer: int

proc initAnim(data: AnimData): Anim
proc update(a: var Anim)
proc dirty(a: Anim): bool


# The Graphic enum is generated based on the "gfx.nims" config file.
# Graphics can be used at compile time or at runtime

var graphic: Graphic
var anim: Anim

const anims: array[Graphic, AnimData] = [
  gfxBarrier: AnimData(first: 0, len: 10, speed: 3),
  gfxGem:     AnimData(first: 0, len: 8, speed: 4),
  gfxPlayer:  AnimData(first: 0, len: 8, speed: 5),
  gfxSacrificedItems: AnimData(first: 0, len: 8, speed: 3),
  gfxBullet:    AnimData(first: 0, len: 4, speed: 3),
  gfxMuzzle:    AnimData(first: 0, len: 8, speed: 2),
  gfxBreakable: AnimData(first: 7, len: 7, speed: 3),
  gfxShield:    AnimData(first: 0, len: 4, speed: 2),
]

let s = addr objMem[0]  # pointer to some sprite

proc setCurrentGraphic(g: Graphic) =
  graphic = g
  anim = initAnim(anims[g])
  s[].init(
    pos = vec2i(120, 80) - vec2i(g.w, g.h) / 2,
    size = g.size,
    tid = 0,  # we're lacking a tile or palette allocator
    pal = 0,  # so let's just use index 0.
  )
  copyPal(addr objPalMem[s[].pal], g)
  copyFrame(addr objTileMem[s[].tid], g, frame = 0)


proc main =

  irq.init()
  irq.enable(iiVBlank)

  dispcnt.init(obj = true, obj1d = true)

  for obj in mitems(objMem):
    obj.hide()

  setCurrentGraphic(gfxPlayer)

  while true:
    keyPoll()
    
    if keyHit(kiLeft) and graphic > Graphic.low:
      setCurrentGraphic(graphic.pred)
    
    if keyHit(kiRight) and graphic < Graphic.high:
      setCurrentGraphic(graphic.succ)
    
    anim.update()
    
    VBlankIntrWait()
    
    # copy a new frame into VRAM only if we're on a different
    # frame of animation than previously.
    if anim.dirty:
      copyFrame(addr objTileMem[s[].tid], graphic, anim.frame)


# Anim logic:

proc initAnim(data: AnimData): Anim =
  result.data = data
  result.frame = 0
  result.timer = data.speed + 1

proc update(a: var Anim) =
  dec a.timer
  if a.timer < 0:
    a.timer = a.data.speed
    inc a.frame
    if a.frame >= a.data.first + a.data.len:
      a.frame = 0

proc dirty(a: Anim): bool =
  a.timer == a.data.speed


main()
