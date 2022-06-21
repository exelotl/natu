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

from ./core import qran, qranRange

proc pickRandom*[T](arr: openArray[T]): T =
  ## Return a random item from an array.
  arr[qranRange(0, arr.len)]

proc pickRandom*[T](arr: ptr UncheckedArray[T], len: int): T =
  ## Return a random item from an unchecked array with a given length.
  arr[qranRange(0, len)]

proc rand*[T:Fixed|Ordinal](a, b: T): T =
  ## Return a random value between `a` and `b` inclusive.
  T(qranRange(a.int, b.int+1))

proc rand*[T:Fixed|Ordinal](s: Slice[T]): T =
  ## Return a random value from a slice.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##    
  ##    let n = rand(0..100)
  ## 
  T(qranRange(s.a.int, s.b.int+1))

proc rand*(T: typedesc): T =
  ## Return a random value from an enum
  rand(T.low..T.high)

{.pop.}
