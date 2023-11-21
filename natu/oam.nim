## Object Attribute Memory functions
## =================================

{.warning[UnusedImport]: off.}

import ./math
import private/[common, types, memdef]
from private/memmap import objMem, objAffMem
from private/privutils import writeFields

export objMem, objAffMem
export ObjAttr, ObjAffine, ObjAttrPtr, ObjAffinePtr

{.compile(toncPath & "/src/tonc_obj_affine.c", toncCFlags).}

{.pragma: tonc, header: "tonc_oam.h".}

type
  ObjMode* {.size:2.} = enum
    omReg = ATTR0_REG
    omAff = ATTR0_AFF
    omHide = ATTR0_HIDE
    omAffDbl = ATTR0_AFF_DBL
  
  ObjFxMode* {.size:2.} = enum
    fxNone = 0
      ## Normal object, no special effects.
    fxBlend = ATTR0_BLEND
      ## Alpha blending enabled.
      ## The object is effectively placed into the `bldcnt.a` layer to be blended
      ## with the `bldcnt.b` layer using the coefficients from `bldalpha`,
      ## regardless of the current `bldcnt.mode` setting.
    fxWindow = ATTR0_WINDOW
      ## The sprite becomes part of the object window.
  
  ObjSize* {.size:2.} = enum
    ## Sprite size constants, high-level interface.
    ## Each corresponds to a pair of fields (`size` in attr0, `shape` in attr1)
    s8x8, s16x16, s32x32, s64x64,
    s16x8, s32x8, s32x16, s64x32,
    s8x16, s8x32, s16x32, s32x64

func setAttr*(obj: ObjAttrPtr; a0, a1, a2: uint16) {.inline.} =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2

func setAttr*(obj: var ObjAttr; a0, a1, a2: uint16) {.inline.} =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2


# Obj affine procedures
# ---------------------

proc init*(oaff: var ObjAffine; pa, pb, pc, pd: Fixed) {.inline.} =
  ## Set the elements of an object affine matrix.
  oaff.pa = pa.int16
  oaff.pb = pb.int16
  oaff.pc = pc.int16
  oaff.pd = pd.int16

proc setToIdentity*(oaff: var ObjAffine) {.inline.} =
  ## Set an object affine matrix to the identity matrix.
  oaff.pa = 0x0100
  oaff.pb = 0
  oaff.pc = 0
  oaff.pd = 0x0100

proc setToScaleRaw*(oaff: var ObjAffine; sx, sy: Fixed) {.inline.} =
  ## Mathematically correct version of `setToScale`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  oaff.pa = sx.int16
  oaff.pb = 0
  oaff.pc = 0
  oaff.pd = sy.int16

proc setToShearXRaw*(oaff: var ObjAffine; hx: Fixed) {.inline.} =
  oaff.pa = 0x0100
  oaff.pb = hx.int16
  oaff.pc = 0
  oaff.pd = 0x0100

proc setToShearYRaw*(oaff: var ObjAffine; hy: Fixed) {.inline.} =
  oaff.pa = 0x0100
  oaff.pb = 0
  oaff.pc = hy.int16
  oaff.pd = 0x0100

proc setToRotationRaw*(oaff: var ObjAffine; alpha: uint16) {.inline.} =
  ## Mathematically correct version of `setToRotation`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  let ss = luSin(alpha.Angle).fp
  let cc = luCos(alpha.Angle).fp
  oaff.pa = (cc).int16
  oaff.pb = (-ss).int16
  oaff.pc = (ss).int16
  oaff.pd = (cc).int16

proc premul*(dst: var ObjAffine, src: ObjAffine) =
  ## Pre-multiply the matrix `dst` by `src`.
  ## i.e.
  ## 
  ## .. code-block::
  ## 
  ##   dst = src * dst
  let tmp_a = dst.pa.int
  let tmp_b = dst.pb.int
  let tmp_c = dst.pc.int
  let tmp_d = dst.pd.int
  dst.pa = ((src.pa.int * tmp_a + src.pb.int * tmp_c) shr 8).int16
  dst.pb = ((src.pa.int * tmp_b + src.pb.int * tmp_d) shr 8).int16
  dst.pc = ((src.pc.int * tmp_a + src.pd.int * tmp_c) shr 8).int16
  dst.pd = ((src.pc.int * tmp_b + src.pd.int * tmp_d) shr 8).int16

proc postmul*(dst: var ObjAffine, src: ObjAffine) =
  ## Post-multiply the matrix `dst` by `src`.
  ## i.e.
  ## 
  ## .. code-block::
  ## 
  ##   dst = dst * src
  let tmpa = dst.pa.int
  let tmpb = dst.pb.int
  let tmpc = dst.pc.int
  let tmpd = dst.pd.int
  dst.pa = ((tmp_a * src.pa.int + tmp_b * src.pc.int) shr 8).int16
  dst.pb = ((tmp_a * src.pb.int + tmp_b * src.pd.int) shr 8).int16
  dst.pc = ((tmp_c * src.pa.int + tmp_d * src.pc.int) shr 8).int16
  dst.pd = ((tmp_c * src.pb.int + tmp_d * src.pd.int) shr 8).int16

proc setToScaleAndRotationRaw*(oaff: var ObjAffine; sx, sy: Fixed; alpha: uint16) =
  ## Mathematically correct version of `setToScaleAndRotation`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  let ss = luSin(alpha.Angle).int
  let cc = luCos(alpha.Angle).int
  oaff.pa = ((cc*sx) shr 12).int16
  oaff.pb = ((-ss*sx) shr 12).int16
  oaff.pc = ((ss*sy) shr 12).int16
  oaff.pd = ((cc*sy) shr 12).int16

proc rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: ptr AffSrcEx) {.importc: "obj_rotscale_ex", tonc.}
  ## Rot/scale an object around an arbitrary point.
  ## Sets up `obj` and `oaff` for rot/scale transformation around an arbitrary point using the `asx` data.
  ## 
  ## :obj:  Object to set.
  ## :oaff: Object affine data to set.
  ## :asx:  Affine source data: screen and texture origins, scales and angle.

template rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: AffSrcEx) =
  rotscaleEx(obj, oaff, unsafeAddr asx)

proc setToScale*(oa: var ObjAffine; sx: Fixed, sy = sx) {.inline.} =
  ## Set an object affine matrix for scaling.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  oa.setToScaleRaw(x.Fixed, y.Fixed)

proc setToRotation*(oa: var ObjAffine; theta: uint16) {.inline.} =
  ## Set obj matrix to counter-clockwise rotation.
  ## 
  ## :oaff:  Object affine matrix to set.
  ## :alpha: CCW angle. full-circle is `0x10000`.
  oa.setToRotationRaw(0'u16 - theta)

proc setToShearX*(oa: var ObjAffine; hx: Fixed) {.inline.} =
  oa.setToShearXRaw(-hx)

proc setToShearY*(oa: var ObjAffine; hy: Fixed) {.inline.} =
  oa.setToShearYRaw(-hy)

proc setToScaleAndRotation*(oa: var ObjAffine; sx, sy: Fixed; theta: uint16) {.inline.} =
  ## Set obj matrix to 2d scaling, then counter-clockwise rotation.
  ## 
  ## :oaff:  Object affine matrix to set.
  ## :sx:    Horizontal scale (zoom). .8 fixed point.
  ## :sy:    Vertical scale (zoom). .8 fixed point.
  ## :alpha: CCW angle. full-circle is `0x10000`.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  oa.setToScaleAndRotationRaw(x.Fixed, y.Fixed, 0'u16 - theta)


# SPRITE GETTERS/SETTERS
# ----------------------

{.push inline.}

# copy attr0,1,2 from one object into another
func setAttr*(obj: ObjAttrPtr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)
func setAttr*(obj: var ObjAttr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)

# getters

func x*(obj: ObjAttr): int = (obj.attr1 and ATTR1_X_MASK).int
func y*(obj: ObjAttr): int = (obj.attr0 and ATTR0_Y_MASK).int
func pos*(obj: ObjAttr): Vec2i = vec2i(obj.x, obj.y)
func mode*(obj: ObjAttr): ObjMode = (obj.attr0 and ATTR0_MODE_MASK).ObjMode
func fx*(obj: ObjAttr): ObjFxMode = (obj.attr0 and (ATTR0_BLEND or ATTR0_WINDOW)).ObjFxMode
func mos*(obj: ObjAttr): bool = (obj.attr0 and ATTR0_MOSAIC) != 0
func is8bpp*(obj: ObjAttr): bool = (obj.attr0 and ATTR0_8BPP) != 0
func affId*(obj: ObjAttr): int = ((obj.attr1 and ATTR1_AFF_ID_MASK) shr ATTR1_AFF_ID_SHIFT).int
func size*(obj: ObjAttr): ObjSize = (((obj.attr0 and ATTR0_SHAPE_MASK) shr 12) or (obj.attr1 shr 14)).ObjSize
func hflip*(obj: ObjAttr): bool = (obj.attr1 and ATTR1_HFLIP) != 0
func vflip*(obj: ObjAttr): bool = (obj.attr1 and ATTR1_VFLIP) != 0
func tileId*(obj: ObjAttr): int = ((obj.attr2 and ATTR2_ID_MASK) shr ATTR2_ID_SHIFT).int
func palId*(obj: ObjAttr): int = ((obj.attr2 and ATTR2_PALBANK_MASK) shr ATTR2_PALBANK_SHIFT).int
func prio*(obj: ObjAttr): int = ((obj.attr2 and ATTR2_PRIO_MASK) shr ATTR2_PRIO_SHIFT).int

# setters

func `x=`*(obj: var ObjAttr; x: int) =
  obj.attr1 = (x.uint16 and ATTR1_X_MASK) or (obj.attr1 and not ATTR1_X_MASK)

func `y=`*(obj: var ObjAttr; y: int) =
  obj.attr0 = (y.uint16 and ATTR0_Y_MASK) or (obj.attr0 and not ATTR0_Y_MASK)

func `pos=`*(obj: var ObjAttr; v: Vec2i) =
  obj.x = v.x
  obj.y = v.y

func `tileId=`*(obj: var ObjAttr; tileId: int) =
  obj.attr2 = ((tileId.uint16 shl ATTR2_ID_SHIFT) and ATTR2_ID_MASK) or (obj.attr2 and not ATTR2_ID_MASK)

func `palId=`*(obj: var ObjAttr; palId: int) =
  obj.attr2 = ((palId.uint16 shl ATTR2_PALBANK_SHIFT) and ATTR2_PALBANK_MASK) or (obj.attr2 and not ATTR2_PALBANK_MASK)

func `hflip=`*(obj: var ObjAttr; v: bool) =
  obj.attr1 = (v.uint16 shl 12) or (obj.attr1 and not ATTR1_HFLIP)
  
func `vflip=`*(obj: var ObjAttr; v: bool) =
  obj.attr1 = (v.uint16 shl 13) or (obj.attr1 and not ATTR1_VFLIP)

func `mode=`*(obj: var ObjAttr; v: ObjMode) =
  obj.attr0 = (v.uint16) or (obj.attr0 and not ATTR0_MODE_MASK)

func `fx=`*(obj: var ObjAttr; v: ObjFxMode) =
  obj.attr0 = (v.uint16) or (obj.attr0 and not (ATTR0_BLEND or ATTR0_WINDOW))

func `mos=`*(obj: var ObjAttr; v: bool) =
  obj.attr0 = (v.uint16 shl 12) or (obj.attr0 and not ATTR0_MOSAIC)

func `is8bpp=`*(obj: var ObjAttr; v: bool) =
  obj.attr0 = (v.uint16 shl 13) or (obj.attr0 and not ATTR0_8BPP)

func `affId=`*(obj: var ObjAttr; affId: int) =
  obj.attr1 = ((affId.uint16 shl ATTR1_AFF_ID_SHIFT) and ATTR1_AFF_ID_MASK) or (obj.attr1 and not ATTR1_AFF_ID_MASK)

func `size=`*(obj: var ObjAttr; v: ObjSize) =
  let shape = (v.uint16 shl 12) and ATTR0_SHAPE_MASK
  let size = (v.uint16 shl 14)
  obj.attr0 = shape or (obj.attr0 and not ATTR0_SHAPE_MASK)
  obj.attr1 = size or (obj.attr1 and not ATTR1_SIZE_MASK)
  
func `prio=`*(obj: var ObjAttr; prio: int) =
  obj.attr2 = ((prio.uint16 shl ATTR2_PRIO_SHIFT) and ATTR2_PRIO_MASK) or (obj.attr2 and not ATTR2_PRIO_MASK)

# ID shorthands:

func aff*(obj: ObjAttr): int = obj.affId
func tid*(obj: ObjAttr): int = obj.tileId
func pal*(obj: ObjAttr): int = obj.palId

func `aff=`*(obj: var ObjAttr; aff: int) = obj.affId = aff
func `tid=`*(obj: var ObjAttr; tid: int) = obj.tileId = tid
func `pal=`*(obj: var ObjAttr; pal: int) = obj.palId = pal


template initObj*(args: varargs[untyped]): ObjAttr =
  ## Create a new ObjAttr value.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[0] = initObj(
  ##     pos = vec2i(100, 100),
  ##     size = s32x32,
  ##     tileId = 0,
  ##     palId = 3
  ##   )
  var obj: ObjAttr
  writeFields(obj, args)
  obj

template init*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Initialise an object in-place.
  ## 
  ## Omitted fields will default to zero.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[0].init(
  ##     pos = vec2i(100, 100),
  ##     size = s32x32,
  ##     tileId = 0,
  ##     palId = 3
  ##   )
  obj.setAttr(0, 0, 0)
  writeFields(obj, args)

template edit*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Change some fields of an object.
  ## 
  ## Like `obj.init`, but omitted fields will be left unchanged.
  ## 
  ## .. code-block:: nim
  ## 
  ##   objMem[0].edit(
  ##     pos = vec2i(100, 100),
  ##     size = s32x32,
  ##     tileId = 0,
  ##     palId = 3
  ##   )
  ## 
  writeFields(obj, args)


template dup*(obj: ObjAttr, args: varargs[untyped]): ObjAttr =
  ## Duplicate an object, modifying some fields and returning the copy.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##    
  ##    # Make a copy of Obj 0, but change some properties:
  ##    objMem[1] = objMem[0].dup(x = 100, hflip = true)
  ##    
  var tmp = obj
  writeFields(tmp, args)
  tmp


# Size helpers:

const oamSizes: array[ObjSize, array[2, uint8]] = [
  [ 8'u8, 8'u8], [16'u8,16'u8], [32'u8,32'u8], [64'u8,64'u8], 
  [16'u8, 8'u8], [32'u8, 8'u8], [32'u8,16'u8], [64'u8,32'u8],
  [ 8'u8,16'u8], [ 8'u8,32'u8], [16'u8,32'u8], [32'u8,64'u8],
]

func getSize*(size: ObjSize): tuple[w, h: int] =
  ## Get the width and height in pixels of an `ObjSize` enum value.
  let arr = oamSizes[size]
  (arr[0].int, arr[1].int)
  
func getWidth*(size: ObjSize): int =
  ## Get the width in pixels of an `ObjSize` enum value.
  oamSizes[size][0].int

func getHeight*(size: ObjSize): int =
  ## Get the height in pixels of an `ObjSize` enum value.
  oamSizes[size][1].int

func getSize*(obj: ObjAttr | ObjAttrPtr): tuple[w, h: int] =
  ## Get the width and height of an object in pixels.
  getSize(obj.size)
  
func getWidth*(obj: ObjAttr | ObjAttrPtr): int =
  ## Get the width of an object in pixels.
  getWidth(obj.size)
  
func getHeight*(obj: ObjAttr | ObjAttrPtr): int =
  ## Get the height of an object in pixels.
  getHeight(obj.size)


func hide*(obj: var ObjAttr) =
  ## Hide an object.
  ## 
  ## Equivalent to ``obj.mode = omHide``
  ## 
  obj.mode = omHide

func unhide*(obj: var ObjAttr; mode = omReg) =
  ## Unhide an object.
  ## 
  ## Equivalent to ``obj.mode = mode``
  ## 
  ## **Parameters:**
  ## 
  ## obj
  ##   Object to unhide.
  ## 
  ## mode
  ##   Object mode to unhide to. Necessary because this affects the affine-ness of the object.
  ## 
  obj.mode = mode

{.pop.}
