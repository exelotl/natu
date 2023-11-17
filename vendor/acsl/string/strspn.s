/*
 * strspn/strcspn implementation for GBA
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

		.global	strspn
		.global	strcspn
		.global	strpbrk

		.section .text.f.strspn
		.thumb
		.balign	2

@ size_t strspn(const char *s1, const char *s2);

strspn:		movs	r2,0
strspn_common:	mov	r12,r0		@ save s1 in R12
		push	{r2,r4}		@ create 256-bit array in the stack
		movs	r3,r2
		movs	r4,r2
		push	{r2,r3,r4}	@ ...2, 3, 4 words...
		push	{r2,r3,r4}	@ ...5, 6, 7 words...
		lsrs	r3,1		@ bit 31 of first word always 0
		push	{r3}		@ ... and 8 words (256 bits)
1:		ldrb	r0,[r1]		@ grab byte
		adds	r1,1		@ prepare next
		cmp	r0,0
		beq	1f		@ if end of string, go to next phase
		mvns	r3,r0		@ we use bits in reverse order
		lsls	r3,32-5		@   (shortens main loop)
		lsrs	r3,32-5		@ R3 = 31 - byte % 32 (bit index)
		movs	r2,1
		lsls	r2,r3		@ R2 = bitmask to set or clear
		lsrs	r0,5		@ R0 = word index
		lsls	r0,2		@ R0 = word offset
		add	r0,sp		@ R0 = pointer to correct word
		ldr	r3,[r0]
		eors	r3,r4		@ negate if strcspn
		orrs	r3,r2		@ set or clear bit in array
		eors	r3,r4		@ negate again if strcspn
		str	r3,[r0]
		b	1b

1:		mov	r2,r12		@ set R2 = s1
		movs	r0,0		@ set match counter to -1 to ensure
		subs	r0,1		@   it's zero in the first iteration
		mov	r4,sp

1:		adds	r0,1		@ increment counter
		ldrb	r1,[r2]
		adds	r2,1		@ point to next byte
		lsls	r3,r1,32-5
		lsrs	r3,32-5		@ R3 = byte % 32
		lsrs	r1,5		@ R1 = word index
		lsls	r1,2		@ R1 = word offset
		ldr	r1,[r4,r1]	@ grab bit array word
		lsls	r1,r3		@ shift the bit to the sign bit
		bmi	1b		@ loop if bit was set

		add	sp,8*4		@ Clean up the 8 words of the array
		pop	{r4}
		bx	lr


@ size_t strcspn(const char *s1, const char *s2);

strcspn:	movs	r2,0
		subs	r2,1		@ all 1's
		b	strspn_common


		.section .text.f.strpbrk
		.thumb
		.balign	2

@ char *strpbrk(const char *s1, const char *s2);

strpbrk:	push	{r0,lr}
		bl	strcspn
		pop	{r1,r3}
		adds	r0,r1
		ldrb	r1,[r0]
		cmp	r1,1
		sbcs	r1,r1
		bics	r0,r1
		bx	r3

		.ltorg
