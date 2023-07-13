/*
 * Handle partially implemented functions
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

@ From stdio.h

		.global	fprintf
		.global	vfprintf
		.global	printf
		.global	vprintf
		.global	fputc
		.global	fputs
		.global	putchar
		.global	puts
		.global	fwrite

		.text
		.thumb


printf:		push	{r1-r3}
		mov	r1,sp			@ va_list
		ldr	r4,=str_printf
		b	1f
vprintf:	ldr	r4,=str_vprintf		@ prefix 1
1:		ldr	r5,=str_Exits		@ prefix 2
		b	err2Prefixes

puts:		push	{r0}
		mov	r1,sp
		ldr	r0,=fstr_strlf
		ldr	r4,=str_puts
		ldr	r5,=str_Exits
		b	err2Prefixes

fputs:		movs	r5,r1
		ldr	r4,=str_fputs
		mov	r6,lr
		bl	testOutStrm
		push	{r0}
		mov	r1,sp
		ldr	r0,=fstr_string
		ldr	r5,=str_Exits
		b	err2Prefixes

putchar:	push	{r0}
		ldr	r0,=str_charExits
		mov	r1,sp
		ldr	r4,=str_putchar
		movs	r5,0
		b	err2Prefixes

fprintf:	movs	r5,r0
		ldr	r4,=str_fprintf
		mov	r6,lr
		bl	testOutStrm
		movs	r0,r1		@ format string
		push	{r2-r3}		@ possible varargs
		mov	r1,sp
		ldr	r5,=str_Exits
		b	err2Prefixes

vfprintf:	movs	r5,r0
		ldr	r4,=str_vfprintf
		mov	r6,lr
		bl	testOutStrm
		movs	r0,r1		@ format string
		movs	r1,r2		@ va_list
		ldr	r5,=str_Exits
		b	err2Prefixes


fputc:		movs	r5,r1
		ldr	r4,=str_fputc
		mov	r6,lr		@ requirement for testOutStrm
		bl	testOutStrm
		push	{r0}
		mov	r1,sp
		ldr	r0,=str_charExits
		movs	r5,0
		b	err2Prefixes

fwrite:		movs	r5,r3
		ldr	r4,=str_fwrite
		mov	r6,lr		@ requirements for testOutStrm
		bl	testOutStrm

		@ umull block
		.balign	4
		mov	lr,pc
		bx	lr
		.arm
		umull	r3,r12,r1,r2
		add	lr,pc,1
		bx	lr
		.thumb

		mov	r1,r12
		cmp	r1,0
		beq	1f
		@ overflow, set to UINT_MAX
		movs	r3,0
		subs	r3,1
1:		ldr	r1,=acsl_rawStr
		str	r0,[r1]
		str	r3,[r1,4]
		ldr	r0,=str_Exits
		ldr	r6,=acsl_prefixStr
		str	r4,[r6]
		bl	acsl_err

@ Internal, non AAPCS-compliant, does not touch r0-r3
testOutStrm:	cmp	r5,0
		beq	unsupp
		ldr	r5,[r5]
		ldr	r7,=0xBADBEEF+1
		cmp	r5,r7
		beq	1f
		adds	r7,1
		cmp	r5,r7
		bne	unsupp
1:		bx	lr
unsupp:		push	{r4,r6}
		ldr	r0,=str_Unsupp
errFormattedSP:	mov	r1,sp
errFormatted:	bl	acsl_errFormatted

err2Prefixes:	ldr	r6,=acsl_prefixStr
		stmia	r6!,{r4,r5}
		b	errFormatted

		.ltorg

		.section .rodata

fstr_string:	.asciz	"%s"
fstr_strlf:	.asciz	"%s\n"

str_Unsupp:	.asciz	"Unsupported stream in call to %s\n with LR=%.8p"

str_Exits:	.asciz	" terminates the program.\nPrinted text:\n"

str_charExits:
		.asciz	" terminates the program.\nPrinted char: '%c'"

str_vfprintf:	.ascii	"v"	@ fall through
str_fprintf:	.ascii	"f"	@ fall through
str_printf:	.asciz	"printf"
str_vprintf:	.asciz	"vprintf"
str_fwrite:	.asciz	"fwrite"
str_fputc:	.ascii	"f"	@ fall through
str_putc:	.asciz	"putc"	@ putc is defined as a macro, though
str_fputs:	.ascii	"f"	@ fall through
str_puts:	.asciz	"puts"
str_putchar:	.asciz	"putchar"

