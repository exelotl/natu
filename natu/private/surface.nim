## Graphics surfaces
## =================
## Tonclib's Surface system provides the basic functionality for
## drawing onto graphic surfaces of different types. This includes
## - *bmp16*: 16bpp bitmap surfaces
## - *bmp8*: 8bpp bitmap surfaces.
## - *chr4*(c/r): 4bpp tiled surfaces.
## This covers almost all of the GBA graphic modes.
## 
## [Note]
## While Tonc has one Surface type, here we create several `distinct` copies of it.
## This way, we can use overloading to get rid of all the prefixes.
## And it becomes harder to call the wrong procedure on the wrong kind of surface.
## 

import types

type
  SurfaceBmp16* {.borrow:`.`.} = distinct Surface  ## 16bpp linear (bitmap/tilemap).
  SurfaceBmp8* {.borrow:`.`.} = distinct Surface   ## 8bpp linear (bitmap/tilemap).
  SurfaceChr4r* {.borrow:`.`.} = distinct Surface  ## 4bpp tiles, row-major.
  SurfaceChr4c* {.borrow:`.`.} = distinct Surface  ## 4bpp tiles, column-major.
  
  Surface* {.importc: "TSurface", header: "tonc.h", bycopy.} = object
    data* {.importc: "data".}: ptr uint8     ## Surface data pointer.
    pitch* {.importc: "pitch".}: uint32      ## Scanline pitch in bytes.
    width* {.importc: "width".}: uint16      ## Image width in pixels.
    height* {.importc: "height".}: uint16    ## Image width in pixels.
    bpp* {.importc: "bpp".}: uint8           ## Bits per pixel.
    kind* {.importc: "type".}: uint8         ## Surface type (not used that much).
    palSize* {.importc: "palSize".}: uint16  ## Number of colors.
    palData* {.importc: "palData".}: ptr Color  ## Pointer to palette.
  
  SurfaceKind* {.size: sizeof(int).} = enum
    SRF_NONE = 0,          ## No specific type.
    SRF_BMP16 = 1,         ## 16bpp linear (bitmap/tilemap).
    SRF_BMP8 = 2,          ## 8bpp linear (bitmap/tilemap).
    SRF_CHR4R = 4,         ## 4bpp tiles, row-major.
    SRF_CHR4C = 5,         ## 4bpp tiles, column-major.
    # SRF_CHR8 = 6,        ## 8bpp tiles, row-major. [not implemented]
    # SRF_ALLOCATED = 0x80
  
  SomeSurface* = Surface | SurfaceBmp16 | SurfaceBmp8 | SurfaceChr4c | SurfaceChr4r
  
  SurfacePtr* = ptr Surface
  SurfaceBmp16Ptr* = ptr SurfaceBmp16
  SurfaceBmp8Ptr* = ptr SurfaceBmp8
  SurfaceChr4cPtr* = ptr SurfaceChr4c
  SurfaceChr4rPtr* = ptr SurfaceChr4r
  SomeSurfacePtr* = ptr SomeSurface

# Rendering procedure types
# [idea: Use this to create a runtime-polymorphic kind of Surface?]
type
  FnGetPixel* = proc (src: SurfacePtr; x, y: int): uint32 {.noconv.}
  FnPlot* = proc (dst: SurfacePtr; x, y: int; clr: uint32) {.noconv.}
  FnHLine* = proc (dst: SurfacePtr; x1, y, x2: int; clr: uint32) {.noconv.}
  FnVLine* = proc (dst: SurfacePtr; x, y1, y2: int; clr: uint32) {.noconv.}
  FnLine* = proc (dst: SurfacePtr; x1, y1, x2, y2: int; clr: uint32) {.noconv.}
  FnRect* = proc (dst: SurfacePtr; left, top, right, bottom: int; clr: uint32) {.noconv.}
  FnFrame* = proc (dst: SurfacePtr; left, top, right, bottom: int; clr: uint32) {.noconv.}
  FnBlit* = proc (dst: SurfacePtr; dstX, dstY: int; width, height: uint, src: SurfacePtr; srcX, srcY: int) {.noconv.}
  FnFlood* = proc (dst: SurfacePtr; x, y: int; clr: uint32) {.noconv.}
  
  SurfaceProcTab* {.importc: "TSurfaceProcTab", header: "tonc.h", bycopy.} = object
    ## Rendering procedure table
    name* {.importc: "name".}: cstring
    getPixel* {.importc: "getPixel".}: FnGetPixel
    plot* {.importc: "plot".}: FnPlot
    hline* {.importc: "hline".}: FnHLine
    vline* {.importc: "vline".}: FnVLine
    line* {.importc: "line".}: FnLine
    rect* {.importc: "rect".}: FnRect
    frame* {.importc: "frame".}: FnFrame
    blit* {.importc: "blit".}: FnBlit
    flood* {.importc: "flood".}: FnFlood


# Global Surfaces
# ---------------

var m3Surface* {.importc: "m3_surface", header: "tonc.h".}: Surface
var m4Surface* {.importc: "m4_surface", header: "tonc.h".}: Surface
var m5Surface* {.importc: "m5_surface", header: "tonc.h".}: Surface

var bmp16Tab* {.importc: "bmp16_tab", header: "tonc.h".}: SurfaceProcTab
var bmp8Tab* {.importc: "bmp8_tab", header: "tonc.h".}: SurfaceProcTab
var chr4cTab* {.importc: "chr4c_tab", header: "tonc.h".}: SurfaceProcTab

# Procedures
# ----------

# Basic video surface API.
# The Surface type and the various functions working on it
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


# Initialisation
# --------------

proc init*(srf: SurfacePtr; ty: SurfaceKind; data: pointer; width, height: uint; bpp: uint; pal: ptr Color) {.importc: "srf_init", header: "tonc.h".}
  ## Initalize a surface for `type` formatted graphics.
  ## [[ For these bindings, it's just used by typesafe versions below ]]

proc init*(srf: SurfaceChr4cPtr; data: pointer; width, height: uint; pal: ptr Color) =
  ## Initalize a surface for 4bpp column-major tiles
  ## `srf`     Surface to initialize.
  ## `data`    Pointer to the surface memory.
  ## `width`   Width of surface.
  ## `height`  Height of surface.
  ## `pal`     Pointer to the surface's palette.
  init(srf.SurfacePtr, SRF_CHR4C, data, width, height, bpp=4, pal)

proc init*(srf: SurfaceChr4rPtr; data: pointer; width, height: uint; pal: ptr Color) =
  ## Initalize a surface for 4bpp row-major tiles
  ## `srf`     Surface to initialize.
  ## `data`    Pointer to the surface memory.
  ## `width`   Width of surface.
  ## `height`  Height of surface.
  ## `pal`     Pointer to the surface's palette.
  init(srf.SurfacePtr, SRF_CHR4R, data, width, height, bpp=4, pal)

proc init*(srf: SurfaceBmp16Ptr; data: pointer; width, height: uint; pal: ptr Color) =
  ## Initalize a 16bpp bitmap surface
  ## `srf`     Surface to initialize.
  ## `data`    Pointer to the surface memory.
  ## `width`   Width of surface.
  ## `height`  Height of surface.
  ## `pal`     Pointer to the surface's palette.
  init(srf.SurfacePtr, SRF_BMP16, data, width, height, bpp=16, pal)

proc init*(srf: SurfaceBmp8Ptr; data: pointer; width, height: uint; pal: ptr Color) =
  ## Initalize an 8bpp bitmap surface
  ## `srf`     Surface to initialize.
  ## `data`    Pointer to the surface memory.
  ## `width`   Width of surface.
  ## `height`  Height of surface.
  ## `pal`     Pointer to the surface's palette.
  init(srf.SurfacePtr, SRF_BMP8, data, width, height, bpp=8, pal)


# Common Procedures
# -----------------

proc palCopy*(dst, src: SomeSurfacePtr; count: uint) {.importc: "srf_pal_copy", header: "tonc.h".}
  ## Copy `count` colors from `src`'s palette to `dst`'s palette.

proc getPtr*(srf: SomeSurfacePtr; x, y: uint): pointer {.importc: "srf_get_ptr", header: "tonc.h".}
  ## Get the byte address of coordinates (`x`, `y`) on the surface.

proc align*(width: uint; bpp: uint): uint {.importc: "srf_align", header: "tonc.h".}
  ## Get the word-aligned number of bytes for a scanline.
  ## `width`  Number of pixels.
  ## `bpp`    Bits per pixel.

proc setPtr*(srf: SomeSurfacePtr; `ptr`: pointer) {.importc: "srf_set_ptr", header: "tonc.h".}
  ## Set Data-pointer surface for `srf`.
  
proc setPal*(srf: SomeSurfacePtr; pal: ptr Color; size: uint) {.importc: "srf_set_pal", header: "tonc.h".}
  ## Set the palette pointer and its size.

proc getPtr*(srf: SomeSurfacePtr; x: uint; y: uint; stride: uint): pointer {.importc: "_srf_get_ptr", header: "tonc.h".}
  ## Inline and semi-safe version of getPtr(). Use with caution.

proc getPixel*(src: SurfaceBmp16Ptr; x, y: int): uint32 {.importc: "_sbmp16_get_pixel", header: "tonc.h".}
  ## Get the pixel value of `src` at (`x`, `y`).


## 16bpp bitmap surfaces
## ---------------------
## Routines for 16bpp linear surfaces. For use in modes 3 and 5. Can
## also be used for regular tilemaps to a point.

proc plot*(dst: SurfaceBmp16Ptr; x, y: int; clr: uint32) {.importc: "_sbmp16_plot", header: "tonc.h".}
  ## Plot a single pixel on a 16-bit buffer; inline version.
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y`    Y-coord.
  ## `clr`  Color.

proc hline*(dst: SurfaceBmp16Ptr; x1, y, x2: int; clr: uint32) {.importc: "sbmp16_hline", header: "tonc.h".}
  ## Draw a horizontal line on an 16bit buffer
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y`    Y-coord.
  ## `x2`   Second X-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc vline*(dst: SurfaceBmp16Ptr; x, y1, y2: int; clr: uint32) {.importc: "sbmp16_vline", header: "tonc.h".}
  ## Draw a vertical line on an 16bit buffer
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y1`   First Y-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc line*(dst: SurfaceBmp16Ptr; x1, y1, x2, y2: int; clr: uint32) {.importc: "sbmp16_line", header: "tonc.h".}
  ## Draw a line on an 16bit buffer.
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y1`   First Y-coord.
  ## `x2`   Second X-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc rect*(dst: SurfaceBmp16Ptr; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp16_rect", header: "tonc.h".}
  ## Draw a rectangle in 16bit mode.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color.
  ## Note: Does normalization, but not bounds checks.

proc frame*(dst: SurfaceBmp16Ptr; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp16_frame", header: "tonc.h".}
  ## Draw a rectangle in 16bit mode.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color.
  ## Note: Does normalization, but not bounds checks.
  # PONDER: RB in- or exclusive?

proc blit*(dst: SurfaceBmp16Ptr; dstX, dstY: int; width, height: uint; src: SurfaceBmp16Ptr; srcX, srcY: int) {.importc: "sbmp16_blit", header: "tonc.h".}
  ## 16bpp blitter. Copies a rectangle from one surface to another.
  ## `dst`     Destination surface.
  ## `dstX`    Left coord of rectangle on `dst`.
  ## `dstY`    Top coord of rectangle on `dst`.
  ## `width`   Width of rectangle to blit.
  ## `height`  Height of rectangle to blit.
  ## `src`     Source surface.
  ## `srcX`    Left coord of rectangle on `src`.
  ## `srcY`    Top coord of rectangle on `src`.
  ## Note: The rectangle will be clipped to both `src` and `dst`.

proc floodfill*(dst: SurfaceBmp16Ptr; x, y: int; clr: uint32) {.importc: "sbmp16_floodfill", header: "tonc.h".}
  ## Floodfill an area of the same color with new color `clr`.
  ## `dst`  Destination surface.
  ## `x`    X-coordinate.
  ## `y`    Y-coordinate;
  ## `clr`  Color.


## 8bpp bitmap surfaces
## --------------------
## Routines for 8bpp linear surfaces. For use in mode 4 and affine tilemaps.

proc getPixel*(src: SurfaceBmp8Ptr; x, y: int): uint32 {.importc: "_sbmp8_get_pixel", header: "tonc.h".}
  ## Get the pixel value of `src` at (`x`, `y`); inline version.

proc plot*(dst: SurfaceBmp8Ptr; x, y: int; clr: uint32) {.importc: "_sbmp8_plot", header: "tonc.h".}
  ## Plot a single pixel on a 8-bit buffer; inline version.
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y`    Y-coord.
  ## `clr`  Color.

proc hline*(dst: SurfaceBmp8Ptr; x1, y, x2: int; clr: uint32) {.importc: "sbmp8_hline", header: "tonc.h".}
  ## Draw a horizontal line on an 8-bit buffer
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y`    Y-coord.
  ## `x2`   Second X-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc vline*(dst: SurfaceBmp8Ptr; x, y1, y2: int; clr: uint32) {.importc: "sbmp8_vline", header: "tonc.h".}
  ## Draw a vertical line on an 8-bit buffer
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y1`   First Y-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc line*(dst: SurfaceBmp8Ptr; x1, y1, x2, y2: int; clr: uint32) {.importc: "sbmp8_line", header: "tonc.h".}
  ## Draw a line on an 8-bit buffer.
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y1`   First Y-coord.
  ## `x2`   Second X-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc rect*(dst: SurfaceBmp8Ptr; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp8_rect", header: "tonc.h".}
  ## Draw a rectangle in 8-bit mode.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color.
  ## Note: Does normalization, but not bounds checks.

proc frame*(dst: SurfaceBmp8Ptr; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp8_frame", header: "tonc.h".}
  ## Draw a rectangle in 8-bit mode.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color.
  ## Note: Does normalization, but not bounds checks.
  # PONDER: RB in- or exclusive?

proc blit*(dst: SurfaceBmp8Ptr; dstX, dstY: int, width, height: uint; src: SurfaceBmp8Ptr; srcX, srcY: int) {.importc: "sbmp8_blit", header: "tonc.h".}
  ## 16bpp blitter. Copies a rectangle from one surface to another.
  ## `dst`     Destination surface.
  ## `dstX`    Left coord of rectangle on `dst`.
  ## `dstY`    Top coord of rectangle on `dst`.
  ## `width`   Width of rectangle to blit.
  ## `height`  Height of rectangle to blit.
  ## `src`     Source surface.
  ## `srcX`    Left coord of rectangle on `src`.
  ## `srcY`    Top coord of rectangle on `src`.
  ## Note: The rectangle will be clipped to both `src` and `dst`.

proc floodfill*(dst: SurfaceBmp8Ptr; x, y: int; clr: uint32) {.importc: "sbmp8_floodfill", header: "tonc.h".}
  ## Floodfill an area of the same color with new color `clr`.
  ## `dst`  Destination surface.
  ## `x`    X-coordinate.
  ## `y`    Y-coordinate;
  ## `clr`  Color.


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
## ::
##   30x20t screen:
##     Row-major:
##        0  1  2  3 ...
##       30 31 32 33 ...
##       60 61 62 63 ...
##   
##     Column-major:
##        0 20 40 60 ...
##        1 21 41 61 ...
##        2 22 41 62 ...
##
## With 4bpp tiles, the column-major version makes the `y`
## coordinate match up nicely with successive words. For this reason,
## column-major is preferred over row-major.

proc getPixel*(src: SurfaceChr4cPtr; x, y: int): uint32 {.importc: "_schr4c_get_pixel", header: "tonc.h".}
  ## Get the pixel value of `src` at (`x`, `y`); inline version.

proc plot*(dst: SurfaceChr4cPtr; x, y: int; clr: uint32) {.importc: "_schr4c_plot", header: "tonc.h".}
  ## Plot a single pixel on a 4bpp tiled surface; inline version.
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y`    Y-coord.
  ## `clr`  Color.
  ## Note: Fairly slow. Inline plotting functionality if possible.

proc hline*(dst: SurfaceChr4cPtr; x1, y, x2: int; clr: uint32) {.importc: "schr4c_hline", header: "tonc.h".}
  ## Draw a horizontal line on a 4bpp tiled surface
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y`    Y-coord.
  ## `x2`   Second X-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc vline*(dst: SurfaceChr4cPtr; x, y1, y2: int; clr: uint32) {.importc: "schr4c_vline", header: "tonc.h".}
  ## Draw a vertical line on a 4bpp tiled surface
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y1`   First Y-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc line*(dst: SurfaceChr4cPtr; x1, y1, x2, y2: int; clr: uint32) {.importc: "schr4c_line", header: "tonc.h".}
  ## Draw a line on a 4bpp tiled surface.
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y1`   First Y-coord.
  ## `x2`   Second X-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc rect*(dst: SurfaceChr4cPtr; left, top, right, bottom: int; clr: uint32) {.importc: "schr4c_rect", header: "tonc.h".}
  ## Render a rectangle on a 4bpp tiled canvas.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color-index.

proc frame*(dst: SurfaceChr4cPtr; left, top, right, bottom: int; clr: uint32) {.importc: "schr4c_frame", header: "tonc.h".}
  ## Draw a rectangle on a 4bpp tiled surface.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color.
  ## Note: Does normalization, but not bounds checks.
  # PONDER: RB in- or exclusive?

proc blit*(dst: SurfaceChr4cPtr; dstX, dstY: int; width, height: uint; src: SurfaceChr4cPtr; srcX, srcY: int) {.importc: "schr4c_blit", header: "tonc.h".}
  ## Blitter for 4bpp tiled surfaces. Copies a rectangle from one surface to another.
  ## `dst`     Destination surface.
  ## `dstX`    Left coord of rectangle on `dst`.
  ## `dstY`    Top coord of rectangle on `dst`.
  ## `width`   Width of rectangle to blit.
  ## `height`  Height of rectangle to blit.
  ## `src`     Source surface.
  ## `srcX`    Left coord of rectangle on `src`.
  ## `srcY`    Top coord of rectangle on `src`.
  ## Note: The rectangle will be clipped to both `src` and `dst`.

proc floodfill*(dst: SurfaceChr4cPtr; x, y: int; clr: uint32) {.importc: "schr4c_floodfill", header: "tonc.h".}
  ## Floodfill an area of the same color with new color `clr`.
  ## `dst`  Destination surface.
  ## `x`    X-coordinate.
  ## `y`    Y-coordinate;
  ## `clr`  Color.
  ## Note: This routines is probably very, very slow. 

# Additional routines

proc prepMap*(srf: SurfaceChr4cPtr; map: ptr uint16; se0: uint16) {.importc: "schr4c_prep_map", header: "tonc.h".}
  ## Prepare a screen-entry map for use with chr4.
  ## `srf`  Surface with size information.
  ## `map`  Screen-blocked map to initialize.
  ## `se0`  Additive base screen-entry.

proc getPtr*(srf: SurfaceChr4cPtr; x, y: int): ptr uint32 {.importc: "schr4c_get_ptr", header: "tonc.h".}
  ## Special pointer getter for chr4: start of in-tile line.


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
## ::
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
##
## With 4bpp tiles, the column-major version makes the `y`
## coordinate match up nicely with successive words. For this reason,
## column-major is preferred over row-major.

proc getPixel*(src: SurfaceChr4rPtr; x, y: int): uint32 {.importc: "_schr4r_get_pixel", header: "tonc.h".}
  ## Get the pixel value of `src` at (`x`, `y`); inline version.

proc plot*(dst: SurfaceChr4rPtr; x, y: int; clr: uint32) {.importc: "_schr4r_plot", header: "tonc.h".}
  ## Plot a single pixel on a 4bpp tiled surface; inline version.
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y`    Y-coord.
  ## `clr`  Color.
  ## Note: Slow as fuck. Inline plotting functionality if possible.

proc hline*(dst: SurfaceChr4rPtr; x1, y, x2: int; clr: uint32) {.importc: "schr4r_hline", header: "tonc.h".}
  ## Draw a horizontal line on a 4bpp tiled surface
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y`    Y-coord.
  ## `x2`   Second X-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc vline*(dst: SurfaceChr4rPtr; x, y1, y2: int; clr: uint32) {.importc: "schr4r_vline", header: "tonc.h".}
  ## Draw a vertical line on a 4bpp tiled surface
  ## `dst`  Destination surface.
  ## `x`    X-coord.
  ## `y1`   First Y-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc line*(dst: SurfaceChr4rPtr; x1, y1, x2, y2: int; clr: uint32) {.importc: "schr4r_line", header: "tonc.h".}
  ## Draw a line on a 4bpp tiled surface.
  ## `dst`  Destination surface.
  ## `x1`   First X-coord.
  ## `y1`   First Y-coord.
  ## `x2`   Second X-coord.
  ## `y2`   Second Y-coord.
  ## `clr`  Color.
  ## Note: Does normalization, but not bounds checks.

proc rect*(dst: SurfaceChr4rPtr; left, top, right, bottom: int; clr: uint32) {.importc: "schr4r_rect", header: "tonc.h".}
  ## Render a rectangle on a tiled canvas.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color-index. Octupled if > 16.
  ## Note: For a routine like this you can strive for programmer sanity
  ##  or speed. This is for speed. Except for very small rects, this 
  ##  is between 5x and 300x faster than the trivial version.
  
proc frame*(dst: SurfaceChr4rPtr; left, top, right, bottom: int; clr: uint32) {.importc: "schr4r_frame", header: "tonc.h".}
  ## Draw a rectangle on a 4bpp tiled surface.
  ## `dst`     Destination surface.
  ## `left`    Left side of rectangle;
  ## `top`     Top side of rectangle.
  ## `right`   Right side of rectangle.
  ## `bottom`  Bottom side of rectangle.
  ## `clr`     Color.
  ## Note: Does normalization, but not bounds checks.
  # PONDER: RB in- or exclusive?

# Additional routines

proc prepMap*(srf: SurfaceChr4rPtr; map: ptr uint16; se0: uint16) {.importc: "schr4r_prep_map", header: "tonc.h".}
  ## Prepare a screen-entry map for use with chr4.
  ## `srf`   Surface with size information.
  ## `map`   Screen-blocked map to initialize.
  ## `se0`   Additive base screen-entry.

proc getPtr*(srf: SurfaceChr4rPtr; x: int; y: int): ptr uint32 {.importc: "schr4r_get_ptr", header: "tonc.h".}
  ## Special pointer getter for chr4: start of in-tile line.

