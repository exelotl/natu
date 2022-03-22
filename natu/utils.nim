import std/volatile

{.push inline.}

proc peek*[T](address: ptr T): T =
  volatileLoad(address)

proc poke*[T](address: ptr T, value: T) =
  volatileStore(address, value)

func isPowerOfTwo*(n: SomeInteger): bool =
  n > 0 and (n and (n-1)) == 0

func logPowerOfTwo*(n: uint): uint =
  ## Given that `n` is a power of two, return the power.
  ((n and 0xAAAAAAAA'u) != 0).uint or
    ((n and 0xCCCCCCCC'u) != 0).uint shl 1 or
    ((n and 0xF0F0F0F0'u) != 0).uint shl 2 or
    ((n and 0xFF00FF00'u) != 0).uint shl 3 or
    ((n and 0xFFFF0000'u) != 0).uint shl 4

{.pop.}
