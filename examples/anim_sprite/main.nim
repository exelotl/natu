## Animated Sprite Example
## =======================
## This example demonstrates a technique for animated sprites on the GBA:
## Make sure you're comfortable with the `move_sprite` example before tackling this!
##
## How it works:
## - In VRAM, we allocate enough space for 1 frame of animation.
## - Each VBlank, we copy the current frame into this space, replacing the previous contents.
## 
## For a more thorough breakdown of this approach, see:
## https://pineight.com/gba/managing-sprite-vram.txt
##
## Twiggy spritesheet by GrafxKid: https://opengameart.org/users/grafxkid
## Image data (twiggy.s) is produced using `grit` in the terminal:
## ::
##    grit twiggy.png -gB4 -pn16
## 

import natu

# Include the spritesheet in the build, make the data available to Nim
{.compile: "twiggy.s".}
var twiggyTiles {.importc: "twiggyTiles".}: array[3328, uint32]
var twiggyPal {.importc: "twiggyPal".}: array[16, uint16]


# Animation data
# --------------
# An animation is a list of frames in the spritesheet.
# Nim doesn't have good support for addressable constant data, so if we want
#  to put our animation data in ROM, we must use C as a work around.

type
  AnimDataPtr = ptr AnimData
  AnimData {.bycopy, exportc.} = object
    frames: ptr UncheckedArray[int]
    len: int
    speed: int

# Use emit to produce C code.
{.emit:"""
static const AnimData animIdle = {
  .frames = (int[]){1,3,4,5},
  .len = 4,
  .speed = 7,
};
static const AnimData animWalk = {
  .frames = (int[]){13,14,15,16,17,18},
  .len = 6,
  .speed = 4,
};
""".}

# Bring the variables from C back into Nim
var animIdle {.importc, nodecl.}: AnimData
var animWalk {.importc, nodecl.}: AnimData


# Animation state
# ---------------

type Anim {.bycopy.} = object
  ## Holds the current state of an animation.
  data: AnimDataPtr
  pos: int
  timer: int

proc initAnim*(data: AnimDataPtr): Anim {.noinit.} =
  result.data = data
  result.timer = data.speed + 1
  result.pos = 0

template frame*(a: Anim): int =
  ## Get the current frame number within the sprite sheet.
  a.data.frames[a.pos]

proc update*(a: var Anim) =
  ## Progress anim timer, advance to the next frame if necessary.
  if a.timer > 0:
    dec a.timer
  else:
    inc a.pos
    if a.pos >= a.data.len:
      a.pos = 0
    a.timer = a.data.speed


# Current animation state of the player:
var anim = initAnim(addr animWalk)
var cooldown = 180

proc updatePlayerAnim() =
  # Toggle between walking and idling every 3 seconds
  dec cooldown
  if cooldown <= 0:
    if anim.data == addr animIdle:
      anim = initAnim(addr animWalk)
    else:
      anim = initAnim(addr animIdle)
    cooldown = 180
  # Progress the animation
  anim.update()


# Memory locations used by our sprite:
# (in a real project these should come from allocators of some kind)
const tid = 0  # base tile in object VRAM
const oid = 0  # OAM entry number
const pal = 0  # palette slot

# amount of memory taken up by 1 frame of animation
const framePixels = 32*32
const frameBytes = framePixels div 2
const frameWords = frameBytes div sizeof(uint32)


proc main() =
  
  irqInit()
  irqEnable(II_VBLANK)
  
  # enable sprites with 1d mapping
  REG_DISPCNT = DCNT_OBJ or DCNT_OBJ_1D
  
  # copy palette into Object PAL RAM
  memcpy16(addr palObjBank[pal], addr twiggyPal, twiggyPal.len)
  
  # copy an initial frame into Object VRAM
  memcpy32(addr tileMemObj[tid], addr twiggyTiles[0], frameWords)
  
  # hide all sprites
  for obj in mitems(oamMem):
    obj.hide()
  
  # set up sprite
  oamMem[oid].setAttr(
    ATTR0_Y(60) or ATTR0_4BPP or ATTR0_SQUARE,
    ATTR1_X(100) or ATTR1_SIZE_32,
    ATTR2_ID(tid) or ATTR2_PALBANK(pal)
  )
  
  while true:
    updatePlayerAnim()
    VBlankIntrWait()
    # Copy current frame of animation into Object VRAM (replacing the old frame)
    memcpy32(addr tileMemObj[tid], addr twiggyTiles[anim.frame * frameWords], frameWords)

main()
