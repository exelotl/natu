/*
 * strcat implementation for GBA
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

		.global	strcat

		.section .text.ARM
		.arm

		.ltorg

		.text
		.thumb

@ char *strcat(char *restrict dest, const char *restrict src);

/*
strcat:		push	{r0,r1,lr}
		bl	strlen
		mov	r12,r0
		pop	{r0,r1,r2}
		mov	lr,r2
		add	r12,r0
		ldr	r3,=acsl_strcpyEntry
		bx	r3
*/
strcat:		subs	r2,r0,1
1:		adds	r2,1
		ldrb	r3,[r2]
		cmp	r3,0
		bne	1b
		mov	r12,r2
		ldr	r3,=acsl_strcpyEntry
		bx	r3

		.ltorg
