/*
 * memchr implementation for GBA
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

		.global	memchr

		.section .text.ARM
		.arm

memchr_arm:	ldrb	r3,[r0,1]!
		cmp	r3,r1
		bxeq	lr
		subs	r2,1
		bne	memchr_arm
		mov	r0,0
		bx	lr

		.ltorg

		.text
		.thumb

@ void *memchr(const void *s, int c, size_t n);

memchr:		cmp	r2,0
		beq	retzero
		subs	r0,1
		ldr	r3,=memchr_arm
		bx	r3

retzero:	movs	r0,0
		bx	lr

		.ltorg
