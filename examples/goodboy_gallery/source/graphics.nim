import natu/kit/gfx_operations

# Generated data
include ../output/graphics

# Graphic API, including
# Accessors & utils:  w, h, bpp, size, onscreen()
# Direct operations:  copyPal(), copyFrame()
# Tile allocator:     allocObjTiles(), freeObjTiles()
# Palette manager:    acquireObjPal(), releaseObjPal()
export gfx_operations
