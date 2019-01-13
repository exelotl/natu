
# TODO: rework and finish the surface bindings?

# Should take advantage of the type system:
# - Make some types e.g. SurfaceBmp8, SurfaceChr4C, with constructors (makeSurfaceBmp8)
#  then I can use overloading, so the procs don't need ugly prefixes and it's hard to call the wrong one.
# - Could add variations that take rect and vec2i types?
# - Also need to format and finish adding all the comments...
# - And figure the best way to bind the procs themselves (just use `var` params?)

##
## Graphics surfaces
## =================
##
## 	Tonclib's Surface system provides the basic functionality for
## 	drawing onto graphic surfaces of different types. This includes
## 	- *bmp16*: 16bpp bitmap surfaces
## 	- *bmp8*: 8bpp bitmap surfaces.
## 	- *chr4*(c/r): 4bpp tiled surfaces.
## 	This covers almost all of the GBA graphic modes.
##
## 16bpp bitmap surfaces
## ---------------------
## Routines for 16bpp linear surfaces. For use in modes 3 and 5. Can
## also be used for regular tilemaps to a point.
##
## 8bpp bitmap surfaces
## --------------------
## Routines for 8bpp linear surfaces. For use in mode 4 and affine tilemaps.
##
## 4bpp tiled surfaces, column major
## ---------------------------------
## A (4bpp) tiled surface is formed when each tilemap entry
## references a unique tile (this is done by schr4c_prep_map()).
## The pixels on the tiles will then uniquely map onto pixels on the
## screen.
##
## There are two ways of map-layout here: row-major indexing and
## column-major indexing. The difference if is that tile 1 is to the
## right of tile 0 in the former, but under it in the latter.
## <pre>
## 30x20t screen:
##   Row-major:
##      0  1  2  3 ...
##     30 31 32 33 ...
##     60 61 62 63 ...
##
##   Column-major:
##      0 20 40 60 ...
##      1 21 41 61 ...
##      2 22 41 62 ...
## </pre>
##
## With 4bpp tiles, the column-major version makes the <i>y</i>
## coordinate match up nicely with successive words. For this reason,
## column-major is preferred over row-major.
##
## 4bpp tiled surfaces, row major
## ------------------------------
## A (4bpp) tiled surface is formed when each tilemap entry
## references a unique tile (this is done by schr4r_prep_map()).
## The pixels on the tiles will then uniquely map onto pixels on the
## screen.
##
## There are two ways of map-layout here: row-major indexing and
## column-major indexing. The difference if is that tile 1 is to the
## right of tile 0 in the former, but under it in the latter.
##
## <pre>
## 30x20t screen:
##   Row-major:
##      0  1  2  3 ...
##     30 31 32 33 ...
##     60 61 62 63 ...
##
##   Column-major:
##      0 20 40 60 ...
##      1 21 41 61 ...
##      2 22 41 62 ...
## </pre>
##
## With 4bpp tiles, the column-major version makes the <i>y</i>
## coordinate match up nicely with successive words. For this reason,
## column-major is preferred over row-major.
##

type
  ESurfaceType* {.size: sizeof(int).} = enum
    SRF_NONE = 0,               ## No specific type.
    SRF_BMP16 = 1,              ## 16bpp linear (bitmap/tilemap).
    SRF_BMP8 = 2,               ## 8bpp linear (bitmap/tilemap).
    SRF_CHR4R = 4,              ## 4bpp tiles, row-major.
    SRF_CHR4C = 5,              ## 4bpp tiles, column-major.
    SRF_CHR8 = 6,               ## 8bpp tiles, row-major.
    SRF_ALLOCATED = 0x80

type
  Surface* = ptr SurfaceObj
  SurfaceObj* {.importc: "TSurface", header: "tonc.h", bycopy.} = object
    data* {.importc: "data".}: ptr uint8 ## Surface data pointer.
    pitch* {.importc: "pitch".}: uint32 ## Scanline pitch in bytes.
    width* {.importc: "width".}: uint16 ## Image width in pixels.
    height* {.importc: "height".}: uint16 ## Image width in pixels.
    bpp* {.importc: "bpp".}: uint8  ## Bits per pixel.
    `type`* {.importc: "type".}: uint8 ## Surface type (not used that much).
    palSize* {.importc: "palSize".}: uint16 ## Number of colors.
    palData* {.importc: "palData".}: ptr uint16 ## Pointer to palette.


# Rendering procedure types
type
  fnGetPixel* = proc (src: Surface; x, y: int): uint32 {.noconv.}
  fnPlot* = proc (dst: Surface; x, y: int; clr: uint32) {.noconv.}
  fnHLine* = proc (dst: Surface; x1, y, x2: int; clr: uint32) {.noconv.}
  fnVLine* = proc (dst: Surface; x, y1, y2: int; clr: uint32) {.noconv.}
  fnLine* = proc (dst: Surface; x1, y1, x2, y2: int; clr: uint32) {.noconv.}
  fnRect* = proc (dst: Surface; left, top, right, bottom: int; clr: uint32) {.noconv.}
  fnFrame* = proc (dst: Surface; left, top, right, bottom: int; clr: uint32) {.noconv.}
  fnBlit* = proc (dst: Surface; dstX, dstY: int; width, height: uint, src: Surface; srcX, srcY: int) {.noconv.}
  fnFlood* = proc (dst: Surface; x, y: int; clr: uint32) {.noconv.}

type
  SurfaceProcTab* {.importc: "TSurfaceProcTab", header: "tonc.h", bycopy.} = object
    ## Rendering procedure table
    name* {.importc: "name".}: cstring
    getPixel* {.importc: "getPixel".}: fnGetPixel
    plot* {.importc: "plot".}: fnPlot
    hline* {.importc: "hline".}: fnHLine
    vline* {.importc: "vline".}: fnVLine
    line* {.importc: "line".}: fnLine
    rect* {.importc: "rect".}: fnRect
    frame* {.importc: "frame".}: fnFrame
    blit* {.importc: "blit".}: fnBlit
    flood* {.importc: "flood".}: fnFlood


# Global Surfaces
# -------
var m3_surface* {.importc: "m3_surface", header: "tonc.h".}: SurfaceObj
var m4_surface* {.importc: "m4_surface", header: "tonc.h".}: SurfaceObj
var m5_surface* {.importc: "m5_surface", header: "tonc.h".}: SurfaceObj
var bmp16_tab* {.importc: "bmp16_tab", header: "tonc.h".}: SurfaceProcTab
var bmp8_tab* {.importc: "bmp8_tab", header: "tonc.h".}: SurfaceProcTab
var chr4c_tab* {.importc: "chr4c_tab", header: "tonc.h".}: SurfaceProcTab

# Procedures
# ----------

# Basic video surface API.
# The SurfaceObj struct and the various functions working on it
# provide a basic API for working with different types of
# graphic surfaces, like 16bpp bitmaps, 8bpp bitmaps, but also
# tiled surfaces.
#
# - SRF_BMP8: 8bpp linear (Mode 4 / affine BGs)
# - SRF_BMP16: 16bpp bitmaps (Mode 3/5 / regular BGs to some extent)
# - SRF_CHR4C: 4bpp tiles, column-major (Regular tiled BG)
# - SRF_CHR4R: 4bpp tiles, row-major (Regular tiled BG, OBJs)
#
# For each of these functions exist for the most important drawing
# options: plotting, lines and rectangles. For BMP8/BMP16 and to
# some extent CHR4C, there are blitters as well.

proc srf_init*(srf: Surface; `type`: ESurfaceType; data: pointer; width: uint; height: uint; bpp: uint; pal: ptr uint16) {.importc: "srf_init", header: "tonc.h".}
proc srf_pal_copy*(dst: Surface; src: Surface; count: uint) {.importc: "srf_pal_copy", header: "tonc.h".}
proc srf_get_ptr*(srf: Surface; x: uint; y: uint): pointer {.importc: "srf_get_ptr", header: "tonc.h".}

proc srf_align*(width: uint; bpp: uint): uint {.importc: "srf_align", header: "tonc.h".}
  ## Get the word-aligned number of bytes for a scanline.
  ## `width` Number of pixels.
  ## `bpp`   Bits per pixel.
    
proc srf_set_ptr*(srf: Surface; `ptr`: pointer) {.importc: "srf_set_ptr", header: "tonc.h".}
  ## Set Data-pointer surface for `srf`.
  
proc srf_set_pal*(srf: Surface; pal: ptr uint16; size: uint) {.importc: "srf_set_pal", header: "tonc.h".}
  ## Set the palette pointer and its size.

proc srf_get_ptr*(srf: Surface; x: uint; y: uint; stride: uint): pointer {.importc: "srf_get_ptr", header: "tonc.h".}
  ## 

proc sbmp16_get_pixel*(src: Surface; x: int; y: int): uint32 {.importc: "sbmp16_get_pixel", header: "tonc.h".}
proc sbmp16_plot*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "sbmp16_plot", header: "tonc.h".}
proc sbmp16_hline*(dst: Surface; x1: int; y: int; x2: int; clr: uint32) {.importc: "sbmp16_hline", header: "tonc.h".}
proc sbmp16_vline*(dst: Surface; x: int; y1: int; y2: int; clr: uint32) {.importc: "sbmp16_vline", header: "tonc.h".}
proc sbmp16_line*(dst: Surface; x1: int; y1: int; x2: int; y2: int; clr: uint32) {.importc: "sbmp16_line", header: "tonc.h".}
proc sbmp16_rect*(dst: Surface; left: int; top: int; right: int; bottom: int; clr: uint32) {.importc: "sbmp16_rect", header: "tonc.h".}
proc sbmp16_frame*(dst: Surface; left: int; top: int; right: int; bottom: int; clr: uint32) {.importc: "sbmp16_frame", header: "tonc.h".}
proc sbmp16_blit*(dst: Surface; dstX: int; dstY: int; width: uint; height: uint; src: Surface; srcX: int; srcY: int) {.importc: "sbmp16_blit", header: "tonc.h".}
proc sbmp16_floodfill*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "sbmp16_floodfill", header: "tonc.h".}

## Fast inlines .
# proc _sbmp16_plot*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "_sbmp16_plot", header: "tonc.h".}
# proc _sbmp16_get_pixel*(src: Surface; x: int; y: int): uint32 {.importc: "_sbmp16_get_pixel", header: "tonc.h".}

proc sbmp8_get_pixel*(src: Surface; x: int; y: int): uint32 {.importc: "sbmp8_get_pixel", header: "tonc.h".}
proc sbmp8_plot*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "sbmp8_plot", header: "tonc.h".}
proc sbmp8_hline*(dst: Surface; x1: int; y: int; x2: int; clr: uint32) {.importc: "sbmp8_hline", header: "tonc.h".}
proc sbmp8_vline*(dst: Surface; x: int; y1: int; y2: int; clr: uint32) {.importc: "sbmp8_vline", header: "tonc.h".}
proc sbmp8_line*(dst: Surface; x1: int; y1: int; x2: int; y2: int; clr: uint32) {.importc: "sbmp8_line", header: "tonc.h".}
proc sbmp8_rect*(dst: Surface; left: int; top: int; right: int; bottom: int; clr: uint32) {.importc: "sbmp8_rect", header: "tonc.h".}
proc sbmp8_frame*(dst: Surface; left: int; top: int; right: int; bottom: int; clr: uint32) {.importc: "sbmp8_frame", header: "tonc.h".}
proc sbmp8_blit*(dst: Surface; dstX: int; dstY: int; width: uint; height: uint; src: Surface; srcX: int; srcY: int) {.importc: "sbmp8_blit", header: "tonc.h".}
proc sbmp8_floodfill*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "sbmp8_floodfill", header: "tonc.h".}

## Fast inlines .
# proc _sbmp8_plot*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "_sbmp8_plot", header: "tonc.h".}
# proc _sbmp8_get_pixel*(src: Surface; x: int; y: int): uint32 {.importc: "_sbmp8_get_pixel", header: "tonc.h".}

proc schr4c_get_pixel*(src: Surface; x, y: int): uint32 {.importc: "schr4c_get_pixel", header: "tonc.h".}
proc schr4c_plot*(dst: Surface; x, y: int; clr: uint32) {.importc: "schr4c_plot", header: "tonc.h".}
proc schr4c_hline*(dst: Surface; x1, y, x2: int; clr: uint32) {.importc: "schr4c_hline", header: "tonc.h".}
proc schr4c_vline*(dst: Surface; x, y1, y2: int; clr: uint32) {.importc: "schr4c_vline", header: "tonc.h".}
proc schr4c_line*(dst: Surface; x1, y1, x2, y2: int; clr: uint32) {.importc: "schr4c_line", header: "tonc.h".}
proc schr4c_rect*(dst: Surface; left, top, right, bottom: int; clr: uint32) {.importc: "schr4c_rect", header: "tonc.h".}
proc schr4c_frame*(dst: Surface; left, top, right, bottom: int; clr: uint32) {.importc: "schr4c_frame", header: "tonc.h".}
proc schr4c_blit*(dst: Surface; dstX, dstY:int; width, height: uint; src: Surface; srcX: int; srcY: int) {.importc: "schr4c_blit", header: "tonc.h".}
proc schr4c_floodfill*(dst: Surface; x, y: int; clr: uint32) {.importc: "schr4c_floodfill", header: "tonc.h".}

## Additional routines

proc schr4c_prep_map*(srf: Surface; map: ptr uint16; se0: uint16) {.importc: "schr4c_prep_map", header: "tonc.h".}
proc schr4c_get_ptr*(srf: Surface; x, y: int): ptr uint32 {.importc: "schr4c_get_ptr", header: "tonc.h".}

## Fast inlines .
# proc _schr4c_plot*(dst: Surface; x, y: int; clr: uint32) {.importc: "_schr4c_plot", header: "tonc.h".}
# proc _schr4c_get_pixel*(src: Surface; x, y: int): uint32 {.importc: "_schr4c_get_pixel", header: "tonc.h".}


proc schr4r_get_pixel*(src: Surface; x: int; y: int): uint32 {.importc: "schr4r_get_pixel", header: "tonc.h".}
proc schr4r_plot*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "schr4r_plot", header: "tonc.h".}
proc schr4r_hline*(dst: Surface; x1: int; y: int; x2: int; clr: uint32) {.importc: "schr4r_hline", header: "tonc.h".}
proc schr4r_vline*(dst: Surface; x: int; y1: int; y2: int; clr: uint32) {.importc: "schr4r_vline", header: "tonc.h".}
proc schr4r_line*(dst: Surface; x1: int; y1: int; x2: int; y2: int; clr: uint32) {.importc: "schr4r_line", header: "tonc.h".}
proc schr4r_rect*(dst: Surface; left: int; top: int; right: int; bottom: int; clr: uint32) {.importc: "schr4r_rect", header: "tonc.h".}
proc schr4r_frame*(dst: Surface; left: int; top: int; right: int; bottom: int; clr: uint32) {.importc: "schr4r_frame", header: "tonc.h".}

# Additional routines

proc schr4r_prep_map*(srf: Surface; map: ptr uint16; se0: uint16) {.importc: "schr4r_prep_map", header: "tonc.h".}
proc schr4r_get_ptr*(srf: Surface; x: int; y: int): ptr uint32 {.importc: "schr4r_get_ptr", header: "tonc.h".}

#  Fast inlines.
# proc _schr4r_plot*(dst: Surface; x: int; y: int; clr: uint32) {.importc: "_schr4r_plot", header: "tonc.h".}
# proc _schr4r_get_pixel*(src: Surface; x: int; y: int): uint32 {.importc: "_schr4r_get_pixel", header: "tonc.h".}
