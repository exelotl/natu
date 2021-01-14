## Object Attribute Memory functions
## =================================

import types, math, memdef

proc oamInit*(obj: ObjAttrPtr; count: uint) {.importc: "oam_init", header: "tonc.h".}
  ## Initialize an array of `count` ObjAttrs with with safe values.

proc oamCopy*(dst, src: ObjAttrPtr; count: uint) {.importc: "oam_copy", header: "tonc.h".}
  ## Copies `count` OAM entries from `src` to `dst`.
  
proc oamClear*() {.importc: "OAM_CLEAR", header: "tonc.h".}


# Obj attr only

proc setAttr*(obj: ObjAttrPtr; a0, a1, a2: uint16) {.inline.} =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2

proc setAttr*(obj: var ObjAttr; a0, a1, a2: uint16) {.inline.} =
  ## Set the attributes of an object
  setAttr(addr obj, a0, a1, a2)

proc setPos*(obj: ObjAttrPtr; x, y: int) {.importc: "obj_set_pos", header: "tonc.h".}
  ## Set the position of an object
  
proc setPos*(obj: var ObjAttr; x, y: int) {.inline.} =
  ## Set the position of an object
  setPos(addr obj, x, y)

proc setPos*(obj: ObjAttrPtr; pos: Vec2i) {.inline.} =
  ## Set the position of an object using a vector
  setPos(obj, pos.x, pos.y)
  
proc setPos*(obj: var ObjAttr; pos: Vec2i) {.inline.} =
  ## Set the position of an object using a vector
  setPos(addr obj, pos.x, pos.y)

#  example pure Nim implementation
#  how is the performance of this?
#  does explicitly using uint16 have a negative impact?
# proc setPos*(obj: ObjAttrPtr; x, y: uint16) =
#   ## Set the position of an object
#   obj.attr0 = (obj.attr0 and not ATTR0_Y_MASK) or ((y shl ATTR0_Y_SHIFT) and ATTR0_Y_MASK)
#   obj.attr1 = (obj.attr1 and not ATTR1_X_MASK) or ((x shl ATTR1_X_SHIFT) and ATTR1_X_MASK)


proc hide*(oatr: ObjAttrPtr) {.importc: "obj_hide", header: "tonc.h".}
  ## Hide an object

proc hide*(oatr: var ObjAttr) {.inline.} =
  hide(addr oatr)

proc unhide*(obj: ObjAttrPtr; mode: uint16) {.importc: "obj_unhide", header: "tonc.h".}
  ## Unhide an object.
  ## `obj`  Object to unhide.
  ## `mode` Object mode to unhide to. Necessary because this affects the affine-ness of the object.

proc unhide*(oatr: var ObjAttr)  {.inline.} =
  hide(addr oatr)

func getSizeImpl(obj: ObjAttrPtr): ptr array[2, uint8] {.importc: "obj_get_size", header: "tonc.h".}

func getSize*(obj: ObjAttrPtr): tuple[w,h:int] {.inline.} =
  ## Get the width and height of an object in pixels
  let arr = getSizeImpl(obj)
  (arr[0].int, arr[1].int)

template getSize*(obj: ObjAttr): tuple[w,h:int] =
  ## Get the width and height of an object in pixels
  getSize(unsafeAddr obj)

func getWidth*(obj: ObjAttrPtr): int {.importc: "obj_get_width", header: "tonc.h".}
  ## Get the width of an object in pixels
  
template getWidth*(obj: ObjAttr): int =
  ## Get the width of an object in pixels
  getWidth(unsafeAddr obj)
  
func getHeight*(obj: ObjAttrPtr): int {.importc: "obj_get_height", header: "tonc.h".}
  ## Get the height of an object in pixels
  
template getHeight*(obj: ObjAttr): int =
  ## Get the height of an object in pixels
  getHeight(unsafeAddr obj)


proc copy*(dst, src: ObjAttrPtr; count: uint) {.importc: "obj_copy", header: "tonc.h".}
  ## Copy attributes 0-2 in `count` ObjAttrs.

proc hideMulti*(obj: ObjAttrPtr; count: uint32) {.importc: "obj_hide_multi", header: "tonc.h".}
  ## Hide an array of ObjAttrs

proc unhideMulti*(obj: ObjAttrPtr; mode: uint16; count: uint) {.importc: "obj_unhide_multi", header: "tonc.h".}
  ## Unhide an array of ObjAttrs


# Obj affine procedures
# ---------------------

proc affCopy*(dst, src: ObjAffinePtr; count: uint) {.importc: "obj_aff_copy", header: "tonc.h".}
  ## Copy `count` object affine matrices from src to dest
  # TODO: could make this more nim-friendly? Arrays instead of pointers? How to ensure safety though?


proc affSet*(oaff: var ObjAffine; pa, pb, pc, pd: Fixed) {.importc: "obj_aff_set", header: "tonc.h".}
  ## Set the elements of an object affine matrix.

proc affIdentity*(oaff: var ObjAffine) {.importc: "obj_aff_identity", header: "tonc.h".}
  ##  Set an object affine matrix to the identity matrix

proc affScale*(oaff: var ObjAffine; sx, sy: Fixed) {.importc: "obj_aff_scale", header: "tonc.h".}
  ## Set an object affine matrix for scaling.
  
proc affShearX*(oaff: var ObjAffine; hx: Fixed) {.importc: "obj_aff_shearx", header: "tonc.h".}
proc affShearY*(oaff: var ObjAffine; hy: Fixed) {.importc: "obj_aff_sheary", header: "tonc.h".}
proc affRotate*(oaff: var ObjAffine; alpha: uint16) {.importc: "obj_aff_rotate", header: "tonc.h".}
  ## Set obj matrix to counter-clockwise rotation.
  ## `oaff`  Object affine struct to set.
  ## `alpha` CCW angle. full-circle is 10000h.
  
proc affRotscale*(oaff: var ObjAffine; sx, sy: Fixed; alpha: uint16) {.importc: "obj_aff_rotscale", header: "tonc.h".}
  ## Set obj matrix to 2d scaling, then counter-clockwise rotation.
  ## `oaff`  Object affine struct to set.
  ## `sx`    Horizontal scale (zoom). .8 fixed point.
  ## `sy`    Vertical scale (zoom). .8 fixed point.
  ## `alpha` CCW angle. full-circle is 10000h.

proc affRotscale*(oaff: var ObjAffine; affSrc: ptr AffSrc) {.importc: "obj_aff_rotscale2", header: "tonc.h".}
  ## Set obj matrix to 2d scaling, then counter-clockwise rotation.
  ## `oaff` Object affine struct to set.
  ## `as`   Struct with scales and angle.

# [alternative ways of doing it?]
# proc affSet*(oaff: ObjAffinePtr; pa, pb, pc, pd: Fixed) {.importc: "obj_aff_set", header: "tonc.h".}
# proc affIdentity*(oaff: ObjAffinePtr) {.importc: "obj_aff_identity", header: "tonc.h".}
# proc affScale*(oaff: ObjAffinePtr; sx, sy: Fixed) {.importc: "obj_aff_scale", header: "tonc.h".}
# proc affShearX*(oaff: ObjAffinePtr; hx: Fixed) {.importc: "obj_aff_shearx", header: "tonc.h".}
# proc affShearY*(oaff: ObjAffinePtr; hy: Fixed) {.importc: "obj_aff_sheary", header: "tonc.h".}
# proc affRotate*(oaff: ObjAffinePtr; alpha: uint16) {.importc: "obj_aff_rotate", header: "tonc.h".}
# proc affRotscale*(oaff: ObjAffinePtr; sx, sy: Fixed; alpha: uint16) {.importc: "obj_aff_rotscale", header: "tonc.h".}
# proc affRotscale*(oaff: ObjAffinePtr; affSrc: ptr AffSrc) {.importc: "obj_aff_rotscale2", header: "tonc.h".}
# proc affShearX*(oaff: var ObjAffine; hx: Fixed) = affShearX(addr oaff, hx)
# proc affShearY*(oaff: var ObjAffine; hy: Fixed) = affShearY(addr oaff, hy)
# proc affRotate*(oaff: var ObjAffine; alpha: uint16) = affRotate(addr oaff, alpha)
# proc affRotscale*(oaff: var ObjAffine; sx, sy: Fixed; alpha: uint16) = affRotscale(addr oaff, sx, sy, alpha)
# proc affRotscale*(oaff: var ObjAffine; affSrc: ptr AffSrc) = affRotscale(addr oaff, affSrc)


proc affPreMul*(dst: var ObjAffine, src: ObjAffinePtr) {.importc: "obj_aff_premul", header: "tonc.h".}
  ## Pre-multiply the matrix `dst` by `src`
  ## i.e. ::
  ##   dst = src * dst

proc affPostMul*(dst: var ObjAffine, src: ObjAffinePtr) {.importc: "obj_aff_postmul", header: "tonc.h".}
  ## Post-multiply the matrix `dst` by `src`
  ## i.e. ::
  ##   dst = dst * src

template affPreMul*(dst: var ObjAffine, src: ObjAffine) = affPreMul(dst, unsafeAddr src)
template affPostMul*(dst: var ObjAffine, src: ObjAffine) = affPostMul(dst, unsafeAddr src)

proc rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: ptr AffSrcEx) {.importc: "obj_rotscale_ex", header: "tonc.h".}
  ## Rot/scale an object around an arbitrary point.
  ## Sets up `obj` and `oaff` for rot/scale transformation around an arbitrary point using the `asx` data.
  ## `obj`  Object to set.
  ## `oaff` Object affine data to set.
  ## `asx`  Affine source data: screen and texture origins, scales and angle.

template rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: AffSrcEx) =
  rotscaleEx(obj, oaff, unsafeAddr asx)

#  inverse (object -> screen) functions, could be useful
proc affScaleInv*(oa: var ObjAffine; wx, wy: Fixed) {.importc: "obj_aff_scale_inv", header: "tonc.h".}
proc affRotateInv*(oa: var ObjAffine; theta: uint16) {.importc: "obj_aff_rotate_inv", header: "tonc.h".}
proc affShearxInv*(oa: var ObjAffine; hx: Fixed) {.importc: "obj_aff_shearx_inv", header: "tonc.h".}
proc affShearyInv*(oa: var ObjAffine; hy: Fixed) {.importc: "obj_aff_sheary_inv", header: "tonc.h".}


# SPRITE GETTERS/SETTERS
# ----------------------
# [Here we can use Nim features to make these a little bit more bearable]

type
  ObjMode* {.size:2.} = enum
    omReg = ATTR0_REG
    omAff = ATTR0_AFF
    omHide = ATTR0_HIDE
    omAffDbl = ATTR0_AFF_DBL
  
  ObjFxMode* {.size:2.} = enum
    fxNormal = 0
    fxBlend = ATTR0_BLEND
    fxWin = ATTR0_WINDOW
  
  ObjSize* {.size:1.} = enum
    ## Sprite size constants, high-level interface.
    ## Each corresponds to a pair of fields (`size` in attr0, `shape` in attr1)
    s8x8
    s8x16
    s8x32
    s16x8
    s16x16
    s16x32
    s32x8
    s32x16
    s32x32
    s32x64
    s64x32
    s64x64

const sizeToFlags: array[ObjSize, tuple[shape:uint16, size:uint16]] = [
  (ATTR0_SQUARE, ATTR1_SIZE_8x8),
  (ATTR0_TALL, ATTR1_SIZE_8x16),
  (ATTR0_TALL, ATTR1_SIZE_8x32),
  (ATTR0_WIDE, ATTR1_SIZE_16x8),
  (ATTR0_SQUARE, ATTR1_SIZE_16x16),
  (ATTR0_TALL, ATTR1_SIZE_16x32),
  (ATTR0_WIDE, ATTR1_SIZE_32x8),
  (ATTR0_WIDE, ATTR1_SIZE_32x16),
  (ATTR0_SQUARE, ATTR1_SIZE_32x32),
  (ATTR0_TALL, ATTR1_SIZE_32x64),
  (ATTR0_WIDE, ATTR1_SIZE_64x32),
  (ATTR0_SQUARE, ATTR1_SIZE_64x64),
]

const flagsToSize = [
  [ s8x8, s16x16, s32x32, s64x64 ], 
  [ s16x8, s32x8, s32x16, s64x32 ],
  [ s8x16, s8x32, s16x32, s32x64 ],
]

# copy attr0,1,2 from one object into another
proc setAttr*(obj: ObjAttrPtr, src: ObjAttr) {.inline.} = setAttr(obj, src.attr0, src.attr1, src.attr2)
proc setAttr*(obj: var ObjAttr, src: ObjAttr) {.inline.} = setAttr(addr obj, src)
proc clear*(obj: ObjAttrPtr) {.inline.} = setAttr(obj, 0, 0, 0)
proc clear*(obj: var ObjAttr) {.inline.} = clear(addr obj)

# getters

proc x*(obj: ObjAttr): int {.inline.} = (obj.attr1 and ATTR1_X_MASK).int
proc y*(obj: ObjAttr): int {.inline.} = (obj.attr0 and ATTR0_Y_MASK).int
proc pos*(obj: ObjAttr): Vec2i {.inline.} = vec2i(obj.x, obj.y)
proc mode*(obj: ObjAttr): ObjMode {.inline.} = (obj.attr0 and ATTR0_MODE_MASK).ObjMode
proc fx*(obj: ObjAttr): ObjFxMode {.inline.} = (obj.attr0 and (ATTR0_BLEND or ATTR0_WINDOW)).ObjFxMode
proc mos*(obj: ObjAttr): bool {.inline.} = (obj.attr0 and ATTR0_MOSAIC) != 0
proc is8bpp*(obj: ObjAttr): bool {.inline.} = (obj.attr0 and ATTR0_8BPP) != 0
proc aff*(obj: ObjAttr): int {.inline.} = ((obj.attr1 and ATTR1_AFF_ID_MASK) shr ATTR1_AFF_ID_SHIFT).int
proc size*(obj: ObjAttr): ObjSize {.inline.} = flagsToSize[obj.attr0 shr 14][obj.attr1 shr 14].ObjSize
proc hflip*(obj: ObjAttr): bool {.inline.} = (obj.attr1 and ATTR1_HFLIP) != 0
proc vflip*(obj: ObjAttr): bool {.inline.} = (obj.attr1 and ATTR1_VFLIP) != 0
proc tid*(obj: ObjAttr): int {.inline.} = ((obj.attr2 and ATTR2_ID_MASK) shr ATTR2_ID_SHIFT).int
proc pal*(obj: ObjAttr): int {.inline.} = ((obj.attr2 and ATTR2_PALBANK_MASK) shr ATTR2_PALBANK_SHIFT).int
proc prio*(obj: ObjAttr): int {.inline.} = ((obj.attr2 and ATTR2_PRIO_MASK) shr ATTR2_PRIO_SHIFT).int

# ptr setters

proc `x=`*(obj: ObjAttrPtr, x: int) {.inline.} =
  obj.attr1 = (x.uint16 and ATTR1_X_MASK) or (obj.attr1 and not ATTR1_X_MASK)

proc `y=`*(obj: ObjAttrPtr, y: int) {.inline.} =
  obj.attr0 = (y.uint16 and ATTR0_Y_MASK) or (obj.attr0 and not ATTR0_Y_MASK)

proc `pos=`*(obj: ObjAttrPtr, v: Vec2i) {.inline.} =
  obj.x = v.x
  obj.y = v.y

proc `tid=`*(obj: ObjAttrPtr, tid: int) {.inline.} =
  obj.attr2 = ((tid.uint16 shl ATTR2_ID_SHIFT) and ATTR2_ID_MASK) or (obj.attr2 and not ATTR2_ID_MASK)

proc `pal=`*(obj: ObjAttrPtr, pal: int) {.inline.} =
  obj.attr2 = ((pal.uint16 shl ATTR2_PALBANK_SHIFT) and ATTR2_PALBANK_MASK) or (obj.attr2 and not ATTR2_PALBANK_MASK)

proc `hflip=`*(obj: ObjAttrPtr, v:bool) {.inline.} =
  obj.attr1 = (v.uint16 shl 12) or (obj.attr1 and not ATTR1_HFLIP)
  
proc `vflip=`*(obj: ObjAttrPtr, v:bool) {.inline.} =
  obj.attr1 = (v.uint16 shl 13) or (obj.attr1 and not ATTR1_VFLIP)

proc `mode=`*(obj: ObjAttrPtr, v: ObjMode) {.inline.} =
  obj.attr0 = (v.uint16) or (obj.attr0 and not ATTR0_MODE_MASK)

proc `fx=`*(obj: ObjAttrPtr, v: ObjFxMode) {.inline.} =
  obj.attr0 = (v.uint16) or (obj.attr0 and not (ATTR0_BLEND or ATTR0_WINDOW))

proc `mos=`*(obj: ObjAttrPtr, v: bool) {.inline.} =
  obj.attr0 = (v.uint16 shl 12) or (obj.attr0 and not ATTR0_MOSAIC)

proc `is8bpp=`*(obj: ObjAttrPtr, v: bool) {.inline.} =
  obj.attr0 = (v.uint16 shl 13) or (obj.attr0 and not ATTR0_8BPP)

proc `aff=`*(obj: ObjAttrPtr, aff: int) {.inline.} =
  obj.attr1 = ((aff.uint16 shl ATTR1_AFF_ID_SHIFT) and ATTR1_AFF_ID_MASK) or (obj.attr1 and not ATTR1_AFF_ID_MASK)

proc `size=`*(obj: ObjAttrPtr, v: ObjSize) {.inline.} =
  let (shape, size) = sizeToFlags[v]
  obj.attr0 = shape.uint16 or (obj.attr0 and not ATTR0_SHAPE_MASK)
  obj.attr1 = size.uint16 or (obj.attr1 and not ATTR1_SIZE_MASK)
  
proc `prio=`*(obj: ObjAttrPtr, prio: int) {.inline.} =
  obj.attr2 = ((prio.uint16 shl ATTR2_PRIO_SHIFT) and ATTR2_PRIO_MASK) or (obj.attr2 and not ATTR2_PRIO_MASK)


# var setters

proc `x=`*(obj: var ObjAttr, x: int) {.inline.} = (addr obj).x = x
proc `y=`*(obj: var ObjAttr, y: int) {.inline.} = (addr obj).y = y
proc `pos=`*(obj: var ObjAttr, pos: Vec2i) {.inline.} = (addr obj).pos = pos
proc `tid=`*(obj: var ObjAttr, tid: int) {.inline.} = (addr obj).tid = tid
proc `pal=`*(obj: var ObjAttr, pal: int) {.inline.} = (addr obj).pal = pal
proc `hflip=`*(obj: var ObjAttr, hflip: bool) {.inline.} = (addr obj).hflip = hflip
proc `vflip=`*(obj: var ObjAttr, vflip: bool) {.inline.} = (addr obj).vflip = vflip
proc `mode=`*(obj: var ObjAttr, mode: ObjMode) {.inline.} = (addr obj).mode = mode
proc `fx=`*(obj: var ObjAttr, fx: ObjFxMode) {.inline.} = (addr obj).fx = fx
proc `mos=`*(obj: var ObjAttr, mos: bool) {.inline.} = (addr obj).mos = mos
proc `is8bpp=`*(obj: var ObjAttr, is8bpp: bool) {.inline.} = (addr obj).is8bpp = is8bpp
proc `size=`*(obj: var ObjAttr, size: ObjSize) {.inline.} = (addr obj).size = size
proc `aff=`*(obj: var ObjAttr, aff: int) {.inline.} = (addr obj).aff = aff
proc `prio=`*(obj: var ObjAttr, prio: int) {.inline.} = (addr obj).prio = prio

import macros

macro writeObj(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  result = newStmtList()
  if args.len == 1 and args[0].kind == nnkStmtList:
    for i, node in args[0]:
      if node.kind != nnkAsgn:
        error("Expected assignment, got " & repr(node))
      let (key, val) = (node[0], node[1])
      result.add quote do:
        `obj`.`key` = `val`
  else:
    for i, node in args:
      if node.kind != nnkExprEqExpr:
        error("Expected assignment, got " & repr(node))
      let (key, val) = (node[0], node[1])
      result.add quote do:
        `obj`.`key` = `val`

template initObj*(args: varargs[untyped]): ObjAttr =
  var obj: ObjAttr
  writeObj(obj, args)
  obj

template init*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Initialise an object.
  ## Omitted fields will default to zero.
  ## e.g.
  ## ::
  ##   oamMem[0].init:
  ##     pos = vec2i(100, 100)
  ##     size = s32x32
  ##     tid = 0
  ##     pal = 3
  obj.clear()
  writeObj(obj, args)

template edit*(obj: ObjAttrPtr | var ObjAttr, args: varargs[untyped]) =
  ## Update some fields of an object.
  ## Like `init`, but omitted fields will be left unchanged.
  writeObj(obj, args)

