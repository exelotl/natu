/*
 * Unit test for ldexp()
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
#include <math.h>
#include <errno.h>

int ldexp_test(double inp, int e, double expect, int eno, int line)
{
  errno = 0;
  double actual = ldexp(inp, e);
  int save_errno = errno;
  int err = 0;
  if (copysign(1.0, actual) != copysign(1.0, expect))
  {
    printf("ldexp line %d: Signs don't match: got %.13a, want %.13a\n", line, actual, expect);
    err = 1;
  }
  if ((!isnan(actual) || !isnan(expect)) && (actual != expect))
  {
    printf("ldexp line %d: Values don't match: got %.13a, want %.13a\n", line, actual, expect);
    err = 1;
  }

#ifndef IGNORE_ERRNO  // Used to cross-check with glibc, which has other
                      // criteria for errno
  if (save_errno != eno)
  {
    printf("ldexp line %d: ERRNO: got %d, want %d\n", line, save_errno, eno);
    err = 1;
  }
#endif
  return err;
}
int ldexp_test2(double inp, int e, double expect, int eno, int line)
{
//  if (isnan(inp))
//    return ldexp_test(inp, e, expect, eno, line);
  return ldexp_test(inp, e, expect, eno, line) + ldexp_test(-inp, e, -expect, eno, line);
}
#define TESTLDE(x, e, r) (errors+=ldexp_test2(x, e, r, 0, __LINE__))
#define TESTLDE_E(x, e, r) (errors+=ldexp_test2(x, e, r, ERANGE, __LINE__))

int ldexpf_test(float inp, int e, float expect, int eno, int line)
{
  errno = 0;
  float actual = ldexpf(inp, e);
  int save_errno = errno;
  int err = 0;
  if (copysignf(1.0f, actual) != copysignf(1.0f, expect))
  {
    printf("ldexpf line %d: Signs don't match: got %.6a, want %.6a\n", line, actual, expect);
    err = 1;
  }
  if ((!isnan(actual) || !isnan(expect)) && (actual != expect))
  {
    printf("ldexpf line %d: Values don't match: got %.6a, want %.6a\n", line, actual, expect);
    err = 1;
  }
#ifndef IGNORE_ERRNO
  if (save_errno != eno)
  {
    printf("ldexpf line %d: ERRNO: got %d, want %d\n", line, save_errno, eno);
    err = 1;
  }
#endif
  return err;
}
int ldexpf_test2(double inp, int e, double expect, int eno, int line)
{
  return ldexpf_test(inp, e, expect, eno, line) + ldexpf_test(-inp, e, -expect, eno, line);
}
#define TESTLDF(x, e, r) (errors+=ldexpf_test2(x, e, r, 0, __LINE__))
#define TESTLDF_E(x, e, r) (errors+=ldexpf_test2(x, e, r, ERANGE, __LINE__))

int main()
{
  int errors = 0;

  ldexp_test(0x1.2340000000000p-1022, -36, 0x0.0000000012340p-1022,0,__LINE__);
  // Normal to normal
  TESTLDE  (0x1.p0, 0, 0x1.p0);
  TESTLDE  (0x1.p0, 1, 0x1.p1);
  TESTLDE  (0x1.p-200, 200, 0x1.p0);
  TESTLDE  (0x1.p200, -200, 0x1.p0);
  TESTLDE  (0x1.ABCD34560F2E1p-1000, -22, 0x1.ABCD34560F2E1p-1022);

  // Overflow/underflow of exponent
  TESTLDE_E(0x1.p-1000, 2147483647, HUGE_VAL);
  TESTLDE_E(0x1.p+1000, 2147483647, HUGE_VAL);
  TESTLDE_E(0x1.p-1000, -2147483648, 0.);
  TESTLDE_E(0x1.p+1000, -2147483648, 0.);

  // Normal to denormal
  TESTLDE  (0x1.2345678000000p-1022, -12, 0x0.0012345678000p-1022);
  TESTLDE  (0x1.2340000000000p-1022, -20, 0x0.0000123400000p-1022);
  TESTLDE  (0x1.2340000000000p-1022, -28, 0x0.0000001234000p-1022);
  TESTLDE  (0x1.2340000000000p-1022, -36, 0x0.0000000012340p-1022);
  TESTLDE  (0x1.2340000000000p-1022, -40, 0x0.0000000001234p-1022);
  // Denormal to denormal
  TESTLDE  (0x0.ABCD34560F2E1p-1022, 0, 0x0.ABCD34560F2E1p-1022);
  // Denormal to normal
  TESTLDE  (0x0.ABCD34560F2E1p-1022, 1, 0x0.ABCD34560F2E1p-1021);
  TESTLDE  (0x0.ABCD34560F2E1p-1022, 1022, 0x0.ABCD34560F2E1p0);
  TESTLDE  (0x0.0000000ABCD34p-1022, 1022, 0x0.0000000ABCD34p0);
  TESTLDE  (0x0.0000000000ABCp-1022, 1022, 0x0.0000000000ABCp0);
  TESTLDE  (0x0.ABCD34560F2E1p-1022, 1022, 0x0.ABCD34560F2E1p0);
  // Denormal to denormal, loss of precision
  TESTLDE_E(0x0.ABCD34560F2E1p-1022, -1, 0x0.ABCD34560F2E0p-1023);
  TESTLDE_E(0x0.0000000ABCD34p-1022, -8, 0x0.000000000ABCDp-1022);
  TESTLDE_E(0x0.0000000000AB3p-1022, -4, 0x0.00000000000ABp-1022);
  // Normal to denormal, loss of precision
  TESTLDE_E(0x1.ABCD34560F2E1p-1022, -4, 0x0.1ABCD34560F2Ep-1022);
  TESTLDE_E(0x1.2340000000000p-1022, -44, 0x0.0000000000123p-1022);
  TESTLDE_E(0x1.2300000000001p-1022, -44, 0x0.0000000000123p-1022);
  // Rounding test
  TESTLDE_E(0x1.2280000000000p-1022, -44, 0x0.0000000000122p-1022);
  TESTLDE_E(0x1.2280000000001p-1022, -44, 0x0.0000000000123p-1022);
  TESTLDE_E(0x1.22C0000000000p-1022, -44, 0x0.0000000000123p-1022);
  TESTLDE_E(0x1.2380000000000p-1022, -44, 0x0.0000000000124p-1022);
  TESTLDE_E(0x1.0000000012280p-1022, -8, 0x0.0100000000122p-1022);
  TESTLDE_E(0x1.0000000012281p-1022, -8, 0x0.0100000000123p-1022);
  TESTLDE_E(0x1.0000000012380p-1022, -8, 0x0.0100000000124p-1022);
  TESTLDE_E(0x1.0000000012381p-1022, -8, 0x0.0100000000124p-1022);

  // Infinity and NaN
  TESTLDE  (NAN, 12, NAN);
  TESTLDE  (HUGE_VAL, 12, HUGE_VAL);

  // Single-precision tests
  // Normal to normal
  TESTLDF  (0x1.p0f, 0, 0x1.p0f);
  TESTLDF  (0x1.p0f, 1, 0x1.p1f);
  TESTLDF  (0x1.p-20f, 20, 0x1.p0f);
  TESTLDF  (0x1.p20f, -20, 0x1.p0f);
  TESTLDF  (0x1.ABCD36p-120f, -6, 0x1.ABCD36p-126f);
  TESTLDF  (0x1.ABCD36p+120f, 7, 0x1.ABCD36p+127f);
  // Special case
  TESTLDF_E(0x1.FFFFFEp-126, -1, 0x1.000000p-126);

  // Overflow/underflow of exponent
  TESTLDF_E(0x1.p-30f, 2147483647, HUGE_VALF);
  TESTLDF_E(0x1.p+30f, 2147483647, HUGE_VALF);
  TESTLDF_E(0x1.p-30f, -2147483647, 0.f);
  TESTLDF_E(0x1.p+30f, -2147483647, 0.f);

  // Normal to denormal
  TESTLDF  (0x1.234000p-126f, -12, 0x0.001234p-126f);
  // Denormal to denormal
  TESTLDF  (0x0.876000p-126f, -12, 0x0.000876p-126f);
  // Denormal to normal
  TESTLDF  (0x0.ABCD56p-126f, 1, 0x0.ABCD56p-125f);
  // Denormal to denormal, loss of precision
  TESTLDF_E(0x0.ABCD56p-126f, -1, 0x0.ABCD58p-127f);
  // Normal to denormal, loss of precision
  TESTLDF_E(0x1.ABCD56p-126f, -4, 0x0.1ABCD6p-126f);
  TESTLDF_E(0x1.234000p-126f, -16, 0x0.000124p-126f);
  TESTLDF_E(0x1.001000p-126f, -12, 0x0.001000p-126f);
  TESTLDF_E(0x1.001002p-126f, -12, 0x0.001002p-126f);
  TESTLDF_E(0x1.003000p-126f, -12, 0x0.001004p-126f);
  TESTLDF_E(0x1.005000p-126f, -12, 0x0.001004p-126f);

  if (errors)
    printf("* %d failed tests\n", errors);
  else
    puts("* PASS");
  return 0;
}
