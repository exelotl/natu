/*
 * Auxiliary text drawing functions
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

		.include "gba_constants.inc"

		.global	acsl_renderChar
		.global	acsl_putChar
		.global	acsl_printText
		.global	acsl_printRawText

		.section .data
		.balign	4
acsl_col:	.word	0
acsl_row:	.word	0

		.section .rodata
		.balign	4

FontWidth	= 5
FontHeight	= 8
Font:		.incbin	"fonts/font5x8.bin"

		.text
		.thumb

@ Not optimized for speed

@ uint16_t *acsl_renderChar(uint16_t *dest, char c, int colour);

acsl_renderChar:
		push	{r4-r5}

		@ Parameters for mode 3

		@ R3 = Screen address increment to go to right edge of char
		@ in next scanline from left edge of character
		ldr	r3,=#(240+8)*2
		mov	r12,r3

@ registers:
@ r0 = moving pixel address
@ r1 = character, converted to character bitmap address
@ r2 = input colour
@ r3 = scratch register / inner loop
@ r4 = outer loop
@ r5 = shift register with bits from bitmap
@ r12 = screen address increment to go to next scanline from past the right
@       edge

		@ Next Char
		lsls	r1,#3		@ 8 bytes per character
		ldr	r3,=#Font
		adds	r1,r3		@ add font base

		ldr	r5,[r1]		@ top half of char
		adds	r0,16		@ right edge of char

		movs	r4,#8
3:
		movs	r3,#8
2:
		subs	r0,#2		@ move one pixel left
		lsrs	r5,1
		bcc	1f
		strh	r2,[r0]
1:
		subs	r3,#1		@ dec pixel col counter
		bhi	2b

		add	r0,r12		@ next scanline's screen address

		cmp	r4,#5		@ at row 5, read next half
		bne	1f
		ldr	r5,[r1,#4]	@ load bottom half
1:		subs	r4,#1		@ dec pixel row counter
		bhi	3b

		@ finish and return
		pop	{r4-r5}
bxlr:		bx	lr

		.ltorg


@ void acsl_putChar(char c);
@ Uses state from acsl_col and acsl_row

acsl_putChar:
		ldr	r3,=#acsl_col
		ldr	r1,[r3]		@ R1 = x, R2 = y
		ldr	r2,[r3,#4]
		cmp	r0,#10
		beq	doLF

		cmp	r1,#240/FontWidth
		blo	1f
		movs	r1,#0
		adds	r2,#1
1:		cmp	r2,#160/FontHeight
		beq	Scroll
		bhi	bxlr		@ not necessary if scroll works
		adds	r1,#1
		str	r1,[r3]
		subs	r1,#1
		str	r2,[r3,#4]

		ldr	r3,=#2*FontWidth
		muls	r1,r3
		ldr	r3,=#2*240*FontHeight
		muls	r2,r3
		adds	r2,r1
		movs	r1,r0		@ char to 2nd param
		ldr	r3,=#VRAM
		adds	r0,r2,r3	@ address to 1st param
		ldr	r2,=#0x7FFF
		b	acsl_renderChar

doLF:		movs	r1,#0
		adds	r2,#1
		str	r1,[r3]
		cmp	r2,#160/8
		beq	Scroll
		bhi	bxlr
		str	r2,[r3,#4]
		bx	lr
Scroll:	@ not implemented - update Y and return
		str	r1,[r3]
		str	r2,[r3,#4]
		bx	lr

@ void acsl_printText(char *text);
acsl_printText:
		push	{r4,lr}
		movs	r4,r0
1:		ldrb	r0,[r4]
		adds	r4,#1
		cmp	r0,#0
		beq	1f
		bl	acsl_putChar
		b	1b

1:		pop	{r0,r1}
		movs	r4,r0
		bx	r1

@ void acsl_printRawText(char *text, size_t len);
acsl_printRawText:
		cmp	r1,#0
		beq	bxlr
		push	{r4-r5,lr}
		movs	r4,r0
		movs	r5,r1
1:		ldrb	r0,[r4]
		adds	r4,#1
		bl	acsl_putChar
		subs	r5,#1
		bhi	1b
		pop	{r0-r2}
		movs	r4,r0
		movs	r5,r1
		bx	r2
