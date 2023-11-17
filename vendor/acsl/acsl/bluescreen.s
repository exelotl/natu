/*
 * bluescreen.s: Error screen routines
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

		.global	acsl_err
		.global	acsl_errWait
		.global	acsl_errFormatted
		.global	acsl_errFmtWait

		.global	acsl_waitKeyRelease
		.global	acsl_waitKeyReleaseAllOf
		.global	acsl_waitKeyReleaseAnyOf
		.global	acsl_waitKeyPress
		.global	acsl_waitKeyPressAnyOf
		.global	acsl_waitKeyPressAllOf
		.global	acsl_waitVBlankStart
		.global	acsl_waitVBlankEnd
		.global	acsl_prefixStr
		.global	acsl_prefixStr2
		.global	acsl_rawStr
		.global	acsl_rawStrLen

		.include "gba_constants.inc"
		.include "gba_moreconstants.inc"

		.section .rodata
str_Str:	.asciz	"%s"
str_PressStart:	.asciz	"\n\nPress START to reset."

		.section .data
acsl_prefixStr:	.word	0
acsl_prefixStr2:
		.word	0
acsl_rawStr:	.word	0	@ pointer
acsl_rawStrLen:	.word	0	@ length

		.text
		.thumb

@ void acsl_errFmtWait(const char *format, va_list v);

acsl_errFmtWait:
		movs	r4,r0
		movs	r5,r1
		ldr	r0,=1<<KEY_START
		bl	acsl_waitKeyRelease
		bl	acsl_waitKeyPress
		movs	r0,r4
		movs	r1,r5
		b	acsl_errFormatted

@ void acsl_errWait(const char *msg);

acsl_errWait:	movs	r4,r0
		ldr	r0,=1<<KEY_START
		bl	acsl_waitKeyRelease
		bl	acsl_waitKeyPress
		movs	r0,r4
		@ fall through to acsl_err

@ void acsl_err(const char *msg);

acsl_err:	push	{r0}
		ldr	r0,=str_Str
		mov	r1,sp
		@ fall through

@ void acsl_errFormated(const char *format, va_list v);
@ algn is the number of AAPCS words before the original "..."

acsl_errFormatted:
		movs	r5,r1

		@ Master interrupts disable
		ldr	r1,=REG_IME
		movs	r2,0
		str	r2,[r1]
		movs	r2,PSR_IRQ_DISABLE_BIT|PSR_FIQ_DISABLE_BIT

		.balign 4
		mov	r12,pc
		bx	r12
		.arm
		mrs	r1,cpsr
		orr	r1,r2
		@ CPU interrupts disable
		msr	cpsr,r1
		add	r12,pc,1
		bx	r12
		.thumb

		movs	r4,r0
		ldr	r0,=1<<KEY_BUTTON_A|1<<KEY_BUTTON_B|1<<KEY_BUTTON_R|1<<KEY_BUTTON_L|1<<KEY_SELECT
		bl	acsl_waitKeyReleaseAllOf
		bl	acsl_waitVBlankEnd
		bl	acsl_waitVBlankStart

		ldr	r1,=REG_DISPCNT
		ldr	r0,=1<<DC_BG2EN | 0<<DC_FRAME | 3<<DC_MODE
		str	r0,[r1]

		ldr	r0,=VRAM
		ldr	r1,=0x45	@ dark blue BG
		ldr	r2,=2*240*160
		bl	memset

		ldr	r0,=acsl_prefixStr
		ldr	r0,[r0]
		cmp	r0,0
		beq	1f
		bl	acsl_printText

		ldr	r0,=acsl_prefixStr2
		ldr	r0,[r0]
		cmp	r0,0
		beq	1f
		bl	acsl_printText
1:

		movs	r1,r4
		ldr	r0,=acsl_putChar+1

		movs	r2,r5
		bl	acsl_formatStr

		ldr	r1,=acsl_rawStr
		ldr	r0,[r1]
		cmp	r0,0
		beq	1f
		ldr	r1,[r1,4]
		bl	acsl_printRawText
1:
		ldr	r0,=str_PressStart
		bl	acsl_printText

		ldr	r0,=1<<KEY_START
		bl	acsl_waitKeyRelease
		bl	acsl_waitKeyPress
		bl	acsl_waitKeyRelease

		swi	0x26		@ "hard" reset (BIOS screen)

		.ltorg

@ unsigned acsl_waitKeyRelease(unsigned key);
@ unsigned acsl_waitKeyReleaseAllOf(unsigned keys);
@ Wait until all specified buttons are pressed. Returns the input argument.

acsl_waitKeyRelease:
acsl_waitKeyReleaseAllOf:
		ldr	r1,=REG_KEYINPUT
1:              ldr	r2,[r1]
		tst	r2,r0
		beq	1b
		bx	lr

@ unsigned acsl_waitKeyReleaseAnyOf(unsigned keys);
@ Wait until at least one of the specified buttons is pressed; returns the arg

acsl_waitKeyReleaseAnyOf:
		ldr	r1,=REG_KEYINPUT
1:              ldr	r2,[r1]
		ands	r2,r0
		cmp	r2,r0
		beq	1b
		bx	lr

@ unsigned acsl_waitKeyPress(unsigned key);
@ unsigned acsl_waitKeyPressAnyOf(unsigned keys);
@ Wait until at least one of the specified buttons is released; returns arg

acsl_waitKeyPress:
acsl_waitKeyPressAnyOf:
		ldr	r1,=REG_KEYINPUT
1:		ldr	r2,[r1]
		tst	r2,r0
		bne	1b
		bx	lr

@ unsigned acsl_waitKeyPressAllOf(unsigned keys);
@ Wait until all of the specified buttons are released; returns the input arg

acsl_waitKeyPressAllOf:
		ldr	r1,=REG_KEYINPUT
1:		ldr	r2,[r1]
		ands	r2,r0
		cmp	r2,r0
		bne	1b
		bx	lr

@ void acsl_waitVBlankStart(void);

acsl_waitVBlankStart:
		ldr	r1,=REG_DISPSTAT
1:		ldrh	r0,[r1]
		lsrs	r0,DS_VBLANK_FLAG+1
		bcc	1b
		bx	lr

@ void acsl_waitVBlankEnd(void);

acsl_waitVBlankEnd:
		ldr	r1,=REG_DISPSTAT
1:		ldrh	r0,[r1]
		lsrs	r0,DS_VBLANK_FLAG+1
		bcs	1b
		bx	lr

		.ltorg
