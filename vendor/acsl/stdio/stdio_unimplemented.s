/*
 * Handle unimplemented functions
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

@ stdio.h

		.global	remove
		.global	rename
		.global	tmpfile
		.global	tmpnam
		.global	fclose
		.global	fflush
		.global	fopen
		.global	freopen
		.global	fscanf
		.global	scanf
		.global	vfscanf
		.global	vscanf
		.global	fgetc
		.global	fgets
		.global	gets
		.global	getc
		.global	getchar
		.global	ungetc
		.global	fread
		.global	fgetpos
		.global	fseek
		.global	fsetpos
		.global	ftell
		.global	rewind
		.global	clearerr
		.global	feof
		.global	ferror
		.global	system

		.text
		.thumb

COUNT		= 0
		.macro	unimp
		movs	r0,COUNT
		COUNT = COUNT + 1
		b	unimplemented
		.endm

@ Important: The order of labels and the order of strings must correspond.

remove:		unimp
rename:		unimp
tmpfile:	unimp
tmpnam:		unimp
fclose:		unimp
fflush:		unimp
fopen:		unimp
freopen:	unimp
fscanf:		unimp
scanf:		unimp
vfscanf:	unimp
vscanf:		unimp
fgetc:		unimp
fgets:		unimp
gets:		unimp
getc:		unimp
getchar:	unimp
ungetc:		unimp
fread:		unimp
fgetpos:	unimp
fseek:		unimp
fsetpos:	unimp
ftell:		unimp
rewind:		unimp
clearerr:	unimp
feof:		unimp
ferror:		unimp
system:		unimp

unimplemented:
		ldr	r1,=str_names

		cmp	r0,0
		beq	3f
1:		subs	r0,1
2:		ldrb	r2,[r1]
		adds	r1,1
		cmp	r2,0
		bne	2b
		cmp	r0,0
		bne	1b
3:		push	{r1,lr}
		ldr	r0,=str_Unimplemented
		mov	r1,sp
		bl	acsl_errFormatted

		.ltorg

		.section .rodata

str_Unimplemented:
		.asciz	"Call to unimplemented function: %s\n with LR=%.8p"

str_names:	.asciz	"remove"
		.asciz	"rename"
		.asciz	"tmpfile"
		.asciz	"tmpnam"
		.asciz	"fclose"
		.asciz	"fflush"
		.asciz	"fopen"
		.asciz	"freopen"
		.asciz	"fscanf"
		.asciz	"scanf"
		.asciz	"vfscanf"
		.asciz	"vscanf"
		.asciz	"fgetc"
		.asciz	"fgets"
		.asciz	"gets"
		.asciz	"getc"
		.asciz	"getchar"
		.asciz	"ungetc"
		.asciz	"fread"
		.asciz	"fgetpos"
		.asciz	"fseek"
		.asciz	"fsetpos"
		.asciz	"ftell"
		.asciz	"rewind"
		.asciz	"clearerr"
		.asciz	"feof"
		.asciz	"ferror"
		.asciz	"system"
