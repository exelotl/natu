/*
 * strtol implementation for GBA
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

		.global	acsl_numParse
		.global	acsl_applySign

		.include "errnos.inc"

		.section .text.f.acsl_numParse
		.thumb

acsl_numParse:	push	{r1,r4,r5,lr}
		movs	r4,0		@ R4 = -1 if minus sign, 0 if not
		mov	r12,r2
		movs	r2,r0
		movs	r0,0		@ initial return value
		movs	r5,r2		@ points after last valid digit, or
					@ beginning of string if none found
		@ Skip initial whitespace
1:		ldrb	r1,[r2]
		adds	r2,1
		cmp	r1,' '
		beq	1b
		cmp	r1,9
		blo	1f
		cmp	r1,13
		bls	1b
1:
		cmp	r1,'+'
		bne	1f
		ldrb	r1,[r2]
		adds	r2,1		@ consume plus sign
		bx	r3
1:		cmp	r1,'-'
		bne	1f
		subs	r4,1		@ set to -1
		ldrb	r1,[r2]
		adds	r2,1		@ consume minus sign
1:		bx	r3

acsl_applySign:	eors	r0,r4		@ Apply sign to result
		eors	r1,r4
		subs	r0,r4
		sbcs	r1,r4
		movs	r2,r5
		pop	{r3,r4,r5}
		cmp	r3,0
		beq	1f
		str	r2,[r3]		@ Store ptr to first unrecognized char
1:		pop	{r3}
		bx	r3


		.ltorg
