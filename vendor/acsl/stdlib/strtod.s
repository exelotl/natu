/*
 * strtod implementation for GBA
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

		.global	strtod
		.global	strtold

		.text
		.thumb

@ Registers:
@  R1:R0 = float, or mantissa
@  R2 = input pointer; scratch when no longer necessary
@  R3 = input character most of the time; scratch when no longer necessary
@  R4 = scratch register
@  R5 = output pointer
@  R6 = flags
@  R7 = exponent

@ Parsing flags (in R6):
F_POINT		= 0	@ Decimal point seen
F_RESOL		= 1	@ Set if rounding resolved
F_RNDDG		= 2	@ Value of the 54th significant bit
F_NZRND		= 3	@ Nonzero bits found after the 54th
			@ This differs from F_RESOL in that F_RESOL will be
			@ 1 if the rounding digit is 0 even if there's all
			@ zeros after it.
F_NZDIG		= 4	@ Digit != 0 found; while left zeros are found, the
			@ exponent should not increase.
F_NEGXP		= 5	@ negative exponent
F_VALID		= 6	@ Set if there's a valid number
F_ODDEX		= 8	@ Set if the 10 exponent is odd
F_SHFT4		= 9	@ Set if we shifted 4 positions instead of 3 when
			@ exponent is odd


strtold:
strtod:		ldr	r3,=acsl_numParse+1
		mov	r12,r3
		movs	r3,acsl_strtodFunc+1-(.+6)
		add	r3,pc
		bx	r12

checkInf:	movs	r4,'a'^'A'
		ldrb	r3,[r2]
		orrs	r3,r4		@ the 'i' is already there;
		cmp	r3,'n'		@ compare the 'n' and the 'f'
		bne	badKw
		ldrb	r3,[r2,1]
		orrs	r3,r4
		cmp	r3,'f'
		bne	badKw

		adds	r5,r2,2		@ accept "inf"
		ldrb	r3,[r2,2]
		orrs	r3,r4
		cmp	r3,'i'		@ got "inf", check "inity"
		bne	3f
		ldrb	r3,[r2,3]
		orrs	r3,r4
		cmp	r3,'n'
		bne	3f
		ldrb	r3,[r2,4]
		orrs	r3,r4
		cmp	r3,'i'
		bne	3f
		ldrb	r3,[r2,5]
		orrs	r3,r4
		cmp	r3,'t'
		bne	3f
		ldrb	r3,[r2,6]
		orrs	r3,r4
		cmp	r3,'y'
		bne	3f
		adds	r5,r2,7
3:		ldr	r1,=0x7FF00000	@ return infinity
		movs	r0,0
		b	endNumber


checkNaN:	movs	r4,'a'^'A'
		ldrb	r3,[r2]
		orrs	r3,r4		@ the 'n' is already there;
		cmp	r3,'a'		@ check the 'a' and the other 'n'
		bne	badKw
		ldrb	r3,[r2,1]
		orrs	r3,r4
		cmp	r3,'n'
		bne	badKw
		adds	r5,r2,2		@ accept "nan"
		@ Check the BRE "nan([0-9a-z_]*)" (case insensitive)
		ldrb	r3,[r2,2]
		adds	r2,3		@ go past '('
		cmp	r3,'('
		bne	3f
1:		ldrb	r3,[r2]
		adds	r2,1
		cmp	r3,'0'
		blo	2f
		cmp	r3,'9'
		bls	1b
		cmp	r3,'_'
		beq	1b
		orrs	r3,r4
		cmp	r3,'a'
		blo	3f
		cmp	r3,'z'
		bhi	3f
		b	1b
2:		cmp	r3,')'
		bne	3f
		movs	r5,r2		@ accept "nan(xxxx)"
3:		ldr	r1,=0x7FF80000	@ return quiet NaN
		movs	r0,0
		b	endNan

acsl_strtodFunc:
		push	{r4-r7}
		movs	r6,0		@ clear flags
		movs	r7,0		@ R7 = exponent

		movs	r3,r1		@ free R1 to use as 2nd word
		movs	r1,0
		movs	r4,0x20
		orrs	r4,r3
		cmp	r4,'i'
		beq	checkInf
		cmp	r4,'n'
		beq	checkNaN
		cmp	r3,'0'
		beq	3f
2:		b	decimal

badKw:
endNan:
endNumber:	pop	{r2,r3,r6,r7}
		cmp	r5,r3		@ if something accepted, sign is good
		beq	1f		@ otherwise don't apply sign
		lsls	r2,31		@ sign must be in highest bit only
		orrs	r1,r2		@ set sign in result
1:		movs	r4,0		@ don't apply the integer sign
		ldr	r2,=acsl_applySign+1
		bx	r2

3:
		movs	r5,r2		@ '0' is a valid digit
		movs	r4,1<<F_VALID	@ Set digit valid in case we branch
		orrs	r6,r4		@ to decimal
		ldrb	r3,[r2]
		adds	r2,1
		movs	r4,0x20
		orrs	r4,r3
		cmp	r4,'x'
		bne	2b
		movs	r4,1<<F_VALID	@ Not branched to decimal; clear
		bics	r6,r4		@ valid digit bit

		@ Hex float

hexDigit:	ldrb	r3,[r2]
		adds	r2,1
		cmp	r3,'.'
		beq	XpointFound
		cmp	r3,'0'
		blo	2f
		cmp	r3,'9'
		bls	1f
		movs	r4,'a'^'A'
		orrs	r3,r4
		cmp	r3,'p'
		beq	binExp
		cmp	r3,'a'
2:		blo	endNumberX
		cmp	r3,'f'
		bhi	endNumberX
		subs	r3,'a'-('9'+1)
1:		subs	r3,'0'
		movs	r5,r2		@ valid digit found
		movs	r4,1<<F_VALID
		orrs	r6,r4
		lsrs	r4,r6,F_POINT+1	@ point present?
		bcc	3f		@ jump if not

		@ Handle digits after the point
		lsrs	r4,r6,F_NZDIG+1	@ nonzero digit found?
		bcs	1f		@ no adjustments if so
		@ Handle first digit after the point
		movs	r4,0
		cmp	r3,8		@ 4-bit CLZ subtracted from exp
		sbcs	r7,r4		@ subtract 1 if < 8
		cmp	r3,4
		sbcs	r7,r4		@ subtract 1 if < 4
		cmp	r3,2
		sbcs	r7,r4		@ subtract 1 if < 2
		cmp	r3,1
		sbcs	r7,r4		@ subtract 1 if < 1
		b	1f

3:		@ Handle digits before the point
		lsrs	r4,r6,F_NZDIG+1	@ nonzero digit found?
		bcs	2f		@ add 4 to exp if so
		@ Handle first digit before the point
		movs	r4,0
		cmp	r3,8		@ 4-bit log2, sort of
		adcs	r7,r4		@ add 1 if >= 8
		cmp	r3,4
		adcs	r7,r4		@ add 1 if >= 4
		cmp	r3,2
		adcs	r7,r4		@ add 1 if >= 2
		cmp	r3,1
		adcs	r7,r4		@ add 1 if >= 1
		subs	r7,4		@ don't add 4 (faster than branching)
2:		adds	r7,4		@ adjust exp by 4 bits (1 hex digit)

1:		cmp	r3,0
		beq	1f
		movs	r4,1<<F_NZDIG
		orrs	r6,r4		@ set nonzero digit found flag
1:		lsrs	r4,r6,F_RESOL+1	@ rounding resolved?
		bcc	1f		@ if not, there's much more work
		cmp	r3,0		@ check if a digit is != 0
		beq	hexDigit	@ if not, nothing else to do
		movs	r4,1<<F_NZRND
		orrs	r6,r4		@ mark nonzero found after round bit
		b	hexDigit

1:		lsrs	r4,r1,52-32	@ is the mantissa full?
		beq	addXDigit	@ skip next part if not

		lsrs	r4,r6,F_RNDDG+1	@ are we in a tie?
		bcs	chkXTie		@ skip if we are

		@ If not ignoring, round bit=0 and mantissa full, the
		@ remaining possibility is that this digit has the rounding
		@ bit in bit 3.
		lsls	r3,28		@ move to high bits to check
setXRoundingR3:	lsrs	r4,r3,31	@ isolate rounding bit
		lsls	r4,F_RNDDG
		orrs	r6,r4		@ set rounding bit to result
		lsls	r4,r3,1		@ check rest of bits
		beq	1f		@ don't set flags if zero
		movs	r4,1<<F_NZRND|1<<F_RESOL
		orrs	r6,r4		@ set nonzero; rounding resolved
1:		mvns	r3,r3		@ negate rnd bit
		lsrs	r4,r3,31	@ clear other bits...
		lsls	r4,F_RESOL	@ ... and move into position
		orrs	r6,r4		@ rounding also resolved if rnd bit=0
		b	hexDigit

chkXTie:	cmp	r3,0
		beq	hexDigit	@ nothing decided yet
		movs	r4,1<<F_NZRND|1<<F_RESOL
		orrs	r6,r4		@ set rounding NZ and RESOLved flags
		b	hexDigit

addXDigit:	lsrs	r4,r1,49-32	@ is there room for the next digit?
		bne	1f		@ if not, go bit by bit
		lsrs	r4,r0,28	@ 64-bit shift left by 4 bits
		lsls	r1,4
		orrs	r1,r4
		lsls	r0,4
		adds	r0,r3		@ add digit and go on
		b	hexDigit

1:		lsls	r3,29		@ shift R3, shift out MSB bit
		adcs	r0,r0		@ into mantissa
		adcs	r1,r1
		lsrs	r4,r1,52-32	@ did this bit fill the mantissa?
		bne	setXRoundingR3	@ deal with rounding if not
		adds	r3,r3		@ another bit of R3
		adcs	r0,r0		@ into mantissa
		adcs	r1,r1
		lsrs	r4,r1,52-32	@ did this bit fill the mantissa?
		bne	setXRoundingR3	@ deail with rounding if not
		adds	r3,r3		@ another bit of R3
		adcs	r0,r0		@ into mantisa
		adcs	r1,r1		@ this one does fill the mantissa
		b	setXRoundingR3

XpointFound:	lsrs	r4,r6,F_POINT+1
		bcs	endNumberX
		movs	r4,1<<F_POINT
		orrs	r6,r4
		lsrs	r4,r6,F_VALID+1	@ valid digit present?
		bcc	hexDigit	@ if not yet, go on
		movs	r5,r2		@ count the dot as valid
		b	hexDigit

endNumber_pxy:	b	endNumber
binExp:		lsrs	r4,r6,F_VALID+1	@ any valid digit before the 'P'?
		bcc	endNumber_pxy	@ if not, bad
		ldrb	r3,[r2]
		adds	r2,1		@ consume 'p'
		movs	r4,0		@ R4 = exponent in this section
		cmp	r3,'+'
		beq	1f
		cmp	r3,'-'
		bne	2f
		movs	r4,1<<F_NEGXP
		orrs	r6,r4
		movs	r4,0
1:		ldrb	r3,[r2]		@ digit loop
		adds	r2,1
2:		subs	r3,'0'		@ entry point if neither '+' nor '-'
		blo	endNumberAddX
		cmp	r3,9
		bhi	endNumberAddX
		movs	r5,r2		@ valid exponent digit
		mov	r12,r3
		lsls	r3,r4,2		@ *4
		adds	r4,r3		@ *5
		adds	r4,r4		@ *10
		add	r4,r12		@ +digit
		b	1b

endNumberAddX:	lsrs	r3,r6,F_NEGXP+1	@ check sign of exponent
		bcc	1f
		negs	r4,r4		@ make it negative
1:		adds	r7,r4		@ add exponent

endNumberX:	@ Check rounding and reconstruct a float from the parts
		@ before jumping to endNumber, considering overflow and
		@ denormals, and rounding in the case of denormals

		@ R2 changes meaning now, as it's no longer needed, and
		@ is a scratch register too

		bx	pc
		.arm
		.balign	4
		@ If we can save about every other instruction and avoid
		@ branches, using ARM mode will save time

		add	r7,1024		@ apply bias to R7
		sub	r7,2		@ correct bias is 1023, and we take
					@ one due to the placement of the
					@ implicit mantissa '1' bit

		orrs	r4,r0,r1	@ mantissa zero?
		moveq	r7,0		@ set exponent to 0 if so
		beq	zeroOk		@ and take a shortcut

		@ 64-bit CLZ for normalization

		cmp	r1,0
		@ CLZ in R0 (low word)
		moveq	r3,64		@ there are 32 zeros already in R1
		moveq	r2,r0
		@ CLZ in R1 (high word)
		movne	r3,32
		movne	r2,r1
		@ Normalization proper
		bl	clz_ARM
		sub	r3,11		@ R3 = number of bits to shift R1:R0
		lsl	r1,r3
		sub	r4,r3,32
		orr	r1,r1,r0,lsl r4
		rsb	r4,r3,32
		orr	r1,r1,r0,lsr r4
		lsl	r0,r3		@ Normalization finished
Bit52set:
		@ Denormalize and round if exponent is not positive
		cmp	r7,1		@ Denormal?
		bge	1f		@ Jump if normal
		rsb	r7,r7,1		@ R7 = shift count
		cmp	r7,53
		movhi	r7,54		@ clamp to avoid too big exponent

		mov	r2,r0		@ Keep shifted out data for rounding
		mov	r12,r1
		mov	r0,r0,lsr r7	@ 64-bit shift right by R7
		rsb	r4,r7,32
		orr	r0,r0,r1,lsl r4
		sub	r4,r7,32
		orr	r0,r0,r1,lsr r4
		lsr	r1,r1,r7

		@ Isolate shifted out bits in high bits of R12:R2
		rsb	r7,r7,64
		mov	r12,r12,lsl r7	@ 64-bit shift left by R7
		sub	r4,r7,32
		orr	r12,r12,r2,lsl r4
		rsb	r4,r7,32
		orr	r12,r12,r2,lsr r4
		ands	r4,r6,1<<F_NZRND|1<<F_RNDDG
		orrs	r2,r4,r2,lsl r7	@ those digits contribute too

		@ Rounding for denormals
		mov	r3,r12,lsr 31	@ R3 = 1 if bit 63 = 1, 0 otherwise
		orrs	r4,r2,r12,lsl 1	@ are bits 62..0 = 0?
		lslseq	r4,r0,31	@ if so, check evenness of result
		moveq	r3,0		@ if zero, and even, round down

		adds	r0,r3		@ Apply rounding
		adc	r1,0
		bic	r6,1<<F_RNDDG	@ Ensure no further rounding
		tst	r1,1<<(52-32)	@ check if it has overflown to normal
		@ Set R7 to exponent again
		moveq	r7,0
		movne	r7,1

		@ It is unclear what is an underflow in the case of this
		@ function. The code below sets ERANGE in case the float was
		@ nonzero but the result is zero.
		@orrs	r4,r0,r1
		@ldreq	r3,=errno
		@moveq	r4,ERANGE	@ Set ERANGE on underflow
		@streq	r4,[r3]
		@moveq	r7,0		@ Set exponent to 0 if zero

		@ glibc's behaviour seems to be to set errno if denormal and
		@ nonzero bits shifted out, that is, if the max of the
		@ significant bits in the input and in the result < 53.
		@
		@ After further tests, that doesn't seem to be the case;
		@ it seems that if the result is a denormal, the input must
		@ be exact or otherwise ERANGE is raised. Due to a bug, our
		@ behaviour is pretty close to that anyway.
		orrs	r4,r2,r12	@ any bit nonzero?
		movne	r4,ERANGE
		ldrne	r3,=errno
		strne	r4,[r3]		@ set errno to ERANGE if so
1:
		@ Rounding for normal
		and	r3,r6,1<<F_RNDDG @ R3 = 1 if rounding digit was set
		lsr	r3,F_RNDDG	@ and 0 otherwise
		tst	r0,1		@ check parity
		tsteq	r6,1<<F_NZRND	@ if even, check if nonzero
		moveq	r3,0		@ if even or nonzero, set R3 to 0
		adds	r0,r3
		adc	r1,0
		tst	r1,1<<(53-32)	@ overflown?
		addne	r7,1
		movsne	r1,r1,lsr 1	@ this produces Z!=0 for sure
zeroOk:
		bics	r1,1<<(52-32)	@ clear implicit bit
		add	r7,1		@ easier to compare and set this way
		cmp	r7,2048
		movhs	r0,0		@ if >= 0x7FF, set to infinity
		movhs	r1,0
		movhs	r4,ERANGE
		ldrhs	r7,=errno
		strhs	r4,[r7]		@ and set errno to ERANGE too
		movhs	r7,2048
		sub	r7,1		@ restore
		orrs	r1,r1,r7,lsl (52-32)
1:		ldr	r4,=endNumber+1
		bx	r4

		@ 64-bit Count Leading Zeros (not AAPCS compliant)
		@ Entry: R1:R0 = number
		@ Output: R3 = count
		@ Clobbers R2
		.arm
clz_ARM:	cmp	r1,0
		@ CLZ in R0 (low word)
		moveq	r3,64		@ there are 32 zeros already in R1
		moveq	r2,r0
		@ CLZ in R1 (high word)
		movne	r3,32
		movne	r2,r1
		cmp	r2,1<<16
		subhs	r3,16
		movhs	r2,r2,lsr 16
		cmp	r2,1<<8
		subhs	r3,8
		movhs	r2,r2,lsr 8
		cmp	r2,1<<4
		subhs	r3,4
		movhs	r2,r2,lsr 4
		cmp	r2,1<<2
		subhs	r3,2
		movhs	r2,r2,lsr 2
		cmp	r2,1<<1
		subhs	r3,2
		sublo	r3,r2
		bx	lr

		.ltorg

		@ Decimal handling
		.thumb
nextDigit:	ldrb	r3,[r2]
		adds	r2,1
decimal:
		cmp	r3,'.'
		beq	pointFound
		cmp	r3,'E'
		beq	decExp
		cmp	r3,'e'
		beq	decExp
		subs	r3,'0'
		blo	endNumberDec
		cmp	r3,9
		bhi	endNumberDec
		movs	r5,r2		@ valid digit found
		movs	r4,1<<F_VALID	@ from now on, '.' will advance R5
		orrs	r6,r4

		lsrs	r4,r6,F_RESOL+1
		bcs	mantissaFull

		movs	r4,r0
		orrs	r4,r1		@ nonzero digits present?
		orrs	r4,r3		@ including current digit
		bne	1f		@ process if so

		@ all digits so far are zeros
		lsrs	r4,r6,F_POINT+1	@ point present?
		bcc	nextDigit	@ if not, ignore
		subs	r7,1		@ increase exponent
		b	nextDigit
1:
		ldr	r4,=0x19999999
		cmp	r1,r4
		bne	1f
		lsls	r4,4
		adds	r4,9
		cmp	r0,r4
1:		blo	1f
		bhi	overflow
		cmp	r3,6
		bhs	overflow
1:
		@ 64-bit multiply-by-10
		mov	r12,r3
		movs	r4,r1
		adds	r3,r0,r0
		adcs	r4,r4		@ n*2
		adds	r3,r3
		adcs	r4,r4		@ n*4
		adds	r0,r3
		adcs	r1,r4		@ n*4 + n = n*5
		adds	r0,r0
		adcs	r1,r1		@ n*10
		mov	r3,r12
		movs	r4,0
		adds	r0,r3		@ n * 10 + digit
		adcs	r1,r4

		lsrs	r4,r6,F_POINT+1	@ point present?
		bcc	nextDigit	@ if not, exponent is unchanged
		subs	r7,1		@ decrease exponent
		b	nextDigit

overflow:	movs	r4,1<<F_RESOL
		orrs	r6,r4
		@ Fall through to mantissaFull

mantissaFull:	lsrs	r4,r6,F_POINT+1
		bcs	nextDigit
		adds	r7,1
		b	nextDigit

pointFound:	lsrs	r4,r6,F_POINT+1
		bcs	endNumberDec
		movs	r4,1<<F_POINT
		orrs	r6,r4
		lsrs	r4,r6,F_VALID+1	@ valid digit present?
		bcc	nextDigit	@ if not yet, go on
		movs	r5,r2		@ count the dot as valid
		b	nextDigit

endNumber_pxy2:	b	endNumber

decExp:		lsrs	r4,r6,F_VALID+1	@ any valid digit before the 'e'?
		bcc	endNumber_pxy2	@ if not, bad
		ldrb	r3,[r2]
		adds	r2,1		@ consume 'e'
		movs	r4,0		@ R4 = exponent in this section
		cmp	r3,'+'
		beq	1f
		cmp	r3,'-'
		bne	2f
		movs	r4,1<<F_NEGXP
		orrs	r6,r4
		movs	r4,0
1:		ldrb	r3,[r2]		@ digit loop
		adds	r2,1
2:		subs	r3,'0'		@ entry point if neither '+' nor '-'
		blo	endNumberAddD
		cmp	r3,9
		bhi	endNumberAddD
		movs	r5,r2		@ valid exponent digit
		mov	r12,r3
		lsls	r3,r4,2		@ *4
		adds	r4,r3		@ *5
		adds	r4,r4		@ *10
		add	r4,r12		@ +digit
		b	1b

endNumberAddD:	lsrs	r3,r6,F_NEGXP+1	@ check sign of exponent
		bcc	1f
		negs	r4,r4		@ make it negative
1:		adds	r7,r4		@ add exponent
endNumberDec:
		@ We have a 64-bit number and we have to place the first 1
		@ in bit 52.
		bx	pc
		.arm
		.balign	4

		orrs	r4,r0,r1	@ mantissa zero?
		moveq	r7,0		@ set exponent to 0 if so
		beq	zeroOk		@ and take a shortcut

		bl	clz_ARM		@ Count leading zeros

		orr	r6,r6,r3,lsl 16	@ Store count in R6

		@ Flush number to the left
		lsl	r1,r3		@ 64-bit shift left by R3
		sub	r4,r3,32
		orr	r1,r1,r0,lsl r4
		rsb	r4,r3,32
		orr	r1,r1,r0,lsr r4
		lsl	r0,r3

		add	r7,324		@ offset in table
		and	r4,r7,1
		bic	r7,1		@ make even

		cmp	r7,-20		@ Range check
		movlt	r0,0
		movlt	r1,0
		movlt	r7,0
		blt	zeroOk
		cmp	r7,308+324
		movgt	r7,308+324	@ Clamp
		orrgt	r4,1		@ set 10exp to 309 to ensure overflow

		orrs	r6,r6,r4,lsl F_ODDEX	@ set odd exp flag
		ldr	r4,=acsl_TenPowers
		@ 64-bit multiply by the power of ten from the table

		add	r4,r4,r7,lsl 2
		ldmia	r4!,{r2,r3}
		bic	r2,1<<0		@ clear bit 0 which isn't part of num

		tst	r6,1<<F_ODDEX	@ odd exponent means we need to mult
					@ by 10 again
		beq	1f
		mov	r12,0		@ 96-bit multiply-by-10
		adds	r4,r2,r2
		adcs	lr,r3,r3
		adc	r12,r12		@ *2
		adds	r4,r4
		adcs	lr,lr
		adc	r12,r12		@ *4
		adds	r2,r4
		adcs	r3,lr
		adc	r12,0		@ *5
		adds	r2,r2
		adcs	r3,r3
		adc	r12,r12		@ *10
		lsr	r2,3		@ We need to shift 3 or 4 positions
		orr	r2,r2,r3,lsl 29	@ to get a normalized number again;
		lsr	r3,3		@ these count for the 2exp later.
		orr	r3,r3,r12,lsl 29
		lsrs	r12,3+1
		bcc	1f
		rrxs	r3,r3
		rrx	r2,r2
		orr	r6,1<<F_SHFT4	@ flag "4 positions shifted"
1:
		umull	r4,lr,r0,r2
		umull	r2,r12,r1,r2
		adds	r2,lr
		umull	r0,lr,r3,r0
		adcs	r12,lr
		umull	r3,lr,r1,r3
		adc	r1,lr,0
		adds	r2,r0
		adcs	r0,r3,r12
		adcs	r1,0
		@ Result: R1:R0:R2:R4

		ldr	r12,=acsl_Exp2ForEntry
		ldrsh	r7,[r12,r7]	@ 2exp - has a bias of 1080

		bmi	1f		@ bit 63 needs to be set; jump if so
		adds	r4,r4		@ otherwise, shift all 128 bits left
		adcs	r2,r2
		adcs	r0,r0
		adc	r1,r1
		sub	r7,1		@ (and the 2exp fixed appropriately)
1:
		sub	r7,1080-1023-64	@ adjust exponent
					@ 1080 is the bias in the table
					@ 1023 is the bias in a double
					@ 64 is the # of bits in the mantissa
		sub	r7,r7,r6,lsr 16	@ add CLZ

		@ Don't shift R4 since we want it for nonzero check only
		orr	r4,r4,r2,lsl 21	@ for nonzero check
		lsr	r2,11		@ 64-bit shift to move bit 63 to 52
		orrs	r2,r2,r0,lsl 22	@ round bit is carry
		orrcs	r6,1<<F_RNDDG
		lsr	r0,11
		orr	r0,r0,r1,lsl 21
		lsr	r1,11
		orr	r4,r4,r0,lsl 31	@ include parity in R4
		orrs	r2,r4
		orrne	r6,1<<F_NZRND

		tst	r6,1<<F_ODDEX
		addne	r7,3
		tst	r6,1<<F_SHFT4	@ only set when F_ODDEX is set too
		addne	r7,1

		b	Bit52set

		.ltorg
