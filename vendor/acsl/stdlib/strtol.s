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

@ strtol and strtoul are very similar, but trying to fuse them in a single
@ function would make the code longer, slower and harder to understand.

		.syntax	unified
		.cpu	arm7tdmi

		.global	strtol
		.global	atoi
		.global	atol

		.include "errnos.inc"

		.section .text.f.strtol
		.thumb

@ long strtol(const char *restrict nptr, char **restrict endptr, int base);

strtol:		ldr	r3,=acsl_numParse+1
		mov	r12,r3
		cmp	r2,10
		beq	1f
		cmp	r2,8
		beq	8f
		movs	r3,acsl_strtolFunc+1-(.+6)
		add	r3,pc
		bx	r12
atoi:
atol:
		movs	r1,0
1:		movs	r3,acsl_lDecimalFunc+1-(.+6)
		add	r3,pc
		bx	r12
8:		movs	r3,acsl_lOctalFunc+1-(.+6)
		add	r3,pc
		bx	r12

acsl_strtolFunc:
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

badDigit:	ldr	r3,=acsl_applySign+1
		bx	r3

checkBaseAZ:	subs	r1,'A'-('9'+1)
checkBase:	subs	r1,'0'
		cmp	r1,r12
		bhs	badDigit	@ Jump if char >= base
		movs	r5,r2		@ Valid digit found, point past it

		@ Switch to ARM mode to use umull, as we have no shorter way
		@ of checking for overflow
		bx	pc
		.balign	4
		.arm

		umull	r0,r3,r12,r0
		cmp	r3,0

		add	r3,pc,1
		bx	r3
		.thumb
		bne	overflow

		adds	r0,r1		@ add digit
		bcs	overflow	@ jump if wraparound
		@ The result must be between 0 and 0x7FFFFFFFF if positive,
		@ and between 0 and 0x80000000 if negative
		bmi	chkMore		@ jump if >= 0x80000000

1:		ldrb	r1,[r2]
		adds	r2,1
		b	nextDigit

chkMore:	cmn	r0,r4		@ add 1 if negative; OK if it
		bpl	1b		@ was 0x80000000 and now 0x7FFFFFFF;
					@ otherwise fall through to overflow

overflow:	ldr	r1,=errno
		movs	r0,ERANGE
		str	r0,[r1]
		subs	r0,ERANGE+1	@ set R0 t0 0xFFFFFFFF
		lsrs	r0,1		@ shift R0 to get 0x7FFFFFFF=LONG_MAX
		subs	r0,r4		@ if negative, set it to LONG_MIN
		b	1b

baseFromNum:	cmp	r1,'0'
		bne	acsl_lDecimalFunc
1:
		movs	r5,r2		@ '0' is a valid digit
		ldrb	r1,[r2]
		adds	r2,1		@ consume '0'
		cmp	r1,'X'
		beq	1f
		cmp	r1,'x'
		bne	acsl_lOctalFunc
1:
		movs	r3,16		@ set base to 16
		mov	r12,r3
		ldrb	r1,[r2]
		adds	r2,1		@ consume the 'X' or 'x'
		b	nextDigit

		@ Signed decimal is fairly simple
acsl_lDecimalFunc:
		ldr	r3,=214748364
		mov	r12,r3
2:		subs	r1,'0'
		blo	badDigit
		cmp	r1,9
		bhi	badDigit
		movs	r5,r2		@ valid digit found
		cmp	r0,r12		@ R12*10 is the overflow threshold
		bhi	0f		@ if higher, we're in trouble
		lsls	r3,r0,2		@ *4
		adds	r0,r3		@ *5
		lsls	r0,1		@ *10
		adds	r0,r1		@ +digit
		bpl	1f		@ if positive, all good
		cmn	r0,r4		@ Test if R0 is also negative after
		bmi	0f		@ adding -sign. If so, overflow.
1:		ldrb	r1,[r2]
		adds	r2,1		@ consume digit
		b	2b

		@ overflow
0:		ldr	r1,=errno
		movs	r0,ERANGE
		str	r0,[r1]
		subs	r0,ERANGE+1	@ set R0 t0 0xFFFFFFFF
		lsrs	r0,1		@ shift R0 to get 0x7FFFFFFF=LONG_MAX
		subs	r0,r4		@ if negative, set it to LONG_MIN
		b	1b

		@ Signed octal is short too
acsl_lOctalFunc:
2:		subs	r1,'0'
		blo	badDigit
		cmp	r1,7
		bhi	badDigit
		movs	r5,r2		@ valid digit found
		@ This overflow check is kinda tricky
		lsrs	r3,r0,29	@ check if we'll shift out zeros
		bne	0f		@ if not, we're in trouble
		bcc	1f		@ if bit 28 was 0, we're clear
		cmp	r4,0		@ check sign
		bpl	0f		@ if positive, overflow for sure
		lsls	r3,r0,4		@ are the other bits zero?
		bne	0f		@ if not, overflow
		cmp	r1,0		@ is the incoming digit a zero?
		bne	0f		@ if not, overflow
1:
		lsls	r0,3
		adds	r0,r1
1:		ldrb	r1,[r2]
		adds	r2,1		@ consume digit
		b	2b

		@ overflow
0:		ldr	r1,=errno
		movs	r0,ERANGE
		str	r0,[r1]
		subs	r0,ERANGE+1	@ set R0 t0 0xFFFFFFFF
		lsrs	r0,1		@ shift R0 to get 0x7FFFFFFF=LONG_MAX
		subs	r0,r4		@ if negative, set it to LONG_MIN
		b	1b


		.ltorg
