/*
 * crt0.s: Startup file for GBA C library
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
		.cpu arm7tdmi
		.arm
		.section .gbaheader

		.global	_start
_start:		b	start

		.include "header.inc"
		.include "gba_constants.inc"
		.include "gba_moreconstants.inc"

		.text
_joybus:	.arm
		swi	0x030000	@ Unhandled here - stop
		b	_joybus



start:		.arm
		@ Stacks not changed from default.
		@ Note an ISR should switch to the System stack ASAP.

		add	lr,pc,1
		bx	lr		@ Switch to Thumb mode
		.thumb

		ldr	r0,=__armtext_load_start
		ldr	r1,=__armtext_start
		ldr	r2,=__armtext_size
		bl	copyWords

		ldr	r0,=__data_load_start
		ldr	r1,=__data_start
		ldr	r2,=__data_size
		bl	copyWords

		bl	acsl_initMemMgr

		movs	r0,0		@ argc = 0
		movs	r1,0		@ argv = NULL
		bl	main

		push	{r0}

		ldr	r0,=str_Exit
		mov	r1,sp
		bl	acsl_errFmtWait

		.ltorg

		.section .rodata

str_Exit:	.asciz	"Program terminated normally.\nExit code: %d."
		.balign	4

		.text
		.thumb

@ Copy memory to memory in multiples of 4 bytes.
@ R0 = origin
@ R1 = dest
@ R2 = size in bytes (must be a multiple of 4).
@ Note: Destroys R4-R7. Not AAPCS-compliant; for internal use only.
copyWords:	subs	r2,20
		blo	2f
		@ Copy floor(Size / 20) words
1:		ldmia	r0!,{r3,r4,r5,r6,r7}
		stmia	r1!,{r3,r4,r5,r6,r7}
		subs	r2,20
		bhs	1b
2:		adds	r2,20	@ Restore original count % 20
		beq	2f	@ jump if length was 0 to start with
		@ Copy (Size % 20) words
1:		ldmia	r0!,{r3}
		stmia	r1!,{r3}
		subs	r2,4
		bhi	1b
2:		bx	lr

		.ltorg
