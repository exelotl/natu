/*
 * math.h implementation for GBA
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
#ifndef __INCLUDED_MATH_H__
#define __INCLUDED_MATH_H__

#define M_PI 3.141592653589793

typedef float float_t;
typedef double double_t;

float fabsf(float x);
double fabs(double x);
long double fabsl(long double x);

float copysignf(float dest, float src);
double copysign(double dest, double src);
long double copysignl(long double dest, long double src);
#ifdef __thumb__
int __isnanf_thumb(float x);
int __isnan_thumb(float x);
#  define isnan(x) (sizeof(x)==4?__isnanf_thumb(x):__isnan_thumb(x))
#else
int __isnanf_arm(double x);
int __isnan_arm(double x);
#  define isnan(x) (sizeof(x)==4?__isnanf_arm(x):__isnan_arm(x))
#endif

float nanf(const char *s);
double nan(const char *s);
long double nanl(const char *s);

float ldexpf(float x, int e);
double ldexp(double x, int e);
long double ldexpl(long double x, int e);

#define HUGE_VAL (__builtin_huge_val())
#define HUGE_VALF (__builtin_huge_valf())
#define HUGE_VALL (__builtin_huge_vall())
#define INFINITY (__builtin_inff())
#define NAN (__builtin_nanf(""))

#define MATH_ERRNO 1
#define MATH_ERREXCEPT 2
#define math_errhandling MATH_ERRNO

#define FP_NAN 0
#define FP_INFINITE 1
#define FP_ZERO 2
#define FP_SUBNORMAL 3
#define FP_NORMAL 4

#define FP_ILOGB0 (-2147483647)
#define FP_ILOGBNAN 2147483647

/* Macros that we should leave undefined */
// #undef FP_FAST_FMAF
// #undef FP_FAST_FMA
// #undef FP_FAST_FMAL

#endif // __INCLUDED_MATH_H__
