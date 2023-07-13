/*
 * sprintf implementation for GBA
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
		.syntax	unified
		.cpu	arm7tdmi

		.global	sprintf
		.global	vsprintf

		.text
		.thumb

		@ sprintf character output function
sprintf_outfn:	ldr	r1,=bufptr
		ldr	r2,[r1]
		strb	r0,[r2]
		adds	r2,1
		str	r2,[r1]
		bx	lr

@ int sprintf(char *str, const char *format, ...);

sprintf:	push	{r2,r3}		@ all args to the stack
		mov	r2,sp		@ va_list pointer
		push	{lr}
		bl	vsprintf
		ldr	r1,[sp]
		add	sp,12
		bx	r1

@ int vsprintf(char *str, const char *format, va_list v);

vsprintf:	ldr	r3,=bufptr
		str	r0,[r3]
		ldr	r0,=sprintf_outfn+1
		push	{lr}
		bl	acsl_formatStr
		pop	{r1}
		ldr	r2,=bufptr
		ldr	r3,[r2]
		movs	r2,0
		strb	r2,[r3]		@ add NULL terminator
		bx	r1

		.ltorg

		.section .bss

bufptr:		.space	4
