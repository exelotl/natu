/*
 * isalpha, isalnum etc. implementation for GBA
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

		.global	isalnum
		.global	isalpha
		.global	iscntrl
		.global	isdigit
		.global	isgraph
		.global	islower
		.global	isprint
		.global	ispunct
		.global	isspace
		.global	isupper
		.global	isxdigit

		.section .text.f.isalnum
		.thumb
		.balign	2

isalnum:	cmp	r0,'0'
		blo	false
		cmp	r0,'9'
		bls	true
		movs	r1,0x20
		orrs	r0,r1
		cmp	r0,'a'
		blo	false
		cmp	r0,'z'
		bhi	false
		movs	r0,1
		bx	lr

		.section .text.f.isupper
		.thumb
		.balign	2

isupper:	cmp	r0,'A'
		blo	false
		cmp	r0,'Z'
		bhi	false
		movs	r0,1
		bx	lr

		.section .text.f.islower
		.thumb
		.balign	2

islower:	cmp	r0,'a'
		blo	false
		cmp	r0,'z'
		bhi	false
		movs	r0,1
		bx	lr

		.section .text.f.isprint
		.thumb
		.balign	2

isprint:	cmp	r0,' '
		blo	false
		cmp	r0,127
		bhs	false
		movs	r0,1
		bx	lr

		.section .text.f.isgraph
		.thumb
		.balign	2

isgraph:	cmp	r0,' '
		bls	false
		cmp	r0,127
		bhs	false
true:		movs	r0,1
		bx	lr

		.section .text.f.iscntrl
		.thumb
		.balign	2

iscntrl:	cmp	r0,' '
		blo	true
		cmp	r0,127
		beq	true
false:		movs	r0,0
		bx	lr

		.section .text.f.isdigit
		.thumb
		.balign	2

isdigit:	cmp	r0,'0'
		blo	false
		cmp	r0,'9'
		bhi	false
		movs	r0,1
		bx	lr

		.section .text.f.isspace
		.thumb
		.balign	2

isspace:	cmp	r0,' '
		beq	true
		cmp	r0,9
		blo	false
		cmp	r0,13
		bhi	false
		movs	r0,1
		bx	lr

		.section .text.f.isxdigit
		.thumb
		.balign	2

isxdigit:	cmp	r0,'0'
		blo	false
		cmp	r0,'9'
		bls	true
		movs	r1,0x20
		orrs	r0,r1
		cmp	r0,'a'
		blo	false
		cmp	r1,'f'
		bhi	false
		movs	r0,1
		bx	lr

		.ltorg
