/*
 * strcmp and strcoll implementation for GBA
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

		.global	strcmp
		.global	strcoll

		.section .text
		.thumb

@ int strcmp(const char *s1, const char *s2);
@ int strcoll(const char *s1, const char *s2);

strcoll:	@ alias of strcmp
strcmp:		movs	r2,r0
		subs	r1,r0
1:		ldrb	r0,[r2]
		ldrb	r3,[r2,r1]
		adds	r2,1
		subs	r0,r3
		bne	1f
		cmp	r3,0
		bne	1b
1:		bx	lr

		.ltorg
