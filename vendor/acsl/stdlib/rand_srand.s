/*
 * rand()/srand() implementation for GBA
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

@
@ Random number generation
@ Implements the SFC32 PRNG by Chris Doty-Humphrey
@

		.global	rand
		.global	srand

		.section .data

		.balign	4
		@ equivalent to initialization with seed 0
rngstate:	.word	0xC3EFFE89
		.word	0x8D56782D
		.word	0xF149B0C0
		.word	0x0000000C

		.section .text.f.rand
		.thumb

AA		.req	r1
BB		.req	r2
DD		.req	r0
PTR		.req	r3
rand:		ldr	r3,=rngstate
		movs	AA,0
		ldr	DD,[PTR,12]
		adds	DD,1
		str	DD,[PTR,12]

		ldr	AA,[PTR,0]
		ldr	BB,[PTR,4]
		adds	DD,AA
		adds	DD,BB
		lsrs	AA,BB,9
		eors	AA,BB
		str	AA,[PTR,0]
		.unreq	AA		@ done with AA
CC		.req	r1
		ldr	CC,[PTR,8]
		lsls	BB,CC,3
		adds	BB,CC
		str	BB,[PTR,4]
		lsrs	BB,CC,11
		lsls	CC,32-11
		orrs	CC,BB
		.unreq	BB
		adds	CC,DD
		str	CC,[PTR,8]
		bx	lr
		.unreq	CC
		.unreq	DD

		.ltorg

		.section .text.f.srand
		.thumb

srand:		push	{r4,lr}
		ldr	r1,=rngstate
		str	r0,[r1]
		str	r0,[r1,4]
		str	r0,[r1,8]
		movs	r0,0
		str	r0,[r1,12]
		movs	r4,12
1:		bl	rand
		subs	r4,1
		bhi	1b
		pop	{r2,r3}
		movs	r4,r2
		bx	r3

		.ltorg
