import std/volatile
import ./private/[common, types]

export FnPtr

{.compile(toncPath & "/src/tonc_core.c", toncCFlags).}
{.compile(toncPath & "/asm/tonc_memcpy.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_memset.s", toncAsmFlags).}

{.pragma: tonc, header: "tonc_core.h".}
{.pragma: toncinl, header: "tonc_core.h".}  # indicates that the definition is in the header.

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


# Tonc memory functions
# ---------------------

proc memset16*(dst: pointer, hw: uint16, hwcount: SomeInteger) {.importc: "memset16", tonc.}
  ## Fastfill for halfwords, analogous to memset()
  ## 
  ## Uses `memset32()` if `hwcount > 5`
  ## 
  ## :dst:     Destination address.
  ## :hw:      Source halfword (not address).
  ## :hwcount: Number of halfwords to fill.
  ## 
  ## .. note::
  ##    | `dst` *must* be halfword aligned.
  ##    | `r0` returns as `dst + hwcount*2`.

proc memcpy16*(dst: pointer, src: pointer, hwcount: SomeInteger) {.importc: "memcpy16", tonc.}
  ## Copy for halfwords.
  ## 
  ## Uses `memcpy32()` if `hwcount > 6` and `src` and `dst` are aligned equally.
  ## 
  ## :dst:     Destination address.
  ## :src:     Source address.
  ## :hwcount: Number of halfwords to fill.
  ## 
  ## .. note::
  ##    | `dst` and `src` *must* be halfword aligned.
  ##    | `r0` and `r1` return as `dst + hwcount*2` and `src + hwcount*2`.

proc memset32*(dst: pointer, wd: uint32, wcount: SomeInteger) {.importc: "memset32", tonc.}
  ## Fast-fill by words, analogous to memset()
  ## 
  ## Like CpuFastSet(), only without the requirement of 32byte chunks and no awkward store-value-in-memory-first issue.
  ## 
  ## :dst:     Destination address.
  ## :wd:      Fill word (not address).
  ## :wcount:  Number of words to fill.
  ## 
  ## .. note::
  ##    | `dst` *must* be word aligned.
  ##    | `r0` returns as `dst + wcount*4`.

proc memcpy32*(dst: pointer, src: pointer, wcount: SomeInteger) {.importc: "memcpy32", tonc.}
  ## Fast-copy by words.
  ## 
  ## Like :ref:`CpuFastFill`, only without the requirement of 32byte chunks
  ## 
  ## :dst:     Destination address.
  ## :src:     Source address.
  ## :wcount:  Number of words.
  ## 
  ## .. note ::
  ##    | `src` and `dst` *must* be word aligned.
  ##    | `r0` and `r1` return as `dst + wcount*4` and `src + wcount*4`.


# Repeated-value creators
# -----------------------
# These take a hex-value and duplicate it to all fields, like ``0x88 -> 0x88888888``.

func dup8*(x: uint8): uint16 =
  ## Duplicate a byte to form a halfword: ``0x12 -> 0x1212``.
  x.uint16 or (x.uint16 shl 8)

func dup16*(x: uint16): uint32 =
  ## Duplicate a halfword to form a word: ``0x1234 -> 0x12341234``.
  x.uint32 or (x.uint32 shl 16)

func quad8*(x: uint8): uint32 =
  ## Quadruple a byte to form a word: ``0x12 -> 0x12121212``.
  x.uint32 * 0x01010101

func octup*(x: uint8): uint32 =
  ## Octuple a nybble to form a word: ``0x1 -> 0x11111111``
  x.uint32 * 0x11111111


# Bit packing
# -----------

func bytes2hword*(b0, b1: uint8): uint16 =
  ## Pack 2 bytes into a word. Little-endian order.
  b0.uint16 or (b1.uint16 shl 8)

func bytes2word*(b0, b1, b2, b3: uint8): uint32 =
  ## Pack 4 bytes into a word. Little-endian order.
  b0.uint32 or (b1.uint32 shl 8) or (b2.uint32 shl 16) or (b3.uint32 shl 24)
  
func hword2word*(h0, h1: uint16): uint32 =
  ## Pack 2 halfwords into a word. Little-endian order.
  h0.uint32 or (h1.uint32 shl 16)


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
  prngState = if seed == 0: (1979339339) else: (seed)

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
  when T is bool:
    (rand() and 0b01).bool
  elif T is range or T is enum:
    rand(T.low, T.high)
  else:
    cast[T](rand())


proc sample*[T](arr: openArray[T]): T =
  ## Get a random item from an array.
  arr[rand(arr.len-1)]

proc sample*[T](arr: ptr UncheckedArray[T], len: SomeInteger): T =
  ## Get a random item from an unchecked array with a given length.
  arr[rand(len-1)]


proc pickRandom*[T](arr: openArray[T]): T {.deprecated: "Use `sample` instead.".} =
  sample(arr)

proc pickRandom*[T](arr: ptr UncheckedArray[T], len: SomeInteger): T {.deprecated: "Use `sample` instead.".} =
  sample(arr, len)


# Sector checking
# ---------------

proc octant*(x, y: int): uint {.importc: "octant", tonc.}
  ## Get the octant that (`x`, `y`) is in.
  ## 
  ## This function divides the circle in 8 parts. The angle starts at the `y=0` line and then moves in the direction
  ## of the `x=0` line. On the screen, this would be like starting at the 3 o'clock position and moving clockwise.

proc octantRot*(x0, y0: int): uint {.importc: "octant_rot", tonc.}
  ## Get the rotated octant that (`x`, `y`) is in.
  ## 
  ## Like `octant()` but with a twist. The 0-octant starts 22.5° earlier so that 3 o'clock falls in the middle of 
  ## octant 0, instead of at its start. This can be useful for 8 directional pointing.


# Compile-time utils
# ------------------

template readBin*(path: static string): untyped =
  ## 
  ## Read a binary file at compile-time as an array of bytes.
  ## 
  ## If assigned to a top-level `let` variable, this data will be placed in ROM.
  ## 
  ## e.g.
  ## 
  ## .. code-block:: nim
  ##   
  ##   let shipPal = readBin("ship.pal.bin")
  ## 
  const data = static:
    const str = staticRead(path)
    var arr: array[str.len, byte]
    for i, c in str:
      arr[i] = c.byte
    arr
  data