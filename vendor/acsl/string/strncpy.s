/*
 * strncpy and strxfrm implementation for GBA
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

		.global	strncpy
		.global	strxfrm

		.section .text.ARM
		.arm

@ char *strncpy(char *restrict dest, const char *restrict src, size_t n);


strncpy:	mov	r12,r0
		cmp	r2,0
		bxeq	lr

1:		ldrb	r3,[r1],1
		strb	r3,[r12],1
		subs	r2,1
		bxeq	lr
		cmp	r3,0
		bne	1b

1:		strb	r3,[r12],1
		subs	r2,1
		bhi	1b
		bx	lr

		.section .text.f.strxfrm
		.thumb

@ strxfrm is similar, but it returns the length, not the pointer, and does not
@ fill the buffer with zeros

@ size_t strxfrm(char *restrict dest, const char *restrict src, size_t n);

strxfrm:	cmp	r2,0
		beq	retzero

		mov	r12,r0
		subs	r1,r0

1:		ldrb	r3,[r1,r0]
		strb	r3,[r0]
		cmp	r3,0
		beq	1f
		adds	r0,1
		subs	r2,1
		bne	1b
1:		negs	r0,r0
		add	r0,r12
bxr3:		bx	r3

retzero:	movs	r0,0
		bx	lr

		.ltorg
