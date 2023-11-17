/*
 * strstr implementation for GBA
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

		.global	strstr

		.text
		.thumb

@ char *strstr(const char *s1, const char *s2);

		@ KMP needs O(strlen(s2)) memory, so we use naive search
strstr:		mov	r12,r1
		subs	r0,r1
		subs	r0,1

1:		mov	r1,r12		@ rewind both pointers
		adds	r0,1		@ next position in s1
2:		ldrb	r3,[r1]		@ grab byte from s2
		cmp	r3,0
		beq	3f		@ success if end of s2
		ldrb	r2,[r0,r1]	@ grab byte from s1
		adds	r1,1		@ advance both pointers at once
		cmp	r3,r2		@ can't compare zeros because R3 != 0
		beq	2b		@ while it matches
		cmp	r2,0
		bne	1b		@ if s1 not ended, rewind & try next

		movs	r0,0		@ not found, return null
		bx	lr

3:		add	r0,r12		@ readjust R0 to return correct ptr
		bx	lr

		.ltorg
