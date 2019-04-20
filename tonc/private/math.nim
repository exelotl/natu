## Mathematical functions
## ======================

# The following templates are omitted because they're already in the standard library
#  ABS
#  MAX
#  MIN
#  SWAP
#  CLAMP
#  IN_RANGE(x, min, max) -- instead use (min..max).contains(x)

# The following new templates are added:
#  approach(x, target, amount)

template sgn*[T: SomeInteger](x: T): T =
  ## Get the sign of `x`
  if x >= 0: 1
  else: -1

template sgn3*[T: SomeInteger](x: T): T =
  ## Tri-state sign: -1 for negative, 0 for 0, +1 for positive.  
  if x > 0: 1
  elif x < 0: -1
  else: 0

template sgn*(x: Fixed): int =
  ## Get the sign of `x`
  if x >= fixed(0): 1
  else: -1
  
template sgn3*(x: Fixed): int =
  ## Tri-state sign: -1 for negative, 0 for 0, +1 for positive.  
  if x > fixed(0): 1
  elif x < fixed(0): -1
  else: 0

template reflect*[T](x, min, max: T): T =
  ## Reflects `x` at boundaries `min` and `max`
  ## If `x` is outside the range [`min`, `max`>, it'll be placed inside again with the same distance
  ##  to the 'wall', but on the other side. Example for lower border: `y` = `min - (x - min)` = `2 * min + x`.
  ## Returns: Reflected value of `x`.
  ## Note: `max` is exclusive!
  if x >= max: 2 * (max - 1) - x
  elif x < min: 2 * min - x
  else: x

template wrap*[T](x, min, max: T): T =
  ## Wraps `x` to stay in range [`min`, `max`>
  if x >= max: x + min - max
  elif x < min: x + max - min
  else: x

template approach*[T](x, target, step: T): T =
  ## Move `x` towards `target` by `step` without exceeding target.
  ## Step should be a positive number.
  if x < target:
    min(x + step, target)
  else:
    max(x - step, target)

const
  FIX_SHIFT*:int = 8
  FIX_SCALE*:int = (1 << FIX_SHIFT)
  FIX_MASK*:int = (FIX_SCALE - 1)

# TODO: check the compiled output for these to make sure they're performant?

proc fixed*(n: int): Fixed = (n << FIX_SHIFT).Fixed
  ## Convert an integer to fixed-point
proc fixed*(n: float32): Fixed = (n * FIX_SCALE.float32).Fixed
  ## Convert a float to fixed-point

proc toInt*(a: Fixed): int = a.int div FIX_SCALE
  ## Convert a fixed point value to an integer.
proc toInt32*(a: Fixed): int32 = a.int32 div FIX_SCALE.int32
  ## Convert a fixed point value to a 32-bit integer.
proc toFloat32*(a: Fixed): float32 = a.float32 / FIX_SCALE.float32
  ## Convert a fixed point value to floating point.

proc `$`*(a: Fixed): string {.borrow.} # TODO: better implementation?

proc `+`*(a, b: Fixed): Fixed = (a.int + b.int).Fixed
proc `-`*(a, b: Fixed): Fixed = (a.int - b.int).Fixed
proc `*`*(a, b: Fixed): Fixed = ((a.int * b.int) div FIX_SCALE).Fixed
proc `/`*(a, b: Fixed): Fixed = ((a.int << FIX_SHIFT) div b.int).Fixed

proc `==`*(a, b: Fixed): bool {.borrow.}
proc `<`*(a, b: Fixed): bool {.borrow.}
proc `<=`*(a, b: Fixed): bool {.borrow.}
proc `-`*(a: Fixed): Fixed {.borrow.}

proc mul64*(a, b: Fixed): Fixed = (((cast[int64](a)) * b.int) div FIX_SCALE).Fixed
  ## Multiply two fixed point values using 64bit math (to help avoid overflows)
proc div64*(a, b: Fixed): Fixed = (((cast[int64](a)) << FIX_SHIFT) div b.int).Fixed
  ## Divide two fixed point values using 64bit math (to help avoid overflows)

# Note:
# While full type safety may be preferred, fixed-point * and / can easily overflow.
# Therefore we should allow (fix*int), and it follows that we should have other
#  operators for completeness.
 
proc `+`*(a: Fixed, b: int): Fixed = (a.int + (b << FIX_SHIFT)).Fixed
proc `-`*(a: Fixed, b: int): Fixed = (a.int - (b << FIX_SHIFT)).Fixed
proc `*`*(a: Fixed, b: int): Fixed = (a.int * b).Fixed
proc `/`*(a: Fixed, b: int): Fixed = (a.int div b).Fixed

proc `+`*(a: int, b: Fixed): Fixed = ((a << FIX_SHIFT) + b.int).Fixed
proc `-`*(a: int, b: Fixed): Fixed = ((a << FIX_SHIFT) - b.int).Fixed
proc `*`*(a: int, b: Fixed): Fixed = (a * b.int).Fixed

proc `==`*(a: Fixed, b: int): bool = a == (b << FIX_SHIFT).Fixed
proc `<`*(a: Fixed, b: int): bool = a < (b << FIX_SHIFT).Fixed
proc `<=`*(a: Fixed, b: int): bool = a <= (b << FIX_SHIFT).Fixed

proc `==`*(a: int, b: Fixed): bool = (a << FIX_SHIFT).Fixed == b
proc `<`*(a: int, b: Fixed): bool = (a << FIX_SHIFT).Fixed < b
proc `<=`*(a: int, b: Fixed): bool = (a << FIX_SHIFT).Fixed <= b

proc `+=`*(a: var Fixed, b: Fixed|int) =  a = a + b
proc `-=`*(a: var Fixed, b: Fixed|int) =  a = a - b
proc `*=`*(a: var Fixed, b: Fixed|int) =  a = a * b
proc `/=`*(a: var Fixed, b: Fixed|int) =  a = a / b


# Lookup Tables
# -------------

const
  SIN_LUT_SIZE* = 514
  DIV_LUT_SIZE* = 257
  
var sinLut* {.importc: "sin_lut", header: "tonc.h".}: array[514, int16]
var divLut* {.importc: "div_lut", header: "tonc.h".}: array[257, int32]

proc luSin*(theta: uint32): int32 {.importc: "lu_sin", header: "tonc.h".}
  ## Look-up a sine value (2π = 0x10000)
  ## `theta` Angle in [0,FFFFh] range
  ## Return: .12f sine value

proc luCos*(theta: uint32): int32 {.importc: "lu_cos", header: "tonc.h".}
  ## Look-up a cosine value (2π = 0x10000)
  ## `theta` Angle in [0,FFFFh] range
  ## Returns .12f cosine value

proc luDiv*(x: uint32): uint32 {.importc: "lu_div", header: "tonc.h".}
  ## Look-up a division value between 0 and 255
  ## `x` reciprocal to look up.
  ## Returns 1/x (.16f)

proc luLerp32*(lut: ptr int32; x: uint; shift: uint): int {.importc: "lu_lerp32", header: "tonc.h".}
  ## Linear interpolator for 32bit LUTs.
  ## A lut is essentially the discrete form of a function, f(x).
  ## You can get values for non-integer `x` via (linear) interpolation between f(x) and f(x+1).
  ## `lut`   The LUT to interpolate from.
  ## `x`     Fixed point number to interpolate at.
  ## `shift` Number of fixed-point bits of `x`.

proc luLerp16*(lut: ptr int16; x: uint; shift: uint): int {.importc: "lu_lerp16", header: "tonc.h".}
  ## As luLerp32, but for 16bit LUTs.

# TODO: Test Fixed sin/cos/div
# TODO: Make sure Fixed values can be used for rotation.
#       This should be good, because the affine matrices also use .8f

proc sin*(theta: Fixed): Fixed =
  ## Use lookup table to get the sine of a fixed point number.
  (sinLut[((theta.int) << 1) and 0x01ff] >> 4).Fixed
  
proc cos*(theta: Fixed): Fixed =
  ## Use lookup table to get the cosine of a fixed point number.
  (sinLut[(((theta.int) << 1) + 128) and 0x01ff] >> 4).Fixed

# TODO: implement
# proc reciprocal(x:Fixed): Fixed
  


# Rectangle / vector types
# -----------------------
# [Deviating from Tonc here for something that's more usable in Nim]
# [Added Vec2i as preferred alias for Point]
# [Added Vec2f which is like Vec2i but fixed-point]
# [Omitted 3D 'Vector' type for now]

type
  Point = Vec2i
  Point32 = Vec2i
  
  Vec2i* = object {.bycopy.}
    ## Integer 2D vector/point type
    x*, y*: int
    
  Vec2f* = object {.bycopy.}
    ## Fixed point 24:8 2D vector/point type
    x*, y*: Fixed


proc vec2i*(x, y:int):Vec2i {.noinit.} =
  ## Initialise an integer vector
  result.x = x
  result.y = y

proc vec2i*():Vec2i {.noinit.} =
  ## Initialise an integer vector to 0,0
  result.x = 0
  result.y = 0


proc vec2f*(x, y:Fixed):Vec2f {.noinit.} =
  ## Initialise a fixed-point vector
  result.x = x
  result.y = y

proc vec2f*(x, y:int|float32):Vec2f {.noinit.} =
  ## Initialise a fixed-point vector, values converted from int or float
  result.x = fixed(x)
  result.y = fixed(y)

proc vec2f*():Vec2f {.noinit.} =
  ## Initialise a fixed-point vector to 0,0
  result.x = 0.Fixed
  result.y = 0.Fixed


proc vec2i*(v: Vec2f):Vec2i {.noinit.} =
  ## Convert an integer vector to a fixed-point vector
  result.x = toInt(v.x)
  result.y = toInt(v.y)

proc vec2f*(v: Vec2i):Vec2f {.noinit.} =
  ## Convert a fixed-point vector to an integer vector
  result.x = fixed(v.x)
  result.y = fixed(v.y)


# Integer vector operations
# -------------------------

proc `+`*(a, b: Vec2i):Vec2i {.noinit.} =
  ## Add two vectors
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `-`*(a, b: Vec2i):Vec2i {.noinit.} =
  ## Subtract two vectors
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `*`*(a: Vec2i, n:int):Vec2i {.noinit.} =
  ## Scale vector by n
  result.x = a.x * n
  result.y = a.y * n

proc `/`*(a: Vec2i, n:int):Vec2i {.noinit.} =
  ## Scale vector by 1/n
  result.x = a.x div n
  result.y = a.y div n

proc `*`*(a, b: Vec2i):int =
  ## Dot product of two vectors
  (a.x * b.x) + (a.y * b.y)

proc `-`*(a: Vec2i):Vec2i {.noinit.} =
  ## Equivalent to a * -1
  vec2i(-a.x, -a.y)
  
proc `+=`*(a: var Vec2i, b: Vec2i) =
  ## Vector compound addition
  a.x += b.x
  a.y += b.y
  
proc `-=`*(a: var Vec2i, b: Vec2i) =
  ## Vector compound subtraction
  a.x -= b.x
  a.y -= b.y
  
proc `*=`*(a: var Vec2i, n:int) =
  ## Compound scale a vector by n
  a.x *= n
  a.y *= n
  
proc `/=`*(a: var Vec2i, n:int) =
  ## Compound scale a vector by 1/n
  a.x = a.x div n
  a.y = a.y div n


# Fixed point vector operations
# -----------------------------

proc `+`*(a, b: Vec2f):Vec2f {.noinit.} =
  ## Add two fixed point vectors
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `-`*(a, b: Vec2f):Vec2f {.noinit.} =
  ## Subtract two fixed point vectors
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `*`*(a: Vec2f, n:Fixed|int):Vec2f {.noinit.} =
  ## Scale a fixed point vector by n
  result.x = a.x * n
  result.y = a.y * n

proc `/`*(a: Vec2f, n:Fixed|int):Vec2f {.noinit.} =
  ## Scale a fixed point vector by 1/n
  result.x = a.x / n
  result.y = a.y / n

proc `*`*(a, b: Vec2f):Fixed =
  ## Dot product of two fixed point vectors
  (a.x * b.x) + (a.y * b.y)

proc `-`*(a: Vec2f):Vec2f {.noinit.} =
  ## Equivalent to a * -1
  vec2f(-a.x, -a.y)

proc `+=`*(a: var Vec2f, b: Vec2f) =
  ## Vector compound addition
  a.x += b.x
  a.y += b.y
  
proc `-=`*(a: var Vec2f, b: Vec2f) =
  ## Vector compound subtraction
  a.x -= b.x
  a.y -= b.y
  
proc `*=`*(a: var Vec2f, n:Fixed|int) =
  ## Compound scale a vector by n
  a.x *= n
  a.y *= n
  
proc `/=`*(a: var Vec2f, n:Fixed|int) =
  ## Compound scale a vector by 1/n
  a.x = a.x / n
  a.y = a.y / n


# Rectangles
# ----------

type Rect* = object
  ## Rectangle type.
  ## Ranges from `left..right-1`, `top..bottom-1`
  left*, top*, right*, bottom*: int

proc rectBounds*(left, top, right, bottom:int):Rect {.noinit.} =
  result.left = left
  result.top = top
  result.right = right
  result.bottom = bottom

proc rectAt*(x, y, width, height:int):Rect {.noinit.} =
  result.left = x
  result.top = y
  result.right = x + width
  result.bottom = y + height

template x*(r: Rect): int = r.left
template y*(r: Rect): int = r.top
template width*(r: Rect): int = r.right - r.left
template height*(r: Rect): int = r.bottom - r.top

proc `x=`*(r: var Rect, x: int) =
  r.right += x - r.left
  r.left = x

proc `y=`*(r: var Rect, y: int) = 
  r.bottom += y - r.top
  r.top = y

proc `width=`*(r: var Rect, w: int) =
  r.right = r.left + w

proc `height=`*(r: var Rect, h: int) = 
  r.bottom = r.top + h

proc move*(r: var Rect, dx, dy: int) =
  ## Move rectangle by (`dx`, `dy`)
  r.left += dx
  r.top += dy
  r.right += dx
  r.bottom += dy

proc inflate*(r: var Rect, n: int) =
  ## Increase size of rectangle by `n` on all sides
  r.left -= n
  r.top -= n
  r.right += n
  r.bottom += n
  
proc inflate*(r: var Rect, dw, dh: int) =
  ## Increase size of rectangle by `dw` horizontally, `dh` vertically
  r.left -= dw
  r.top -= dh
  r.right += dw
  r.bottom += dh

proc center*(r: Rect): Vec2i =
  ## Get the center point of a rectangle
  vec2i((r.left + r.right) div 2, (r.top + r.bottom) div 2)

proc `center=`*(r: var Rect, p: Vec2i) =
  ## Set the center point of a rectangle
  # TODO: this is actually incorrect for odd sizes?
  let hw = r.width div 2
  let hh = r.height div 2
  r.left = p.x - hw
  r.top = p.y - hh
  r.right = p.x + hw
  r.bottom = p.y + hh

proc topLeft*(r: Rect): Vec2i =
  vec2i(r.left, r.top)
  
proc topRight*(r: Rect): Vec2i =
  vec2i(r.right, r.top)
  
proc bottomLeft*(r: Rect): Vec2i =
  vec2i(r.left, r.bottom)
  
proc bottomRight*(r: Rect): Vec2i =
  vec2i(r.right, r.bottom)