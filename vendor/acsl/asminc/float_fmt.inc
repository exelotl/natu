/*
 * Floating-point support for format strings in GBA library
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

@ All float formatting routines push r5, r10 and r11
endFloat:	pop	{r1-r2,r5}
		mov	r10,r1
		mov	r11,r2
		b	mainLoopC


		@ Handle %a format
fmt_a:		strb	r0,[r6,L_FMTCHAR]
		ldr	r0,[r6,L_FLAGS]
		orrs	r0,r1		@ Copy LOWER flag from r1
		str	r0,[r6,L_FLAGS]

		ldr	r0,[r6,L_PREC]
		mov	r9,r0		@ Save orig. precision for later
		cmp	r0,0
		bge	1f		@ If unspecified, override default
		movs	r0,13		@ Default precision for doubles in %a
		str	r0,[r6,L_PREC]
1:
		bl	floatCommon
		@ R0, R1 = number; R2 = 2exp

		cmp	r1,0		@ r1 < 0 indicates r0 = ptr to string
		bge	1f
txtF:		movs	r1,0
		str	r1,[r6,L_PREC]
		movs	r1,3		@ Argument to fmtBuf
		@ R0 is already the buffer pointer
		b	fmtBuf
1:
		@ we need registers!
		@ do the equivalent to: push {r5}; push {r11}, push {r10}
		@ to recover use e.g. pop {r2,r3,r5}; mov r10,r2; mov r11,r3
		push	{r5}
		mov	r3,r10
		mov	r5,r11
		push	{r3,r5}

		movs	r3,1
		lsls	r3,10
		subs	r3,1		@ R3=1023
		subs	r5,r2,r3	@ R5=2exp
		ldr	r2,[r6,L_FLAGS]
		movs	r3,1<<F_LOWER
		ands	r3,r2
		adds	r3,'A'-('9'+1)
		mov	r12,r3		@ R12 = 7 or 27h depending on case
		movs	r2,r6
		adds	r2,L_BUF+30
		bl	conv64toHex
		@ R0 = pointer to first

		movs	r3,0		@ Exponent if zero
		movs	r2,r0
		subs	r2,r6
		cmp	r2,L_BUF+30
		beq	1f
		ldr	r3,=-1022	@ Exponent if denormal
1:
		movs	r1,r6
		adds	r1,L_BUF+30-14	@ limit of digits for a mantissa

		cmp	r0,r1
		beq	2f		@ equal unless denormal
		movs	r2,'0'
1:		subs	r0,1
		strb	r2,[r0]		@ fill with zeros
		cmp	r0,r1
		bne	1b
		movs	r5,r3		@ Denormals are printed denormalized
2:
		mov	r1,r9		@ retrieve original precision
		mov	r9,r5		@ exponent to R9 as required later
		cmp	r1,0		@ Original precision negative?
		bge	2f		@ No traling zero removal if so
		@ Remove trailing zeros
		movs	r1,r6
		adds	r1,L_BUF+30	@ buffer terminator
1:		subs	r1,1
		ldrb	r2,[r1]		@ grab chars from the right
		cmp	r2,'0'		@ is it a zero?
		bne	1f		@ if not, we've found the position
		cmp	r1,r0		@ are we at the beginning of the num?
		bne	1b		@ no, repeat
		@ it will fall through here only if the number is 0
1:
		adds	r1,1
		movs	r2,0		@ store a terminator after the last
		strb	r2,[r1]		@ nonzero
		subs	r1,r0		@ total length
		subs	r1,1		@ remove the first digit from the cnt
		str	r1,[r6,L_PREC]	@ use as precision
2:
		mov	r10,r0		@ pointer to first digit

		@ Append 0X or 0x to prefix
		ldrb	r0,[r6,L_PFX]
		adds	r0,L_PFX
		adds	r0,1
		movs	r1,'0'
		strb	r1,[r6,r0]
		adds	r0,1
		ldr	r1,[r6,L_FLAGS]
		movs	r2,1<<F_LOWER
		ands	r1,r2
		movs	r2,'X'
		orrs	r1,r2
		strb	r1,[r6,r0]
		subs	r0,L_PFX
		strb	r0,[r6,L_PFX]

		@ Predict the length; set R0 = predicted length

		adds	r0,5		@ length("N.p+E") = 5
		asrs	r1,r5,31	@ R5 is still a copy of the exponent
		adds	r5,r1
		eors	r5,r1		@ absolute value
		movs	r1,0
		cmp	r5,10
		adcs	r0,r1		@ +1 if 2+ digits in exp
		cmp	r5,100
		adcs	r0,r1		@ +1 if 3+ digits in exp
		ldr	r2,=1000
		cmp	r5,r2
		adcs	r0,r1		@ +1 if 4+ digits in exp
		ldr	r1,[r6,L_PREC]
		adds	r0,r1		@ add precision
		cmp	r1,0
		bne	1f
		ldr	r1,[r6,L_FLAGS]
		lsrs	r1,F_ALT+1
		bcs	1f
		subs	r0,1		@ dot not printed
1:		b	common_e_a

		@ Handle a value of zero in %e format
zero_e:		movs	r1,'0'
		lsls	r1,8
		strh	r1,[r6,L_BUF+28]
		movs	r0,0
		movs	r1,L_BUF+29
		b	zeroEntry_e

		@ Handle %e format
fmt_e:		strb	r0,[r6,L_FMTCHAR]
		ldr	r0,[r6,L_FLAGS]
		orrs	r0,r1		@ Copy LOWER flag from r1
		str	r0,[r6,L_FLAGS]
		bl	floatCommon
		cmp	r1,0		@ r1 < 0 indicates r0 = ptr to string
		blt	txtF		@ output it
		bne	1f
		cmp	r0,0		@ Conversion of 0.0 to decimal? Avoid
		beq	zero_e		@ some processing inadequate for it
1:
		bl	normDenorm	@ for decimal we need it normalized
		ldr	r3,=float2Dec_arm
		bl	bxr3
		@ returns R0 = 10exp

		@ With decimal in this format we need some string processing
		bl	adjustDec
		@ returns R0=exp, R1=offset of first digit relative to R6

zeroEntry_e:	@ Enter here if the number was 0.0, with R1 = L_BUF+29 and R0
		@ (10exp) = 0. The buffer contains a single '0' in this case.

		@ push registers (see comment in fmt_a)
		push	{r5}
		mov	r3,r10
		mov	r5,r11
		push	{r3,r5}

		mov	r9,r0		@ R9 = exponent
		adds	r1,r6
		mov	r10,r1		@ first digit pointer in R10

		@ Predict length to output in R0
		asrs	r1,r0,31
		adds	r0,r1
		eors	r0,r1		@ absolute value
		cmp	r0,100		@ does exp need less than 3 digits?
		sbcs	r0,r0		@ R0=-1 if so
		adds	r0,7		@ length of "N.e+EEE" = 7; subtract
					@ 1 if exp has less than 3 digits

		ldr	r1,[r6,L_PREC]
		adds	r0,r1		@ add precision
		cmp	r1,0
		bne	2f
		@ precision=0; check F_ALT to see if we still output a point
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_ALT+1	@ point mandatory?
		bcs	2f		@ keep the place for the point if so
		subs	r0,1		@ remove the point from the length
2:		ldrb	r1,[r6,L_PFX]	@ grab prefix length
		adds	r0,r1		@ add length of prefix (0 if none)
common_e_a:
		@ Prepare to output padding spaces, sign, and padding zeros
		ldr	r5,[r6,L_WIDTH]
		subs	r5,r0		@ how many spaces to output?
		mov	r11,r5		@ save for right padding
		ble	2f		@ skip if none

		ldr	r2,[r6,L_FLAGS]
		lsls	r2,32-F_LJUST
		bcs	2f		@ if L_JUST, no spaces
		lsls	r2,F_LJUST-F_ZEROPAD
		bcs	2f		@ if zero padding, no spaces

1:		movs	r0,' '		@ output padding spaces
		bl	out1
		subs	r5,1
		bhi	1b
		mov	r11,r5		@ no more padding to do
2:
		@ output prefix
		ldrb	r0,[r6,L_PFX+1]
		cmp	r0,0
		beq	1f
		bl	out1
		ldrb	r0,[r6,L_PFX+2]
		cmp	r0,0
		beq	1f
		bl	out1
		ldrb	r0,[r6,L_PFX+3]
		cmp	r0,0
		beq	1f
		bl	out1
1:
		mov	r5,r11
		cmp	r5,0
		ble	2f
		@ If something left, it must be zero padding or right just.
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_LJUST+1
		bcs	2f		@ if L_JUST, no zeros

1:		movs	r0,'0'		@ output padding zeros
		bl	out1
		subs	r5,1
		bhi	1b
		mov	r11,r5		@ no more padding to do
2:
		@ Output the first digit
		mov	r1,r10		@ pointer to 1st digit
		ldrb	r0,[r1]
		adds	r1,1
		mov	r10,r1
		bl	out1

		@ check whether to omit the point
		ldr	r1,[r6,L_PREC]
		cmp	r1,0
		bne	1f
		ldr	r1,[r6,L_FLAGS]
		lsrs	r1,F_ALT+1
		bcc	2f
1:		movs	r0,'.'
		bl	out1
2:
		@ output all visible digits; if we exhaust the buffer,
		@ then keep outputting zeros up to the precision
		mov	r5,r10		@ R5 will be our pointer
		ldr	r1,[r6,L_PREC]
		adds	r1,r5
		mov	r10,r1		@ R11 will be our limit

		@ output decimal digits up to precision or first null
		cmp	r5,r10
		beq	outputExp
1:		ldrb	r0,[r5]		@ Grab first decimal part digit
		adds	r5,1
		cmp	r0,0
		beq	1f		@ If terminated, go to zeros loop
		bl	out1
		cmp	r5,r10
		bne	1b
		b	outputExp
		@ Fill the rest with zeros
1:		movs	r0,'0'		@ Output a '0' in place of the null
		bl	out1
		cmp	r5,r10
		beq	outputExp
1:		adds	r5,1
		movs	r0,'0'
		bl	out1
		cmp	r5,r10
		bne	1b

outputExp:
		@ output the E
		ldr	r0,[r6,L_FLAGS]
		movs	r1,1<<F_LOWER
		ands	r1,r0
		movs	r0,'E'
		ldrb	r2,[r6,L_FMTCHAR]
		cmp	r2,'A'		@ for format 'A' output a P instead
		bne	1f
		movs	r0,'P'
1:
		orrs	r0,r1
		bl	out1

		@ output the exponent's sign
		mov	r5,r9		@ 10exp or 2exp depending on %E or %A
		asrs	r0,r5,31
		adds	r5,r0
		eors	r5,r0		@ absolute value
		mov	r9,r5
		negs	r0,r0
		adds	r0,r0		@ difference between '+' and '-'
		adds	r0,'+'
		bl	out1
		@ Output the exponent itself with at least 2 digits. This
		@ method is accurate only up to 1098; using more precision
		@ means it won't fit in the 8 bits max allowed by thumb mov.
		@ Fortunately we don't ever work with exp>1074, so it works.
		movs	r0,0x4000/100+1	@ 1/100 in fixed point 18.14
		muls	r0,r5		@ multiply exponent by 1/100
		lsrs	r0,14		@ integer part, hundreds digit
		beq	1f		@ don't output it if zero
		movs	r1,100
		muls	r1,r0		@ hundreds * 100
		subs	r5,r1		@ remainder in R5
		ldr	r2,=mod100tbl
		adds	r0,r0
		ldrh	r0,[r2,r0]
		mov	r10,r0		@ keep to output hundreds digit later
		lsls	r0,24		@ thousands digit
		lsrs	r0,24
		cmp	r0,'0'
		beq	2f
		bl	out1
2:		mov	r0,r10
		lsrs	r0,8		@ hundreds digit
		bl	out1
1:		ldr	r2,=mod100tbl
		adds	r5,r5
		ldrh	r0,[r2,r5]	@ grab the two digits from the table
		lsrs	r5,r0,8		@ leave the units digit in R5
		lsls	r0,24		@ tens digit
		lsrs	r0,24
		ldrb	r2,[r6,L_FMTCHAR]
		cmp	r2,'A'
		bne	1f		@ if format != 'A', output tens digit
		mov	r2,r9
		cmp	r2,10		@ if exp < 10, don't output it
		blo	2f
1:		bl	out1		@ output it
2:		movs	r0,r5
		bl	out1		@ last digit of exponent

		mov	r5,r11
		cmp	r5,0
		ble	2f		@ no more padding to do?
1:		movs	r0,' '
		bl	out1
		subs	r5,1
		bhi	1b
2:
		b	endFloat

txtF_pxy1:	b	txtF

		@ Handle a value of zero in %f format
zero_f:		movs	r1,'0'
		lsls	r1,8
		strh	r1,[r6,L_BUF+28]
		movs	r0,0
		movs	r1,L_BUF+29
		b	zeroEntry_f

fmt_f:		strb	r0,[r6,L_FMTCHAR]
		ldr	r0,[r6,L_FLAGS]
		orrs	r0,r1		@ Copy LOWER flag from r1
		str	r0,[r6,L_FLAGS]
		bl	floatCommon
		cmp	r1,0		@ r1 < 0 indicates r0 = ptr to string
		blt	txtF_pxy1	@ output it
		bne	1f
		cmp	r0,0		@ Conversion of 0.0 to decimal? Avoid
		beq	zero_f		@ some processing inadequate for it
1:
		bl	normDenorm	@ for decimal we need it normalized
		ldr	r3,=float2Dec_arm
		bl	bxr3
		@ returns R0 = 10exp

		@ With decimal in this format we need some string processing
		bl	adjustDec
		@ returns R0=exp, R1=offset of first digit relative to R6
zeroEntry_f:
		@ push registers (see comment in fmt_a)
		push	{r5}
		mov	r3,r10
		mov	r5,r11
		push	{r3,r5}

		mov	r9,r0		@ R9 = exponent
		mov	r10,r1		@ first digit pointer in R10

		@ predict total length to print
		ldr	r3,[r6,L_PREC]
		movs	r1,0
		subs	r1,1
		cmp	r0,r1
		bge	1f
		movs	r0,0
1:
		adds	r0,2		@ add point and one digit
		cmp	r0,2		@ length("0.")
		bge	1f
		movs	r0,2		@ at least outputs one leading zero
1:		adds	r0,r3		@ total digits = digits+prec+point
		cmp	r3,0		@ precision zero?
		bne	1f
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_ALT+1	@ # flag absent?
		bcs	1f
		subs	r0,1		@ no point present if PREC=0 and no #
1:		ldrb	r2,[r6,L_PFX]
		adds	r0,r2
		ldr	r5,[r6,L_WIDTH]
		subs	r5,r0
		mov	r11,r5		@ padding amount to R11
		ble	2f

		@ Prepare to output padding spaces, sign, and padding zeros
		ldr	r2,[r6,L_FLAGS]
		lsls	r2,32-F_LJUST
		bcs	2f		@ if L_JUST, no spaces
		lsls	r2,F_LJUST-F_ZEROPAD
		bcs	2f		@ if zero padding, no spaces

1:		movs	r0,' '		@ output padding spaces
		bl	out1
		subs	r5,1
		bhi	1b
		mov	r11,r5		@ no more padding to do
2:
		@ output prefix
		ldrb	r0,[r6,L_PFX+1]
		cmp	r0,0
		beq	1f
		bl	out1
1:
		mov	r5,r11
		cmp	r5,0
		ble	2f
		@ If something left, it must be zero padding or right just.
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_LJUST+1
		bcs	2f		@ if L_JUST, no zeros

1:		movs	r0,'0'		@ output padding zeros
		bl	out1
		subs	r5,1
		bhi	1b
		mov	r11,r5		@ no more padding to do
2:

		@ Output the digits
		mov	r5,r9		@ exponent
		cmp	r5,0
		bge	1f

		movs	r0,'0'
		bl	out1
		b	endWholeDigits_f
1:
		@ Hack: Ensure no commas are printed unless the ' flag is set
		@ (it works because the exponent is never negative, so R2
		@ is guaranteed to have bit 31 set, and treated as unsigned,
		@ therefore it's guaranteed to be bigger than the maximum
		@ exponent)
		mvns	r2,r5

		ldr	r3,[r6,L_FLAGS]
		lsrs	r3,F_1000_SEP+1
		bcc	1f
		mov	r2,r9
		ldr	r3,=0x10000/3+1
		muls	r3,r2
		lsrs	r3,16		@ R3 = exp / 3
		lsls	r1,r3,1
		adds	r3,r1		@ R3 = floor(exp / 3) * 3
		subs	r2,r3		@ R2 = exp % 3
		adds	r2,2		@ never output ',' before first digit
1:
		subs	r2,1
		bne	2f
		movs	r0,','
		bl	out1
		movs	r2,3
2:
		mov	r1,r10		@ digit pointer
		movs	r0,'0'
		cmp	r1,L_BUF+30
		bhs	2f
		ldrb	r0,[r6,r1]
2:		adds	r1,1
		mov	r10,r1
		push	{r2}
		bl	out1
		pop	{r2}
		subs	r5,1
		bge	1b
endWholeDigits_f:
		@ Check whether to print the decimal point
		ldr	r5,[r6,L_PREC]
		cmp	r5,0
		bne	1f
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_ALT+1
		bcc	2f
1:		movs	r0,'.'
		bl	out1
2:

0:		cmp	r5,0
		beq	3f		@ if prec is 0, don't output decimals
		mov	r1,r9
		adds	r1,1		@ Is precision < -1?
		bpl	1f		@ Output normal decimals if not
		mov	r9,r1
		movs	r0,'0'		@ Output zeros until precision is OK
		bl	out1
		subs	r5,1
		b	0b

1:		mov	r1,r10
		movs	r0,'0'
		cmp	r1,L_BUF+30
		bge	2f
		ldrb	r0,[r6,r1]
		adds	r1,1
		mov	r10,r1
2:		bl	out1
		subs	r5,1
		bhi	1b
3:
		@ If left-justified, pad right
		mov	r5,r11
		cmp	r5,0		@ any pending padding?
		ble	2f		@ if not, we're done
1:		movs	r0,' '		@ must be left-justification padding
		bl	out1
		subs	r5,1
		bhi	1b
2:
		b	endFloat

txtF_pxy2:	b	txtF

zero_g:		movs	r1,'0'
		lsls	r1,8
		strh	r1,[r6,L_BUF+28]
		movs	r0,0
		movs	r1,L_BUF+29
		b	zeroEntry_g

fmt_g:		ldr	r0,[r6,L_FLAGS]
		orrs	r0,r1		@ Copy LOWER flag from r1
		str	r0,[r6,L_FLAGS]
		bl	floatCommon

		ldr	r3,[r6,L_PREC]
		subs	r3,1
		bge	1f
		movs	r3,0
1:		str	r3,[r6,L_PREC]

		cmp	r1,0		@ r1 < 0 indicates r0 = ptr to string
		blt	txtF_pxy2	@ output it
		bne	1f
		cmp	r0,0		@ Conversion of 0.0 to decimal? Avoid
		beq	zero_g		@ some processing inadequate for it
1:
		bl	normDenorm	@ for decimal we need it normalized
		ldr	r3,=float2Dec_arm
		bl	bxr3
		@ returns R0 = 10exp

		@ With decimal in this format we need some string processing
		bl	adjustDec
		@ returns R0=exp, R1=offset of first digit relative to R6
zeroEntry_g:
		ldr	r2,[r6,L_PREC]
		adds	r2,1
		movs	r3,4
		negs	r3,r3
		@ R0 = X, R2 = P, R3 = -4
		cmp	r3,r0		@ -4 <= X?
		bgt	do_e		@ do_E if not
		cmp	r0,r2		@ X < P?
		bge	do_e		@ do_E if not
		@ Use %f-style formatting with precision P-X-1
		subs	r2,r0
		subs	r2,1
		ldr	r3,[r6,L_FLAGS]
		lsrs	r3,F_ALT+1
		bcs	2f

		@ Trim zeros
1:		cmp	r2,0
		beq	2f
		adds	r3,r2,r0
		adds	r3,1		@ bounds check: must be >= -1
		bmi	3f
		subs	r3,1
		adds	r3,r1
		cmp	r3,L_BUF+30
		bhs	3f		@ bounds check: must be within buffer
		ldrb	r3,[r6,r3]
		cmp	r3,'0'
		bne	2f
3:		subs	r2,1
		b	1b

2:		str	r2,[r6,L_PREC]
		b	zeroEntry_f

do_e:		subs	r2,1
		ldr	r3,[r6,L_FLAGS]
		lsrs	r3,F_ALT+1
		bcs	2f

		@ Trim zeros
1:		cmp	r2,0
		beq	2f
		adds	r3,r2,r1
		cmp	r3,L_BUF+30
		bhs	3f		@ bounds check: must be within buffer
		ldrb	r3,[r6,r3]
		cmp	r3,'0'
		bne	2f
3:		subs	r2,1
		b	1b

2:		str	r2,[r6,L_PREC]
		b	zeroEntry_e

@trimZeros_g:
		@ TODO
@		bx	lr

		.ltorg


		@ Auxiliary routines

bxr3:		bx	r3

		@ Check for inf, NaN, sign and denormal; process sign;
		@ separate mantissa and exponent
floatCommon:	movs	r0,'j'
		strb	r0,[r6,L_SIZE]	@ force size=doubleword

		ldr	r1,[r6,L_PREC]	@ if PREC is unspecified, set to 6
		cmp	r1,0
		bge	1f
		movs	r1,6
		str	r1,[r6,L_PREC]
1:
		push	{lr}
		bl	getParam32or64
		pop	{r3}
		mov	lr,r3
		lsls	r3,r1,1		@ check sign bit and remove it
		bcc	posF		@ jump if positive

		ldr	r2,='-'*256+1

signDoneF:	str	r2,[r6,L_PFX]	@ set negative sign
		lsrs	r2,r3,52-32+1	@ isolate exponent part in R2
					@ (R3 is shifted left by 1, hence +1)
		lsls	r1,12		@ get rid of sign+exponent
		lsrs	r1,12		@ shift back into position
		cmp	r2,0		@ denormal?
		beq	doneF		@ done if so
		@ r2 = exponent (11 bits)
		adds	r3,r2,1		@ detect if it was 0x7FF
		lsrs	r3,11		@ did we shift out all bits?
		bne	inf_nan		@ if not, it's inf or nan
		movs	r3,1
		lsls	r3,52-32	@ make the implicit 1 explicit
		orrs	r1,r3
doneF:		bx	lr

posF:		@ note R3 is in use here!
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_PLUS+1
		bcs	addPlusF	@ '+' has precedence over ' '
		lsrs	r2,F_SPACE-F_PLUS
		bcs	addSpaceF
		movs	r2,0
		b	signDoneF

addPlusF:	ldr	r2,=1+'+'*256
		b	signDoneF
addSpaceF:	ldr	r2,=1+' '*256
		b	signDoneF

inf_nan:	lsls	r3,r1,12
		ldr	r2,[r6,L_FLAGS]
		orrs	r3,r0		@ mantissa zero?
		beq	inf_found	@ inf if so
		ldr	r0,=strNaN	@ "nan"
		lsrs	r2,F_LOWER+1
		bcs	inf_nan_common
		ldr	r0,=strNAN	@ "NAN"
		b	inf_nan_common
inf_found:	ldr	r0,=strInf	@ "inf"
		lsrs	r2,F_LOWER+1
		bcs	inf_nan_common
		ldr	r0,=strINF	@ "INF"
inf_nan_common:	movs	r1,1
		lsls	r1,31		@ set sign bit to indicate ptr in R0
		bx	lr


normDenorm:	@ Normalize a denormal - DO NOT CALL WITH R0=R1=0
		@ This could really use CLZ... sigh
		lsls	r3,r1,12	@ if we were called with a normal
		bcs	2f		@ number, bit 52 is set; return if so
		beq	least21		@ if r1 = 0, bit shift is at least 21
		adds	r0,r0
		adcs	r1,r1		@ shift bits 51..0 left
		lsls	r3,r1,12	@ bit 52 already set?
		bcs	2f		@ normalization finished if so
1:		subs	r2,1		@ decrease 2exp
		adds	r0,r0		@ keep shifting until bit 52 set
		adcs	r1,r1
3:		lsls	r3,r1,12
		bcc	1b
2:		bx	lr

@ shift 21 bits in one go (exponent is adjusted by just 20)
@ This is cheap to implement but denormals are a corner case and don't
@ deserve too much attention. They're expected to be slow anyway.
least21:	subs	r2,20
		lsrs	r1,r0,11
		lsls	r0,21
		b	3b


@ input: R0 = raw 10 exponent from float2Dec_arm
@ output: R0 = corrected 10 exponent; R1 = pointer to first digit in mantissa
@ Note: the mantissa has no decimal point at this stage; it's just 20 digits
@ with possibly zeros in the first two positions.
adjustDec:
		@ Apply rounding before anything else, as that can increase
		@ the number of digits
		movs	r2,'0'		@ Add another '0' for safe rounding
		lsls	r2,8
		strh	r2,[r6,L_BUF+8]
		movs	r2,0		@ Zero terminator
		strh	r2,[r6,L_BUF+30]

		@ Scan for first nonzero in buffer; there should be at most 2
		movs	r1,L_BUF+9
1:		adds	r1,1
		ldrb	r3,[r6,r1]
		cmp	r3,'0'
		beq	1b

		@ Our 10exp applies to a decimal point at L_BUF+11; we need
		@ to adjust exponent according to number of leading zeros
		adds	r0,L_BUF+11
		subs	r0,r1

		@ For %f, the rounding point depends on the power of ten too
		ldrb	r2,[r6,L_FMTCHAR]
		cmp	r2,'F'
		ldr	r2,[r6,L_PREC]
		bne	1f		@ use precision if not F-formatting
		adds	r2,r0		@ add 10exp
		adds	r2,1		@ R2 = Ndigits to advance to find
		bmi	3f		@  rounding point; if < -1 don't rnd
		subs	r2,1		@ we can't compare with -1 so...
1:
		adds	r3,r1,r2	@ add number of visible digits
		adds	r3,1		@ one more digit
		cmp	r3,L_BUF+30	@ past the digits we have?
		bhs	3f		@ nothing else to do if so
		ldrb	r2,[r6,r3]	@ grab digit AFTER the last to show
		@ We don't have enough digits to determine a tie in
		@ round-to-nearest-or-even, so we don't use that. Ties are
		@ always rounded away from zero.
		cmp	r2,'5'		@ determine rounding
		blo	3f		@ don't round up if less than 5
		@ add 1 in ASCII to the visible digits
		subs	r3,1
		ldrb	r2,[r6,r3]
		cmp	r2,'9'
		bne	2f		@ if not 9, go to increase digit
1:		movs	r2,'0'
		strb	r2,[r6,r3]
		subs	r3,1
		ldrb	r2,[r6,r3]
		cmp	r2,'9'		@ if 9, replace  with 0, go back one
		beq	1b		@ digit, and repeat
2:		adds	r2,1		@ increase the first non-9
		strb	r2,[r6,r3]
		cmp	r3,r1
		bhs	3f
		@ Rounding finished before the first digit; new first digit
		@ has changed now, so update it and increase exponent
		movs	r1,r3
		adds	r0,1
3:
		@ R0 = adjusted 10exp; R1 = offset of 1st digit rel. to R6
		bx	lr


		.ltorg

		.section .text.ARM
		.arm

@ R0, R1 = normalized mantissa
@ R2 = actual exponent
float2Dec_arm:	push	{r4-r5,r7-r10}

		add	r6,L_BUF+30

@		add	r2,1024
		add	r2,50+1		@ bias of 1074 that we're using

		add	r3,r2,3		@ offset obtained experimentally
		mov	r4,0x9A00
		orr	r4,0x21		@ 0x9A21 = ceil(log10(2)*2^16*2)
		mul	r3,r4
		add	r3,0x6300
		add	r3,0x3D		@ 0x633D=2^18-floor(log10(64)*2^16*2)
		lsr	r3,17		@ R3 now is in [0,308-(-324)]
		bic	r3,1		@ make it even
		ldr	r8,=acsl_TenPowers
		ldr	r4,[r8,r3,LSL 2]!
		ldr	r5,[r8,4]
		ldr	r12,=acsl_Exp2ForEntry
		ldrsh	r7,[r12,r3]	@ R7 = 2 exponent for this 10 power
		sub	r3,324		@ R3 now is a 10 power in [-324,308]

		add	r12,r2,10	@ Calculate relative position of
		subs	r12,r7		@ mantissa wrt power of ten

		ldr	r10,=mod100tbl	@ prepare pointer

		mov	r9,-20		@ digit counter
		@ shift R0:R1 by R12
1:
		mov	r7,r0
		lsl	r0,r12
		lsl	r1,r12
		rsb	r12,32
		orr	r1,r1,r7,lsr r12

		mov	r7,1<<(32-7)	@ this bit ends the loop; rest zeros

		@ Schoolbook division in binary
2:		lsrs	r5,1
		rrx	r4,r4
		subs	r2,r0,r4
		sbcs	r12,r1,r5
		movcs	r0,r2
		movcs	r1,r12
		adcs	r7,r7
		bcc	2b

		@ Look up ASCII digits and store them in the buffer
		add	r7,r7
		ldrh	r2,[r10,r7]
		strh	r2,[r6,r9]

		adds	r9,2
		bge	retConvArm

		ldr	r4,[r8,-8]!	@ Next lower power of ten
		ldr	r5,[r8,4]

		tst	r4,1
		moveq	r12,6
		movne	r12,7

		b	1b


retConvArm:	sub	r6,L_BUF+30
		mov	r0,r3

		pop	{r4-r5,r7-r10}
		bx	lr

		.ltorg

		.section .rodata

		.balign	4
strInf:		.asciz	"inf"
		.balign	4
strNaN:		.asciz	"nan"
		.balign	4
strINF:		.asciz	"INF"
		.balign	4
strNAN:		.asciz	"NAN"
