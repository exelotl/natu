/*
 * strncat implementation for GBA
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

		.global	strncat

		.text
		.thumb

strncat:	mov	r12,r0
		cmp	r2,0
		beq	2f
		subs	r0,1
1:		adds	r0,1
		ldrb	r3,[r0]
		cmp	r3,0
		bne	1b
		subs	r1,r0
1:		ldrb	r3,[r1,r0]
		strb	r3,[r0]
		cmp	r3,0
		beq	2f
		adds	r0,1
		subs	r2,1
		bne	1b
		movs	r3,0
		adds	r0,1
		strb	r3,[r0]
2:		mov	r0,r12
		bx	lr

		.ltorg
