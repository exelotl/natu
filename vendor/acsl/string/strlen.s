/*
 * strlen implementation for GBA
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

		.global	strlen

/*
		.section .text.ARM
		.arm

strlen:		mov	r1,r0
		mov	r0,0
		tst	r1,3
		beq	faster
		ldrb	r2,[r1],1
		cmp	r2,0
		bxeq	lr
		add	r0,1
		tst	r1,3
		beq	faster
		ldrb	r2,[r1],1
		cmp	r2,0
		bxeq	lr
		add	r0,1
		tst	r1,3
		beq	faster
		ldrb	r2,[r1],1
		cmp	r2,0
		bxeq	lr
		add	r0,1

faster:		sub	r0,1
1:
		add	r0,1
		ldmia	r1!,{r2,r3}
		tst	r2,0xFF
		bxeq	lr
		add	r0,1
		tst	r2,0xFF00
		bxeq	lr
		add	r0,1
		tst	r2,0xFF0000
		bxeq	lr
		add	r0,1
		tst	r2,0xFF000000
		bxeq	lr
		add	r0,1
		tst	r3,0xFF
		bxeq	lr
		add	r0,1
		tst	r3,0xFF00
		bxeq	lr
		add	r0,1
		tst	r3,0xFF0000
		bxeq	lr
		add	r0,1
		tst	r3,0xFF000000
		bne	1b
		bx	lr

		.ltorg
*/
		.text
		.thumb

strlen:		adds	r1,r0,0		@ never carry
		sbcs	r0,r0		@ R0 = -1
1:		adds	r0,1
		ldrb	r2,[r1,r0]
		cmp	r2,0
		bne	1b
bxlr:		bx	lr

		.ltorg
