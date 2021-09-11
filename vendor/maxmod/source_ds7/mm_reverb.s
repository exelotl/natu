/****************************************************************************
 *                                                          __              *
 *                ____ ___  ____ __  ______ ___  ____  ____/ /              *
 *               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               *
 *              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                *
 *             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 *
 *                                                                          *
 *                             Reverb System                                *
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
 
#include "mp_defs.inc"
#include "mp_macros.inc"

/***********************************************************************
 * Reverb Parameters
 *-------------------------------------
 * MEMORY	output address	32-bit
 * DELAY	buffer length	16-bit
 * RATE		sampling rate	16-bit
 * FEEDBACK	volume		11-bit
 * PANNING	panning		7-bit
 * DRY		output dry	1-bit
 * FORMAT	output format	1-bit
 *-------------------------------------
 *
 * 2-bit channel selection
 *
 *-------------------------------------
 *
 * Reverb output uses channels 1 and 3
 *
 ***********************************************************************/
 
/***********************************************************************
 *
 * Global Symbols
 *
 ***********************************************************************/
 
	.global		mmReverbEnable
	
	.global		mmReverbConfigure
	.global		mmReverbStart
	.global		mmReverbStop
	
	.global		mmReverbDisable

/***********************************************************************
 * 
 * Definitions
 *
 ***********************************************************************/

#define	SOUND1CNT	0x4000410
#define SOUND3CNT	0x4000430
#define SOUNDCNT	0x4000500
#define SNDCAP0CNT	0x4000508
#define SNDCAP0DAD	0x4000510
#define SNDCAP0LEN	0x4000514

.equ ReverbChannelMask,	0b1010

/***********************************************************************
 *
 * Memory
 *
 ***********************************************************************/

	.BSS
	.ALIGN 2

ReverbFlags:
	.space 2
ReverbNoDryLeft:
	.space 1
ReverbNoDryRight:
	.space 1
ReverbEnabled:
	.space 1
ReverbStarted:
	.space 1


	.TEXT
	.THUMB
	.ALIGN 2

/***********************************************************************
 * mmReverbEnable()
 *
 * Enable Reverb System (lock reverb channels from sequencer)
 ***********************************************************************/
						.thumb_func
mmReverbEnable:

	ldr	r0,=ReverbEnabled		// catch if reverb is already enabled
	ldrb	r1, [r0]			//
	cmp	r1, #0				//
	beq	1f				//
	bx	lr				//
	
1:	mov	r1, #1				// set enabled flag
	strb	r1, [r0]			//
	
	push	{lr}
	
	mov	r0, #ReverbChannelMask		// lock reverb channels
	bl	mmLockChannels			//
	
	bl	ResetSoundAndCapture
	
	pop	{r3}
	bx	r3
	
/***********************************************************************
 * mmReverbDisable()
 *
 * Disable Reverb System.
 ***********************************************************************/
						.thumb_func
mmReverbDisable:
	
	ldr	r0,=ReverbEnabled		// catch if reverb isn't enabled
	ldrb	r1, [r0]			//
	cmp	r1, #0				//
	bne	1f				//
	bx	lr				//
1:						//
	mov	r1, #0				// clear enabled flag
	strb	r1, [r0]			//
	
	push	{lr}
	
	bl	ResetSoundAndCapture
	
	mov	r0, #ReverbChannelMask		// unlock channels
	bl	mmUnlockChannels		//
	
	pop	{r3}
	bx	r3
	
/***********************************************************************
 * ResetSoundAndCapture()
 ***********************************************************************/
						.thumb_func
ResetSoundAndCapture:
	
	ldr	r0,=0x2840007F			// disable/reset sound channels
						// 7F/1 volume default
						// 40 pan default
						// 16bit default
	mov	r2, #0				// src needs input
	ldr	r3,=0xFE00			// 32khz default
	mov	r4, #0				// len needs input
	ldr	r1,=SOUND1CNT			//
	stmia	r1!, {r0,r2,r3,r4}		//
	add	r1, #16				//
	stmia	r1!, {r0,r2,r3,r4}		//
	
	mov	r0, #0
	
	ldr	r1,=SNDCAP0CNT			// reset capture
	strh	r2, [r1]			//
	add	r1, #8				//
	stmia	r1!, {r0,r2}			// 
	stmia	r1!, {r0,r2}			// 
	
	ldr	r1,=ReverbFlags			// clear nodry & flags
	strh	r2, [r1]			//
	ldr	r1,=ReverbNoDryLeft		//
	strh	r2, [r1]			//
	
	bx	lr

/***********************************************************************
 * mmReverbConfigure( config )
 *
 * Configure reverb system.
 ***********************************************************************/
						.thumb_func
mmReverbConfigure:
	
	ldr	r1,=ReverbEnabled		// catch if reverb isn't enabled
	ldrb	r1, [r1]
	cmp	r1, #0				//
	bne	1f				//
	bx	lr				//
1:						//

	push	{r4, r5, lr}
	
	ldmia	r0, {r0-r4}			// copy data to stack
	push	{r0-r4}				//
	mov	r4, sp
	
	ldrh	r5, [r4, #mmrc_flags]
	
	lsr	r0, r5, #MMRFS_LEFT+1		// setup left channel if flagged
	bcc	1f				//
	mov	r0, r4				//
	ldr	r1,=SOUND1CNT			//
	bl	SetupChannel			//
	
	lsr	r0, r5, #MMRFS_INVERSEPAN+1	// test INVERSEPAN flag
	bcc	2f				//
	
	ldrb	r0, [r4, #mmrc_panning]		//     inverse panning for other channel
	mov	r1, #128			//
	sub	r1, r0				//
	cmp	r1, #128			//     clip 128=127
	bne	3f				//
	mov	r1, #127			//
3:	strb	r1, [r4, #mmrc_panning]		//
2:
	ldr	r1,=SNDCAP0CNT			
	
	lsr	r0, r5, #MMRFS_MEMORY+1		// set capture DAD
	bcc	2f				//
	ldr	r0, [r4, #mmrc_memory]		//
	str	r0, [r1, #8]			//
2:						//
	
	lsr	r0, r5, #MMRFS_DELAY+1		// set capture LEN
	bcc	2f				//
	ldr	r0, [r4, #mmrc_delay]		//
	strh	r0, [r1, #12]			//
2:						//
	
	ldr	r0, [r4, #mmrc_memory]		// memory += length for other channel
	ldrh	r1, [r4, #mmrc_delay]		//
	lsl	r1, #2				//
	add	r0, r1				//
	str	r0, [r4, #mmrc_memory]		//
	
1:

	lsr	r0, r5, #MMRFS_RIGHT+1		// setup right channel if flagged
	bcc	1f				//
	mov	r0, r4				//
	ldr	r1,=SOUND3CNT			//
	bl	SetupChannel			//
	
	ldr	r1,=SNDCAP0CNT			
	
	lsr	r0, r5, #MMRFS_MEMORY+1		// set capture DAD
	bcc	2f				//
	ldr	r0, [r4, #mmrc_memory]		//
	str	r0, [r1, #16]			//
2:						//
	
	lsr	r0, r5, #MMRFS_DELAY+1		// set capture LEN
	bcc	2f				//
	ldr	r0, [r4, #mmrc_delay]		//
	strh	r0, [r1, #20]			//
2:						//

1:	
	
	ldr	r1,=SOUND1CNT
	ldr	r2,=SNDCAP0CNT
	
	
	
	lsr	r0, r5, #MMRFS_8BITLEFT+1	// check/set 8-bit left
	bcc	1f				//
	ldrb	r0, [r2]			//
	mov	r3, #1<<3			//
	orr	r0, r3				//
	strb	r0, [r2]			//
	mov	r0, #0b00001000			//
	strb	r0, [r1, #3]			//
1:						//

	lsr	r0, r5, #MMRFS_16BITLEFT+1	// check/set 16-bit left
	bcc	1f				//
	ldrb	r0, [r2]			//
	mov	r3, #1<<3			//
	bic	r0, r3				//
	strb	r0, [r2]			//
	mov	r0, #0b00101000			//
	strb	r0, [r1, #3]			//
1:						//

	add	r1, #0x20			//-right channel

	lsr	r0, r5, #MMRFS_8BITRIGHT+1	// check/set 8-bit right
	bcc	1f				//
	ldrb	r0, [r2, #1]			//
	mov	r3, #1<<3			//
	orr	r0, r3				//
	strb	r0, [r2, #1]			//
	mov	r0, #0b00001000			//
	strb	r0, [r1, #3]			//
1:						//

	lsr	r0, r5, #MMRFS_16BITRIGHT+1	// check/set 16-bit right
	bcc	1f				//
	ldrb	r0, [r2, #1]			//
	mov	r3, #1<<3			//
	bic	r0, r3				//
	strb	r0, [r2, #1]			//
	mov	r0, #0b00101000			//
	strb	r0, [r1, #3]			//
1:						//
	
	mov	r3, #0
	ldr	r2,=ReverbNoDryLeft		// check/set dry bits
	mov	r1, #1				//
	lsr	r0, r5, #MMRFS_NODRYLEFT+1	//
	bcc	1f				//
	strb	r1, [r2]			//
	mov	r3, #1
1:						//
	lsr	r0, r5, #MMRFS_NODRYRIGHT+1	//
	bcc	1f				//
	strb	r1, [r2, #1]			//
	mov	r3, #1
1:						//
	mov	r1, #0				//
	lsr	r0, r5, #MMRFS_DRYLEFT+1	//
	bcc	1f				//
	strb	r1, [r2]			//
	mov	r3, #1
1:						//
	lsr	r0, r5, #MMRFS_DRYRIGHT+1	//
	bcc	1f				//
	strb	r1, [r2, #1]			//
	mov	r3, #1
1:						//

	cmp	r3, #0
	beq	1f
	bl	CopyDrySettings
1:

	ldr	r0,=ReverbFlags			// save flags
	strh	r5, [r0]			//
	
	add	sp, #20
	
	pop	{r4,r5}
	pop	{r3}
	bx	r3

/***********************************************************************
 * SetupChannel( config, hwchannel )
 *
 * Setup hardware channel
 ***********************************************************************/
						.thumb_func
SetupChannel:
	push	{r4-r6, lr}
	ldrh	r2, [r0, #mmrc_flags]
	
	lsr	r2, #1				// memory/SRC
	bcc	1f				//
	ldr	r3, [r0, #mmrc_memory]		//
	str	r3, [r1, #4]			//
1:						//
	
	lsr	r2, #1				// delay/LEN
	bcc	1f				//
	ldrh	r3, [r0, #mmrc_delay]		//
	strh	r3, [r1, #12]			//
1:						//
	
	lsr	r2, #1				// rate/TMR
	bcc	1f				//
	ldrh	r3, [r0, #mmrc_rate]		//
	neg	r3, r3				//
	strh	r3, [r1, #8]			//
1:						//
	
	lsr	r2, #1				// feedback/CNT:volume,shift
	bcc	1f				//
	ldrh	r3, [r0, #mmrc_feedback]	//
						//
	ldr	r4,=mmVolumeTable		// translate volume into volume&div
	lsr	r5, r3, #7			//
	ldrb	r6, [r4, r5]			//
	lsl	r6, #8				//
						//
	add	r5, #16				//
	ldrb	r5, [r4, r5]			//
	lsr	r3, r5				//
	orr	r3, r6				//
						//
	strh	r3, [r1, #0]			//
1:						//
	
	lsr	r2, #1				// panning/CNT:panning
	bcc	1f				//
						//
	ldrb	r3, [r0, #mmrc_panning]		//
	strb	r3, [r1, #2]			//
1:						//
	
	pop	{r4-r6, pc}
	
/***********************************************************************
 * CopyDrySettings
 *
 * Setup SOUNDCNT with dry settings
 ***********************************************************************/
						.thumb_func
CopyDrySettings:

	ldr	r0,=ReverbStarted
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	1f
	bx	lr
1:
	
	ldr	r0,=SOUNDCNT			// r0 = SOUNDCNT
	ldrh	r0, [r0]			//
	
	mov	r1, #0b1111			// clear SOURCE bits
	lsl	r1, #8				//
	bic	r0, r1				//
	
	ldr	r1,=ReverbNoDryLeft		// if ReverbNoDryLeft
	ldrb	r2, [r1]			//    source_left = channel_1
	cmp	r2, #0				//
	beq	1f				//
	mov	r2, #0b01			//
	lsl	r2, #8				//
	orr	r0, r2				//
1:
	ldrb	r2, [r1, #1]			// if ReverbNoDryRight
	cmp	r2, #0				//    source_right = channel_3
	beq	1f				//
	mov	r2, #0b10			//
	lsl	r2, #10				//
	orr	r0, r2				//
1:
	ldr	r1,=SOUNDCNT			// write SOUNDCNT
	strh	r0, [r1]			//
	
	bx	lr
	
/***********************************************************************
 * mmReverbStart( channels )
 *
 * Start reverb output.
 ***********************************************************************/
						.thumb_func
mmReverbStart:
	
	push	{r4,lr}
	
	push	{r0}
	
	bl	mmReverbStop			// stop first... (to reset)
	
	pop	{r0}
	
	ldr	r2,=SNDCAP0CNT
	ldr	r3,=SOUND1CNT
	
	push	{r0}
	
	lsr	r0, #1				// check/start left channel
	bcc	1f				//
	
	mov	r1, #128
	ldrb	r0, [r2]			// enable left capture
	orr	r0, r1				//
	strb	r0, [r2]			//
	
	ldrb	r0, [r3, #3]			// start left channel
	orr	r0, r1				//
	strb	r0, [r3, #3]			// (capture is live!)
	
1:
	pop	{r0}
	
	add	r3, #0x20

	lsr	r0, #2				// check/start right channel
	bcc	1f				//
	
	mov	r1, #128
	ldrb	r0, [r2, #1]			// enable right capture
	orr	r0, r1				//
	strb	r0, [r2, #1]			//
	
	ldrb	r0, [r3, #3]			// start right channel
	orr	r0, r1				//
	strb	r0, [r3, #3]			// (capture is live!)
1:

	ldr	r0,=ReverbStarted
	mov	r1, #1
	strb	r1, [r0]

	bl	CopyDrySettings

	pop	{r4}
	pop	{r3}
	bx	r3
	
/***********************************************************************
 * mmReverbStop( channels )
 *
 * Stop reverb output.
 ***********************************************************************/
						.thumb_func
mmReverbStop:

	push	{r4,r5}
	
	ldr	r2,=SNDCAP0CNT
	ldr	r3,=SOUND1CNT
	ldr	r4,=SOUNDCNT
	ldrh	r4, [r4]
	
	mov	r1, #128
	
	lsr	r0, #1
	bcc	1f
	ldrb	r5, [r3, #3]			// disable left channel
	bic	r5, r1				//
	strb	r5, [r3, #3]			//
	
	ldrb	r5, [r2]			// disable left capture
	bic	r5, r1				//
	strb	r5, [r2]			//
	
	mov	r5, #0b11			// restore left output (enable dry output)
	lsl	r5, #8				//
	bic	r4, r5				//
1:

	add	r3, #0x20
	
	lsr	r0, #1
	bcc	1f
	ldrb	r5, [r3, #3]			// disable right channel
	bic	r5, r1				//
	strb	r5, [r3, #3]			//
	
	ldrb	r5, [r2, #1]			// disable right capture
	bic	r5, r1				// 
	strb	r5, [r2, #1]			//
	
	mov	r5, #0b11			// restore right output
	lsl	r5, #10				//
	bic	r4, r5				//
1:
	ldr	r0,=SOUNDCNT			// set SOUNDCNT
	strh	r4, [r0]			//
	
	ldr	r0,=ReverbStarted
	mov	r1, #0
	strb	r1, [r0]
	
	pop	{r4,r5}
	bx	lr

.pool
