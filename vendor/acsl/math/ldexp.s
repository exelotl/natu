/*
 * ldexp() implementation for GBA
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

		.global	ldexp

		.text
		.thumb

@ double ldexp(double n, int e);
@ long double ldexpl(long double n, int e);

ldexpl:
ldexp:		mov	r12,r4
		cmp	r2,0
		beq	unchanged	@ Fast-track the case e = 0
		lsls	r3,r1,1
		beq	denormal_low	@ Denormal or zero; bits 32-51 are 0
		lsrs	r3,21
		lsls	r3,20
		bics	r1,r3		@ Clear exponent bits
		lsrs	r3,20		@ Exponent in R3
		beq	denormal_input	@ If exponent != 0, process normally

normal_input:	adds	r4,r3,1
		asrs	r4,11
		cmp	r4,1		@ exponent = 0x7FF?
		beq	infnan		@ if so, return the input unchanged

		adds	r3,r2		@ add the e arg to the exponent
		bvs	overunder	@ if overflow, R2 is the original
					@ amount to change and will tell us
					@ the direction of the overflow
		ble	denormal_output
		movs	r2,r3		@ required for overunder
		adds	r4,r2,1
		asrs	r4,11
		cmp	r4,1		@ output exponent >= 0x7FF?
		bhs	overunder	@ if positive, this means overflow

		@ Normal case, at last! Replace the exponent with the new one.
		lsls	r2,20
		orrs	r1,r2
		mov	r4,r12
		bx	lr

		@ R2 negative means underflow; else overflow
overunder:	movs	r0,0
		movs	r3,0
		lsrs	r1,31		@ set to 0 preserving sign bit
		lsls	r1,31
		cmp	r2,0
		blt	1f
		movs	r3,1
		lsls	r3,11
		subs	r3,1		@ R3 = 0x7FF
1:		ldr	r2,=errno
		movs	r4,ERANGE
		str	r4,[r2]
infnan:		lsls	r3,20
		orrs	r1,r3
unchanged:	mov	r4,r12
		bx	lr

denormal_low:
		cmp	r0,0
		beq	unchanged

		@ Avoid N loop iterations if they aren't necessary
		@ (N should be <= 20)
N		= 20
		lsrs	r4,r0,32-N
		beq	lowN
		subs	r3,N
		orrs	r1,r4
		lsls	r0,N
		b	denormal_input

lowN:		orrs	r1,r0
		subs	r3,32
		movs	r0,0
		@ fall through to denormal_input

		@ Denormal input - normalize it (producing exp <= 0)
denormal_input:	adds	r3,1		@ compensate exponent encoding
		lsls	r4,r1,1
		adcs	r3,r3		@ R3 = R3 * 2 + sign bit
1:		adds	r0,r0
		adcs	r1,r1
		subs	r3,2		@ dec exponent 1-31 (bit 0 is sign)
		lsrs	r4,r1,52-32	@ did the '1' reach the Normal bit?
		beq	1b		@ loop if not yet
		lsls	r1,12		@ clear implicit bit...
		lsrs	r1,12		@ ... and move back to place
		lsls	r4,r3,31	@ sign bit
		orrs	r1,r4		@ place it back
		asrs	r3,1		@ remove it from exponent
		b	normal_input

denormal_output:
		movs	r2,r3
		movs	r4,52
		cmn	r3,r4
		blt	overunder

		movs	r4,1
		lsls	r4,52-32
		orrs	r1,r4		@ Implicit bit is now explicit

		movs	r4,1
		subs	r4,r3		@ Total number to shift: 1 - exp
		movs	r3,r4
		subs	r3,32
		blo	2f

		@ 32 bits or more to shift, all bits from R1 go to R0 and
		@ R1 is cleared (except sign)
		movs	r4,32
		subs	r4,r3		@ R4 = amount to lshift
		movs	r2,r1
		lsls	r2,r4		@ Do we shift out any 1's?
		adds	r2,r2
		orrs	r2,r0		@ The whole of R0 is shifted out,
					@ so it must be counted too
		bcs	3f		@ if rounding bit set, set ERANGE
		beq	1f		@ skip if no 1's are shifted out
3:		beq	3f
		movs	r2,1		@ signal that there are nonzero bits
3:		adcs	r2,r2		@ Carry comes from `adds r2,r2` above
		movs	r4,ERANGE
		push	{r2}
		ldr	r2,=errno	@ set errno
		str	r4,[r2]
		pop	{r2}

1:		movs	r0,r1
		lsls	r0,1		@ clear sign bit
		lsrs	r0,1
		lsrs	r0,r3		@ Shift
		lsrs	r1,31		@ Preserve sign bit, rest zeros
		lsls	r1,31
		@ Rounding
		lsrs	r2,1		@ R2 contains the rounding data
		@ Enter here with Carry = rounding bit, NZ if nonzero
		@ bits remain after rounding bit
roundit:	bcc	unchanged
		bne	1f		@ if any nonzero bits remained
		lsrs	r4,r0,1		@ tie; check parity
		bcc	unchanged
1:		movs	r4,0
		adds	r0,1
		adcs	r1,r4
		mov	r4,r12
		bx	lr

		@ Less than 32 bits to shift
2:		movs	r3,32
		subs	r3,r4
		movs	r2,r0
		lsls	r2,r3		@ R2 = bits shifted out
		push	{r2}
		beq	1f		@ if not, life is good
		movs	r3,ERANGE
		ldr	r2,=errno	@ set errno
		str	r3,[r2]
		movs	r3,32		@ calculate R3 again as it's lost now
		subs	r3,r4
1:
		lsrs	r0,r4
		movs	r2,r1
		lsls	r2,r3
		orrs	r0,r2
		lsls	r1,1		@ get and clear sign bit
		adcs	r2,r2		@ place sign bit in bit 0 of R2
		lsrs	r1,1
		lsrs	r1,r4
		lsls	r2,31		@ move sign bit into place
		orrs	r1,r2
		pop	{r2}
		lsls	r2,1		@ move rounding bit to carry
		b	roundit


		.ltorg
