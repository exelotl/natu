/*
 * Format strings (sprintf etc) implementation for GBA
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

		.global	acsl_formatStr
		.global acsl_endFmtStr

		.section .text
		.thumb

out1:		adds	r7,1		@ count characters output
		bx	r4

@ Quick version of %s used when no bells and whistles are requested
quick_s:	bl	getParam32
		mov	r9,r5
		movs	r5,r0
		cmp	r0,0
		bne	1f
		ldr	r5,=strNull
1:		ldrb	r0,[r5]
		cmp	r0,0
		beq	2f
1:		adds	r5,1
		bl	out1
		ldrb	r0,[r5]
		cmp	r0,0
		bne	1b
2:		mov	r5,r9
		b	mainLoopC

@ Quick version of %c used when no bells and whistles are requested
quick_c:	bl	getParam32	@ get parameter
		bl	out1		@ output char
		b	mainLoopC	@ return to main


/*
   Parse roughly this syntax (regex form):

  ^
  ( [^%]      # Non-formatting character
  | %%        # Percent character
  | %[cs]     # Fast-track %c and %s for speed
  | %         # Format spec introducer
    ([1-9][0-9]* \$)?     # Optional parameter number
    [ 0'#+-]*             # Flags, zero or more
    ( [0-9]+              # Numeric width
    | \* ([0-9]+ \$)?     # Parametric width, optional parameter number
    )?                    # Width is optional
    (\.                   # Precision introducer
      ( [0-9]+            # Numeric precision
      | \* ([0-9]+ \$)?   # Parametric precision, optional parameter number
      )?                  # Value is optional, 0 if not specified
    )?                    # Precision is optional
    ( hh?|ll?|[ZzjtL] )?  # Optional length
    ( [aAcdeEfFgGinopsuxX] | . )  # Type suffix, catch-all for syntax errors
  )*          # zero or more
  $

  Note: This is a deterministic RE. Allowing a 0 in the first positional
  parameter would change that, so we don't.

*/

@ Offset of the locals themselves relative to R6
@ Note: These can't be arbitrarily changed. Some are chosen strategically.
@       See comment below.
L_FLAGS		= 0*4
L_PFX		= 1*4	@ 4 bytes "Pascal" string; can be sign, 0x or empty
L_WIDTH		= 2*4
L_PREC		= 3*4
L_SIZE		= 4*4	@ h, l, j, z, t, L; internal: c, s
L_BUF		= 5*4	@ 32 bytes, 8 words (max used length is 31)
L_PARAM		= 13*4	@ Parameter index (%n$...)
L_FMTCHAR	= L_SIZE+1	@ format char: a,e,f,g (used for floats)

@ Maximum necessary length for the buffer is 31:
@  2: We use one extra byte after the string terminator, for halfword
@     alignment in conv64toDecARM.
@ 22: Octal for UINT64_MAX = 1777777777777777777777 (length 22)
@  7: Commas added (result = 1,777,777,777,777,777,777,777)
@ All other variations don't use the buffer or use fewer chars.

@ Locals size = last + 4
LOCALS_SIZE	= 14*4

@ Flag field definitions
@ Note: These can't be arbitrarily changed. Some are chosen strategically.
@       See comment below.
F_USE_POS	= 0	@ Use positional params n$ (*)
F_PLUS		= 1	@ + sign for positive, + flag (preferred)
F_1000_SEP	= 2	@ thousands sep, "'" flag
F_ALT		= 3	@ alternative form, # flag
F_ZEROPAD	= 4	@ zero padding, 0 flag
F_LOWER		= 5	@ lower case flag
F_LJUST		= 6	@ left justify flag, - flag
F_SIGNED	= 7	@ signed format (%d, %i)
F_SPACE		= 8	@ space in positive numbers, " " flag

/*
(*) We don't know the index of the main argument in advance, due to the fact
    that there may or may not be a * for width and prec. Therefore, we can't
    use a field initialized to the position of the argument that we override
    in case there is a positional parameter; we use a flag instead to switch
    modes when necessary.

F_USE_POS must be zero, as 1<<F_USE_POS is presumed to be 1 on initialization
of current % parameter section (see parseFmtStr).

F_LOWER must be 5, because that's de difference between upper and lower case.

F_SPACE must be > F_PLUS so that we can use two shifts in a row, e.g.
		lsrs	r2,F_PLUS+1
		bcs	isPlus
		lsrs	r2,F_SPACE-F_PLUS
		bcs	isSpace
Similarly, F_LJUST must be > F_ZEROPAD.
Similarly, F_ALT must be < F_ZEROPAD.

L_SIZE, L_FMTCHAR are 1 byte in size.
They can share a word.
*/

@ size_t acsl_formatStr(void (*handler)(char c), const char *fmt, va_list v);

acsl_formatStr:
		mov	r12,r2
		mov	r2,r8
		mov	r3,r9
		push	{r2-r7,lr}	@ save regs
		sub	sp,LOCALS_SIZE
		mov	r6,sp
		mov	r8,r12		@ R8 = varargs pointer
		movs	r4,r0		@ R4 = output function
		movs	r5,r1		@ R5 = format string pointer
		movs	r7,0		@ R7 = character counter
		str	r7,[r6,L_FLAGS]	@ Clear flags

		@ Main loop
mainLoopC:	ldrb	r0,[r5]
		adds	r5,1
		cmp	r0,'%'		@ Format char?
		beq	parseFmtStr
		cmp	r0,0		@ End of string?
		beq	acsl_endFmtStr
prtChr:		bl	out1		@ output character
		b	mainLoopC

acsl_endFmtStr:	mov	sp,r6		@ clear any stacking levels
		add	sp,LOCALS_SIZE
		movs	r0,r7		@ return # of characters output
		pop	{r2-r7}
		mov	r8,r2
		mov	r9,r3
		pop	{r3}
		bx	r3		@ return

parseFmtStr:
		ldrb	r0,[r5]
		adds	r5,1
		cmp	r0,'%'
		beq	prtChr		@ if %%, print %
		cmp	r0,'c'		@ if %c, fast-track it
		beq	quick_c
		cmp	r0,'s'		@ if %s, fast-track it
		beq	quick_s

		@ Initialize current parameter

		ldr	r1,[r6,L_FLAGS]
		movs	r2,1<<F_USE_POS
		ands	r1,r2		@ Clear all flags except F_USE_POS
		str	r1,[r6,L_FLAGS]
		movs	r1,0
		str	r1,[r6,L_WIDTH]
		strb	r1,[r6,L_SIZE]
		str	r1,[r6,L_PFX]
		str	r1,[r6,L_BUF+28]
		negs	r2,r2
		str	r2,[r6,L_PREC]		@ default to -1

		cmp	r0,'9'
		bhi	flagChk
		cmp	r0,'1'
		blo	flagChk

		bl	getNumber

		cmp	r0,'$'
		bne	gotWidth		@ if not a $, the number must
						@ be a width

		@ Store pointer to positional parameter
		subs	r1,1
		lsls	r1,2
		add	r1,r8
		str	r1,[r6,L_PARAM]

		ldr	r1,[r6,L_FLAGS]
		movs	r2,1<<F_USE_POS		@ from now on, positional
		orrs	r1,r2			@ parameters must always be
		str	r1,[r6,L_FLAGS]		@ used

		ldrb	r0,[r5]			@ consume the '$'
		adds	r5,1

flagChk:	cmp	r0,'+'
		bhi	chkMinusZero
		beq	flagPlus
		cmp	r0,'#'
		blo	chkSpace
		beq	flagHash
		cmp	r0,39		@ ord("'")
		bne	notFlag

		@ "'" flag - F_1000_SEP
		movs	r2,1<<F_1000_SEP
flagSet:	ldr	r1,[r6,L_FLAGS]		@ entry point; set flag in r2
		orrs	r1,r2
		str	r1,[r6,L_FLAGS]
		ldrb	r0,[r5]			@ consume the flag
		adds	r5,1
		b	flagChk

flagHash:	@ "#" flag, F_ALT
		movs	r2,1<<F_ALT
		b	flagSet

flagPlus:	@ "+" flag, F_PLUS
		movs	r2,1<<F_PLUS
		b	flagSet

chkSpace:	cmp	r0,' '
		bne	notFlag

		@ " " flag - F_SPACE
		movs	r2,1
		lsls	r2,F_SPACE
		b	flagSet

chkMinusZero:	movs	r2,1<<F_LJUST
		cmp	r0,'-'
		beq	flagSet
		movs	r2,1<<F_ZEROPAD
		cmp	r0,'0'
		beq	flagSet

notFlag:	cmp	r0,'1'
		bhs	chkWidthNum

		cmp	r0,'*'
		bne	chkDot

		@ Asterisk - if we're in positional mode, read a position;
		@ otherwise read the param. Either way, go to gotWidth.
		ldrb	r0,[r5]		@ consume the '*'
		adds	r5,1

		ldr	r1,[r6,L_FLAGS]
		lsrs	r1,F_USE_POS+1
		bcs	1f

		mov	r2,r8
		ldr	r1,[r2]
		adds	r2,4
		mov	r8,r2
		b	gotWidth

1:		bl	getNumber
		cmp	r0,'$'		@ '*'+number not followed by '$'?
		bne	chkDot		@ syntax error, hmmm...

		ldrb	r0,[r5]		@ consume the '$'
		adds	r5,1

		subs	r1,1
		lsls	r1,2
		add	r1,r8
		ldr	r1,[r1]
		b	gotWidth

chkWidthNum:	cmp	r0,'9'
		bhi	chkDot

		bl	getNumber

gotWidth:	cmp	r1,0
		bge	1f
		@ Negative width parameter counts as LJUST
		negs	r1,r1
		ldr	r2,[r6,L_FLAGS]
		movs	r3,1<<F_LJUST
		orrs	r2,r3
		str	r2,[r6,L_FLAGS]
1:		str	r1,[r6,L_WIDTH]

chkDot:		cmp	r0,'.'
		bne	chkSize

		ldrb	r0,[r5]		@ consume the '.'
		adds	r5,1

		movs	r1,0
		str	r1,[r6,L_PREC]	@ default in presence of '.' (stdC)

		cmp	r0,'0'
		bhs	chkPrecNum

		cmp	r0,'*'
		bne	chkSize

		ldrb	r0,[r5]		@ consume the '*'
		adds	r5,1

		ldr	r1,[r6,L_FLAGS]
		lsrs	r1,F_USE_POS+1
		bcs	1f

		mov	r2,r8
		ldr	r1,[r2]
		adds	r2,4
		mov	r8,r2
		b	gotPrec

1:		bl	getNumber
		cmp	r0,'$'		@ *number not followed by '$'?
		bne	chkSize		@ syntax error, hmmm...

		ldrb	r0,[r5]		@ consume the '$'
		adds	r5,1

		subs	r1,1
		lsls	r1,2
		add	r1,r8
		ldr	r1,[r1]
		b	gotPrec

chkPrecNum:	cmp	r0,'9'
		bhi	chkSize

		bl	getNumber

gotPrec:	str	r1,[r6,L_PREC]

chkSize:	cmp	r0,'l'
		beq	gotLSize
		cmp	r0,'j'
		beq	gotSize
		cmp	r0,'L'
		beq	gotSize
		cmp	r0,'z'
		beq	gotSize
		cmp	r0,'t'
		beq	gotSize
		cmp	r0,'h'
		bne	chkType
		movs	r1,r0		@ R1 = flag to store in L_SIZE
		ldrb	r0,[r5]		@ consume the 'h'
		adds	r5,1
		cmp	r0,'h'		@ another 'h'?
		bne	1f		@ if not, store and we're done
		movs	r1,'c'		@ turn 'hh' into 'c' (internal flag)
		ldrb	r0,[r5]		@ consume the second 'h'
		adds	r5,1
1:		strb	r1,[r6,L_SIZE]
		b	chkType

gotLSize:	ldrb	r1,[r5]		@ peek next char
		cmp	r1,'l'		@ another 'l'?
		bne	gotSize		@ if not, treat as normal size char
		adds	r5,1		@ consume first 'l'
		movs	r0,'j'		@ act as if 'll' was 'j'

gotSize:	strb	r0,[r6,L_SIZE]
		ldrb	r0,[r5]		@ consume size char
		adds	r5,1

chkType:	movs	r1,'a' ^ 'A'	@ get case bit, that should be 0x20
		ands	r1,r0		@ isolate r0's letter case bit in r1
		bics	r0,r1		@ turn r0 to caps

		@ Comparison tree, max 4 comparisons:
		@ ((((a) c [d]) e ([f] (g))) i (((n) o (p)) s (u (x))))
		cmp	r0,'I'
		beq	fmt_i
		bhi	chk_nopsux

		cmp	r0,'E'
		beq	fmt_e_pxy
		bhi	chk_fg

		cmp	r0,'C'
		beq	fmt_c_pxy
		bhi	fmt_d

		cmp	r0,'A'
		beq	fmt_a_pxy
		b	mainLoopC	@ unrecognized, skip it

fmt_e_pxy:	b	fmt_e
fmt_a_pxy:	b	fmt_a
fmt_c_pxy:	b	fmt_c

chk_fg:		cmp	r0,'G'
		bne	fmt_f_pxy
		b	fmt_g

fmt_f_pxy:	b	fmt_f

chk_nopsux:	cmp	r0,'S'
		beq	fmt_s_pxy
		bhi	chk_ux

		cmp	r0,'O'
		beq	fmt_o_pxy
		bhi	chk_p

		cmp	r0,'N'
		beq	fmt_n_pxy
		b	mainLoopC

fmt_n_pxy:	b	fmt_n
fmt_o_pxy:	b	fmt_o

chk_p:		cmp	r0,'P'
		beq	fmt_p_pxy
		b	mainLoopC

fmt_p_pxy:	b	fmt_p
fmt_s_pxy:	b	fmt_s

chk_ux:		cmp	r0,'U'
		beq	fmt_u_pxy
		cmp	r0,'X'
		beq	fmt_x_pxy
		b	mainLoopC

fmt_u_pxy:	b	fmt_u
fmt_x_pxy:	b	fmt_x



@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ Format char handlers
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

fmt_u:		cmp	r1,0		@ upper?
		beq	mainLoopC_1	@ d and i must both be lowercase
		b	common_u_i_d

fmt_i:		@ i & d are treated as equal
fmt_d:
		cmp	r1,0		@ upper?
		beq	mainLoopC_1	@ d and i must both be lowercase
		movs	r1,1<<F_SIGNED
		ldr	r2,[r6,L_FLAGS]
		orrs	r2,r1
		str	r2,[r6,L_FLAGS]

common_u_i_d:
		bl	getParam32or64
		ldr	r2,[r6,L_FLAGS]
		ldrb	r3,[r6,L_SIZE]
		cmp	r3,'j'
		beq	int64_d

		lsrs	r1,r2,F_SIGNED+1
		bcc	noSignD
		cmp	r0,0
		blt	negSignD
		ldr	r3,='+'*256+1
		lsrs	r1,r2,F_PLUS+1
		bcs	setSignD	@ PLUS has precedence over SPACE
		ldr	r3,=' '*256+1
		lsrs	r1,r2,F_SPACE+1
		bcs	setSignD
		b	noSignD
negSignD:	negs	r0,r0
		ldr	r3,='-'*256+1
setSignD:	str	r3,[r6,L_PFX]
noSignD:	movs	r1,r0
		movs	r0,r6
		adds	r0,L_BUF
		bl	conv32toDec
		movs	r1,r6
		adds	r1,L_BUF+30
		subs	r1,r0
		mov	r9,r0
		bl	addCommas
		b	fmtBuf

int64_d:	mov	r12,r5		@ we're out of scratch registers!
		movs	r3,0
		lsrs	r5,r2,F_SIGNED+1
		bcc	noSignLLD
		cmp	r1,0
		blt	negSignLLD
		ldr	r3,='+'*256+1
		lsrs	r5,r2,F_PLUS+1
		bcs	setSignLLD
		ldr	r3,=' '*256+1
		lsrs	r5,r2,F_SPACE+1
		bcs	setSignLLD
		b	noSignLLD
negSignLLD:	movs	r3,r1
		movs	r1,0
		negs	r0,r0
		sbcs	r1,r3
		ldr	r3,='-'*256+1
setSignLLD:	str	r3,[r6,L_PFX]
noSignLLD:	mov	r5,r12		@ phew
		movs	r2,r0
		movs	r3,r1
		movs	r0,r6
		adds	r0,L_BUF
		bl	conv64toDec
		movs	r1,r6
		adds	r1,L_BUF+30
		subs	r1,r0
		bl	addCommas
		b	fmtBuf

fmt_c:		cmp	r1,0		@ upper?
		beq	mainLoopC_1	@ c must be lowercase
		movs	r0,0
		ldr	r1,[r6,L_PREC]
		mov	r9,r1		@ R9 = original PREC
		str	r0,[r6,L_PREC]	@ Zero out PREC

		bl	getParam32
		str	r0,[r6,L_BUF+24]
		movs	r2,L_BUF+24
		adds	r0,r6,r2
		movs	r1,1
		b	common_c_s

strlen_w:	movs	r3,'s'		@ store 's' to flag long string/char
		strb	r3,[r6,L_SIZE]
		bl	wcslen
		b	common_s_ls

fmt_s:		cmp	r1,0		@ upper?
		beq	mainLoopC_1	@ s must be lowercase
		ldr	r1,[r6,L_PREC]
		mov	r9,r1		@ R9 = original PREC
		movs	r1,0
		str	r1,[r6,L_PREC]	@ Zero out PREC

		bl	getParam32
		cmp	r0,0
		bne	strNotNull

		@ Null string pointer handling
		ldr	r0,=strNull
		movs	r1,strNull_len

		mov	r2,r9
		cmp	r2,0
		blt	nullOk
		cmp	r1,r2
		ble	nullOk
		movs	r1,0		@ no output if it doesn't fit
nullOk:		b	fmtBuf

mainLoopC_1:	b	mainLoopC

strNotNull:
		ldrb	r2,[r6,L_SIZE]
		cmp	r2,'l'
		push	{r0}
		beq	strlen_w
		bl	strlen
common_s_ls:	movs	r1,r0
		pop	{r0}

common_c_s:	ldrb	r3,[r6,L_SIZE]
		cmp	r3,'l'		@ long string?

		@ unsigned comparison so that a negative value acts as
		@ a very high value
		cmp	r1,r9		@ is R1 already the smallest?
		blo	1f
		mov	r1,r9		@ grab from R9
1:
		b	fmtBuf

fmt_p:		cmp	r1,0		@ upper?
		beq	mainLoopC_1	@ p must be lowercase

		ldr	r2,[r6,L_FLAGS]
		movs	r1,1<<F_ALT | 1<<F_LOWER
		orrs	r2,r1
		str	r2,[r6,L_FLAGS]
		movs	r1,'x'
		strb	r1,[r6,L_PFX+2]
		bl	getParam32
		movs	r1,0
		cmp	r0,0
		bne	common_x_p
		subs	r0,1
		str	r0,[r6,L_PREC]	@ For printing (nil), prec is ignored
		ldr	r0,=strNil
		movs	r1,strNil_len
		b	fmtBuf		@ Print (nil) as string

fmt_x:		ldr	r0,[r6,L_FLAGS]
		orrs	r0,r1		@ Copy LOWER flag from r1
		str	r0,[r6,L_FLAGS]
		movs	r3,'X'
		orrs	r3,r1
		strh	r3,[r6,L_PFX+2]	@ Hack: it's never printed if the
					@ previous char is empty

		bl	getParam32or64
		ldr	r2,[r6,L_FLAGS]
		movs	r3,r0
		orrs	r3,r1
		beq	1f		@ Zero never has a 0x prefix

		lsrs	r3,r2,F_ALT+1	@ 0x notation requested?
		bcc	1f		@ jump if not
		@ Set 0x prefix
common_x_p:	movs	r3,'0'
		strb	r3,[r6,L_PFX+1]
		movs	r3,2
		strb	r3,[r6,L_PFX]
1:
		movs	r3,1<<F_LOWER
		ands	r3,r2
		adds	r3,'A'-('9'+1)
		mov	r12,r3		@ R12 = 7 or 27h depending on case

		movs	r2,r6
		adds	r2,L_BUF+30	@ parameter for conv32toHex

		cmp	r1,0
		bne	int64_x
		bl	conv32toHex
		movs	r1,r6
		adds	r1,L_BUF+30
		subs	r1,r0
		bl	addCommas
		b	fmtBuf

int64_x:	bl	conv64toHex
		movs	r1,r6
		adds	r1,L_BUF+30
		subs	r1,r0
		bl	addCommas
		b	fmtBuf

fmt_o:		cmp	r1,0		@ upper?
		beq	mainLoopC_1	@ o must be lowercase

		bl	getParam32or64

		movs	r2,r6
		adds	r2,L_BUF+30
		movs	r3,r1
		orrs	r3,r0
		beq	endConv_o

1:		lsls	r3,r0,29
		lsrs	r3,29
		adds	r3,'0'
		subs	r2,1
		strb	r3,[r2]
		lsls	r3,r1,29
		lsrs	r0,3
		orrs	r0,r3
		lsrs	r1,3
		bne	1b
		cmp	r0,0
		bne	1b

endConv_o:	movs	r0,r2
		movs	r1,r6
		adds	r1,L_BUF+30
		subs	r1,r0
		bl	addCommas
		@ We do the same as GCC here, namely to include commas in
		@ the count of digits for precision purposes.
		ldr	r3,[r6,L_FLAGS]
		lsrs	r3,F_ALT+1	@ # flag?
		bcc	1f		@ if not # then skip
		@ The # flag makes it difficult to predict the length
		ldr	r2,[r6,L_PREC]
		subs	r2,1
		cmp	r2,r1
		bge	1f
		lsrs	r3,F_ZEROPAD-F_ALT	@ 0 flag?
		bcc	2f		@ add extra zero to PREC if not
		lsrs	r3,F_LJUST-F_ZEROPAD
		bcs	2f		@ if LJUST, ZEROPAD is ignored
		ldr	r3,[r6,L_WIDTH]
		adds	r2,r1,1		@ length of number + extra zero
		cmp	r3,r2		@ WIDTH enough for that length?
		bhs	1f		@ do nothing if so

2:		adds	r2,r1,1
		str	r2,[r6,L_PREC]	@ set precision to length+1

1:		b	fmtBuf


fmt_n:		cmp	r1,0		@ upper?
		beq	1f		@ n must be lowercase

		bl	getParam32
		ldrb	r1,[r6,L_SIZE]
		cmp	r1,'h'
		beq	n_halfword
		cmp	r1,'c'
		beq	n_byte
		str	r7,[r0]
		cmp	r1,'j'
		bne	1f
		movs	r1,0
		str	r1,[r0,4]
1:		b	mainLoopC

n_halfword:	strh	r7,[r0]
		b	1b
n_byte:		strb	r7,[r0]
		b	1b


		.ltorg


		.ifdef	WITH_FLOAT_FORMATTING

		.include "float_fmt.inc"
		@ the include may leave another section active
		.section .text
		.thumb

		.else

fmt_a:
fmt_e:
fmt_f:
fmt_g:
		movs	r0,'j'
		strb	r0,[r6,L_SIZE]
		bl	getParam32or64
		movs	r0,'%'
		bl	out1
		subs	r5,1
		ldrb	r0,[r5]
		b	mainLoopC

		.section .rodata
strNoFloat:	.asciz	"Floating-point support for format strings was not included in this build."

		.section .text
		.thumb

		.endif

@ Formatting for all flags
@ Calculates:
@  - How much left padding to apply
@  - How much zero padding to apply
@  - How much right padding to apply
@  - Which flags are preserved and which flags are ditched
@ Outputs, in that order (when applicable):
@  - Left space padding
@  - Sign or 0x
@  - Zero padding
@  - The buffer (always)
@  - Right space padding
@ Input: R0 = buffer ptr, R1 = buffer length (or max to print for %s)
@ L_PREC = number of zeros to print. Note: This is not the same meaning as
@          the precision specifier. Note: this should be set to 0 by the
@          %s and %c formats. If negative, we assume 1.
fmtBuf:		push	{r5,r7}
		mov	r9,r0
		movs	r5,r1
		ldr	r1,[r6,L_PREC]
		cmp	r1,0
		bge	1f		@ if specified, use it
		movs	r3,1		@ if not, use
		str	r3,[r6,L_PREC]	@ replace PREC with that
1:		ldr	r2,[r6,L_WIDTH]
		cmp	r2,0
		beq	ignore_lpad
		ldr	r2,[r6,L_FLAGS]
		lsrs	r3,r2,F_LJUST+1	@ left-padding is for right
		bcs	ignore_lpad	@ justification, not left
		lsrs	r3,r2,F_ZEROPAD+1
		bcc	apply_lpad	@ Left padding with spaces
		cmp	r1,0
		bge	apply_lpad	@ if PREC present, zero flag ignored
		@ Right-justify with zero padding via L_PREC
		ldr	r0,[r6,L_WIDTH]
		ldrb	r3,[r6,L_PFX]	@ first byte is length
		subs	r0,r3		@ minus prefix length
		cmp	r0,1		@ minimum length: 1 zero
		bgt	1f
		movs	r0,1
1:		str	r0,[r6,L_PREC]	@ use as prec
		b	ignore_lpad	@ No spaces; zero pad will effect it

		@ Space padding
apply_lpad:	ldr	r0,[r6,L_WIDTH]


		@ Calculate non-padding length to output
		ldr	r3,[r6,L_PREC]
		cmp	r3,r5		@ calculate r3 = max(r3, r5)
		bhi	1f
		movs	r3,r5
1:		subs	r0,r3		@ spaces to print = width - length
		ldrb	r3,[r6,L_PFX]
		subs	r0,r3		@ ... - prefix length
		ble	ignore_lpad	@ zero or negative: add no spaces

		@ Print spaces
1:		push	{r0}
		movs	r0,' '
		bl	out1
		pop	{r0}
		subs	r0,1
		bhi	1b
ignore_lpad:
		@ Now output the prefix
		ldrb	r0,[r6,L_PFX+1]
		cmp	r0,0
		beq	1f
		bl	out1
		ldrb	r0,[r6,L_PFX+2]
		cmp	r0,0
		beq	1f
		bl	out1
1:
		@ Now print zero padding
		ldr	r0,[r6,L_PREC]
		subs	r0,r5
		ble	print_buffer

1:		push	{r0}
		movs	r0,'0'
		bl	out1
		pop	{r0}
		subs	r0,1
		bhi	1b
print_buffer:
		cmp	r5,0
		beq	2f
		ldrb	r1,[r6,L_SIZE]
		cmp	r1,'s'
		beq	longstring
		@ Output the buffer
1:		mov	r1,r9
		ldrb	r0,[r1]
		adds	r1,1
		mov	r9,r1
		bl	out1
		subs	r5,1
		bhi	1b
2:
		@ Apply right space padding if applicable
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_LJUST+1
		bcc	endFmtBuf	@ done if not left-justified
		ldr	r0,[sp,4]	@ saved R7
		subs	r0,r7,r0	@ r0 = total length printed
		ldr	r5,[r6,L_WIDTH]
		subs	r5,r0
		bls	endFmtBuf	@ no right padding to apply

1:		movs	r0,' '
		bl	out1
		subs	r5,1
		bhi	1b

endFmtBuf:	ldr	r5,[sp]
		add	sp,8
		b	mainLoopC_1	@ Consume and continue

longstring:	mov	r1,r9
		ldr	r0,[r1]
		adds	r1,4
		mov	r9,r1
		bl	out1
		subs	r5,1
		bhi	longstring
		b	2b

getParam32hi0:	movs	r1,0
getParam32:	ldr	r0,[r6,L_FLAGS]
		lsrs	r0,F_USE_POS+1
		bcs	1f

		mov	r3,r8
		ldmia	r3!,{r0}
		mov	r8,r3

2:		ldrb	r3,[r6,L_SIZE]
		cmp	r3,'c'
		beq	char_param
		cmp	r3,'h'
		beq	short_param
		bx	lr

1:		ldr	r3,[r6,L_PARAM]
		ldr	r0,[r3]
		b	2b

char_param:	lsls	r0,24
		ldr	r3,[r6,L_FLAGS]
		lsrs	r3,F_SIGNED+1
		bcs	1f
		lsrs	r0,24
		bx	lr
1:		asrs	r0,24
		bx	lr

short_param:	lsls	r0,16
		ldr	r3,[r6,L_FLAGS]
		lsrs	r3,F_SIGNED+1
		bcs	1f
		lsrs	r0,16
		bx	lr
1:		asrs	r0,16
		bx	lr

getParam32or64:	ldrb	r2,[r6,L_SIZE]
		cmp	r2,'j'
		bne	getParam32hi0	@ No alignment fiddling

		ldr	r0,[r6,L_FLAGS]
		lsrs	r0,F_USE_POS+1	@ using positional?
		bcs	1f		@ go to handle positional if so

		mov	r3,r8		@ long param
		adds	r3,7
		lsrs	r3,3
		lsls	r3,3		@ aligned to double word
		ldmia	r3!,{r0,r1}	@ grab params
		mov	r8,r3		@ store updated pointer
		bx	lr

1:		ldr	r3,[r6,L_PARAM]
		ldmia	r3!,{r0,r1}		@ 0-based first elem is here
		bx	lr

		@ read a number from the current position
		@ returns R0 = next character, R1 = number
		@ (that's not AAPCS compliant, but it's internal anyway)
getNumber:	movs	r1,0
		movs	r2,10
1:		cmp	r0,'9'
		bhi	bxlr
		subs	r0,'0'
		blo	adj_bxlr
		muls	r1,r2
		adds	r1,r0
		ldrb	r0,[r5]
		adds	r5,1
		b	1b

adj_bxlr:	adds	r0,'0'
bxlr:		bx	lr

conv64toDec:	ldr	r1,=conv64toDecARM
		bx	r1

conv32toDec:	ldr	r2,=conv32toDecARM
		bx	r2

		.ltorg

conv64toHex:	movs	r3,r0
		orrs	r3,r1
		beq	3f		@ zero? finish
1:		lsls	r3,r0,28
		lsrs	r3,28
		adds	r3,'0'
		cmp	r3,'9'
		bls	2f
		add	r3,r12
2:		subs	r2,1
		strb	r3,[r2]
		lsls	r3,r1,28
		lsrs	r0,4
		orrs	r0,r3
		lsrs	r1,4
		bne	1b
		@ fall through

conv32toHex:	cmp	r0,0
		beq	3f		@ early exit if zero

1:		lsls	r1,r0,28
		lsrs	r1,28
		adds	r1,'0'
		cmp	r1,'9'
		bls	2f
		add	r1,r12
2:		subs	r2,1
		strb	r1,[r2]
		lsrs	r0,4
		bne	1b
3:		movs	r0,r2
		bx	lr

@ Add commas as thousand separators into the buffer.
@ Input: r0 = pointer, r1 = length
@ Output: r0 = new pointer, r1 = new length
addCommas:	cmp	r1,4
		blt	bxlr
		ldr	r2,[r6,L_FLAGS]
		lsrs	r2,F_1000_SEP+1
		bcc	bxlr
		ldr	r3,=0x20000/3+1
		subs	r1,1
		muls	r3,r1
		lsrs	r3,17		@ R3 = (length-4)/3 = nr of commas -1
		subs	r2,r0,r3	@ point R2 to where to store result
		mov	r12,r3
		adds	r3,r3
		add	r3,r12		@ R3 *= 3
		mov	r12,r2		@ we'll return this pointer
		subs	r1,r3		@ R1 = length % 3
		cmp	r1,0
		beq	one_digit
		cmp	r1,1
		beq	two_digits
		ldrb	r1,[r0]
		strb	r1,[r2]
		adds	r0,1
		adds	r2,1
two_digits:	ldrb	r1,[r0]
		strb	r1,[r2]
		adds	r0,1
		adds	r2,1
one_digit:	ldrb	r1,[r0]
		strb	r1,[r2]
		movs	r1,','
		strb	r1,[r2,1]
		subs	r3,3
		bls	noMoreCommas
		adds	r0,1
		adds	r2,2
1:		ldrb	r1,[r0]
		strb	r1,[r2]
		ldrb	r1,[r0,1]
		strb	r1,[r2,1]
		ldrb	r1,[r0,2]
		strb	r1,[r2,2]
		movs	r1,','
		strb	r1,[r2,3]
		adds	r0,3
		adds	r2,4
		subs	r3,3
		bhi	1b

noMoreCommas:	mov	r0,r12
		movs	r1,r6
		adds	r1,L_BUF+30
		subs	r1,r0
		bx	lr


		.ltorg
/*
passpt:
	push	{r0}
	mov	r0,r12
	push	{r0-r3,lr}
	ldr	r0,=debugText
	mov	r1,1
	mov	lr,r1
	ldr	r1,=acsl_printText+1
	add	lr,pc
	bx	r1
	pop	{r0-r3}
	mov	r12,r0
	pop	{r0}
	mov	lr,r0
	pop	{r0}
	bx	lr
	.pool
debugText:	.asciz "*debug*"
.balign 2
*/

		.section .rodata

strNull:	.asciz	"(null)"
strNull_len	= . - 1 - strNull
strNil:		.asciz	"(nil)"
strNil_len	= . - 1 - strNil

		.balign	2
mod100tbl:	.ascii	"00010203040506070809"
		.ascii	"10111213141516171819"
		.ascii	"20212223242526272829"
		.ascii	"30313233343536373839"
		.ascii	"40414243444546474849"
		.ascii	"50515253545556575859"
		.ascii	"60616263646566676869"
		.ascii	"70717273747576777879"
		.ascii	"80818283848586878889"
		.ascii	"90919293949596979899"


		.section .text.ARM
		.arm
		.balign	4

@ The AAPCS specifies that the register numbers should be rounded to the next
@ even number when the arg occupies 2 words, hence why numlo and numhi are
@ r2 and r3, and r1 is unused on entry.

ptrbuf		.req	r0		@ output buffer pointer
quot		.req	r1		@ quotient (always < 100)
numlo		.req	r2		@ initial number, numerator
numhi		.req	r3		@ initial number, high word
denlo		.req	r4		@ denominators (1e18, 1e16...)
denhi		.req	r5		@ denominators, high word
tmplo		.req	r6		@ temp result of subtraction,
tmphi		.req	r7		@ used to avoid a branch
ctr		.req	r12		@ loop counter itself

/*
  Divide numhi:numlo (up to ~1.8e19) by 1e18.
  Algorithm: schoolbook division in binary.
  Use quotient as index into a 100-element table of digits.
  Remainder stays in numhi:numlo.

  In total, we make 61 compare/shift operations.
*/
@ Entry: R0 = pointer to 32-byte buffer, R2 = low and R3 = high words of
@ positive 64-bit number to convert (< 2^64)
conv64toDecARM:	stmfd	sp!,{r4-r7,lr}

		add	ptrbuf,#30-20	@ end of buf is 30 positions forward;
					@ number is 20 digits long

		ldr	denhi,=0xde0b6b3a	@ 1e18 * 16, high word
		mov	denlo,0x76000000	@ 1e18 * 16, low word
		add	denlo,0x00400000	@ complete it
		mov	ctr,5-1		@ 5 quotient bits (0..18)
		bl	div64spN

		@ Now divide the remainder by 1e16.
		@ Otherwise, same idea.
		ldr	denhi,=0x08e1bc9b	@ 1e16 * 64, high word
		mov	denlo,0xf0000000	@ 1e16 * 64, low word
		add	denlo,0x00400000	@ complete it
		bl	div64sp7

		@ Same with 1e14.
		ldr	denhi,=0x0016bcc4	@ 1e14 * 64, high word
		mov	denlo,0x1e000000	@ 1e14 * 64, low word
		add	denlo,0x00900000	@ complete it
		bl	div64sp7

		@ Same with 1e12.
		mov	denhi,0x00003a00	@ 1e12 * 64, high word
		add	denhi,0x00000035	@ complete it
		mov	denlo,0x29000000	@ 1e12 * 64, low word
		add	denlo,0x00440000	@ complete it
		bl	div64sp7

		@ Same with 1e10.
		mov	denhi,0x00000095	@ 1e10 * 64, high word
		mov	denlo,0x02f00000	@ 1e10 * 64, low word
		add	denlo,0x00090000	@ complete it
		bl	div64sp7

		@ Same with 1e8.
		mov	denhi,0x00000001	@ 1e8 * 64, high word
		ldr	denlo,=0x7d784000	@ 1e8 * 64, low word
		bl	div64sp7

		@ Same with 1e6
		mov	denhi,0
		mov	denlo,0x03d00000	@ 1e6 * 64
		add	denlo,0x00009000
		bl	div64sp7

		@ Same with 1e4.
		mov	denlo,0x0009c000	@ 10000 * 64
		add	denlo,0x00000400
		bl	div64sp7

		@ Same with 1e10.
		mov	denlo,0x00001900	@ 100 * 64
		bl	div64sp7

		@ At this stage, we switch to a 32-bit method
		@ because numhi is now zero.

		@ Last 2 digits are in numlo
		mov	quot,numlo
		bl	store2Digits
		mov	quot,#0
		strh	quot,[ptrbuf]	@ add string terminator

		sub	ptrbuf,21	@ back to the beginning of the buffer
					@ and back 1 char for loop to work

		@ Scan for first non-'0' from the left
1:		ldrb	quot,[ptrbuf,1]!
		cmp	quot,'0'
		beq	1b

		ldmfd	sp!,{r4-r7,lr}
		bx	lr

		@ Specialized division: N(64b) / d(64b) = (q(32b), r(64b)).
		@ The count of quotient bits is a parameter; the divisor
		@ comes pre-adjusted to the highest bit of N.

div64sp7:	mov	ctr,7-1		@ Seven quotient bits
div64spN:	mov	quot,0		@ Ready to accept bits

		subs	tmplo,numlo,denlo	@ subtract; if it doesn't fit,
		sbcs	tmphi,numhi,denhi	@ we won't commit the result
		adc	quot,quot	@ shift the bit into the LSB of quot
		movcs	numlo,tmplo	@ it fits; commit result
		movcs	numhi,tmphi
1:		@ denominator >>= 1 (64-bit)
		movs	denhi,denhi,lsr 1	@ 64-bit shift
		mov	denlo,denlo,rrx
		@ Repeat the subtraction; set bit and commit if it fits
		subs	tmplo,numlo,denlo
		sbcs	tmphi,numhi,denhi
		adc	quot,quot	@ another quotient bit
		movcs	numlo,tmplo
		movcs	numhi,tmphi
		@ loop counter
		subs	ctr,1
		bhi	1b		@ a wraparound indicates end of loop

store2Digits:
		ldr	denlo,=mod100tbl
		add	quot,quot
		ldrh	quot,[denlo,quot]	@ convert quot to ASCII
		strh	quot,[ptrbuf],2	@ store 2 digits
		bx	lr		@ we're done


		@ Clear register aliases
		.unreq	numlo
		.unreq	numhi
		.unreq	denlo
		.unreq	denhi
		.unreq	quot
		.unreq	ptrbuf
		.unreq	ctr

@ Entry: R0 = 32-byte buffer, R1 = Number
ptrbuf		.req	r0
num		.req	r1
recip		.req	r2
quot		.req	r3
tmp		.req	r12

@ Repeatedly performs a multiplication in fixed point of the 32.0 input
@ with the 0.32 fixed point representation of 1/10, to convert it to decimal.
@ The result is a 32.32 number; we get the quotient directly (the integer
@ part of that number), but the remainder must be obtained with another
@ multiplication. Since the decimal part may not be precise, we calculate the
@ remainder as N - 10*quotient. That gives us the last digit. Then we proceed
@ with the other digits in the same way, bailing out as soon as the quotient
@ is less than 10.

@ To obtain the exact division, we use a more accurate divisor. Instead of
@ 0.32, we're actually using 0.35, where the upper 3 bits are zeros. This
@ means that we need a right shift of 3 positions to obtain the quotient.

conv32toDecARM:	mov	tmp,0
		strh	tmp,[ptrbuf,30]!
		cmp	num,0
		bxeq	lr

		cmp	num,10
		blo	storeLast

		ldr	recip,=0xCCCCCCCD	@ 0x800000000/10+1

1:		umull	tmp,quot,recip,num	@ 'tmp' is discarded
		mov	quot,quot,lsr 3
		add	tmp,quot,quot,lsl 2	@ tmp = quot * 5
		sub	tmp,num,tmp,lsl 1	@ remainder in tmp
		mov	num,quot	@ quotient to num, for next iteration

		add	tmp,'0'
		strb	tmp,[ptrbuf,-1]!

		cmp	num,10
		bhs	1b

storeLast:	add	num,'0'
		strb	num,[ptrbuf,-1]!

		bx	lr

		.ltorg

