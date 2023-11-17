/*
 * strtoull implementation for GBA
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

		.global	strtoull
		.global	strtoumax

		.include "errnos.inc"

		.section .text.f.strtoull
		.thumb

@ long strtoull(const char *restrict nptr, char **restrict endptr, int base);

strtoumax:	@ alias of strtoull

strtoull:	ldr	r3,=acsl_numParse+1
		mov	r12,r3
		movs	r3,acsl_strtoullFunc+1-(.+6)
		add	r3,pc
		bx	r12

baseFromNum:	movs	r3,10		@ set base to 10
		mov	r12,r3
		cmp	r1,'0'
		bne	nextDigit
1:
		movs	r5,r2		@ '0' is a valid digit
		ldrb	r1,[r2]
		adds	r2,1		@ consume '0'
		movs	r3,8		@ set base to 8
		mov	r12,r3
		cmp	r1,'X'
		beq	1f
		cmp	r1,'x'
		bne	nextDigit
1:
		movs	r3,16		@ set base to 16
		mov	r12,r3
		ldrb	r1,[r2]
		adds	r2,1		@ consume the 'X' or 'x'
		b	nextDigit

acsl_strtoullFunc:
		push	{r6,lr}
		movs	r6,0		@ clear high word
		mov	r3,r12
		cmp	r3,0
		beq	baseFromNum
		cmp	r3,16		@ if hex, 0x is permitted
		bne	nextDigit
		cmp	r1,'0'
		bne	nextDigit
		movs	r5,r2		@ '0' is a valid digit
		ldrb	r1,[r2]
		adds	r2,1		@ consume '0'
		cmp	r1,'X'
		beq	1f
		cmp	r1,'x'
		bne	nextDigit
1:		ldrb	r1,[r2]
		adds	r2,1		@ consume 'X' or 'x'
nextDigit:
		cmp	r1,'0'
		blo	badDigit
		cmp	r1,'9'
		bls	checkBase
		cmp	r1,'A'
		blo	badDigit
		movs	r3,0x20
		bics	r1,r3
		cmp	r1,'A'
		blo	badDigit
		cmp	r1,'Z'
		bls	checkBaseAZ

badDigit:	movs	r1,r6
		pop	{r2,r3}
		movs	r6,r2
		mov	lr,r3
		ldr	r3,=acsl_applySign+1
		bx	r3

checkBaseAZ:	subs	r1,'A'-('9'+1)
checkBase:	subs	r1,'0'
		cmp	r1,r12
		bhs	badDigit	@ Jump if char >= base
		movs	r5,r2		@ Valid digit found, point past it

		@ Switch to ARM mode to use umull, to do the 64-bit multiply
		bx	pc
		.balign	4
		.arm

		umull	r0,r3,r12,r0
		umull	r6,lr,r12,r6
		adds	r6,r3
		adcs	lr,0

		add	lr,pc,1
		bx	lr
		.thumb
		bne	overflow

		movs	r3,0
		adds	r0,r1		@ add digit
		adcs	r6,r3
		bcs	overflow	@ jump if wraparound
1:		ldrb	r1,[r2]
		adds	r2,1
		b	nextDigit

overflow:	ldr	r1,=errno
		movs	r6,ERANGE
		str	r6,[r1]
		subs	r6,ERANGE+1	@ set R6 t0 0xFFFFFFFF
		movs	r0,r6		@ copy to R0
		movs	r4,0		@ don't negate on exit
		b	1b
