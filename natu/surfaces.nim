## Graphics surfaces
## =================
## Libtonc's Surface system provides the basic functionality for
## drawing onto graphic surfaces of different types. This includes:
## 
## - **bmp16**: 16bpp bitmap surfaces
## - **bmp8**: 8bpp bitmap surfaces.
## - **chr4**(c/r): 4bpp tiled surfaces.
## 
## This covers almost all of the GBA graphic modes.
## 
## .. note::
##    While Tonc has one Surface type, here we create several `distinct` copies of it.
##    This way, we can use overloading to get rid of all the prefixes.
##    And it becomes harder to call the wrong procedure on the wrong kind of surface.
## 

{.warning[UnusedImport]: off.}

import ./video
import private/[common, types]

{.compile(toncPath & "/src/tonc_surface.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_sbmp16.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_sbmp8.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_schr4r.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_schr4c.c", toncCFlags).}

{.pragma: tonc, header: "tonc_surface.h".}
{.pragma: toncinl, header: "tonc_surface.h".}  # inline from header.

type
  SurfaceBmp16* {.borrow:`.`.} = distinct Surface  ## 16bpp linear (bitmap/tilemap).
  SurfaceBmp8* {.borrow:`.`.} = distinct Surface   ## 8bpp linear (bitmap/tilemap).
  SurfaceChr4r* {.borrow:`.`.} = distinct Surface  ## 4bpp tiles, row-major.
  SurfaceChr4c* {.borrow:`.`.} = distinct Surface  ## 4bpp tiles, column-major.
  
  Surface* {.importc: "TSurface", tonc, byref.} = object
    data*: ptr uint8                       ## Surface data pointer.
    pitch*: uint32                         ## Scanline pitch in bytes.
    width*: uint16                         ## Image width in pixels.
    height*: uint16                        ## Image width in pixels.
    bpp*: uint8                            ## Bits per pixel.
    kind* {.importc:"type".}: SurfaceKind  ## Surface type (not used that much).
    palSize*: uint16                       ## Number of colors.
    palData*: ptr Palette                  ## Pointer to palette.
  
  SurfaceKind* {.size: 1.} = enum
    srfNone = 0,          ## No specific type.
    srfBmp16 = 1,         ## 16bpp linear (bitmap/tilemap).
    srfBmp8 = 2,          ## 8bpp linear (bitmap/tilemap).
    srfChr4r = 4,         ## 4bpp tiles, row-major.
    srfChr4c = 5,         ## 4bpp tiles, column-major.
    # srfChr8 = 6,        ## 8bpp tiles, row-major. [not implemented]
    # srfAllocated = 0x80
  
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
  FnGetPixel* = proc (src: Surface; x, y: int): uint32 {.nimcall.}
  FnPlot* = proc (dst: Surface; x, y: int; clr: uint32) {.nimcall.}
  FnHLine* = proc (dst: Surface; x1, y, x2: int; clr: uint32) {.nimcall.}
  FnVLine* = proc (dst: Surface; x, y1, y2: int; clr: uint32) {.nimcall.}
  FnLine* = proc (dst: Surface; x1, y1, x2, y2: int; clr: uint32) {.nimcall.}
  FnRect* = proc (dst: Surface; left, top, right, bottom: int; clr: uint32) {.nimcall.}
  FnFrame* = proc (dst: Surface; left, top, right, bottom: int; clr: uint32) {.nimcall.}
  FnBlit* = proc (dst: Surface; dstX, dstY: int; width, height: uint, src: Surface; srcX, srcY: int) {.nimcall.}
  FnFlood* = proc (dst: Surface; x, y: int; clr: uint32) {.nimcall.}
  
  SurfaceProcTab* {.importc: "TSurfaceProcTab", tonc, bycopy.} = object
    ## Rendering procedure table
    name*: cstring
    getPixel*: FnGetPixel
    plot*: FnPlot
    hline*: FnHLine
    vline*: FnVLine
    line*: FnLine
    rect*: FnRect
    frame*: FnFrame
    blit*: FnBlit
    flood*: FnFlood


# Global Surfaces
# ---------------

let m3Surface* {.importc: "m3_surface", tonc.}: SurfaceBmp16
var m4Surface* {.importc: "m4_surface", tonc.}: SurfaceBmp8
var m5Surface* {.importc: "m5_surface", tonc.}: SurfaceBmp16
let bmp16Tab* {.importc: "bmp16_tab", tonc.}: SurfaceProcTab
let bmp8Tab* {.importc: "bmp8_tab", tonc.}: SurfaceProcTab
let chr4cTab* {.importc: "chr4c_tab", tonc.}: SurfaceProcTab

# Procedures
# ----------

# Basic video surface API.
# The Surface type and the various functions working on it
# provide a basic API for working with different types of
# graphic surfaces, like 16bpp bitmaps, 8bpp bitmaps, but also
# tiled surfaces.
#
# - srfBmp8: 8bpp linear (Mode 4 / affine BGs)
# - srfBmp16: 16bpp bitmaps (Mode 3/5 / regular BGs to some extent)
# - srfChr4c: 4bpp tiles, column-major (Regular tiled BG)
# - srfChr4r: 4bpp tiles, row-major (Regular tiled BG, OBJs)
#
# For each of these functions exist for the most important drawing
# options: plotting, lines and rectangles. For BMP8/BMP16 and to
# some extent CHR4C, there are blitters as well.


# Initialisation
# --------------

proc init*(srf: var Surface; ty: SurfaceKind; data: pointer; width, height: uint; bpp: uint; pal: ptr Palette) {.importc: "srf_init", tonc.}
  ## Initalize a surface for `ty`-formatted graphics.
  ## 
  ## Prefer to use the type-specific `init` procedures below instead.

proc init*(srf: var SurfaceChr4c; data: pointer; width, height: uint; pal: ptr Palette) {.inline.} =
  ## Initalize a surface for 4bpp column-major tiles.
  ## 
  ## :srf:     Surface to initialize.
  ## :data:    Pointer to the surface memory.
  ## :width:   Width of surface.
  ## :height:  Height of surface.
  ## :pal:     Pointer to the surface's palette.
  init(srf.Surface, srfChr4c, data, width, height, bpp=4, pal)

proc init*(srf: var SurfaceChr4r; data: pointer; width, height: uint; pal: ptr Palette) {.inline.} =
  ## Initalize a surface for 4bpp row-major tiles.
  ## 
  ## :srf:     Surface to initialize.
  ## :data:    Pointer to the surface memory.
  ## :width:   Width of surface.
  ## :height:  Height of surface.
  ## :pal:     Pointer to the surface's palette.
  init(srf.Surface, srfChr4r, data, width, height, bpp=4, pal)

proc init*(srf: var SurfaceBmp16; data: pointer; width, height: uint) {.inline.} =
  ## Initalize a 16bpp bitmap surface.
  ## 
  ## :srf:     Surface to initialize.
  ## :data:    Pointer to the surface memory.
  ## :width:   Width of surface.
  ## :height:  Height of surface.
  ## :pal:     Pointer to the surface's palette.
  init(srf.Surface, srfBmp16, data, width, height, bpp=16, nil)

proc init*(srf: var SurfaceBmp8; data: pointer; width, height: uint; pal: ptr Palette) {.inline.} =
  ## Initalize an 8bpp bitmap surface.
  ## 
  ## :srf:     Surface to initialize.
  ## :data:    Pointer to the surface memory.
  ## :width:   Width of surface.
  ## :height:  Height of surface.
  ## :pal:     Pointer to the surface's palette.
  init(srf.Surface, srfBmp8, data, width, height, bpp=8, pal)


# Common Procedures
# -----------------

proc copyColors*(dst, src: SomeSurface; count: uint) {.importc: "srf_pal_copy", tonc.}
  ## Copy `count` colors from `src`'s palette to `dst`'s palette.

proc getPtr*(srf: SomeSurface; x, y: uint): pointer {.importc: "srf_get_ptr", tonc.}
  ## Get the byte address of coordinates (`x`, `y`) on the surface.

proc getPtr*(srf: SomeSurface; x, y: uint; stride: uint): pointer {.importc: "_srf_get_ptr", toncinl.}
  ## Inline version of getPtr(). Use with caution.

proc setPtr*(srf: var SomeSurface; `ptr`: pointer) {.importc: "srf_set_ptr", toncinl.}
  ## Set the data-pointer for surface `srf`.

proc align*(width: uint; bpp: uint): uint {.importc: "srf_align", toncinl.}
  ## Get the word-aligned number of bytes for a scanline.
  ## 
  ## :width:  Number of pixels.
  ## :bpp:    Bits per pixel.

proc setPal*(srf: var SomeSurface; pal: ptr Palette; size: uint) {.importc: "srf_set_pal", toncinl.}
  ## Set the palette pointer and its size.



# 16bpp bitmap surfaces
# ---------------------
# Routines for 16bpp linear surfaces. For use in modes 3 and 5. Can
# also be used for regular tilemaps to a point.

proc getPixel*(src: SurfaceBmp16; x, y: int): uint32 {.importc: "_sbmp16_get_pixel", toncinl.}
  ## Get the pixel value of `src` at (`x`, `y`).

proc plot*(dst: SurfaceBmp16; x, y: int; clr: uint32) {.importc: "_sbmp16_plot", toncinl.}
  ## Plot a single pixel on a 16-bit buffer; inline version.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y:    Y-coord.
  ## :clr:  Color.

proc hline*(dst: SurfaceBmp16; x1, y, x2: int; clr: uint32) {.importc: "sbmp16_hline", tonc.}
  ## Draw a horizontal line on an 16bit buffer.
  ## 
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y:    Y-coord.
  ## :x2:   Second X-coord.
  ## :clr:  Color.
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc vline*(dst: SurfaceBmp16; x, y1, y2: int; clr: uint32) {.importc: "sbmp16_vline", tonc.}
  ## Draw a vertical line on an 16bit buffer.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y1:   First Y-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc line*(dst: SurfaceBmp16; x1, y1, x2, y2: int; clr: uint32) {.importc: "sbmp16_line", tonc.}
  ## Draw a line on an 16bit buffer.
  ## 
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y1:   First Y-coord.
  ## :x2:   Second X-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc rect*(dst: SurfaceBmp16; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp16_rect", tonc.}
  ## Draw a rectangle in 16bit mode.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc frame*(dst: SurfaceBmp16; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp16_frame", tonc.}
  ## Draw a rectangle in 16bit mode.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc blit*(dst: SurfaceBmp16; dstX, dstY: int; width, height: uint; src: SurfaceBmp16; srcX, srcY: int) {.importc: "sbmp16_blit", tonc.}
  ## 16bpp blitter. Copies a rectangle from one surface to another.
  ## 
  ## :dst:     Destination surface.
  ## :dstX:    Left coord of rectangle on `dst`.
  ## :dstY:    Top coord of rectangle on `dst`.
  ## :width:   Width of rectangle to blit.
  ## :height:  Height of rectangle to blit.
  ## :src:     Source surface.
  ## :srcX:    Left coord of rectangle on `src`.
  ## :srcY:    Top coord of rectangle on `src`.
  ## 
  ## .. note::
  ##    The rectangle will be clipped to both `src` and `dst`.

proc floodfill*(dst: SurfaceBmp16; x, y: int; clr: uint32) {.importc: "sbmp16_floodfill", tonc.}
  ## Floodfill an area of the same color with new color `clr`.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coordinate.
  ## :y:    Y-coordinate;
  ## :clr:  Color.


# 8bpp bitmap surfaces
# --------------------
# Routines for 8bpp linear surfaces. For use in mode 4 and affine tilemaps.

proc getPixel*(src: SurfaceBmp8; x, y: int): uint32 {.importc: "_sbmp8_get_pixel", toncinl.}
  ## Get the pixel value of `src` at (`x`, `y`); inline version.

proc plot*(dst: SurfaceBmp8; x, y: int; clr: uint32) {.importc: "_sbmp8_plot", toncinl.}
  ## Plot a single pixel on a 8-bit buffer; inline version.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y:    Y-coord.
  ## :clr:  Color.

proc hline*(dst: SurfaceBmp8; x1, y, x2: int; clr: uint32) {.importc: "sbmp8_hline", tonc.}
  ## Draw a horizontal line on an 8-bit buffer.
  ## 
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y:    Y-coord.
  ## :x2:   Second X-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc vline*(dst: SurfaceBmp8; x, y1, y2: int; clr: uint32) {.importc: "sbmp8_vline", tonc.}
  ## Draw a vertical line on an 8-bit buffer.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y1:   First Y-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc line*(dst: SurfaceBmp8; x1, y1, x2, y2: int; clr: uint32) {.importc: "sbmp8_line", tonc.}
  ## Draw a line on an 8-bit buffer.
  ## 
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y1:   First Y-coord.
  ## :x2:   Second X-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc rect*(dst: SurfaceBmp8; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp8_rect", tonc.}
  ## Draw a rectangle in 8-bit mode.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc frame*(dst: SurfaceBmp8; left, top, right, bottom: int; clr: uint32) {.importc: "sbmp8_frame", tonc.}
  ## Draw a rectangle in 8-bit mode.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc blit*(dst: SurfaceBmp8; dstX, dstY: int, width, height: uint; src: SurfaceBmp8; srcX, srcY: int) {.importc: "sbmp8_blit", tonc.}
  ## 16bpp blitter. Copies a rectangle from one surface to another.
  ## 
  ## :dst:     Destination surface.
  ## :dstX:    Left coord of rectangle on `dst`.
  ## :dstY:    Top coord of rectangle on `dst`.
  ## :width:   Width of rectangle to blit.
  ## :height:  Height of rectangle to blit.
  ## :src:     Source surface.
  ## :srcX:    Left coord of rectangle on `src`.
  ## :srcY:    Top coord of rectangle on `src`.
  ## 
  ## .. note::
  ##    The rectangle will be clipped to both `src` and `dst`.

proc floodfill*(dst: SurfaceBmp8; x, y: int; clr: uint32) {.importc: "sbmp8_floodfill", tonc.}
  ## Floodfill an area of the same color with new color `clr`.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coordinate.
  ## :y:    Y-coordinate;
  ## :clr:  Color.


# 4bpp tiled surfaces, column major
# ---------------------------------

proc getPixel*(src: SurfaceChr4c; x, y: int): uint32 {.importc: "_schr4c_get_pixel", toncinl.}
  ## Get the pixel value of `src` at (`x`, `y`); inline version.

proc plot*(dst: SurfaceChr4c; x, y: int; clr: uint32) {.importc: "_schr4c_plot", toncinl.}
  ## Plot a single pixel on a 4bpp tiled surface; inline version.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y:    Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Fairly slow. Inline plotting functionality if possible.

proc hline*(dst: SurfaceChr4c; x1, y, x2: int; clr: uint32) {.importc: "schr4c_hline", tonc.}
  ## Draw a horizontal line on a 4bpp tiled surface.
  ## 
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y:    Y-coord.
  ## :x2:   Second X-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc vline*(dst: SurfaceChr4c; x, y1, y2: int; clr: uint32) {.importc: "schr4c_vline", tonc.}
  ## Draw a vertical line on a 4bpp tiled surface.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y1:   First Y-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc line*(dst: SurfaceChr4c; x1, y1, x2, y2: int; clr: uint32) {.importc: "schr4c_line", tonc.}
  ## Draw a line on a 4bpp tiled surface.
  ## 
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y1:   First Y-coord.
  ## :x2:   Second X-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc rect*(dst: SurfaceChr4c; left, top, right, bottom: int; clr: uint32) {.importc: "schr4c_rect", tonc.}
  ## Render a rectangle on a 4bpp tiled canvas.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color-index.

proc frame*(dst: SurfaceChr4c; left, top, right, bottom: int; clr: uint32) {.importc: "schr4c_frame", tonc.}
  ## Draw a rectangle on a 4bpp tiled surface.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc blit*(dst: SurfaceChr4c; dstX, dstY: int; width, height: uint; src: SurfaceChr4c; srcX, srcY: int) {.importc: "schr4c_blit", tonc.}
  ## Blitter for 4bpp tiled surfaces. Copies a rectangle from one surface to another.
  ## 
  ## :dst:     Destination surface.
  ## :dstX:    Left coord of rectangle on `dst`.
  ## :dstY:    Top coord of rectangle on `dst`.
  ## :width:   Width of rectangle to blit.
  ## :height:  Height of rectangle to blit.
  ## :src:     Source surface.
  ## :srcX:    Left coord of rectangle on `src`.
  ## :srcY:    Top coord of rectangle on `src`.
  ## 
  ## .. note::
  ##    The rectangle will be clipped to both `src` and `dst`.

proc floodfill*(dst: SurfaceChr4c; x, y: int; clr: uint32) {.importc: "schr4c_floodfill", tonc.}
  ## Floodfill an area of the same color with new color `clr`.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coordinate.
  ## :y:    Y-coordinate;
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    This routines is probably very, very slow. 

# Additional routines

proc prepMap*(srf: SurfaceChr4c; map: ptr ScrEntry | ptr UncheckedArray[ScrEntry]; se0: uint16) {.importc: "schr4c_prep_map", tonc.}
  ## Prepare a screen-entry map for use with chr4.
  ## 
  ## :srf:  Surface with size information.
  ## :map:  Screen-blocked map to initialize.
  ## :se0:  Additive base screen-entry.

proc getPtr*(srf: SurfaceChr4c; x, y: int): ptr uint32 {.importc: "schr4c_get_ptr", tonc.}
  ## Special pointer getter for chr4: start of in-tile line.


# 4bpp tiled surfaces, row major
# ------------------------------

proc getPixel*(src: SurfaceChr4r; x, y: int): uint32 {.importc: "_schr4r_get_pixel", toncinl.}
  ## Get the pixel value of `src` at (`x`, `y`); inline version.

proc plot*(dst: SurfaceChr4r; x, y: int; clr: uint32) {.importc: "_schr4r_plot", toncinl.}
  ## Plot a single pixel on a 4bpp tiled surface; inline version.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y:    Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Slow as fuck. Inline plotting functionality if possible.

proc hline*(dst: SurfaceChr4r; x1, y, x2: int; clr: uint32) {.importc: "schr4r_hline", tonc.}
  ## Draw a horizontal line on a 4bpp tiled surface.
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y:    Y-coord.
  ## :x2:   Second X-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc vline*(dst: SurfaceChr4r; x, y1, y2: int; clr: uint32) {.importc: "schr4r_vline", tonc.}
  ## Draw a vertical line on a 4bpp tiled surface.
  ## 
  ## :dst:  Destination surface.
  ## :x:    X-coord.
  ## :y1:   First Y-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc line*(dst: SurfaceChr4r; x1, y1, x2, y2: int; clr: uint32) {.importc: "schr4r_line", tonc.}
  ## Draw a line on a 4bpp tiled surface.
  ## 
  ## :dst:  Destination surface.
  ## :x1:   First X-coord.
  ## :y1:   First Y-coord.
  ## :x2:   Second X-coord.
  ## :y2:   Second Y-coord.
  ## :clr:  Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

proc rect*(dst: SurfaceChr4r; left, top, right, bottom: int; clr: uint32) {.importc: "schr4r_rect", tonc.}
  ## Render a rectangle on a tiled canvas.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color-index. Octupled if > 16.
  # 
  # .. note::
  #    For a routine like this you can strive for programmer sanity
  #    or speed. This is for speed. Except for very small rects, this 
  #    is between 5x and 300x faster than the trivial version.
  
proc frame*(dst: SurfaceChr4r; left, top, right, bottom: int; clr: uint32) {.importc: "schr4r_frame", tonc.}
  ## Draw a rectangle on a 4bpp tiled surface.
  ## 
  ## :dst:     Destination surface.
  ## :left:    Left side of rectangle;
  ## :top:     Top side of rectangle.
  ## :right:   Right side of rectangle.
  ## :bottom:  Bottom side of rectangle.
  ## :clr:     Color.
  ## 
  ## .. note::
  ##    Does normalization, but not bounds checks.

# Additional routines

proc prepMap*(srf: SurfaceChr4r; map: ptr ScrEntry | ptr UncheckedArray[ScrEntry]; se0: uint16) {.importc: "schr4r_prep_map", tonc.}
  ## Prepare a screen-entry map for use with chr4.
  ## 
  ## :srf:   Surface with size information.
  ## :map:   Screen-blocked map to initialize.
  ## :se0:   Additive base screen-entry.

proc getPtr*(srf: SurfaceChr4r; x: int; y: int): ptr uint32 {.importc: "schr4r_get_ptr", tonc.}
  ## Special pointer getter for chr4: start of in-tile line.

