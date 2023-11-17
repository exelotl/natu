/*
 * snprintf implementation for GBA
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

		.global	snprintf
		.global	vsnprintf

		.text
		.thumb

		@ snprintf character output function
snprintf_outfn:	ldr	r1,=bufptr
		ldr	r2,[r1,4]	@ cnt
		cmp	r7,r2		@ R7 = 1+# chars output from formatStr
		bhs	bxlr		@ opportunity for early termination

		ldr	r2,[r1]
		strb	r0,[r2]
		adds	r2,1
		str	r2,[r1]
bxlr:		bx	lr

@ int snprintf(char *str, size_t size, const char *format, ...);

snprintf:	push	{r3}		@ all args contiguous in the stack
		mov	r3,sp		@ va_list pointer
		push	{lr}
		bl	vsnprintf
		pop	{r1,r3}
		bx	r1

@ int vsnprintf(char *str, size_t size, const char *format, va_list v);

vsnprintf:	mov	r12,r3
		cmp	r1,0
		beq	justCount	@ zero length is treated especially
		ldr	r3,=bufptr
		str	r0,[r3]		@ buffer ptr for callback
		str	r1,[r3,4]	@ buffer cnt for callback
		ldr	r0,=snprintf_outfn+1	@ output function
		movs	r1,r2		@ 3rd arg received is 2nd arg passed
		mov	r2,r12
		push	{lr}
		bl	acsl_formatStr
		pop	{r1}
		ldr	r2,=bufptr
		ldr	r2,[r2]
		movs	r3,0
		strb	r3,[r2]		@ add NULL terminator
		bx	r1

justCount:	ldr	r0,=bxlr+1
		movs	r1,r2
		mov	r2,r12
		push	{lr}
		bl	acsl_formatStr
		pop	{r1}
		bx	r1

		.ltorg

		.section .bss

bufptr:		.space	4
cnt:		.space	4
