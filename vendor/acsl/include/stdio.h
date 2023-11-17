/*
 * stdio.h implementation for GBA
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
#ifndef __INCLUDED_STDIO_H__
#define __INCLUDED_STDIO_H__

#include <stdarg.h>
#include <stddef.h>
#include <errno.h>


#ifndef SEEK_SET
#define SEEK_SET 0
#endif
#ifndef SEEK_CUR
#define SEEK_CUR 1
#endif
#ifndef SEEK_END
#define SEEK_END 2
#endif
#define _IOFBF 0
#define _IOLBF 1
#define _IONBF 2

#define TMP_MAX 20
#define BUFSIZ 1024
#define EOF (-1)
#define FOPEN_MAX 0
#define FILENAME_MAX 31
#define L_tmpnam 12

typedef struct { int _fileno; } FILE;
typedef int fpos_t;

extern FILE *stdin;
extern FILE *stdout;
extern FILE *stderr;

#define fileno(fptr) ((fptr)->_fileno-0xBADBEEF)

int remove(const char *filename);
int rename(const char *old, const char *new);
FILE *tmpfile(void);
char *tmpnam(char *s);
int fclose(FILE *stream);
int fflush(FILE *stream);
FILE *fopen(const char *restrict filename, const char *restrict mode);
FILE *freopen(const char *restrict filename, const char *restrict mode,
  FILE *restrict stream);
void setbuf(FILE *restrict stream, char *restrict buf);
int setvbuf(FILE *restrict stream, char *restrict buf, int mode, size_t size);
int fprintf(FILE *restrict stream, const char *restrict format, ...);
int fscanf(FILE *restrict stream, const char *restrict format, ...);
int printf(const char *restrict format, ...);
int scanf(const char *restrict format, ...);
int snprintf(char *restrict s, size_t n, const char *restrict format, ...);
int sprintf(char *restrict s, const char *restrict format, ...);
int sscanf(const char *restrict s, const char *restrict format, ...);
int vfprintf(FILE *restrict stream, const char *restrict format, va_list arg);
int vfscanf(FILE *restrict stream, const char *restrict format, va_list arg);
int vprintf(const char *restrict format, va_list arg);
int vscanf(const char *restrict format, va_list arg);
int vsnprintf(char *restrict s, size_t n, const char *restrict format,
  va_list arg);
int vsprintf(char *restrict s, const char *restrict format, va_list arg);
int vsscanf(const char *restrict s, const char *restrict format, va_list arg);
int fgetc(FILE *stream);
char *fgets(char *restrict s, int n, FILE *restrict stream);
int fputc(int c, FILE *stream);
int fputs(const char *restrict s, FILE *restrict stream);
int getc(FILE *stream);
int getchar(void);
char *gets(char *s);
#define putc(c, stream) fputc(c, stream)
int putchar(int c);
int puts(const char *s);
int ungetc(int c, FILE *stream);
size_t fread(void *restrict ptr, size_t size, size_t nmemb,
  FILE *restrict stream);
size_t fwrite(const void *restrict ptr, size_t size, size_t nmemb,
  FILE *restrict stream);
int fgetpos(FILE *restrict stream, fpos_t *restrict pos);
int fseek(FILE *stream, long int offset, int whence);
int fsetpos(FILE *stream, const fpos_t *pos);
long int ftell(FILE *stream);
void rewind(FILE *stream);
void clearerr(FILE *stream);
int feof(FILE *stream);
int ferror(FILE *stream);
void perror(const char *s);


#endif // __INCLUDED_STDIO_H__
