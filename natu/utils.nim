import std/volatile
import ./private/types

{.push inline.}

proc peek*[T](address: ptr T): T =
  ## Read a value directly from some memory location.
  volatileLoad(address)

proc poke*[T](address: ptr T, value: T) =
  ## Write a value directly to a memory location.
  volatileStore(address, value)

func isPowerOfTwo*(n: SomeInteger): bool =
  ## Return true if `n` is a power of two.
  n > 0 and (n and (n-1)) == 0

func logPowerOfTwo*(n: uint): uint =
  ## Given that `n` is a power of two, return the power.
  ((n and 0xAAAAAAAA'u) != 0).uint or
    ((n and 0xCCCCCCCC'u) != 0).uint shl 1 or
    ((n and 0xF0F0F0F0'u) != 0).uint shl 2 or
    ((n and 0xFF00FF00'u) != 0).uint shl 3 or
    ((n and 0xFFFF0000'u) != 0).uint shl 4


## Random number generator
## -----------------------
## 
## Uses a simple [XorShift](https://en.wikipedia.org/wiki/Xorshift) algorithm,
## which is adequate for most games.
## 
## .. note::
##    Any range supplied to these procs should be less than 2^16.
##    
##    For example, `rand(max=999999)`, `rand(fp(-300)..fp(300))` or `rand(Natural)`
##    will all give inadequate results.
##    
##    To work around this, use `rand()` to get a raw 32-bit value instead.

var prngState: uint32 = 1979339339

proc seed*(seed: uint32) =
  ## Seed the random number generator.
  prngState = seed

proc rand*(): uint32 =
  ## Get a random 32-bit value.
  result = prngState
  result = result xor (result shl 13)
  result = result xor (result shr 17)
  result = result xor (result shl 5)
  prngState = result

proc rand*[T:Fixed|SomeInteger](max: T): T =
  ## Get a random integer in the range `0..max`.
  ## 
  ## .. note::
  ##    `max` must be less than `2^16` or `fp(256)`.
  cast[T](((rand() and 0x7fff) * (cast[uint32](max) + 1)) shr 15)

proc rand*[T:Ordinal](a, b: T): T =
  ## Get a random value between `a` and `b` inclusive.
  ## 
  ## .. note::
  ##    `a - b` must be less than `2^16`, to avoid overflow.
  cast[T](rand(cast[uint32](b) - cast[uint32](a)) + cast[uint32](a))

proc rand*[T:Ordinal](s: Slice[T]): T =
  ## Get a random value from a slice.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##    
  ##    let n = rand(0..100)
  ## 
  rand(s.a, s.b)

proc rand*[T:Ordinal](t: typedesc[T]): T =
  ## Get a random value of the given type.
  when T is range or T is enum:
    rand(T.low, T.high)
  else:
    cast[T](rand())

proc pickRandom*[T](arr: openArray[T]): T =
  ## Get a random item from an array.
  arr[rand(arr.len-1)]

proc pickRandom*[T](arr: ptr UncheckedArray[T], len: SomeInteger): T =
  ## Get a random item from an unchecked array with a given length.
  arr[rand(len-1)]

{.pop.}
