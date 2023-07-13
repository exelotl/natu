/*
 * acsl.h - Library's function prototypes
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
#ifndef __INCLUDED_ACSL_H__
#define __INCLUDED_ACSL_H__

extern unsigned acsl_col;
extern unsigned acsl_row;
extern size_t acsl_FreeList;
extern const char *acsl_prefixStr;
extern const char *acsl_rawStr;
extern size_t acsl_rawStrLen;

void acsl_err(const char *msg);
void acsl_errWait(const char *msg);
void acsl_errFormatted(const char *fmt, va_list v);
void acsl_errFmtWait(const char *fmt, va_list v);
unsigned acsl_waitKeyRelease(unsigned key);
unsigned acsl_waitKeyReleaseAllOf(unsigned keys);
unsigned acsl_waitKeyReleaseAnyOf(unsigned keys);
unsigned acsl_waitKeyPress(unsigned key);
unsigned acsl_waitKeyPressAnyOf(unsigned keys);
unsigned acsl_waitKeyPressAllOf(unsigned keys);
void acsl_waitVBlankStart(void);
void acsl_waitVBlankEnd(void);
void acsl_renderChar(const void *ptr, const char *text, unsigned short colour);
void acsl_putChar(char c);
void acsl_printText(const char *text);
void acsl_printRawText(const char *text, size_t len);
void acsl_GetMem(size_t size);
void acsl_FreeMem(void *ptr, size_t size);
void acsl_initMemMgr(void);
int acsl_setErrno(int value);

#endif // __INCLUDED_ACSL_H__
