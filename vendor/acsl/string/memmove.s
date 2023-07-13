/*
 * memmove implementation for GBA
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

		.global	memmove

		.section .text.ARM
		.arm

descCopy_arm:	subs	r2,8
		blo	onebyone
1:		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		subs	r2,8
		bhs	1b

onebyone:	adds	r2,8
1:		ldrb	r3,[r0,-1]!
		strb	r3,[r1,-1]!
		subs	r2,1
		bhi	1b

		@ r0 ends up at its initial address
		bx	lr

		.ltorg

		.text
		.thumb

@ void *memmove(void *dest, const void *src, size_t n);

@ Choose which version to run
memmove:	cmp	r2,0
		beq	bxlr

		@ is src strictly between dest and dest+n?
		cmp	r1,r0
		bls	do_memcpy

		adds	r3,r0,r2
		cmp	r1,r3
		bhs	do_memcpy

		@ ascending copy would fail; use descending copy
		adds	r0,r2
		adds	r1,r2
		ldr	r3,=descCopy_arm
		bx	r3

do_memcpy:	ldr	r3,=memcpy+1
		bx	r3

bxlr:		bx	lr


		.ltorg
