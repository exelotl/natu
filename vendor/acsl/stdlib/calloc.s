/*
 * calloc implementation for GBA
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

		.global	calloc

@ void *calloc(size_t nmemb, size_t size);

		.include "errnos.inc"

		.section .text
		.thumb

		.balign	4
calloc:
		@ To check if the operands will overflow a MUL, we use UMULL.
		@ This needs ARM mode.
		mov	r12,pc
		bx	r12
		.arm

		umull	r2,r3,r0,r1	@ size * nmemb

		add	r12,pc,1
		bx	r12
		.thumb

		movs	r0,r2
		cmp	r3,0
		bne	memErr

		adds	r0,3		@ pad length
		bcs	memErr
		movs	r1,3
		bics	r0,r1

		push	{r0,lr}

		bl	malloc

		cmp	r0,0		@ if malloc returns NULL, return
		beq	pop2Ret

		@ R0 = allocated pointer
		movs	r1,0		@ fill byte
		pop	{r2}		@ length

		bl	memset		@ memset returns r0 unchanged

		pop	{r1}
		bx	r1

pop2Ret:	pop	{r1,r2}
		bx	r2

memErr:		ldr	r1,=errno
		ldr	r0,=ENOMEM
		str	r0,[r1]
		movs	r0,0
		bx	r1

		.ltorg
