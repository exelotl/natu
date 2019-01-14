## Object Attribute Memory functions
## =================================

proc oamInit*(obj: ObjAttrPtr; count: uint) {.importc: "oam_init", header: "tonc.h".}
  ## Initialize an array of `count` ObjAttrs with with safe values.

proc oamCopy*(dst, src: ObjAttrPtr; count: uint) {.importc: "oam_copy", header: "tonc.h".}
  ## Copies `count` OAM entries from `src` to `dst`.
  
proc oamClear*() {.importc: "OAM_CLEAR", header: "tonc.h".}


# Obj attr only

proc setAttr*(obj: ObjAttrPtr; a0, a1, a2: uint16) =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2

proc setAttr*(obj: var ObjAttr; a0, a1, a2: uint16) =
  ## Set the attributes of an object
  setAttr(addr obj, a0, a1, a2)

proc setPos*(obj: ObjAttrPtr; x, y: int) {.importc: "obj_set_pos", header: "tonc.h".}
  ## Set the position of an object
  
proc setPos*(obj: var ObjAttr; x, y: int) =
  ## Set the position of an object
  setPos(addr obj, x, y)

proc setPos*(obj: ObjAttrPtr; pos: Vec2i) =
  ## Set the position of an object using a vector
  setPos(obj, pos.x, pos.y)
  
proc setPos*(obj: var ObjAttr; pos: Vec2i) =
  ## Set the position of an object using a vector
  setPos(addr obj, pos.x, pos.y)

#  example pure Nim implementation
#  how is the performance of this?
#  does explicitly using uint16 have a negative impact?
# proc setPos*(obj: ObjAttrPtr; x, y: uint16) =
#   ## Set the position of an object
#   obj.attr0 = (obj.attr0 and (not ATTR0_Y_MASK)) or ((y shl ATTR0_Y_SHIFT) and ATTR0_Y_MASK)
#   obj.attr1 = (obj.attr1 and (not ATTR1_X_MASK)) or ((x shl ATTR1_X_SHIFT) and ATTR1_X_MASK)


proc hide*(oatr: ObjAttrPtr) {.importc: "obj_hide", header: "tonc.h".}
  ## Hide an object

proc hide*(oatr: var ObjAttr) =
  hide(addr oatr)

proc unhide*(obj: ObjAttrPtr; mode: uint16) {.importc: "obj_unhide", header: "tonc.h".}
  ## Unhide an object.
  ## `obj`  Object to unhide.
  ## `mode` Object mode to unhide to. Necessary because this affects the affine-ness of the object.

proc unhide*(oatr: var ObjAttr) =
  hide(addr oatr)

func getSizeImpl(obj: ObjAttrPtr): ptr array[2, uint8] {.importc: "obj_get_size", header: "tonc.h".}

func getSize*(obj: ObjAttrPtr): tuple[w,h:int] =
  ## Get the width and height of an object in pixels
  let arr = getSizeImpl(obj)
  return (arr[0].int, arr[1].int)

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

# [not sure what these do?]
proc affPreMul*(dst: var ObjAffine, src: ObjAffinePtr) {.importc: "obj_aff_premul", header: "tonc.h".}
  ## Pre-multiply `dst` by `src: D = S*D
proc affPostMul*(dst: var ObjAffine, src: ObjAffinePtr) {.importc: "obj_aff_postmul", header: "tonc.h".}
  ## Post-multiply `dst` by `src`: D = D*S

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

