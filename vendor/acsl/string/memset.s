/*
 * memset implementation for GBA
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

		.global	memset

		.section .text.ARM
		.arm

@ void *memset(void *s, int c, size_t n);

memset_arm:	@ Preparatory step: fill a byte if address is odd
		movs	r3,r12,lsr 1
		strbcs	r1,[r12],1
		subscs	r2,1
		bxeq	lr	@ Note: this prevents using a null pointer

		and	r1,0xFF
		orr	r1,r1,r1,LSL 8

		cmp	r2,2
		bls	epilogue

		@ Preparatory step: fill a halfword if address % 4 = 2
		movs	r3,r12,lsr 2
		strhcs	r1,[r12],2
		subscs	r2,2
		bxeq	lr

		orr	r1,r1,r1,LSL 16

		subs	r2,64
		blo	fillWords

		stmfd	sp!,{r0,r4-r8}

		mov	r0,r1
		mov	r3,r1
		mov	r4,r1
		mov	r5,r1
		mov	r6,r1
		mov	r7,r1
		mov	r8,r1

1:		stmia	r12!,{r0-r1,r3-r8}
		stmia	r12!,{r0-r1,r3-r8}
		subs	r2,64
		bhs	1b

		ldmfd	sp!,{r0,r4-r8}

fillWords:	add	r2,64
		subs	r2,4
		blo	fillBytes

1:		stmia	r12!,{r1}
		subs	r2,4
		bhs	1b

fillBytes:	adds	r2,4
		bxeq	lr

		subs	r2,2
epilogue:	strhsh	r1,[r12],2
1:		strneb	r1,[r12]
		bx	lr

		.ltorg

		.text
		.thumb

memset:		mov	r12,r0
		cmp	r2,0
		beq	bxlr
		ldr	r3,=memset_arm
		bx	r3
bxlr:		bx	lr

		.ltorg
