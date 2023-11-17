/*
 * stdint.h implementation for GBA
 *
 * (C) Copyright 2021 Pedro Gimeno Fortea
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
 * IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
#ifndef __INCLUDED_STDINT_H__
#define __INCLUDED_STDINT_H__

typedef   signed char       int8_t;
typedef unsigned char      uint8_t;
typedef   signed short      int16_t;
typedef unsigned short     uint16_t;
typedef   signed int        int32_t;
typedef unsigned int       uint32_t;
typedef   signed long long  int64_t;
typedef unsigned long long uint64_t;
typedef   signed char       int_least8_t;
typedef unsigned char      uint_least8_t;
typedef   signed short      int_least16_t;
typedef unsigned short     uint_least16_t;
typedef   signed int        int_least32_t;
typedef unsigned int       uint_least32_t;
typedef   signed long long  int_least64_t;
typedef unsigned long long uint_least64_t;
typedef   signed int        int_fast8_t;
typedef unsigned int       uint_fast8_t;
typedef   signed int        int_fast16_t;
typedef unsigned int       uint_fast16_t;
typedef   signed int        int_fast32_t;
typedef unsigned int       uint_fast32_t;
typedef   signed long long  int_fast64_t;
typedef unsigned long long uint_fast64_t;
typedef   signed int        intptr_t;
typedef unsigned int       uintptr_t;
typedef   signed long long  intmax_t;
typedef unsigned long long uintmax_t;

#define  INT8_MIN        -128
#define  INT8_MAX         127
#define UINT8_MAX         255U
#define  INT16_MIN       -32768
#define  INT16_MAX        32767
#define UINT16_MAX        65535U
#define  INT32_MIN       -2147483648
#define  INT32_MAX        2147483647
#define UINT32_MAX        4294967295U
#define  INT64_MIN       -9223372036854775808LL
#define  INT64_MAX        9223372036854775807LL
#define UINT64_MAX        18446744073709551615ULL
#define  INT_LEAST8_MIN  -128
#define  INT_LEAST8_MAX   127
#define UINT_LEAST8_MAX   255U
#define  INT_LEAST16_MIN -32768
#define  INT_LEAST16_MAX  32767
#define UINT_LEAST16_MAX  65535U
#define  INT_LEAST32_MIN -2147483648
#define  INT_LEAST32_MAX  2147483647
#define UINT_LEAST32_MAX  4294967295U
#define  INT_LEAST64_MIN -9223372036854775808LL
#define  INT_LEAST64_MAX  9223372036854775807LL
#define UINT_LEAST64_MAX  18446744073709551615ULL
#define  INT_FAST8_MIN   -2147483648
#define  INT_FAST8_MAX    2147483647
#define UINT_FAST8_MAX    4294967295U
#define  INT_FAST16_MIN  -2147483648
#define  INT_FAST16_MAX   2147483647
#define UINT_FAST16_MAX   4294967295U
#define  INT_FAST32_MIN  -2147483648
#define  INT_FAST32_MAX   2147483647
#define UINT_FAST32_MAX   4294967295U
#define  INT_FAST64_MIN  -9223372036854775808LL
#define  INT_FAST64_MAX   9223372036854775807LL
#define UINT_FAST64_MAX   18446744073709551615ULL
#define  INTPTR_MIN      -2147483648
#define  INTPTR_MAX       2147483647
#define UINTPTR_MAX       4294967295U
#define  INTMAX_MIN      -9223372036854775808LL
#define  INTMAX_MAX       9223372036854775807LL
#define UINTMAX_MAX       18446744073709551615ULL
#define  PTRDIFF_MIN     -2147483648
#define  PTRDIFF_MAX      2147483647
#define  SIG_ATOMIC_MIN  -2147483648
#define  SIG_ATOMIC_MAX   2147483647
#define  SIZE_MAX         4294967295U
#define  WCHAR_MIN        0U
#define  WCHAR_MAX        4294967295U
#define  WINT_MIN        -2147483648
#define  WINT_MAX         2147483647
#define  INT8_C(x)   x
#define  INT16_C(x)  x
#define  INT32_C(x)  x
#define  INT64_C(x)  x##LL
#define  INTMAX_C(x) x##LL
#define UINT8_C(x)   x
#define UINT16_C(x)  x
#define UINT32_C(x)  x##U
#define UINT64_C(x)  x##ULL
#define UINTMAX_C(x) x##ULL

#endif // __INCLUDED_STDINT_H__
