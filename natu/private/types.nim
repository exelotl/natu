import ./common
import ./sdl/appcommon
import ../bits

# static:
#   # Make sure we're actually compiling for a 32-bit system.
#   doAssert(sizeof(int) == 4)

converter to_cint*(x: int): cint {.inline.} = x.cint
converter to_cuint*(x: uint): cuint {.inline.} = x.cuint

type
  FnPtr* {.exportc.} = proc () {.nimcall.}    ## Function pointer, used for interrupt handlers etc.

type
  FixedT*[T: SomeInteger, N: static int] = distinct T
    ## A fixed-point number based on type `T`, with `N` bits of precision.
  
  FixedN*[N: static int] = FixedT[cint, N]
    ## A signed 32-bit fixed-point number with `N` bits of precision.
  
  Fixed* = FixedN[8]
    ## A signed 32-bit fixed-point number with 8 bits of precision.

type
  Block* {.importc: "BLOCK", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## 8-word type for fast struct-copies
    data*: array[8, uint32]

type
  ScrEntry* = distinct uint16
    ## Type for screen entries (i.e. the values that make up a tile map)
    ## 
    ## Each screen entry is a bitfield with the following attributes:
    ## 
    ## ======== ======= ========= =====================
    ## Field    Type    Bits      Description
    ## ======== ======= ========= =====================
    ## `tileId` int     0-9       Tile to display (relative to the background's `cbb` × 512)
    ## `hflip`  bool    10        Flip horizontally
    ## `vflip`  bool    11        Flip vertically
    ## `palId`  int     12-15     Palette to use (ignored for 8bpp backgrounds)
    ## `tid`    int     0-9       Alias for tileId
    ## `pal`    int     12-15     Alias for palId
    ## ======== ======= ========= =====================

 
type
  ScrAffEntry* = uint8  ## Type for affine screen entries

type
  Tile* = Tile4
  
  Tile4* {.importc: "TILE4", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## 4bpp tile type, for easy indexing and copying of 16-color tiles
    data* {.importc: "data".}: array[8, uint32]
    
  Tile8* {.importc: "TILE8", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## 8bpp tile type, for easy indexing and copying of 256-color tiles
    data* {.importc: "data".}: array[16, uint32]

type
  ObjAffineSource* = AffSrc
  BgAffineSource* = AffSrcEx
  ObjAffineDest* = AffDst
  BgAffineDest* = AffDstEx
  
  AffSrc* {.importc: "AFF_SRC", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## Simple scale-rotation source struct.
    ## This can be used with :xref:`ObjAffineSet() <ObjAffineSet>`, and several of Tonc's affine functions.
    sx*: FixedT[int16, 8]    ## Horizontal zoom (8.8f)
    sy*: FixedT[int16, 8]    ## Vertical zoom (8.8f)
    alpha*: uint16           ## Counter-clockwise angle (range 0..0xffff)
  
  AffSrcEx* {.importc: "AFF_SRC_EX", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## Extended scale-rotate source struct.
    ## This is used to scale/rotate around an arbitrary point. See `Tonc <https://gbadev.net/tonc/affobj.html#sec-combo>`__ for all the details.
    texX* {.importc: "tex_x".}: Fixed        ## Texture-space anchor, x coordinate  (.8f)
    texY* {.importc: "tex_y".}: Fixed        ## Texture-space anchor, y coordinate  (.8f)
    scrX* {.importc: "scr_x".}: int16        ## Screen-space anchor, x coordinate  (.0f)
    scrY* {.importc: "scr_y".}: int16        ## Screen-space anchor, y coordinate  (.0f)
    sx* {.importc: "sx".}: FixedT[int16, 8]  ## Horizontal zoom (8.8f)
    sy* {.importc: "sy".}: FixedT[int16, 8]  ## Vertical zoom (8.8f)
    alpha* {.importc: "alpha".}: uint16      ## Counter-clockwise angle (range [0, 0xFFFF])
  
  AffDst* {.importc: "AFF_DST", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## Simple scale-rotation destination struct.
    ## This is a P-matrix with contiguous elements, like the BG matrix.
    ## It can be used with :xref:`ObjAffineSet() <ObjAffineSet>`.
    pa*, pb*, pc*, pd*: FixedT[int16, 8]
  
  AffDstEx* {.importc: "AFF_DST_EX", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## Extended scale-rotate destination struct.
    ## 
    ## This contains the P-matrix and a fixed-point offset, the
    ## combination can be used to rotate around an arbitrary point.
    ## 
    ## Mainly intended for :xref:`BgAffineSet() <BgAffineSet>`, but can be used
    ## for object transforms too.
    pa*, pb*, pc*, pd*: FixedT[int16, 8]
    dx*, dy*: int32


type
  BgPoint* = Point16
  Point16* {.importc: "POINT16", header: "tonc_types.h", bycopy, completeStruct.} = object
    x*, y*: int16

type
  BgAffine* = AffDstEx
    ## Affine parameters for backgrounds, as used by :xref:`bgaff[2..3] <bgaff>`.

type
  DmaRec* {.importc: "DMA_REC", header: "tonc_types.h", bycopy, completeStruct.} = object
    ##  DMA struct; range: 0400:00B0 - 0400:00DF
    src* {.importc: "src".}: pointer
    dst* {.importc: "dst".}: pointer
    cnt* {.importc: "cnt".}: uint32
  
  TmrRec* {.importc: "TMR_REC", header: "tonc_types.h", bycopy, completeStruct.} = object
    ## Timer struct, range: 0400:0100 - 0400:010F
    ## note: The attribute is required, because union's counted as u32 otherwise.
    start* {.importc: "start".}: uint16
    count* {.importc: "count".}: uint16  # start and count are actually union fields? does this still work?
    cnt* {.importc: "cnt".}: uint16

type
  Color* = distinct uint16
    ## A 15bpp BGR color value.
    ## 
    ## The red, green and blue components can be accessed via the following fields:
    ## 
    ## ======== ======= ========= =====================
    ## Field    Type    Bits      Description
    ## ======== ======= ========= =====================
    ## `r`      int     0-4       Red component
    ## `g`      int     5-9       Green component
    ## `b`      int     10-14     Blue component
    ## ======== ======= ========= =====================

type
  Palette* = array[16, Color]
    ## A 16-color palette.
    ## 
    ## The first element in a palette is irrelevant, except
    ## for `bgPalMem[0][0]` (i.e. `bgColorMem[0]`) which sets the
    ## backdrop color for the entire screen.

# VRAM array types
# These types allow VRAM access as arrays or matrices in their most natural types.
type
  M3Line* {.deprecated.} = array[240, Color]
  M4Line* {.deprecated.} = array[240, uint8]
  M5Line* {.deprecated.} = array[160, Color]
  M3Mem* = array[160, array[240, Color]]
  M4Mem* = array[160, array[240, uint8]]
    ## .. note::
    ## 
    ##    VRAM does not support 8-bit writes.
    ##    Do not attempt to use this to write bytes directly to VRAM!
    ##    (try one of the `plot()` procedures instead?)
    ## 
  M5Mem* = array[128, array[160, Color]]
  Screenline* = array[32, ScrEntry]
  ScreenMat* = array[32, Screenline]
  Screenblock* = array[1024, ScrEntry]
  # Charblock* = array[512, Tile]
  # Charblock8* = array[256, Tile8]

proc `[]`*(a: var Screenblock; x, y: int): var ScrEntry {.inline.} =
  cast[ptr array[1024, ScrEntry]](addr a)[x + y*32]

proc `[]=`*(a: var Screenblock; x, y: int; v: ScrEntry) {.inline.} =
  cast[ptr array[1024, ScrEntry]](addr a)[x + y*32] = v

when natuPlatform == "gba":
  const CbbTiles = 512
elif natuPlatform == "sdl":
  const CbbTiles = 1024
else:
  {.error: "Unknown platform " & natuPlatform.}

template allowUnboundedAccess(A: typedesc, Len:static[int], T: typedesc) =
  {.push inline.}
  
  proc `[]`*(a: var A, i: int): var T =
    cast[ptr UncheckedArray[T]](addr a)[i]
  
  proc `[]=`*(a: var A, i: int, v: T) =
    cast[ptr UncheckedArray[T]](addr a)[i] = v
  
  converter toArray*(a: var A): var array[Len, T] =
    cast[ptr array[Len, T]](addr a)[]
  
  {.pop.}

type
  Charblock* = array[CbbTiles, Tile]
  Charblock8* = array[CbbTiles div 2, Tile8]
  UnboundedCharblock* {.borrow:`.`.} = distinct array[CbbTiles, Tile]
  UnboundedCharblock8* {.borrow:`.`.} = distinct array[CbbTiles div 2, Tile8]

when natuPlatform == "sdl":
  static:
    doAssert(sizeof(UnboundedCharblock) == NatuCbLen*sizeof(uint16))

allowUnboundedAccess(UnboundedCharblock, CbbTiles, Tile)
allowUnboundedAccess(UnboundedCharblock8, CbbTiles div 2, Tile8)

when natuPlatform == "gba":
  
  type
    OamUint* = uint16
    OamInt* = int16
    
    ObjAttr* {.importc: "OBJ_ATTR", header: "tonc_types.h", bycopy, completeStruct.} = object
      ## Object attributes are the parameters of a sprite.
      ## 
      ## The following accessors are available to work with them:
      ## 
      ## ========== ================== =======================================================
      ## Field      Type               Description
      ## ========== ================== =======================================================
      ## `x`        int                X coordinate of the sprite's top-left corner (0 .. 511)
      ## `y`        int                Y coordinate of the sprite's top-left corner (0 .. 255)
      ## `pos`      :xref:`Vec2i`      Access the X and Y coordinates as a pair.
      ## `mode`     :xref:`ObjMode`    One of `omRegular`, `omAffine`, `omHidden`, `omAffineDouble`.
      ## `fx`       :xref:`ObjFxMode`  One of `fxNone`, `fxBlend`, `fxWindow`.
      ## `mos`      bool               Enables mosaic effect.
      ## `hflip`    bool               Horizontal flip (if mode is `omRegular`)
      ## `vflip`    bool               Vertical flip (if mode is `omRegular`)
      ## `affId`    int                Affine matrix to use (0 .. 31), if mode is `omAffine` or `omAffineDouble`.
      ## `is8bpp`   bool               Display 8bpp tiles if true, 4bpp otherwise.
      ## `size`     :xref:`ObjSize`    Determines the width and height of the sprite.
      ## `tileId`   int                The base tile of the sprite (0 .. 1023), i.e. index into :xref:`objTileMem`.
      ## `palId`    int                Which palette to use in 4bpp mode (0 .. 15), i.e. index into :xref:`objPalMem`.
      ## `prio`     int                Priority value (0 = front, 3 = back)
      ## `tid`      int                Alias for `tileId`.
      ## `pal`      int                Alias for `palId`.
      ## ========== ================== =======================================================
      ## 
      ## The raw underlying fields are as follows:
      ## 
      attr0* {.importc: "attr0".}: uint16
        ## Attribute 0
      attr1* {.importc: "attr1".}: uint16
        ## Attribute 1
      attr2* {.importc: "attr2".}: uint16
        ## Attribute 2
      fill* {.importc: "fill".}: int16
        ## .. warning::
        ##   Messing with `fill` could screw up scaling/rotation that you applied to other sprites!
        ## 
        ## Padding which exists because `ObjAttr` and `ObjAffine` are overlaid in memory.
        ## 
        ## This field will not be copied when assigning one `ObjAttr` to another. Therefore
        ## you may use it for any purpose if your object exists outside of OAM and you intend
        ## to copy it over later.
    
    ObjAffine* {.importc: "OBJ_AFFINE", header: "tonc_types.h", bycopy, completeStruct.} = object
      ## Object affine parameters.
      fill0 {.importc: "fill0".}: array[3, uint16]
      pa* {.importc: "pa".}: int16
      fill1 {.importc: "fill1".}: array[3, uint16]
      pb* {.importc: "pb".}: int16
      fill2 {.importc: "fill2".}: array[3, uint16]
      pc* {.importc: "pc".}: int16
      fill3 {.importc: "fill3".}: array[3, uint16]
      pd* {.importc: "pd".}: int16
    
    ObjAttrPtr* = ptr ObjAttr
      ## Pointer to object attributes.
      
    ObjAffinePtr* = ptr ObjAffine
      ## Pointer to object affine parameters.

elif natuPlatform == "sdl":
  type
    OamUint* = uint32
    OamInt* = int32
    
    ObjAttr* = object
      attr0*: uint32
      attr1*: uint32
      attr2*: uint32
      fill*: int32
    
    ObjAffine* = object
      fill0: array[3, uint32]
      pa*: int32
      fill1: array[3, uint32]
      pb*: int32
      fill2: array[3, uint32]
      pc*: int32
      fill3: array[3, uint32]
      pd*: int32
    
    ObjAttrPtr* = ptr ObjAttr
    ObjAffinePtr* = ptr ObjAffine
  
else:
  {.error: "Unknown platform " & natuPlatform.}
  

{.push inline.}

proc `=copy`*(dst: var ObjAttr, src: ObjAttr) =
  ## Custom copy assignment for ObjAttr to avoid clobbering the
  ## affine matrix data in the `fill` field.
  dst.attr0 = src.attr0
  dst.attr1 = src.attr1
  dst.attr2 = src.attr2

proc `=sink`*(dst: var ObjAttr, src: ObjAttr) =
  ## Custom move assignment for ObjAttr to avoid clobbering the
  ## affine matrix data in the `fill` field.
  dst.attr0 = src.attr0
  dst.attr1 = src.attr1
  dst.attr2 = src.attr2

proc `=copy`*(dst: var ObjAffine, src: ObjAffine) =
  ## Custom copy assignment for ObjAffine to avoid clobbering the
  ## object attribute data in the `fill` fields.
  dst.pa = src.pa
  dst.pb = src.pb
  dst.pc = src.pc
  dst.pd = src.pd

proc `=sink`*(dst: var ObjAffine, src: ObjAffine) =
  ## Custom move assignment for ObjAffine to avoid clobbering the
  ## object attribute data in the `fill` fields.
  dst.pa = src.pa
  dst.pb = src.pb
  dst.pc = src.pc
  dst.pd = src.pd

{.pop.}
