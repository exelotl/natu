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
##   grit ship.png -gB4 -pn16 -ftb
##
## This produces some raw binary files that we can embed into our project using `readBin` from the core module.

import natu/[core, irq, oam, input]

let shipTiles = readBin("ship.img.bin")
let shipPal = readBin("ship.pal.bin")

# Memory locations used by our sprite:
const tid = 0  # base tile in object VRAM
const oid = 0  # OAM entry number
const pal = 0  # palette slot

# ship position vector
var pos = vec2i(50, 30)

# enable VBlank interrupt so we can wait for the end of the frame without burning CPU cycles
irq.init()
irq.enable(iiVBlank)

# enable sprites with 1d mapping
dispcnt.init(obj = true, obj1d = true)

# copy palette into Object PAL RAM
memcpy16(addr objPalMem[pal], unsafeAddr shipPal, shipPal.len div sizeof(uint16))

# copy image into Object VRAM
memcpy32(addr objTileMem[tid], unsafeAddr shipTiles, shipTiles.len div sizeof(uint32))

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
  if keyIsDown(kiLeft): pos.x -= 1
  if keyIsDown(kiRight): pos.x += 1
  if keyIsDown(kiUp): pos.y -= 1
  if keyIsDown(kiDown): pos.y += 1
  
  # wait for the end of the frame
  VBlankIntrWait()
  
  # update sprite position
  s.pos = pos
