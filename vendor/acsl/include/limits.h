/*
 * limits.h implementation for GBA
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
#ifndef __INCLUDED_LIMITS_H__
#define __INCLUDED_LIMITS_H__

#define  CHAR_BIT         8
#define  CHAR_MIN        -128
#define  CHAR_MAX         127
#define SCHAR_MIN        -128
#define SCHAR_MAX         127
#define UCHAR_MAX         255U
#define MB_LEN_MAX        1
#define  SHRT_MIN        -32768
#define  SHRT_MAX         32767
#define USHRT_MAX         65535U
#define  INT_MIN         -2147483648
#define  INT_MAX          2147483647
#define UINT_MAX          4294967295U
#define  LONG_MIN        -2147483648
#define  LONG_MAX         2147483647
#define ULONG_MAX         4294967295U
#define  LLONG_MIN       -9223372036854775808LL
#define  LLONG_MAX        9223372036854775807LL
#define ULLONG_MAX        18446744073709551615ULL

#endif // __INCLUDED_LIMITS_H__
