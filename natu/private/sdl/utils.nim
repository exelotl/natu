
{.pragma: tonc, header: "tonc_core.h".}
{.pragma: toncinl, header: "tonc_core.h".}  # indicates that the definition is in the header.

import ./appcommon
var natuMem {.importc.}: ptr NatuAppMem

template natuLogImpl*(s: cstring, args: varargs[untyped]) =
  natuMem.printf(s, args)


# Tonc memory functions
# ---------------------

type ConstPointer {.importc: "const void *", nodecl.} = pointer

proc memcpy16_impl(dst: pointer, src: ConstPointer, hwcount: cuint) {.importc: "memcpy16", noconv.}
proc memcpy32_impl(dst: pointer, src: ConstPointer, wcount: cuint) {.importc: "memcpy32", noconv.}
proc memset32_impl(dst: pointer, wd: uint32, wcount: cuint) {.importc: "memset32", noconv.}
proc memset16_impl(dst: pointer, hw: uint16, hwcount: cuint) {.importc: "memset16", noconv.}

proc memcpy16*(dst: pointer, src: pointer, hwcount: SomeInteger) =
  memcpy16_impl(dst, src, hwcount.cuint)
proc memcpy32*(dst: pointer, src: pointer, wcount: SomeInteger) =
  memcpy32_impl(dst, src, wcount.cuint)
proc memset32*(dst: pointer, wd: uint32, wcount: SomeInteger) =
  memset32_impl(dst, wd, wcount.cuint)
proc memset16*(dst: pointer, hw: uint16, hwcount: SomeInteger) =
  memset16_impl(dst, hw, hwcount.cuint)


{.emit: """

#include <stdint.h>

void memcpy16(void *dst, const void *src, unsigned int hwcount) {
  const uint16_t *s = (const uint16_t *) src;
  uint16_t *d = (uint16_t *) dst;
  for (unsigned int i = 0; i < hwcount; i++) {
    d[i] = s[i];
  }
}

void memcpy32(void *dst, const void *src, unsigned int wcount) {
  const uint32_t *s = (const uint32_t *) src;
  uint32_t *d = (uint32_t *) dst;
  for (unsigned int i = 0; i < wcount; i++) {
    d[i] = s[i];
  }
}

void memset16(void *dst, uint16_t hw, unsigned int hwcount) {
  uint16_t *d = (uint16_t *) dst;
  for (unsigned int i = 0; i < hwcount; i++) {
    d[i] = hw;
  }
}

void memset32(void *dst, uint32_t wd, unsigned int wcount) {
  uint32_t *d = (uint32_t *) dst;
  for (unsigned int i = 0; i < wcount; i++) {
    d[i] = wd;
  }
}

""".}
