/*
 * isnan() implementation for GBA, ARM double precision version
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

int __isnan_arm(double x)
{
  union { double d; struct { unsigned l; unsigned h; } i; } n;
  n.d = x;

  // 4 ARM instructions, seems optimal
  n.i.h = (n.i.h & 0x7FFFFFFF) + 0x100000;
  return (n.i.h & 0x80000000) != 0 ? n.i.h << 1 | n.i.l : 0;
}
