## Mode 4 Example
## ==============
## This demonstrates bitmap drawing in mode 4 with page-flipping.
## 
## Based on the 'Mystify' screensaver, we have a bunch of points
## that move around the screen and we draw lines between them.
## 
## Cool motion blur is left as an exercise to the reader :^)

import natu/[video, math, utils, bios, irq]

# set up points with random position and velocity:
var vertices: array[6, tuple[pos, vel: Vec2f]]
for v in mitems(vertices):
  v.pos = vec2f(rand(2..237), rand(2..157))
  v.vel = vec2f(rand(fp(-2)..fp(2)), rand(fp(-2)..fp(2)))

# assign palette
bgColorMem[0] = rgb5(2,4,6)      # use dark blue for backdrop color
bgColorMem[1] = rgb5(20,28,31)   # use light blue for ink color

# enable VBlank interrupt
irq.enable(iiVBlank)

# clear VRAM - only necessary to avoid visual junk when quick-launching the game
# from a flashcart, or after restarting the game via soft-reset.
RegisterRamReset({rsVram})

# enable background 2, use display mode 4 (i.e. 8bpp bitmap with page-flipping)
dispcnt.init(bg2 = true, mode = dm4)

while true:
  
  # obtain a pointer to whichever page is not currently being displayed.
  let buf: ptr M4Mem =
    if dispcnt.page: addr m4MemBack
    else: addr m4Mem
  
  buf[].clear()
  
  # begin with the final vertex.
  var prev = vertices[^1].pos
  
  # update and draw all vertices
  for v in mitems(vertices):
    
    # move by velocity
    v.pos += v.vel
    
    # bounce off screen edge
    if v.pos.x.toInt() notin 2..237: v.vel.x *= -1
    if v.pos.y.toInt() notin 2..157: v.vel.y *= -1
    
    # draw line from last point to current point.
    buf[].line(
      prev.x.toInt(), prev.y.toInt(),
      v.pos.x.toInt(), v.pos.y.toInt(),
      clrid = 1,
    )
    prev = v.pos
  
  # wait until the end of the frame
  VBlankIntrWait()
  
  # page flip:
  dispcnt.page = not dispcnt.page
