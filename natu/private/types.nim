# Basic structs and typedefs
# ==========================

static:
  doAssert(sizeof(int) == 4)
  
type
  FnPtr* = proc () {.nimcall.}    ## Function pointer, used for interrupt handlers etc.

# To be used with codegenDecl pragma:
const
  IWRAM_DATA* = "__attribute__((section(\".iwram\"))) $# $#"    ## Put variable in IWRAM (default).
  EWRAM_DATA* = "__attribute__((section(\".ewram\"))) $# $#"    ## Put variable in EWRAM.
  EWRAM_BSS* = "__attribute__((section(\".sbss\"))) $# $#"      ## Put non-initialized variable in EWRAM.
  IWRAM_CODE* = "__attribute__((section(\".iwram\"), target(\"arm\"), long_call)) $# $#$#"  ## Put procedure in IWRAM.
  EWRAM_CODE* = "__attribute__((section(\".ewram\"), long_call)) $# $#$#"  ## Put procedure in EWRAM.

const
  DataInIwram* = "__attribute__((section(\".iwram\"))) $# $#"    ## Put variable in IWRAM (default).
  DataInEwram* = "__attribute__((section(\".ewram\"))) $# $#"    ## Put variable in EWRAM.
  DataInEwramBss* = "__attribute__((section(\".sbss\"))) $# $#"      ## Put non-initialized variable in EWRAM.
  ArmCodeInIwram* = "__attribute__((section(\".iwram\"), target(\"arm\"), long_call)) $# $#$#"  ## Put procedure in IWRAM.
  ThumbCodeInEwram* = "__attribute__((section(\".ewram\"), long_call)) $# $#$#"  ## Put procedure in EWRAM.


type
  Block* {.importc: "BLOCK", header: "tonc.h", bycopy, completeStruct.} = object
    ## 8-word type for fast struct-copies
    data* {.importc: "data".}: array[8, uint32]

type
  Fixed* = distinct int32   ## Fixed point type, "24.8"

type
  Color* = distinct uint16  ## Type for colors

type
  ScrEntry* = uint16    ## Type for screen entries           TODO: make distinct
  ScrAffEntry* = uint8  ## Type for affine screen entries

type
  Tile* = Tile4
  
  Tile4* {.importc: "TILE4", header: "tonc.h", bycopy, completeStruct.} = object
    ## 4bpp tile type, for easy indexing and copying of 16-color tiles
    data* {.importc: "data".}: array[8, uint32]
    
  Tile8* {.importc: "TILE8", header: "tonc.h", bycopy, completeStruct.} = object
    ## 8bpp tile type, for easy indexing and copying of 256-color tiles
    data* {.importc: "data".}: array[16, uint32]

type
  ObjAffineSource* = AffSrc
  BgAffineSource* = AffSrcEx
  ObjAffineDest* = AffDst
  BgAffineDest* = AffDstEx
  
  AffSrc* {.importc: "AFF_SRC", header: "tonc.h", bycopy, completeStruct.} = object
    ## Simple scale-rotation source struct.
    ## This can be used with ``bios.ObjAffineSet``, and several of tonc's affine functions
    sx* {.importc: "sx".}: int16          ## Horizontal zoom (8.8f)
    sy* {.importc: "sy".}: int16          ## Vertical zoom (8.8f)
    alpha* {.importc: "alpha".}: uint16   ## Counter-clockwise angle (range 0..0xffff)
  
  AffSrcEx* {.importc: "AFF_SRC_EX", header: "tonc.h", bycopy, completeStruct.} = object
    ## Extended scale-rotate source struct
    ## This is used to scale/rotate around an arbitrary point. See tonc's main text for all the details.
    texX* {.importc: "tex_x".}: int32   ## Texture-space anchor, x coordinate  (.8f)
    texY* {.importc: "tex_y".}: int32   ## Texture-space anchor, y coordinate  (.8f)
    scrX* {.importc: "scr_x".}: int16   ## Screen-space anchor, x coordinate  (.0f)
    scrY* {.importc: "scr_y".}: int16   ## Screen-space anchor, y coordinate  (.0f)
    sx* {.importc: "sx".}: int16        ## Horizontal zoom (8.8f)
    sy* {.importc: "sy".}: int16        ## Vertical zoom (8.8f)
    alpha* {.importc: "alpha".}: uint16 ## Counter-clockwise angle (range [0, 0xFFFF])
  
  AffDst* {.importc: "AFF_DST", header: "tonc.h", bycopy, completeStruct.} = object
    ## Simple scale-rotation destination struct, BG version.
    ## This is a P-matrix with continuous elements, like the BG matrix.
    ## It can be used with ObjAffineSet.
    pa* {.importc: "pa".}: int16
    pb* {.importc: "pb".}: int16
    pc* {.importc: "pc".}: int16
    pd* {.importc: "pd".}: int16

  AffDstEx* {.importc: "AFF_DST_EX", header: "tonc.h", bycopy, completeStruct.} = object
    ## Extended scale-rotate destination struct
    ## This contains the P-matrix and a fixed-point offset, the
    ##  combination can be used to rotate around an arbitrary point.
    ## Mainly intended for BgAffineSet, but the struct can be used
    ##  for object transforms too.
    pa* {.importc: "pa".}: int16
    pb* {.importc: "pb".}: int16
    pc* {.importc: "pc".}: int16
    pd* {.importc: "pd".}: int16
    dx* {.importc: "dx".}: int32
    dy* {.importc: "dy".}: int32

# Memory map structs
# ==================

# Tertiary types
# These types are used for memory mapping of VRAM, affine registers 
#  and other areas that would benefit from logical memory mapping.

# Regular bg points; range: :0010 - :001F

type
  BgPoint* = Point16
  Point16* {.importc: "POINT16", header: "tonc.h", bycopy, completeStruct.} = object
    x*, y*: int16

type BgAffine* = AffDstEx
  ## Affine parameters for backgrounds; range : 0400:0020 - 0400:003F

type
  DmaRec* {.importc: "DMA_REC", header: "tonc.h", bycopy, completeStruct.} = object
    ##  DMA struct; range: 0400:00B0 - 0400:00DF
    src* {.importc: "src".}: pointer
    dst* {.importc: "dst".}: pointer
    cnt* {.importc: "cnt".}: uint32
  
  TmrRec* {.importc: "TMR_REC", header: "tonc.h", bycopy, completeStruct.} = object
    ## Timer struct, range: 0400:0100 - 0400:010F
    ## note: The attribute is required, because union's counted as u32 otherwise.
    start* {.importc: "start".}: uint16
    count* {.importc: "count".}: uint16  # start and count are actually union fields? does this still work?
    cnt* {.importc: "cnt".}: uint16

type
  Palbank* {.deprecated.} = array[16, Color]
    ## Palette bank type, for 16-color palette banks
  Palette* = array[16, Color]
    ## A 16-color palette


## VRAM array types
## These types allow VRAM access as arrays or matrices in their most natural types.
type
  Screenline* = array[32, ScrEntry]
  M3Line* = array[240, Color]
  M4Line* = array[240, uint8]  ## NOTE: u8, not u16!! (be careful not to write single bytes to VRAM)
  M5Line* = array[160, Color]
  ScreenMat* = array[32, array[32, ScrEntry]]
  Screenblock* = array[1024, ScrEntry]
  Charblock* = array[512, Tile]
  Charblock8* = array[256, Tile8]

proc `[]`*(a: var Screenblock; x, y: int): var ScrEntry {.inline.} =
  cast[ptr array[1024, ScrEntry]](addr a)[x + y*32]

proc `[]=`*(a: var Screenblock; x, y: int; v: ScrEntry) {.inline.} =
  cast[ptr array[1024, ScrEntry]](addr a)[x + y*32] = v

type
  UnboundedCharblock* {.borrow:`.`.} = distinct array[512, Tile]
  UnboundedCharblock8* {.borrow:`.`.} = distinct array[256, Tile8]

template allowUnboundedAccess(A: typedesc, Len:static[int], T: typedesc) =
  {.push inline.}
  
  proc `[]`*(a: var A, i: int): var T =
    cast[ptr UncheckedArray[T]](addr a)[i]
  
  proc `[]=`*(a: var A, i: int, v: T) =
    cast[ptr UncheckedArray[T]](addr a)[i] = v
  
  converter toArray*(a: var A): var array[Len, T] =
    cast[ptr array[Len, T]](addr a)[]
  
  {.pop.}

allowUnboundedAccess(UnboundedCharblock, 512, Tile)
allowUnboundedAccess(UnboundedCharblock8, 256, Tile8)


type
  ObjAttr* {.importc: "OBJ_ATTR", header: "tonc.h", bycopy, completeStruct.} = object
    ## Object attributes. i.e. a sprite.
    ## **Note**
    ##  The `fill` field is padding for the interlace with ObjAffine.
    ##  It will not be copied when assigning one ObjAttr to another.
    attr0* {.importc: "attr0".}: uint16
    attr1* {.importc: "attr1".}: uint16
    attr2* {.importc: "attr2".}: uint16
    fill {.importc: "fill".}: int16
  
  ObjAffine* {.importc: "OBJ_AFFINE", header: "tonc.h", bycopy, completeStruct.} = object
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


# Input
# -----

type
  KeyIndex* = enum
    ## Bit positions for `reg.keyinput` and `reg.keycnt`.
    ## Used with input module functions such as `keyIsDown`.
    kiA            ## Button A
    kiB            ## Button B
    kiSelect       ## Select button
    kiStart        ## Start button
    kiRight        ## Right D-pad
    kiLeft         ## Left D-pad
    kiUp           ## Up D-pad
    kiDown         ## Down D-pad
    kiR            ## Shoulder R
    kiL            ## Shoulder L
  
  KeyState* {.size:2.} = set[KeyIndex]


# Interrupts
# ----------

type
  IrqIndex* {.size: 4.} = enum
    ## IRQ indices, used to enable/disable and register handlers for interrupts.
    iiVBlank,   iiHBlank,  iiVCount,  iiTimer0,
    iiTimer1,   iiTimer2,  iiTimer3,  iiSerial,
    iiDma0,     iiDma1,    iiDma2,    iiDma3,
    iiKeypad,   iiGamepak

