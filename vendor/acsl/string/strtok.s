/*
 * strtok implementation for GBA
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

		.global	strtok

		.text
		.thumb

@ char *strtok(char *s1, const char *s2);

strtok:		push	{r4,r5,lr}

		cmp	r0,0
		beq	1f

		ldr	r2,=saved_ptr
		str	r0,[r2]
		b	2f
1:
		ldr	r0,=saved_ptr
		ldr	r0,[r0]
		cmp	r0,0
		beq	retzero
2:
		movs	r4,r0
		movs	r5,r1

		bl	strspn
		adds	r4,r0		@ start of token
		ldrb	r0,[r4]
		cmp	r0,0		@ (used also as return value)
		beq	zeroptr		@ if end of string, zero internal ptr

		movs	r1,r5
		movs	r0,r4
		bl	strcspn
		adds	r1,r0,r4
		movs	r0,r4		@ return value
		ldrb	r2,[r1]
		cmp	r2,0
		beq	zeroptr
		movs	r2,0
		strb	r2,[r1]
		adds	r1,1		@ skip found characer
		ldr	r2,=saved_ptr
		str	r1,[r2]		@ store pointer for next iteration
		b	ret

retzero:	movs	r0,0
ret:		pop	{r1,r2,r3}
		movs	r4,r1
		movs	r5,r2
		bx	r3

zeroptr:	movs	r2,0
		ldr	r1,=saved_ptr
		str	r2,[r1]
		b	ret		@ also return NULL

		.ltorg

		.section .bss
		.balign	4
saved_ptr:	.space	4
