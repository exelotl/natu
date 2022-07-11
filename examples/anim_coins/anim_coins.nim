## Animated Coins Example
## ======================
## This example demonstrates another technique for animated sprites.
## - All frames of animation are copied into VRAM.
## - Each object's tile ID is set to the appropriate tile in VRAM for its current frame of animation.
##
## This can be great when you have many sprites of the same kind onscreen at once,
## provided your spritesheet has relatively few frames.
##
## It's also light on CPU usage compared to the streaming approach from the `anim_sprite` example.
##
## Coin sprite by GrafxKid: https://opengameart.org/users/grafxkid
## Image data produced via grit:
## ::
##   grit coin.png -gB4 -pn16
##

import natu/[video, oam, bios, irq, math, utils]

{.compile: "coin.s".}
var coinTiles {.importc: "coinTiles".}: array[128, uint32]
var coinPal {.importc: "coinPal".}: array[16, uint16]

const coinAnimFrames = 0..3
const coinNumTiles = 2*2

# Memory locations used by coin sprites:
# (in a real project these should come from allocators of some kind)
const tid = 0  # base tile in object VRAM
const pal = 0  # palette slot

type
  Coin = object
    ## Each coin has a position, speed, and some animation counters.
    ## To give the coins a variety of speeds, we use fixed-point arithmetic.
    pos: Vec2f
    fallSpeed: Fixed
    animFrame: int
    animTimer: int
    animSpeed: int

proc init(c: var Coin) =
  ## Set up a coin object. All properties are randomized.
  c.pos = vec2f(
    fp(rand(0, 224)),
    fp(rand(0, 160))
  )
  c.fallSpeed = rand(200, 300).Fixed
  c.animFrame = rand(coinAnimFrames.a, coinAnimFrames.b+1)
  c.animSpeed = rand(4, 8)
  c.animTimer = rand(1, c.animSpeed+1)

proc update(c: var Coin) =
  
  # advance coin animation timer/frame
  dec c.animTimer
  if c.animTimer <= 0:
    c.animTimer = c.animSpeed
    inc c.animFrame
    if c.animFrame > coinAnimFrames.b:
      c.animFrame = coinAnimFrames.a
  
  # move coin vertically, wrap at bottom of screen
  c.pos.y += c.fallSpeed
  if c.pos.y > fp(160):
    c.pos.y = fp(-16)
    c.pos.x = fp(rand(0, 224))


proc draw(c: var Coin, oid: int) =
  # apply attributes to sprite in OAM
  # note that we point to a different tile in VRAM depending on which anim frame we are on.
  objMem[oid].init:
    pos = vec2i(c.pos)
    size = s16x16
    tid = tid + c.animFrame * coinNumTiles
    pal = pal


var coins {.noinit.}: array[40, Coin]


proc main() =
  
  irq.enable(iiVBlank)
  
  # enable sprites with 1d mapping
  dispcnt.init:
    obj = true
    obj1d = true
  
  # copy palette into object PAL RAM
  memcpy16(addr objPalMem[pal], addr coinPal, coinPal.len)
  
  # copy all frames into object VRAM
  memcpy32(addr objTileMem[tid], addr coinTiles, coinTiles.len)
  
  # initialize coins
  for coin in mitems(coins):
    coin.init()
  
  while true:
    
    # update the positions and frames of all coins
    for coin in mitems(coins):
      coin.update()
    
    VBlankIntrWait()
    
    # sprite counter (object id)
    var oid = 0
    
    # draw all coins, each call to draw also increments the sprite counter
    for coin in mitems(coins):
      coin.draw(oid)
      inc oid
    
    # hide remaining sprites
    while oid < objMem.len:
      objMem[oid].hide()
      inc oid
  

main()
