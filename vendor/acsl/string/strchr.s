/*
 * strchr implementation for GBA
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


		.section .text.fn.strchr
		.thumb

		.global	strchr

@ char *strchr(const char *s, int c);

strchr:		ldrb	r2,[r0]
		cmp	r2,r1
		beq	found
		adds	r0,1
		cmp	r2,0
		bne	strchr
		movs	r0,0		@ return null
found:		bx	lr

		.section .text.fn.strrchr
		.thumb

		.global	strrchr

@ char *strrchr(const char *s, int c);

strrchr:	movs	r3,r0
		movs	r0,0
		subs	r3,1
1:		adds	r3,1
		ldrb	r2,[r3]
		cmp	r2,r1
		beq	rfound
		cmp	r2,0
		bne	1b
		bx	lr

rfound:		movs	r0,r3
		bne	1b
		bx	lr

		.ltorg
