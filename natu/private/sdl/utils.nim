
{.pragma: tonc, header: "tonc_core.h".}
{.pragma: toncinl, header: "tonc_core.h".}  # indicates that the definition is in the header.

# Tonc memory functions
# ---------------------

proc memcpy16_impl(dst: pointer, src: pointer, hwcount: cuint) {.exportc: "memcpy16".} =
  let d = cast[ptr UncheckedArray[uint16]](dst)
  let s = cast[ptr UncheckedArray[uint16]](src)
  for i in 0..<hwcount:
    d[i] = s[i]

proc memcpy32_impl(dst: pointer, src: pointer, wcount: cuint) {.exportc: "memcpy32".} =
  let d = cast[ptr UncheckedArray[uint32]](dst)
  let s = cast[ptr UncheckedArray[uint32]](src)
  for i in 0..<wcount:
    d[i] = s[i]

proc memset32_impl(dst: pointer, w: uint32, wcount: cuint) {.exportc: "memset32".} =
  let d = cast[ptr UncheckedArray[uint32]](dst)
  for i in 0..<wcount:
    d[i] = w

proc memset16_impl(dst: pointer, hw: uint16, hwcount: cuint) {.exportc: "memset16".} =
  let d = cast[ptr UncheckedArray[uint16]](dst)
  for i in 0..<hwcount:
    d[i] = hw


proc memcpy16*(dst: pointer, src: pointer, hwcount: SomeInteger) =
  memcpy16_impl(dst, src, hwcount.cuint)
proc memcpy32*(dst: pointer, src: pointer, wcount: SomeInteger) =
  memcpy32_impl(dst, src, wcount.cuint)
proc memset32*(dst: pointer, w: uint32, wcount: SomeInteger) =
  memset32_impl(dst, w, wcount.cuint)
proc memset16*(dst: pointer, hw: uint16, hwcount: SomeInteger) =
  memset16_impl(dst, hw, hwcount.cuint)
