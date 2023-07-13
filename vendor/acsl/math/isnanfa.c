/*
 * isnanf() implementation for GBA, ARM single precision version
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

int __isnanf_arm(float x)
{
  union { float f; unsigned i; } n;
  n.f = x;

  // 4 ARM instructions... not ideal
  n.i = (n.i & 0x7FFFFFFF) + 0x800000;
  return (n.i & 0x80000000) != 0 ? n.i << 1 : 0;
  // This is able to make it 3 ARM instructions, but only in recent versions
  // return __builtin_uadd_overflow(n.i << 1, 0x01000000, &n.i) ? n.i : 0;
}
