/*
 * Round-trip test for ACSL in GBA
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
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>

int main()
{
  char buf[30];
  char *p;

  unsigned short *scr = (unsigned short *)0x06000000 + (240/2+240*(160/2));
  unsigned i = 0, j = 0;

  unsigned short *dispctl = (unsigned short *)0x04000000;
  dispctl[0] = 0x403;

  double r;
  unsigned len;

  union { double d; struct { unsigned ul; unsigned uh; } u; } n;

  // Test round-tripping of NaN and inf

  len = sprintf(buf, "%.17g", NAN);
  r = strtod(buf, &p);
  assert(isnan(r) && copysign(1.0, r) == 1.0 && p == buf + len);

  len = sprintf(buf, "%.17g", -NAN);
  r = strtod(buf, &p);
  assert(isnan(r) && copysign(1.0, r) == -1.0 && p == buf + len);

  len = sprintf(buf, "%.17g", INFINITY);
  r = strtod(buf, &p);
  assert(r == INFINITY && r > 0 && p == buf + len);

  len = sprintf(buf, "%.17g", -INFINITY);
  r = strtod(buf, &p);
  assert(r == -INFINITY && r < 0 && p == buf + len);

  srand(1);
  do
  {
    unsigned bits = rand();

    // Ensure no NaN or inf is generated
    do
    {
      n.u.uh = (bits << 1) ^ rand();
    }
    while (!(~n.u.uh & 0x7FF00000));

    // Low word
    n.u.ul = (bits << 2) ^ rand();

    // To ASCII
    len = sprintf(buf, "%.17g", n.d);

    // Back to binary
    r = strtod(buf, &p);

    // Did it round-trip?
    if (r != n.d)
    {
      printf("Error: %.13A != %.13A\n", r, n.d);
      break;
    }

    // Is the pointer correct?
    assert(p == buf + len);

    // Animate something cheaply, to see some progress
    scr[++i & 0x7FF] = ++j>>2;
  }
  while (1);
  return 0;
}
