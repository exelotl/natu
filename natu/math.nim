## Mathematical functions
## ======================

{.warning[UnusedImport]: off.}

import private/[common, types, core]
import std/math as std_math

export std_math.sgn

{.compile(toncPath & "/src/tonc_math.c", toncCFlags).}
{.compile(toncPath & "/asm/div_lut.s", toncAsmFlags).}
{.compile(toncPath & "/asm/sin_lut.s", toncAsmFlags).}

{.pragma: tonc, header: "tonc_math.h".}
{.pragma: toncinl, header: "tonc_math.h".}  # indicates that the definition is in the header.

const
  fpShift* = 8
  fpScale* = (1 shl fpShift)
  fpMask* = (fpScale - 1)

type
  FixedT*[T: SomeInteger, N: static int] = distinct T
    ## A fixed-point number based on type `T`, with `N` bits of precision.
  
  FixedN*[N: static int] = FixedT[int, N]
    ## A signed 32-bit fixed-point number with `N` bits of precision.
  
  Fixed* = FixedN[8]
    ## A signed 32-bit fixed-point number with 8 bits of precision.

template getBaseType[T, N](typ: typedesc[FixedT[T,N]]): typedesc[SomeInteger] = T
template getShift[T, N](typ: typedesc[FixedT[T,N]]): int = N
template getScale[T, N](typ: typedesc[FixedT[T,N]]): T = T(1) shl N

template toFixed*(n: SomeNumber, F: typedesc[FixedT]): untyped =
  ## Convert a number to the fixed-point type `F`.
  F(n * typeof(n)(getScale(F)))

template toFixed*[T,N](n: FixedT, F: typedesc[FixedT[T,N]]): untyped =
  ## Convert from one fixed-point format to another.
  const Diff = getShift(F) - getShift(typeof(n))
  when sizeof(n) > sizeof(T):
    when Diff >= 0:
      F(raw(n) shl Diff)
    else:
      F(raw(n) shr -Diff)
  else:
    when Diff >= 0:
      F(T(n) shl Diff)
    else:
      F(T(n) shr -Diff)

template toFixed*(n: SomeNumber|FixedT, N: static int): untyped =
  ## Convert a value to fixed-point with `N` bits of precision.
  n.toFixed(FixedN[N])

template fp*(n: SomeNumber|FixedT): Fixed =
  ## Convert a value to fixed-point with 8 bits of precision.
  n.toFixed(Fixed)

template toInt*(n: FixedT): int = n.int div getScale(typeof(n))
  ## Convert a fixed-point value to an integer.

template toFloat32*(n: FixedT): float32 = n.float32 / getScale(typeof(n)).float32
  ## Convert a fixed-point value to floating point.

proc `$`*[F: FixedT](a: F): string = $(a.toFloat32())  # TODO: better implementation?

when (NimMajor, NimMinor) >= (1, 6):
  # Enable fixed-point numeric literals, e.g: 22.5'fp
  # (Relegated to external file to keep the parser happy)
  include private/fp_literals

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
template `-`*[F: FixedT](a: F): F = F(-raw(a))
template abs*[F: FixedT](a: F): F = F(abs(raw(a)))

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

template `+=`*[F: FixedT](a: var F, b: F) =  a = a + b
template `-=`*[F: FixedT](a: var F, b: F) =  a = a - b
template `*=`*[F: FixedT](a: var F, b: F) =  a = a * b
template `/=`*[F: FixedT](a: var F, b: F) =  a = a / b

template `+=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a + b
template `-=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a - b
template `*=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a * b
template `/=`*[F: FixedT, I: SomeInteger](a: var F, b: I) =  a = a / b

{.push inline.}

func flr*(n: FixedT): int =
  ## Convert a fixed-point number to an integer, always rounding down.
  n.int shr getShift(typeof(n))

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

{.pop.}


# Lookup Tables
# -------------

var sinLut* {.importc: "sin_lut", tonc.}: array[514, int16]
var divLut* {.importc: "div_lut", tonc.}: array[257, int32]

## TODO: make distinct? Add helper functions such as degrees(FixedT|int)
type
  Angle* = uint32  ## 2π = 0x10000 (i.e. angle with 16 bits of resolution)

proc luSin*(theta: Angle): FixedN[12] {.inline.} =
  ## Look-up a sine value (2π = 0x10000)
  ## 
  ## `theta` Angle in [0,FFFFh] range
  ## 
  ## Return: .12f sine value
  FixedN[12](sinLut[(theta shr 7) and 0x1ff])

proc luCos*(theta: Angle): FixedN[12] {.inline.} =
  ## Look-up a cosine value (2π = 0x10000)
  ## 
  ## `theta` Angle in [0,FFFFh] range
  ## 
  ## Returns .12f cosine value
  FixedN[12](sinLut[((theta shr 7) + 128) and 0x1ff])

proc luDiv*(x: range[0..255]): FixedN[16] {.inline.} =
  ## Look-up a division value between 0 and 255
  ## 
  ## `x` reciprocal to look up.
  ## 
  ## Returns 1/x (.16f)
  FixedN[16](divLut[x])

proc luLerp*[A: SomeInteger, F: FixedT](lut: openArray[A]; x: F): A {.inline.} =
  ## Linear interpolator for LUTs.
  ## 
  ## An LUT (lookup table) is essentially the discrete form of a function, `f(x)`.
  ## You can get values for non-integer `x` via (linear) interpolation between `f(x)` and `f(x+1)`.
  ## 
  ## `lut`   The LUT to interpolate from.
  ## `x`     Fixed-point number to interpolate at.
  ## `shift` Number of fixed-point bits of `x`.
  let xa = x shr getShift(F)
  let ya = lut[xa]
  let yb = lut[xa+1]
  ya + ((yb - ya) * (x - (xa shl getShift(F))) shr getShift(F))


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

proc vec2i*(x, y: int): Vec2i =
  ## Initialise an integer vector
  result.x = x
  result.y = y

proc vec2i*(): Vec2i =
  ## Initialise an integer vector to 0,0
  result.x = 0
  result.y = 0

proc vec2i*(v: Vec2f): Vec2i =
  ## Convert an integer vector to a fixed-point vector
  result.x = toInt(v.x)
  result.y = toInt(v.y)

proc vec2f*(x, y: Fixed): Vec2f =
  ## Initialise a fixed-point vector
  result.x = x
  result.y = y

proc vec2f*(x: int|float32; y: int|float32): Vec2f =
  ## Initialise a fixed-point vector, values converted from int or float
  result.x = fp(x)
  result.y = fp(y)

proc vec2f*(): Vec2f =
  ## Initialise a fixed-point vector to 0,0
  result.x = 0.Fixed
  result.y = 0.Fixed

proc vec2f*(v: Vec2i): Vec2f =
  ## Convert a fixed-point vector to an integer vector
  result.x = fp(v.x)
  result.y = fp(v.y)


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

proc `*`*(n: int, a: Vec2i): Vec2i =
  ## Scale vector by n
  result.x = a.x * n
  result.y = a.y * n

proc `/`*(n: int, a: Vec2i): Vec2i =
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


# Fixed-point vector operations
# -----------------------------

proc `+`*(a, b: Vec2i|Vec2f): Vec2f =
  ## Add two fixed-point vectors
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `-`*(a, b: Vec2i|Vec2f): Vec2f =
  ## Subtract two fixed-point vectors
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
  ## Scale a fixed-point vector by n
  result.x = a.x * n
  result.y = a.y * n

proc `/`*(a: Vec2f, n: Fixed|int): Vec2f =
  ## Scale a fixed-point vector by 1/n
  result.x = a.x / n
  result.y = a.y / n

proc `*`*(n: Fixed|int, a: Vec2f): Vec2f =
  ## Scale a fixed-point vector by n
  result.x = a.x * n
  result.y = a.y * n

proc `/`*(n: Fixed|int, a: Vec2f): Vec2f =
  ## Scale a fixed-point vector by 1/n
  result.x = a.x / n
  result.y = a.y / n

proc dot*(a, b: Vec2f): Fixed =
  ## Dot product of two fixed-point vectors
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
  ## Create a new pair of values used by the BG scroll registers, e.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##  bgofs[0] = initBgPoint(10, 20)
  ## 
  result.x = x
  result.y = y

proc toBgPoint*(a: Vec2i): BgPoint =
  ## Convert a vector to a pair of values used by the BG scroll registers, e.g.
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgofs[0] = pos.toBgPoint()
  ## 
  result.x = a.x.int16
  result.y = a.y.int16

proc toBgPoint*(a: Vec2f): BgPoint =
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
