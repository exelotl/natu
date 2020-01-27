## Sprite Example
## ==============
## This example demonstrates:
## - using the VBlank interrupt to update at 60fps without burning CPU cycles
## - loading graphics into memory
## - setting sprite attributes
## - using key functions to move the sprite around
## 
## Ship graphics by Stephen Challener (Redshrike), hosted by OpenGameArt.org
## 
## The `grit` command line tool can be used to convert an image to a representation that the hardware understands.
## i.e. 4bpp paletted, broken into 8x8px tiles which are arranged sequentially (1d mapping)
## ::
##   grit ship.png -gB4 -pn16
##
## This produces an assembly file that we can compile and link with our project using the {.compile.} pragma.

import natu

{.compile: "ship.s".}
var shipTiles {.importc: "shipTiles".}: array[512, uint32]
var shipPal {.importc: "shipPal".}: array[16, uint16]

# Memory locations used by our sprite:
const tid = 0  # base tile in object VRAM
const oid = 0  # OAM entry number
const pal = 0  # palette slot

# ship position vector
var pos = vec2i(50, 30)

# enable VBlank interrupt so we can wait for the end of the frame without burning CPU cycles
irqInit()
irqEnable(II_VBLANK)

# enable sprites with 1d mapping
dispcnt.init(obj = true, obj1d = true)

# copy palette into object PAL RAM
memcpy16(addr palObjBank[pal], addr shipPal, shipPal.len)

# copy image into object VRAM
memcpy32(addr tileMemObj[0][0], addr shipTiles, shipTiles.len)

# hide all sprites
for obj in mitems(oamMem):
  obj.hide()

# set up a sprite
let s = addr oamMem[oid]
s.init:
  pos = pos
  size = s64x64
  tid = tid
  pal = pal

while true:
  # update key states
  keyPoll()
  
  # move the ship
  if keyIsDown(KEY_LEFT): pos.x -= 1
  if keyIsDown(KEY_RIGHT): pos.x += 1
  if keyIsDown(KEY_UP): pos.y -= 1
  if keyIsDown(KEY_DOWN): pos.y += 1
  
  # wait for the end of the frame
  VBlankIntrWait()
  
  # update sprite position
  s.pos = pos
