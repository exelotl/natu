## Mathematical functions
## ======================

{.warning[UnusedImport]: off.}

import private/[common, types]
import std/math as std_math

export std_math.sgn
export FixedT, FixedN, Fixed

{.compile(toncPath & "/src/tonc_math.c", toncCFlags).}
{.compile(toncPath & "/asm/div_lut.c", toncCFlags).}
{.compile(toncPath & "/asm/sin_lut.c", toncCFlags).}

{.pragma: tonc, header: "tonc_math.h".}
{.pragma: toncinl, header: "tonc_math.h".}  # indicates that the definition is in the header.

const
  fpShift* = 8
  fpScale* = (1 shl fpShift)
  fpMask* = (fpScale - 1)

template getBaseType[T, N](typ: typedesc[FixedT[T,N]]): typedesc[SomeInteger] = T
template getShift[T, N](typ: typedesc[FixedT[T,N]]): int = N
template getScale[T, N](typ: typedesc[FixedT[T,N]]): T = T(1) shl N

template toFixed*(n: SomeNumber; F: typedesc[FixedT]): untyped =
  ## Convert a number to the fixed-point type `F`.
  F(n * typeof(n)(getScale(F)))
  # NOTE: a bit of a gotcha here if typeof(n) is smaller than getBaseType(F)
  # might be best to convert `n` to whichever type has most bits first?

template toFixed*[T,N](n: FixedT; F: typedesc[FixedT[T,N]]): untyped =
  ## Convert from one fixed-point format to another.
  const d = getShift(F) - getShift(typeof(n))
  when sizeof(n) > sizeof(T):
    when d >= 0:
      F(raw(n) shl d)
    else:
      F(raw(n) shr -d)
  else:
    when d >= 0:
      F(T(n) shl d)
    else:
      F(T(n) shr -d)

template toFixed*(n: SomeNumber|FixedT; T: typedesc[SomeInteger]; N: static int): untyped =
  ## Convert a value to fixed-point, with a base type of `T` using `N` bits of precision.
  n.toFixed(FixedT[T, N])

template toFixed*(n: SomeNumber|FixedT; N: static int): untyped =
  ## Convert a value to fixed-point with `N` bits of precision.
  n.toFixed(FixedN[N])

template fp*(n: SomeNumber|FixedT): Fixed =
  ## Convert a value to fixed-point with 8 bits of precision.
  n.toFixed(Fixed)

template toInt*(n: FixedT): int = n.int shr getShift(typeof(n))
  ## Convert a fixed-point value to an integer.

template toFloat32*(n: FixedT): float32 = n.float32 / getScale(typeof(n)).float32
  ## Convert a fixed-point value to floating point.

func `$`*[F: FixedT](a: F): string = $(a.toFloat32())  # TODO: better implementation?

# implicit converters for the most common cases?
# converter toFixedN8*(a: SomeNumber): FixedN[8] {.inline.} = toFixed(a, 8)
# converter toFixedN10*(a: SomeNumber): FixedN[10] {.inline.} = toFixed(a, 10)

template raw*[F: FixedT](a: F): untyped = getBaseType(typeof(a))(a)

template `+`*[F: FixedT](a, b: F): F = F(raw(a) + raw(b))
template `-`*[F: FixedT](a, b: F): F = F(raw(a) - raw(b))
template `*`*[F: FixedT](a, b: F): F = F((raw(a) * raw(b)) shr getShift(typeof(a)))
template `/`*[F: FixedT](a, b: F): F = F((raw(a) shl getShift(typeof(a))) div raw(b))

template `==`*[F: FixedT](a, b: F): bool = (raw(a) == raw(b))
template `<`*[F: FixedT](a, b: F): bool = (raw(a) < raw(b))
template `<=`*[F: FixedT](a, b: F): bool = (raw(a) <= raw(b))
template `+`*[F: FixedT](a: F): F = a
template `-`*[F: FixedT](a: F): F = F(-raw(a))
template abs*[F: FixedT](a: F): F = F(abs(raw(a)))

template `+=`*[F: FixedT](a: var F, b: F) =  a = a + b
template `-=`*[F: FixedT](a: var F, b: F) =  a = a - b
template `*=`*[F: FixedT](a: var F, b: F) =  a = a * b
template `/=`*[F: FixedT](a: var F, b: F) =  a = a / b

template mul64*[F: FixedT](a, b: F): F = (((cast[int64](a)) * raw(b)) div getScale(typeof(a))).F
  ## Multiply two fixed-point values using 64-bit math (to help avoid overflows)

template div64*[F: FixedT](a, b: F): F = (((cast[int64](a)) shl getShift(typeof(a))) div raw(b)).F
  ## Divide two fixed-point values using 64-bit math (to help avoid overflows)

template `+`*[F: FixedT, I: SomeInteger](a: F, b: I): F = F(raw(a) + (getBaseType(typeof(a))(b) shl getShift(typeof(a))))
template `-`*[F: FixedT, I: SomeInteger](a: F, b: I): F = F(raw(a) - (getBaseType(typeof(a))(b) shl getShift(typeof(a))))
template `*`*[F: FixedT, I: SomeInteger](a: F, b: I): F = F(raw(a) * getBaseType(typeof(a))(b))
template `/`*[F: FixedT, I: SomeInteger](a: F, b: I): F = F(raw(a) div getBaseType(typeof(a))(b))

template `+`*[F: FixedT, I: SomeInteger](a: I, b: F): F = F((getBaseType(typeof(b))(a) shl getShift(typeof(b))) + raw(b))
template `-`*[F: FixedT, I: SomeInteger](a: I, b: F): F = F((getBaseType(typeof(b))(a) shl getShift(typeof(b))) - raw(b))
template `*`*[F: FixedT, I: SomeInteger](a: I, b: F): F = F(getBaseType(typeof(b))(a) * raw(b))

template `==`*[F: FixedT, I: SomeInteger](a: F, b: I): bool = a == F(getBaseType(typeof(a))(b) shl getShift(typeof(a)))
template `<`*[F: FixedT, I: SomeInteger](a: F, b: I): bool = a < F(getBaseType(typeof(a))(b) shl getShift(typeof(a)))
template `<=`*[F: FixedT, I: SomeInteger](a: F, b: I): bool = a <= F(getBaseType(typeof(a))(b) shl getShift(typeof(a)))

template `==`*[F: FixedT, I: SomeInteger](a: I, b: F): bool = F(getBaseType(typeof(b))(a) shl getShift(typeof(b))) == b
template `<`*[F: FixedT, I: SomeInteger](a: I, b: F): bool = F(getBaseType(typeof(b))(a) shl getShift(typeof(b))) < b
template `<=`*[F: FixedT, I: SomeInteger](a: I, b: F): bool = F(getBaseType(typeof(b))(a) shl getShift(typeof(b))) <= b

template `+=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a + b
template `-=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a - b
template `*=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a * b
template `/=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a / b

template `shr`*[F: FixedT, I: SomeInteger](a: F, b: I): F = F(raw(a) shr b)
template `shl`*[F: FixedT, I: SomeInteger](a: F, b: I): F = F(raw(a) shl b)

{.push inline.}

func flr*(n: FixedT): int =
  ## Convert a fixed-point number to an integer, always rounding down.
  n.int shr getShift(typeof(n))

func ceil*(n: FixedT): int =
  ## Convert a fixed-point number to an integer, always rounding up.
  (n.int + (getScale(typeof(n)) - 1)) shr getShift(typeof(n))

func sgn*(x: FixedT): int =
  ## Get the sign of a fixed-point number.
  ## 
  ## Returns `-1` when `x` is negative, `1` when `x` is positive, or `0` when `x` is `0`.
  sgn(x.raw)

func sgn2*(x: SomeNumber|FixedT): int =
  ## Returns `1` or `-1` depending on the sign of `x`.
  ##
  ## Note: This never returns `0`. Use `sgn` if you want something that does.
  if x >= 0: 1
  else: -1

func approach*[T: SomeNumber|FixedT](x: var T, target, step: T) =
  ## Move `x` towards `target` by `step` without exceeding target.
  ## 
  ## `step` should be a positive number.
  if x < target:
    x = min(x + step, target)
  else:
    x = max(x - step, target)

func lerp*[A: SomeNumber|FixedT, F: FixedT](a, b: A; t: F): A =
  ## Linear interpolation between `a` and `b` using the weight given by `t`.
  ## 
  ## `t` should be a fixed point value in the range of `0.0 .. 1.0`.
  ## 
  a + (((b - a) * t.raw) shr getShift(F))

{.pop.}


# Lookup Tables
# -------------

let sinLut* {.importc: "sin_lut", tonc.}: array[514, int16]
let divLut* {.importc: "div_lut", tonc.}: array[257, int32]

## TODO: make distinct? Add helper functions such as degrees(FixedT|int)
type
  Angle* = uint32
    ## An angle value, where `0x10000` is equivalent to 2π.

func luSin*(theta: Angle): FixedN[12] {.inline.} =
  ## Look-up a sine value.
  ## 
  ## :theta: An unsigned integer angle, where `0x10000` is a full turn.
  ## 
  ## Returns a 20.12 fixed-point number between `-1.0` and `1.0`.
  {.nosideeffect.}:
    FixedN[12](sinLut[(theta shr 7) and 0x1ff])

func luCos*(theta: Angle): FixedN[12] {.inline.} =
  ## Look-up a cosine value.
  ## 
  ## :theta: An unsigned integer angle, where `0x10000` is a full turn.
  ## 
  ## Returns a 20.12 fixed-point number between `-1.0` and `1.0`.
  {.nosideeffect.}:
    FixedN[12](sinLut[((theta shr 7) + 128) and 0x1ff])

func luDiv*(x: range[0..256]): FixedN[16] {.inline.} =
  ## Look-up a division value between 0 and 256.
  ## 
  ## Returns `1/x`, represented as a 16.16 fixed point number.
  {.nosideeffect.}:
    FixedN[16](divLut[x])

func luLerp*[A: SomeInteger|FixedT, F: FixedT](lut: openArray[A]; x: F): A {.inline.} =
  ## Linear interpolator for LUTs.
  ## 
  ## An LUT (lookup table) is essentially the discrete form of a function, `f(x)`.
  ## You can get values for non-integer `x` via (linear) interpolation between `f(x)` and `f(x+1)`.
  ## 
  ## :lut:   The LUT to interpolate from.
  ## :x:     Fixed-point number to interpolate at.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##    
  ##    let myLut* {.importc.}: array[100, int16]  # some array of data.
  ##    
  ##    let n: int16 = luLerp(myLut, fp(10.75))    # get a value ¾ between the 10th and 11th entry of `myLut`.
  ## 
  let xa = x.raw shr getShift(F)
  let ya = lut[xa]
  let yb = lut[xa+1]
  ya + (((yb - ya) * (x.raw - (xa shl getShift(F)))) shr getShift(F))


# Rectangle / vector types
# ------------------------

type
  Vec2i* {.bycopy.} = object
    ## Integer 2D vector/point type
    x*, y*: int
    
  Vec2f* {.bycopy.} = object
    ## Fixed-point `24:8` 2D vector/point type
    x*, y*: Fixed

{.push noinit, inline.}

func vec2i*(x, y: int): Vec2i =
  ## Initialise an integer vector
  result.x = x
  result.y = y

func vec2i*(): Vec2i =
  ## Initialise an integer vector to 0,0
  result.x = 0
  result.y = 0

func vec2i*(v: Vec2f): Vec2i =
  ## Convert an integer vector to a fixed-point vector
  result.x = toInt(v.x)
  result.y = toInt(v.y)

func vec2f*(x: SomeNumber|FixedT; y: SomeNumber|FixedT): Vec2f =
  ## Initialise a fixed-point vector
  result.x = fp(x)
  result.y = fp(y)

func vec2f*(): Vec2f =
  ## Initialise a fixed-point vector to 0,0
  result.x = 0.Fixed
  result.y = 0.Fixed

func vec2f*(v: Vec2i): Vec2f =
  ## Convert a fixed-point vector to an integer vector
  result.x = fp(v.x)
  result.y = fp(v.y)


# Integer vector operations
# -------------------------

func `+`*(a, b: Vec2i): Vec2i =
  ## Add two vectors
  result.x = a.x + b.x
  result.y = a.y + b.y

func `-`*(a, b: Vec2i): Vec2i =
  ## Subtract two vectors
  result.x = a.x - b.x
  result.y = a.y - b.y

func `*`*(a, b: Vec2i): Vec2i =
  ## Component-wise multiplication of two vectors
  result.x = a.x * b.x
  result.y = a.y * b.y

func `/`*(a, b: Vec2i): Vec2i =
  ## Component-wise division of two vectors
  result.x = a.x div b.x
  result.y = a.y div b.y

func `*`*(a: Vec2i, n: int): Vec2i =
  ## Scale vector by n
  result.x = a.x * n
  result.y = a.y * n

func `/`*(a: Vec2i, n: int): Vec2i =
  ## Scale vector by 1/n
  result.x = a.x div n
  result.y = a.y div n

func `*`*(n: int, a: Vec2i): Vec2i =
  ## Scale vector by n
  result.x = a.x * n
  result.y = a.y * n

func `/`*(n: int, a: Vec2i): Vec2i =
  ## Scale vector by 1/n
  result.x = a.x div n
  result.y = a.y div n

func dot*(a, b: Vec2i): int =
  ## Dot product of two vectors
  (a.x * b.x) + (a.y * b.y)

func `shr`*(a: Vec2i, n: int): Vec2i =
  ## Component-wise bit shift right an integer vector.
  result.x = a.x shr n
  result.y = a.y shr n

func `shl`*(a: Vec2i, n: int): Vec2i =
  ## Component-wise bit shift left an integer vector.
  result.x = a.x shl n
  result.y = a.y shl n

func `-`*(a: Vec2i): Vec2i =
  ## Equivalent to a * -1
  vec2i(-a.x, -a.y)

func `+=`*(a: var Vec2i, b: Vec2i) =
  ## Vector compound addition
  a.x += b.x
  a.y += b.y

func `-=`*(a: var Vec2i, b: Vec2i) =
  ## Vector compound subtraction
  a.x -= b.x
  a.y -= b.y

func `*=`*(a: var Vec2i, b: Vec2i) =
  ## Vector component-wise compound multiplicatoin
  a.x *= b.x
  a.y *= b.y

func `/=`*(a: var Vec2i, b: Vec2i) =
  ## Vector component-wise compound division
  a.x = a.x div b.x
  a.y = a.y div b.y

func `*=`*(a: var Vec2i, n: int) =
  ## Compound scale a vector by n
  a.x *= n
  a.y *= n

func `/=`*(a: var Vec2i, n: int) =
  ## Compound scale a vector by 1/n
  a.x = a.x div n
  a.y = a.y div n


# Fixed-point vector operations
# -----------------------------

func `+`*(a, b: Vec2i|Vec2f): Vec2f =
  ## Add two fixed-point vectors
  result.x = a.x + b.x
  result.y = a.y + b.y

func `-`*(a, b: Vec2i|Vec2f): Vec2f =
  ## Subtract two fixed-point vectors
  result.x = a.x - b.x
  result.y = a.y - b.y

func `*`*(a: Vec2f, b: Vec2i|Vec2f): Vec2f =
  ## Component-wise multiplication of two vectors
  result.x = a.x * b.x
  result.y = a.y * b.y

func `/`*(a: Vec2f, b: Vec2i|Vec2f): Vec2f =
  ## Component-wise division of two vectors
  result.x = a.x / b.x
  result.y = a.y / b.y

func `*`*(a: Vec2f, n: Fixed|int): Vec2f =
  ## Scale a fixed-point vector by n
  result.x = a.x * n
  result.y = a.y * n

func `/`*(a: Vec2f, n: Fixed|int): Vec2f =
  ## Scale a fixed-point vector by 1/n
  result.x = a.x / n
  result.y = a.y / n

func `*`*(n: Fixed|int, a: Vec2f): Vec2f =
  ## Scale a fixed-point vector by n
  result.x = a.x * n
  result.y = a.y * n

func `/`*(n: Fixed|int, a: Vec2f): Vec2f =
  ## Scale a fixed-point vector by 1/n
  result.x = a.x / n
  result.y = a.y / n

func dot*(a, b: Vec2f): Fixed =
  ## Dot product of two fixed-point vectors
  (a.x * b.x) + (a.y * b.y)

func `shr`*(a: Vec2f, n: int): Vec2f =
  ## Component-wise bit shift right a fixed-point vector.
  result.x = a.x shr n
  result.y = a.y shr n

func `shl`*(a: Vec2f, n: int): Vec2f =
  ## Component-wise bit shift left a fixed-point vector.
  result.x = a.x shl n
  result.y = a.y shl n

func `-`*(a: Vec2f): Vec2f =
  ## Equivalent to a * -1
  vec2f(-a.x, -a.y)

func `+=`*(a: var Vec2f, b: Vec2f) =
  ## Vector compound addition
  a.x += b.x
  a.y += b.y

func `-=`*(a: var Vec2f, b: Vec2f) =
  ## Vector compound subtraction
  a.x -= b.x
  a.y -= b.y

func `*=`*(a: var Vec2f, b: Vec2i|Vec2f) =
  ## Vector component-wise compound multiplicatoin
  a.x *= b.x
  a.y *= b.y

func `/=`*(a: var Vec2f, b: Vec2i|Vec2f) =
  ## Vector component-wise compound division
  a.x /= b.x
  a.y /= b.y

func `*=`*(a: var Vec2f, n: Fixed|int) =
  ## Compound scale a vector by n
  a.x *= n
  a.y *= n

func `/=`*(a: var Vec2f, n: Fixed|int) =
  ## Compound scale a vector by 1/n
  a.x = a.x / n
  a.y = a.y / n

func lerp*[A: Vec2i|Vec2f, F: FixedT](a, b: A; t: F): A =
  result.x = lerp(a.x,b.x,t)
  result.y = lerp(a.y,b.y,t)

# Additional conversions
# ----------------------

func initBgPoint*(x = 0'i16, y = 0'i16): BgPoint =
  ## Create a new pair of values used by the BG scroll registers, e.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##  bgofs[0] = initBgPoint(10, 20)
  ## 
  result.x = x
  result.y = y

func toBgPoint*(a: Vec2i): BgPoint =
  ## Convert a vector to a pair of values used by the BG scroll registers, e.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgofs[0] = pos.toBgPoint()
  ## 
  result.x = a.x.int16
  result.y = a.y.int16

func toBgPoint*(a: Vec2f): BgPoint =
  ## Convert a fixed-point vector to a pair of values used by the BG scroll registers, e.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgofs[0] = pos.toBgPoint()
  ## 
  result.x = a.x.toInt().int16
  result.y = a.y.toInt().int16


# Rectangles
# ----------

type Rect* = object
  ## Rectangle type.
  ## Ranges from `left..right-1`, `top..bottom-1`
  left*, top*, right*, bottom*: int

func rectBounds*(left, top, right, bottom: int): Rect =
  result.left = left
  result.top = top
  result.right = right
  result.bottom = bottom

func rectAt*(x, y, width, height: int): Rect =
  result.left = x
  result.top = y
  result.right = x + width
  result.bottom = y + height

func x*(r: Rect): int = r.left
func y*(r: Rect): int = r.top
func w*(r: Rect): int = r.right - r.left
func h*(r: Rect): int = r.bottom - r.top
func width*(r: Rect): int = r.right - r.left
func height*(r: Rect): int = r.bottom - r.top

func `x=`*(r: var Rect, x: int) =
  r.right += x - r.left
  r.left = x

func `y=`*(r: var Rect, y: int) = 
  r.bottom += y - r.top
  r.top = y

func `w=`*(r: var Rect, w: int) =
  r.right = r.left + w

func `h=`*(r: var Rect, h: int) = 
  r.bottom = r.top + h

func `width=`*(r: var Rect, w: int) =
  r.right = r.left + w

func `height=`*(r: var Rect, h: int) = 
  r.bottom = r.top + h

func move*(r: var Rect, dx, dy: int) =
  ## Move rectangle by (`dx`, `dy`)
  r.left += dx
  r.top += dy
  r.right += dx
  r.bottom += dy

func move*(r: var Rect, vec: Vec2i) =
  ## Move rectangle by `vec`
  r.left += vec.x
  r.top += vec.y
  r.right += vec.x
  r.bottom += vec.y

func inflate*(r: var Rect, n: int) =
  ## Increase size of rectangle by `n` on all sides
  r.left -= n
  r.top -= n
  r.right += n
  r.bottom += n
  
func inflate*(r: var Rect, dw, dh: int) =
  ## Increase size of rectangle by `dw` horizontally, `dh` vertically
  r.left -= dw
  r.top -= dh
  r.right += dw
  r.bottom += dh

func center*(r: Rect): Vec2i =
  ## Get the center point of a rectangle
  result.x = (r.left + r.right) shr 1
  result.y = (r.top + r.bottom) shr 1

func `center=`*(r: var Rect, p: Vec2i) =
  ## Set the center point of a rectangle
  r.x = p.x - r.w shr 1
  r.y = p.y - r.h shr 1

func topLeft*(r: Rect): Vec2i =
  vec2i(r.left, r.top)

func topRight*(r: Rect): Vec2i =
  vec2i(r.right, r.top)

func bottomLeft*(r: Rect): Vec2i =
  vec2i(r.left, r.bottom)

func bottomRight*(r: Rect): Vec2i =
  vec2i(r.right, r.bottom)

{.pop.}


# Matrices for affine transforms
# ------------------------------

type Mat2f* = object
  pa*, pb*, pc*, pd*: Fixed

func mat2f*(): Mat2f {.inline, noinit.} =
  ## Returns the identity matrix.
  result.pa = fp(1)
  result.pb = fp(0)
  result.pc = fp(0)
  result.pd = fp(1)

func mat2f*(pa, pb, pc, pd: Fixed): Mat2f {.inline, noinit.} =
  result.pa = pa
  result.pb = pb
  result.pc = pc
  result.pd = pd

func mat2fScaled*(sx, sy: Fixed): Mat2f {.inline, noinit.} =
  result.pa = sx
  result.pb = fp(0)
  result.pc = fp(0)
  result.pd = sy

func mat2fInvScaled*(sx, sy: Fixed): Mat2f {.inline, noinit.} =
  result.pa = (luDiv(sx.uint32)).Fixed
  result.pb = fp(0)
  result.pc = fp(0)
  result.pd = (luDiv(sy.uint32)).Fixed

func invScale*(mat: var Mat2f, sx, sy: range[fp(0.0)..fp(1.0)]) {.inline, noinit.} =
  mat.pa = ((mat.pa.int * luDiv(sx.int).int) shr 8).Fixed
  mat.pd = ((mat.pd.int * luDiv(sy.int).int) shr 8).Fixed

func mat2fRotated*(a: Angle): Mat2f {.inline, noinit.} =
  let ss = luSin(a).fp
  let cc = luCos(a).fp
  result.pa = cc
  result.pb = -ss
  result.pc = ss
  result.pd = cc

func `*`*(a, b: Mat2f): Mat2f {.inline, noinit.} =
  result.pa = ((a.pa.int * b.pa.int + a.pb.int * b.pc.int) shr 8).Fixed
  result.pb = ((a.pa.int * b.pb.int + a.pb.int * b.pd.int) shr 8).Fixed
  result.pc = ((a.pc.int * b.pa.int + a.pd.int * b.pc.int) shr 8).Fixed
  result.pd = ((a.pc.int * b.pb.int + a.pd.int * b.pd.int) shr 8).Fixed