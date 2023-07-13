/*
 * perror() partial implementation
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

		.global	perror

		.section .text.f.perror
		.thumb

perror:		movs	r4,r0
		ldr	r0,=errno
		ldr	r0,[r0]
		bl	strerror
		movs	r5,r0
		cmp	r4,0
		beq	1f
		ldrb	r1,[r4]
		cmp	r1,0
		beq	1f
		push	{r4,r5}
		mov	r1,sp
		ldr	r0,=str_perror2
		bl	acsl_errFormatted

1:		push	{r5}
		mov	r1,sp
		ldr	r0,=str_perror1
		bl	acsl_errFormatted

		.ltorg

		.section .rodata

str_perror1:	.asciz	"perror terminates the program. Output:\n%s\n"
str_perror2:	.asciz	"perror terminates the program. Output:\n%s: %s\n"
