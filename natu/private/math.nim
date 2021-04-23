## Mathematical functions
## ======================

{.warning[UnusedImport]: off.}

import common
import types, core

{.compile(toncPath & "/src/tonc_math.c", toncCFlags).}
{.compile(toncPath & "/asm/div_lut.s", toncAsmFlags).}
{.compile(toncPath & "/asm/sin_lut.s", toncAsmFlags).}

# The following utilities are omitted because they're already in the standard library
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
  ## If `x` is outside the range ``min ..< max``, it'll be placed inside again with the same distance
  ##  to the 'wall', but on the other side. Example for lower border: `y` = ``min - (x - min)`` = ``2 * min + x``.
  ## Returns: Reflected value of `x`.
  ## Note: `max` is exclusive!
  if x >= max: 2 * (max - 1) - x
  elif x < min: 2 * min - x
  else: x

template wrap*[T](x, min, max: T): T =
  ## Wraps `x` to stay in range ``min ..< max``
  if x >= max: x + min - max
  elif x < min: x + max - min
  else: x

template approach*[T](x: var T, target, step: T) =
  ## Move `x` towards `target` by `step` without exceeding target.
  ## Step should be a positive number.
  if x < target:
    x = min(x + step, target)
  else:
    x = max(x - step, target)

const
  FIX_SHIFT*: int = 8
  FIX_SCALE*: int = (1 shl FIX_SHIFT)
  FIX_MASK*: int = (FIX_SCALE - 1)

template fp*(n: int): Fixed = (n shl FIX_SHIFT).Fixed
  ## Convert an integer to fixed-point (shorthand)
template fp*(n: float32): Fixed = (n * FIX_SCALE.float32).Fixed
  ## Convert a float to fixed-point (shorthand)

template fixed*(n: int): Fixed = (n shl FIX_SHIFT).Fixed
  ## Convert an integer to fixed-point
template fixed*(n: float32): Fixed = (n * FIX_SCALE.float32).Fixed
  ## Convert a float to fixed-point

template toInt*(a: Fixed): int = a.int div FIX_SCALE
  ## Convert a fixed point value to an integer.
template toInt32*(a: Fixed): int32 = a.int32 div FIX_SCALE.int32
  ## Convert a fixed point value to a 32-bit integer.
template toFloat32*(a: Fixed): float32 = a.float32 / FIX_SCALE.float32
  ## Convert a fixed point value to floating point.

proc `$`*(a: Fixed): string {.borrow.} # TODO: better implementation?

template `+`*(a, b: Fixed): Fixed = (a.int + b.int).Fixed
template `-`*(a, b: Fixed): Fixed = (a.int - b.int).Fixed
template `*`*(a, b: Fixed): Fixed = ((a.int * b.int) div FIX_SCALE).Fixed
template `/`*(a, b: Fixed): Fixed = ((a.int shl FIX_SHIFT) div b.int).Fixed

template `==`*(a, b: Fixed): bool = (a.int == b.int)
template `<`*(a, b: Fixed): bool = (a.int < b.int)
template `<=`*(a, b: Fixed): bool = (a.int <= b.int)
template `-`*(a: Fixed): Fixed = (-a.int).Fixed
template abs*(a: Fixed): Fixed = abs(a.int).Fixed

template mul64*(a, b: Fixed): Fixed = (((cast[int64](a)) * b.int) div FIX_SCALE).Fixed
  ## Multiply two fixed point values using 64bit math (to help avoid overflows)
template div64*(a, b: Fixed): Fixed = (((cast[int64](a)) shl FIX_SHIFT) div b.int).Fixed
  ## Divide two fixed point values using 64bit math (to help avoid overflows)

# Note:
# While full type safety may be preferred, fixed-point * and / can easily overflow.
# Therefore we should allow (fix*int), and it follows that we should have other
#  operators for completeness.

template `+`*(a: Fixed, b: int): Fixed = (a.int + (b shl FIX_SHIFT)).Fixed
template `-`*(a: Fixed, b: int): Fixed = (a.int - (b shl FIX_SHIFT)).Fixed
template `*`*(a: Fixed, b: int): Fixed = (a.int * b).Fixed
template `/`*(a: Fixed, b: int): Fixed = (a.int div b).Fixed

template `+`*(a: int, b: Fixed): Fixed = ((a shl FIX_SHIFT) + b.int).Fixed
template `-`*(a: int, b: Fixed): Fixed = ((a shl FIX_SHIFT) - b.int).Fixed
template `*`*(a: int, b: Fixed): Fixed = (a * b.int).Fixed

template `==`*(a: Fixed, b: int): bool = a == (b shl FIX_SHIFT).Fixed
template `<`*(a: Fixed, b: int): bool = a < (b shl FIX_SHIFT).Fixed
template `<=`*(a: Fixed, b: int): bool = a <= (b shl FIX_SHIFT).Fixed

template `==`*(a: int, b: Fixed): bool = (a shl FIX_SHIFT).Fixed == b
template `<`*(a: int, b: Fixed): bool = (a shl FIX_SHIFT).Fixed < b
template `<=`*(a: int, b: Fixed): bool = (a shl FIX_SHIFT).Fixed <= b

template `+=`*(a: var Fixed, b: Fixed|int) =  a = a + b
template `-=`*(a: var Fixed, b: Fixed|int) =  a = a - b
template `*=`*(a: var Fixed, b: Fixed|int) =  a = a * b
template `/=`*(a: var Fixed, b: Fixed|int) =  a = a / b


# Lookup Tables
# -------------

var sinLut* {.importc: "sin_lut", header: "tonc.h".}: array[514, int16]
var divLut* {.importc: "div_lut", header: "tonc.h".}: array[257, int32]

## TODO: make these distinct, add helper functions such as degrees(Fixed|int)
type
  Angle* = uint32  ## 2π = 0x10000 (i.e. angle with 16 bits of resolution)
  TrigResult* = int32

proc luSin*(theta: Angle): TrigResult {.importc: "lu_sin", header: "tonc.h".}
  ## Look-up a sine value (2π = 0x10000)
  ## `theta` Angle in [0,FFFFh] range
  ## Return: .12f sine value

proc luCos*(theta: Angle): TrigResult {.importc: "lu_cos", header: "tonc.h".}
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


# Rectangle / vector types
# -----------------------
# [Deviating from Tonc here for something that's more usable in Nim]
# [Added Vec2i as a replacement for Point]
# [Added Vec2f which is like Vec2i but fixed-point]
# [Omitted 3D 'Vector' type for now]

type
  Vec2i* {.bycopy.} = object
    ## Integer 2D vector/point type
    x*, y*: int
    
  Vec2f* {.bycopy.} = object
    ## Fixed point 24:8 2D vector/point type
    x*, y*: Fixed

{.push noinit, inline.}

proc vec2i*(x, y: int): Vec2i =
  ## Initialise an integer vector
  result.x = x
  result.y = y

proc vec2i*(): Vec2i =
  ## Initialise an integer vector to 0,0
  result.x = 0
  result.y = 0


proc vec2f*(x, y:Fixed): Vec2f =
  ## Initialise a fixed-point vector
  result.x = x
  result.y = y

proc vec2f*(x, y: int|float32): Vec2f =
  ## Initialise a fixed-point vector, values converted from int or float
  result.x = fixed(x)
  result.y = fixed(y)

proc vec2f*(): Vec2f =
  ## Initialise a fixed-point vector to 0,0
  result.x = 0.Fixed
  result.y = 0.Fixed


proc vec2i*(v: Vec2f): Vec2i =
  ## Convert an integer vector to a fixed-point vector
  result.x = toInt(v.x)
  result.y = toInt(v.y)

proc vec2f*(v: Vec2i): Vec2f =
  ## Convert a fixed-point vector to an integer vector
  result.x = fixed(v.x)
  result.y = fixed(v.y)


# Integer vector operations
# -------------------------

proc `+`*(a, b: Vec2i): Vec2i =
  ## Add two vectors
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `-`*(a, b: Vec2i): Vec2i =
  ## Subtract two vectors
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `*`*(a, b: Vec2i): Vec2i =
  ## Component-wise multiplication of two vectors
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `/`*(a, b: Vec2i): Vec2i =
  ## Component-wise division of two vectors
  result.x = a.x div b.x
  result.y = a.y div b.y

proc `*`*(a: Vec2i, n: int): Vec2i =
  ## Scale vector by n
  result.x = a.x * n
  result.y = a.y * n

proc `/`*(a: Vec2i, n: int): Vec2i =
  ## Scale vector by 1/n
  result.x = a.x div n
  result.y = a.y div n

proc dot*(a, b: Vec2i): int =
  ## Dot product of two vectors
  (a.x * b.x) + (a.y * b.y)

proc `-`*(a: Vec2i): Vec2i =
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

proc `*=`*(a: var Vec2i, b: Vec2i) =
  ## Vector component-wise compound multiplicatoin
  a.x *= b.x
  a.y *= b.y

proc `/=`*(a: var Vec2i, b: Vec2i) =
  ## Vector component-wise compound division
  a.x = a.x div b.x
  a.y = a.x div b.y

proc `*=`*(a: var Vec2i, n: int) =
  ## Compound scale a vector by n
  a.x *= n
  a.y *= n

proc `/=`*(a: var Vec2i, n: int) =
  ## Compound scale a vector by 1/n
  a.x = a.x div n
  a.y = a.y div n


# Fixed point vector operations
# -----------------------------

proc `+`*(a, b: Vec2i|Vec2f): Vec2f =
  ## Add two fixed point vectors
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `-`*(a, b: Vec2i|Vec2f): Vec2f =
  ## Subtract two fixed point vectors
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `*`*(a: Vec2f, b: Vec2i|Vec2f): Vec2f =
  ## Component-wise multiplication of two vectors
  result.x = a.x * b.x
  result.y = a.y * b.y

proc `/`*(a: Vec2f, b: Vec2i|Vec2f): Vec2f =
  ## Component-wise division of two vectors
  result.x = a.x / b.x
  result.y = a.y / b.y

proc `*`*(a: Vec2f, n: Fixed|int): Vec2f =
  ## Scale a fixed point vector by n
  result.x = a.x * n
  result.y = a.y * n

proc `/`*(a: Vec2f, n: Fixed|int): Vec2f =
  ## Scale a fixed point vector by 1/n
  result.x = a.x / n
  result.y = a.y / n

proc dot*(a, b: Vec2f): Fixed =
  ## Dot product of two fixed point vectors
  (a.x * b.x) + (a.y * b.y)

proc `-`*(a: Vec2f): Vec2f =
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

proc `*=`*(a: var Vec2f, b: Vec2i|Vec2f) =
  ## Vector component-wise compound multiplicatoin
  a.x *= b.x
  a.y *= b.y

proc `/=`*(a: var Vec2f, b: Vec2i|Vec2f) =
  ## Vector component-wise compound division
  a.x /= b.x
  a.y /= b.y

proc `*=`*(a: var Vec2f, n: Fixed|int) =
  ## Compound scale a vector by n
  a.x *= n
  a.y *= n

proc `/=`*(a: var Vec2f, n: Fixed|int) =
  ## Compound scale a vector by 1/n
  a.x = a.x / n
  a.y = a.y / n


# Additional conversions
# ----------------------

proc initBgPoint*(x = 0'i16, y = 0'i16): BgPoint =
  ## Create a new pair of values used by the BG scroll registers
  ## e.g. ::
  ##  bgofs[0] = initBgPoint(10, 20)
  result.x = x
  result.y = y

proc toBgPoint*(a: Vec2i): BgPoint =
  ## Convert a vector to a pair of values used by the BG scroll registers
  ## e.g. ::
  ##   bgofs[0] = pos.toBgPoint()
  result.x = a.x.int16
  result.y = a.y.int16

proc toBgPoint*(a: Vec2f): BgPoint =
  ## Convert a fixed point vector to a pair of values used by the BG scroll registers
  ## e.g. ::
  ##   bgofs[0] = pos.toBgPoint()
  result.x = a.x.toInt().int16
  result.y = a.y.toInt().int16


# Rectangles
# ----------

type Rect* = object
  ## Rectangle type.
  ## Ranges from `left..right-1`, `top..bottom-1`
  left*, top*, right*, bottom*: int

proc rectBounds*(left, top, right, bottom: int): Rect =
  result.left = left
  result.top = top
  result.right = right
  result.bottom = bottom

proc rectAt*(x, y, width, height: int): Rect =
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
  r.x = p.x - r.width div 2
  r.y = p.y - r.height div 2

proc topLeft*(r: Rect): Vec2i =
  vec2i(r.left, r.top)

proc topRight*(r: Rect): Vec2i =
  vec2i(r.right, r.top)

proc bottomLeft*(r: Rect): Vec2i =
  vec2i(r.left, r.bottom)

proc bottomRight*(r: Rect): Vec2i =
  vec2i(r.right, r.bottom)

{.pop.}
