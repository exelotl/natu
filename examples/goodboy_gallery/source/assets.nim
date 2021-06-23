import natu/kit/[gfx_operations, bg_operations]

# Generated data
include ../output/graphics
include ../output/backgrounds

# Graphic API, including
# Accessors & utils:  width, height, bpp, size, onscreen()
# Copy functions:     copyPal(), copyFrame()
# Tile allocator:     allocObjTiles(), freeObjTiles()
# Palette manager:    acquireObjPal(), releaseObjPal()
export gfx_operations

# Backgrounds API, including
# load(), loadTiles(), loadMap(), loadPal()
export bg_operations
