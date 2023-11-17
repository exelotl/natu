/*
 * ldexpf() implementation for GBA
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

		.include "errnos.inc"

		.global	ldexpf

		.text
		.thumb

@ double ldexp(double n, int e);
@ long double ldexpl(long double n, int e);

ldexpf:		lsls	r3,r0,1		@ Remove sign bit
		beq	unchanged	@ Return unchanged mantissa if zero
		cmp	r1,0
		beq	unchanged	@ Fast-track the case e = 0
		lsrs	r3,24		@ Exponent in R3
		lsls	r3,23		@ Shift it to position of exponent
		bics	r0,r3		@ Clear exponent bits
		lsrs	r3,23		@ Shift it back
		beq	denormal_input	@ If exponent == 0, it's denormal
normal_input:	cmp	r3,0xFF		@ exponent = 0xFF?
		beq	infnan		@ if so, return the input unchanged

		adds	r3,r1		@ add the e arg to the exponent
		bvs	overunder	@ if overflow, R1 is the original
					@ amount to change and will tell us
					@ the direction of the over/underflow
		ble	denormal_output
		movs	r1,r3		@ required for overunder
		cmp	r3,0xFF		@ output exponent >= 0xFF?
		bhs	overunder	@ overflow if so

		@ Normal case, at last! Replace exponent with the new one.
		lsls	r3,23
		orrs	r0,r3
		bx	lr

		@ R1 negative means underflow; else overflow
overunder:	lsrs	r0,31		@ Clear bits 0-30, preserve sign bit
		lsls	r0,31
		movs	r3,0		@ set exp for zero
		cmp	r1,0		@ check if underflow
		blt	1f		@ if so, exponent 0 is fine
		movs	r3,0xFF		@ set exp for INF
1:		ldr	r1,=errno	@ set errno
		movs	r2,ERANGE
		str	r2,[r1]
infnan:		lsls	r3,23		@ shift exponent to place
		orrs	r0,r3		@ set exponent
unchanged:	bx	lr

		@ Denormal input - normalize it (producing exp <= 0)
denormal_input:	adds	r3,1		@ compensate exponent encoding
		lsrs	r2,r0,31	@ R2 = sign bit
		lsls	r2,31
		lsls	r0,9		@ move bit 22 to bit 31
1:		subs	r3,1		@ dec exponent
		adds	r0,r0		@ shift mantissa
		bcc	1b		@ loop if first 1 not yet shifted out
		lsrs	r0,9		@ move mantissa back to its position
		orrs	r0,r2		@ place sign back
		b	normal_input

denormal_output:
		movs	r1,r3		@ for overunder
		movs	r2,23		@ guard against too negative exponent
		cmn	r3,r2
		blt	overunder

		movs	r2,1
		lsls	r2,23
		orrs	r0,r2		@ Implicit bit is now explicit

		movs	r2,2
		subs	r2,r3		@ Total number to rshift: 2 - exp
					@ (1 - exp + 1 for the sign bit)
		adds	r3,31		@ R3 = lshift count
		movs	r1,r0
		lsls	r1,r3		@ R1 = bits shifted out
		beq	1f		@ if all shifted bits = 0, no errno
		movs	r3,ERANGE
		push	{r1}
		ldr	r1,=errno	@ set errno
		str	r3,[r1]
		pop	{r1}
1:
		lsrs	r3,r0,31	@ preserve sign in R3
		lsls	r3,31
		lsls	r0,1		@ clear sign in R0
		lsrs	r0,r2		@ denormalize
		orrs	r0,r3		@ add sign back
		adds	r1,r1		@ check rounding bit
		bcc	unchanged	@ round down if zero
		bne	1f		@ if nonzero bits, round up
		lsrs	r2,r0,1		@ tie; check parity
		bcc	unchanged	@ round down if even
1:		adds	r0,1		@ Round up. If the mantissa overflows
					@ at this point, the result is still
					@ right (by chance).
		bx	lr

		.ltorg
