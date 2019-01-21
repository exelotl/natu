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
##   grit ship.png -gB4 -gT0088BB -ftb -fh!
##   
## This produces two binary files "ship.img.bin" and "ship.pal.bin".
## We can use staticRead() to embed these into our program at compile-time.

import tonc

const shipImg: cstring = staticRead("ship.img.bin")
const shipPal: cstring = staticRead("ship.pal.bin")

# ship position vector
var pos = vec2i(50, 30)

proc main() =
  
  # enable VBlank interrupt so we can wait for the next frame
  irqInit()
  irqEnable(II_VBLANK)
  
  # enable sprites with 1d mapping
  REG_DISPCNT = DCNT_OBJ or DCNT_OBJ_1D
  
  # copy palette into object PAL RAM
  memcpy16(addr palObjBank[0], shipPal, shipPal.len div 2)
  
  # copy image into object VRAM
  memcpy32(addr tileMemObj[0], shipImg, shipImg.len div 4)
  
  # set up a sprite
  # note: some of these flags are redundant because they turn out to be zero, but it's good to be explicit
  oamMem[0].setAttr(
    ATTR0_Y(pos.y.uint16) or ATTR0_4BPP or ATTR0_SQUARE,
    ATTR1_X(pos.x.uint16) or ATTR1_SIZE_64,
    ATTR2_ID(0) or ATTR2_PALBANK(0)
  )
  
  while true:
    # update key states
    keyPoll()
    
    # move the ship
    if keyIsDown(KEY_LEFT): pos.x -= 1
    if keyIsDown(KEY_RIGHT): pos.x += 1
    if keyIsDown(KEY_UP): pos.y -= 1
    if keyIsDown(KEY_DOWN): pos.y += 1
    
    # update sprite position
    oamMem[0].setPos(pos)
    
    # wait for next frame
    VBlankIntrWait()

main()
