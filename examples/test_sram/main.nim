## Save Data Example
## =================
## This example demonstrates reading and writing to cart storage.
## - Move the sprite with the D-Pad
## - Press START to save the position of the sprite
## - Power off the console
## - Next time you launch the game, the sprite should be where you left it

import natu

# position of the sprite on the screen
var pos = vec2i(0, 0)

# Note: Emulators and flashcarts will try to guess what kind of storage a game uses by
#  searching for a magic string inside the ROM image.
# See http://problemkaputt.de/gbatek.htm#gbacartbackupids for more info.
# The string should begin on a word boundary.
# Inline ASM appears to be a good way to achieve this:
asm """
.balign 4
.string \"SRAM_Vnnn\"
"""

# Validation:
# If the start of SRAM doesn't match the header below, we can assume the game
#  is being run for the first time, or the save file is corrupt.
const saveHeader:cstring = "test_sram"

# Note: Code that reads save data needs to be put in Work RAM.
# To do this, we can use the codegenDecl pragma to annotate the generated C function.

proc validateSave(): bool {.codegenDecl:EWRAM_CODE.} =
  for i,c in saveHeader:
    if sramMem[i].char != c:
      return false
  return true

proc newSave() =
  # Copy the header
  for i,c in saveHeader:
    sramMem[i] = c.uint8
  
  # Set the starting position for the sprite
  sramMem[0x10] = SCREEN_WIDTH div 2
  sramMem[0x11] = SCREEN_HEIGHT div 2
    
proc readSave() {.codegenDecl:EWRAM_CODE.} =
  pos.x = sramMem[0x10].int
  pos.y = sramMem[0x11].int

proc writeSave() =
  sramMem[0x10] = pos.x.uint8
  sramMem[0x11] = pos.y.uint8

proc main() =
  
  # Recommended waitstate configuration
  # (To ensure access to cart memory takes the correct number of CPU cycles?)
  REG_WAITCNT = WS_STANDARD
  
  # Initialise save
  if not validateSave():
    newSave()
  readSave()
  
  # Enable VBlank interrupt so we can wait for the next frame
  irqInit()
  irqEnable(II_VBLANK)
  
  # Show background 0 and sprites
  dispcnt.init:
    bg0 = true
    obj = true
    obj1d = true
  
  # Initialise text
  tteInitChr4cDefault(bgnr = 0, initBgCnt(cbb = 0, sbb = 31))
  tteWrite("""
  Natu Save Example
  ---------------------
  Arrows to move.
  Press START to save
  Press SELECT to load
  Saved data should persist after power off.
  """)
  
  # Hide all sprites
  for obj in mitems(oamMem):
    obj.hide()
  
  # Fill a tile with white
  palObjBank[0][1] = rgb15(31,31,31)
  const numBytes = (8*8) div 2
  memset32(addr tileMemObj[0][0], octup(1), numBytes div sizeof(uint32))
  
  # Initialise a sprite to display our white tile
  oamMem[0].init:
    pos = pos
    size = s8x8
    tid = 0
    pal = 0
  
  while true:
    # Update key states
    keyPoll()
    
    # Move the sprite
    if keyIsDown(KEY_LEFT): pos.x -= 1
    if keyIsDown(KEY_RIGHT): pos.x += 1
    if keyIsDown(KEY_UP): pos.y -= 1
    if keyIsDown(KEY_DOWN): pos.y += 1
    
    # Save/load on button press
    if keyHit(KEY_START): writeSave()
    if keyHit(KEY_SELECT): readSave()
    
    # Wait for next frame
    VBlankIntrWait()
    
    # Update sprite position
    oamMem[0].pos = pos

main()
