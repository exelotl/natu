/****************************************************************************
 *                                                          __              *
 *                ____ ___  ____ __  ______ ___  ____  ____/ /              *
 *               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               *
 *              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                *
 *             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 *
 *                                                                          *
 *                            Sleep Functions                               *
 *                                                                          *
 *         Copyright (c) 2008, Mukunda Johnson (mukunda@maxmod.org)         *
 *                                                                          *
 * Permission to use, copy, modify, and/or distribute this software for any *
 * purpose with or without fee is hereby granted, provided that the above   *
 * copyright notice and this permission notice appear in all copies.        *
 *                                                                          *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES *
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF         *
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR  *
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES   *
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN    *
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF  *
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.           *
 ****************************************************************************/
 
// sleep functions are not needed!
#if 0

/* ARM7 Only Functions */

/*
 * Enter Sleep:
 *   Disable updates [safely]
 *   Disable timer IRQ
 *   Disable sound
 *   Disable speakers
 *   Zero bias level
 */

/*
 * Exit Sleep:
 *   Reset bias level
 *   Enable speakers
 *   Enable timer IRQ
 *   Reset mixer [enables updates]
 */
 
// note: Sound bias level is not readable if the speakers are disabled
// (undocumented)

.global mmEnterSleep
.global mmExitSleep

.equ	IE,		0x4000210
.equ	UPDATE_TIMER,	0x4000100
.equ	SOUNDCNT,	0x4000500
.equ	POWCNT2,	0x4000304
.equ	SoundBias,	0x08
.equ	BiasSlideDelay, 64		// click is pretty muffled with this setting

.TEXT
.THUMB
.ALIGN 2

/****************************************************************************
 * mmEnterSleep
 *
 * Enter low power sleep mode
 * Note: does not disable amplifier
 ****************************************************************************/
						.thumb_func
mmEnterSleep:

	push	{lr}

	bl	mmSuspendIRQ_t
	
	ldr	r0,=UPDATE_TIMER		@ disable updates
	mov	r1, #0				@
	str	r1, [r0]			@

	ldr	r0,=IE				@ clear bit in IE
	ldr	r1, [r0]			@
	mov	r2, #0b1000			@
	bic	r1, r2				@
	str	r1, [r0]			@
	
	bl	mmRestoreIRQ_t
	
	mov	r0, #0				@ reset bias level
	mov	r1, #BiasSlideDelay		@
	swi	SoundBias			@
	
	ldr	r0,=POWCNT2			@ disable speakers
	ldrh	r1, [r0]			@
	mov	r2, #1				@
	bic	r1, r2				@
	strh	r1, [r0]			@
	
	pop	{r3}
	bx	r3
	
/****************************************************************************
 * mmExitSleep
 *
 * Exit low power sleep mode
 ****************************************************************************/
						.thumb_func	
mmExitSleep:
	
	push	{lr}
	
	ldr	r0,=POWCNT2			@ enable speakers
	ldrh	r1, [r0]			@
	mov	r2, #1				@
	orr	r1, r2				@
	strh	r1, [r0]			@
	
	mov	r0, #1				@ reset bias level
	mov	r1, #BiasSlideDelay		@
	swi	SoundBias			@

	ldr	r0,=IE				@ set bit in IE
	ldr	r1, [r0]			@
	mov	r2, #0b1000			@
	orr	r1, r2				@
	str	r1, [r0]			@

	ldrb	r0,=mm_mixing_mode		@ reset mixer
	ldrb	r0, [r0]			@
	bl	mmSelectMode			@
	
	pop	{r3}
	bx	r3

.pool

#endif
