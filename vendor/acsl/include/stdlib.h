/*
 * stdlib.h implementation for GBA
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
#ifndef __INCLUDED_STDLIB_H__
#define __INCLUDED_STDLIB_H__

#include <stddef.h>

#define RAND_MAX 0x7FFFFFFF

typedef struct { int quot; int rem; } div_t;
typedef struct { long quot; long rem; } ldiv_t;
typedef struct { long long quot; long long rem; } lldiv_t;

void *malloc(size_t size);
void free(void *ptr);
void *calloc(size_t nmemb, size_t size);
void *realloc(void *ptr, size_t size);

void exit(int status);
void abort(void);

int atexit(void (*callback)(void));
char *getenv(const char *name);
int system(const char *string);

int rand(void);
void srand(unsigned int seed);

int abs(int n);
long int labs(long int n);
long long int llabs(long long int n);

div_t div(int numer, int denom);
ldiv_t ldiv(long int numer, long int denom);
lldiv_t lldiv(long long int numer, long long int denom);

long strtol(const char *restrict s, char **restrict endp, int base);
long long strtoll(const char *restrict s, char **restrict endp, int base);
unsigned long strtoul(const char *restrict s, char **restrict endp, int base);
unsigned long long strtoull(const char *restrict s, char **restrict endp,
  int base);
int atoi(const char *s);
long int atol(const char *s);
long long int atoll(const char *s);

float strtof(const char *restrict s, char **restrict endp);
double strtod(const char *restrict s, char **restrict endp);
long double strtold(const char *restrict s, char **restrict endp);


#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1
#define MB_CUR_MAX 1

#endif // __INCLUDED_STDLIB_H__
