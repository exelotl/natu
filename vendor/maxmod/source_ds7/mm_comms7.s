/****************************************************************************
 *                                                          __              *
 *                ____ ___  ____ __  ______ ___  ____  ____/ /              *
 *               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               *
 *              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                *
 *             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 *
 *                                                                          *
 *                       Communication System (ARM7)                        *
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

#include "mp_macros.inc"
#include "mp_defs.inc"
#include "mp_mas_structs.inc"

/*****************************************************************************************************************************

[value] represents a 1 byte value
[[value]] represents a 2 byte value
[[[value]]] represents a 3 byte value
[[[[value]]]] represents a 4 byte value
... represents data with a variable length

message table:
-----------------------------------------------------------------------------------------------------------------
message			size	parameters			desc
-----------------------------------------------------------------------------------------------------------------
0: BANK			6	[[#songs]] [[[mm_bank]]]	get sound bank
1: SELCHAN		4	[[bitmask]] [cmd]		select channels
2: START		4	[[id]] [mode] 			start module
3: PAUSE		1	---				pause module
4: RESUME		1	---				resume module
5: STOP			1	---				stop module
6: POSITION		2	[position]			set playback position
7: STARTSUB		3	[[id]]				start submodule
8: MASTERVOL		3	[[volume]]			set master volume
9: MASTERVOLSUB		3	[[volume]]			set master volume for sub module
A: MASTERTEMPO		3	[[tempo]]			set master tempo
B: MASTERPITCH		3	[[pitch]]			set master pitch
C: MASTEREFFECTVOL	3	[[volume]]			set master effect volume, bbaa= volume
D: OPENSTREAM		10	[[[[wave]]]] [[clks]] [[len]] [format]    open audio stream
E: CLOSESTREAM		1	---				close audio stream
F: SELECTMODE		2	[mode]				select audio mode

10: EFFECT		5	[[id]] [[handle]]		play effect, default params
11: EFFECTVOL		4	[[handle]] [volume]		set effect volume
12: EFFECTPAN		4	[[handle]] [panning]		set effect panning
13: EFFECTRATE		5	[[handle]] [[rate]]		set effect pitch
14: EFFECTMULRATE	5	[[handle]] [[factor]]		scale effect pitch
15: EFFECTOPT		4	[[handle]] [options]		set effect options
16: EFFECTEX		11	[[[[sample/id]]]] [[rate]] [[handle]] [vol] [pan] play effect, full params
17: ---			-	---				---

18: REVERBENABLE	1	---				enable reverb
19: REVERBDISABLE	1	---				disable reverb
1A: REVERBCFG		3..14	[[flags]] : [[[[memory]]]] [[delay]] [[rate]] [[feedback]] [panning]
1B: REVERBSTART		1	[channels]			start reverb
1C: REVERBSTOP		1	[channels]			stop reverb

1D: EFFECTCANCELALL	1	---				cancel all effects

1E->3F: Reserved
******************************************************************************************************************************/

/***********************************************************************
 * Value32 format
 *
 * [cc] [mm] [bb] [aa]
 *
 * [mm] : ppmmmmmm, p = parameters, m = message type
 * [aa] : argument1, use if p >= 1
 * [bb] : argument2, use if p >= 2
 * [cc] : argument3, use if p == 3
 ***********************************************************************/
 
/***********************************************************************
 * Datamsg format
 *
 * First byte: Length of data
 * Following bytes: data
 ***********************************************************************/



.equ	FIFO_MAXMOD,	7

.equ	FIFO_SIZE,	256
.equ	FIFO_SIZEB,	8



	.bss
	.align 2
/*******************************************************************
 * mmFifo
 *
 * FIFO queue for messages from ARM9
 *******************************************************************/
mmFifo:
	.space FIFO_SIZE
	
/*******************************************************************
 * mmFifoPosition
 *
 * Read/Write positions in the FIFO
 *******************************************************************/
mmFifoPosition:
	.space 4	// <read>
	.space 4	// <write>
	
mmFifoChannel:
	.space 4
	

//------------------------------------------------------------------
.TEXT
.ARM
.ALIGN 2
//------------------------------------------------------------------

/*******************************************************************
 * mmSetupComms( channel )
 *
 * ARM7 Communication Setup
 *******************************************************************/
	.global mmSetupComms
	.type mmSetupComms STT_FUNC
mmSetupComms:

	push	{r0, lr}
	
	ldr	r1,=mmFifoChannel
	str	r0, [r1]
	
	ldr	r0,=mmFifoPosition		// reset fifo
	mov	r1, #0				//
	mov	r2, #0				//
	stmia	r0, {r1,r2}			//
	
	ldr	r0, [sp]			// setup datamsg handler first
	ldr	r1,=mmReceiveDatamsg		// (first to not miss INIT message!)
//	mov	r2, #0				//
	bl	fifoSetDatamsgHandler		//
	
	ldr	r0, [sp]			// setup value32 handler
	ldr	r1,=mmReceiveValue32		//
	mov	r2, #0				//
	bl	fifoSetValue32Handler		//
	
	pop	{r0, r3}
	bx	r3
	
/*******************************************************************
 * mmReceiveValue32( value32 )
 *
 * Value32 handler
 *******************************************************************/
mmReceiveValue32:
	ldr	r1,=mmFifo
	ldr	r2,=mmFifoPosition
	ldr	r2, [r2, #4]
	lsl	r2, #32-FIFO_SIZEB
	
	mov	r3, r0, lsr#16			// write message type
	and	r3, #0x3F			//
	strb	r3, [r1, r2, lsr#32-FIFO_SIZEB]	//
	add	r2, #1<<(32-FIFO_SIZEB)		//
	
	and	r3, r0, #0xC00000
	
	cmp	r3, #0x400000			// push first byte if p >= 1
	blt	1f				//
	strb	r0, [r1, r2, lsr#32-FIFO_SIZEB]	//
	add	r2, #1<<(32-FIFO_SIZEB)		//
	
	cmp	r3, #0x800000			// push second byte if p >= 2
	blt	1f				//
	lsr	r0, #8				//
	strb	r0, [r1, r2, lsr#32-FIFO_SIZEB]	//
	add	r2, #1<<(32-FIFO_SIZEB)		//
	
	cmp	r3, #0xC00000			// push third (fourth) byte if p >= 3
	blt	1f				// 
	lsr	r0, #16				//
	strb	r0, [r1, r2, lsr#32-FIFO_SIZEB]	//
	add	r2, #1<<(32-FIFO_SIZEB)		//

1:	
	lsr	r2, #32-FIFO_SIZEB		// save position
	ldr	r0,=mmFifoPosition		//
	str	r2, [r0, #4]			//
	
	bx	lr
	
/*******************************************************************
 * mmReceiveDatamsg( num_bytes )
 *
 * Datamsg handler
 *******************************************************************/
mmReceiveDatamsg:
	
	push	{r4,lr}				// preserve regs
					
	sub	sp, #8*4			// allocate space on stack
						// data shouldn't exceed 8 words!
	
	mov	r1, r0				// read data
	ldr	r0,=mmFifoChannel		//
	ldr	r0, [r0]			//
	mov	r2, sp				//
	bl	fifoGetDatamsg			//
	
	ldr	r1,=mmFifo			// r1,r2 = fifo & position
	ldr	r2,=mmFifoPosition		//
	ldr	r2, [r2, #4]			//
	lsl	r2, #32-FIFO_SIZEB		//
	
	ldrb	r4, [sp, #0]			// r4 = length of data
	add	r3, sp, #1
	
1:	ldrb	r0, [r3], #1			// copy data into fifo
	strb	r0, [r1, r2, lsr#32-FIFO_SIZEB]	//
	add	r2, #1<<(32-FIFO_SIZEB)		//
	subs	r4, #1				//
	bne	1b				//
	
	ldr	r0,=mmFifoPosition
	lsr	r2, #32-FIFO_SIZEB
	str	r2, [r0, #4]
	
	add	sp, #8*4
	
	ldr	r0,=mmInitialized		// first datamsg: process comms
	ldrb	r0, [r0]			//
	cmp	r0, #0				//
	bne	1f				//
						//
	bl	mmProcessComms			//
	
1:	pop	{r4,lr}				// restore regs
	bx	lr				// return
	
/*******************************************************************
 * mmSendUpdateToARM9
 *
 * Give ARM9 some data.
 *******************************************************************/
	.global mmSendUpdateToARM9
	.type mmSendUpdateToARM9 STT_FUNC
mmSendUpdateToARM9:

	ldr	r0,=mmLayerMain
	ldrb	r0, [r0, #MPL_ISPLAYING]
	cmp	r0, #0
	movne	r0, #0x10000
	ldr	r2,=mm_sfx_clearmask
	ldr	r1, [r2]
	orr	r1, r0
	mov	r0, #0
	str	r0, [r2]
	
	ldr	r0,=mmFifoChannel
	ldr	r0, [r0]
	
	ldr	r2,=fifoSendValue32
	bx	r2
	
/*******************************************************************
 * mmARM9msg
 *
 * Give ARM9 some data.
 *******************************************************************/
	.global	mmARM9msg
	.type	mmARM9msg STT_FUNC
	
mmARM9msg:
	
	mov	r1, r0
	ldr	r0,=mmFifoChannel
	ldr	r0, [r0]
	ldr	r2,=fifoSendValue32
	bx	r2

/*******************************************************************
 * mmDisableIRQ
 *
 * Disable Interrupts
 *******************************************************************/
mmDisableIRQ:
	mrs	r0, cpsr		// clear irq bit in cpsr
	and	r1, r0, #0x80		// 
	bic	r0, #0x80		//
	msr	cpsr, r0		//
	str	r1, IRQ_State		// save irq bit for restoring
	bx	lr			//
	
/*******************************************************************
 * mmRestoreIRQ
 *
 * Restore Interrupts
 *******************************************************************/
mmRestoreIRQ:
	mrs	r0, cpsr
	ldr	r1, IRQ_State
	orr	r1, r0
	msr	cpsr, r0
	bx	lr


/*******************************************************************
 * rfb(register)
 *
 * Read Fifo Byte
 *******************************************************************/
.macro rfb r
	ldrb	\r, [r6, r5, lsr#32-FIFO_SIZEB]	// r = byte
	add	r5, #1<<(32-FIFO_SIZEB)		// pos++, wraps to boundary
.endm

/*******************************************************************
 * rf16(register)
 *
 * Read Fifo 16-bits
 *******************************************************************/
.macro rf16 r, t
	rfb	\r
	rfb	\t
	orr	\r, \t, lsl#8
.endm

/*******************************************************************
 * rf24(register)
 *
 * Read Fifo 24-bits
 *******************************************************************/
.macro rf24 r, t
	rfb	\r
	rfb	\t
	orr	\r, \t, lsl#8
	rfb	\t
	orr	\r, \t, lsl#16
.endm

#define count r7

/*******************************************************************
 * mmProcessComms
 *
 * Process messages waiting in the fifo
 *******************************************************************/
	.global	mmProcessComms
	.type	mmProcessComms STT_FUNC
mmProcessComms:
	
	push	{r4-r7, lr}
	
	bl	mmDisableIRQ
	
	ldr	r6,=mmFifo			// r5 = read position
	ldr	r0,=mmFifoPosition		// r6 = fifo pointer
	ldmia	r0, {r5,r7}			//
	str	r7, [r0, #0]			//
	
	bl	mmRestoreIRQ			// exit if no messages
	
	subs	r7, r5				// r7 = number of bytes queued
	mov	r5, r5, lsl#(32-FIFO_SIZEB)	//
	addmi	r7, #FIFO_SIZE			//
	beq	.no_messages			//
	
	
.process_messages:
	rfb	r0				// read message
	adr	lr, ProcessNextMessage
	add	pc, r0, lsl#2
	
IRQ_State:	.space 4			// Variable: IRQ_State
	
	b	mmMSG_BANK			// 0
	b	mmMSG_SELCHAN			// 1
	b	mmMSG_START			// 2
	b	mmMSG_PAUSE			// 3
	b	mmMSG_RESUME			// 4
	b	mmMSG_STOP			// 5
	b	mmMSG_POSITION			// 6
	b	mmMSG_STARTSUB			// 7
	b	mmMSG_MASTERVOL			// 8
	b	mmMSG_MASTERVOLSUB		// 9
	b	mmMSG_MASTERTEMPO		// A
	b	mmMSG_MASTERPITCH		// B
	b	mmMSG_MASTEREFFECTVOL		// C
	b	mmMSG_OPENSTREAM		// D
	b	mmMSG_CLOSESTREAM		// E
	b	mmMSG_SELECTMODE		// F
	
	b	mmMSG_EFFECT			// 10
	b	mmMSG_EFFECTVOL			// 11
	b	mmMSG_EFFECTPAN			// 12
	b	mmMSG_EFFECTRATE		// 13
	b	mmMSG_EFFECTMULRATE		// 14
	b	mmMSG_EFFECTOPT			// 15
	b	mmMSG_EFFECTEX			// 16
	b	ProcessNextMessage		// 17
	
	b	mmMSG_REVERBENABLE		// 18
	b	mmMSG_REVERBDISABLE		// 19
	b	mmMSG_REVERBCFG			// 1A
	b	mmMSG_REVERBSTART		// 1B
	b	mmMSG_REVERBSTOP		// 1C
	
	b	mmMSG_EFFECTCANCELALL		// 1D
	
ProcessNextMessage:
	
	subs	r7, #1
	bne	.process_messages
	
.no_messages:
	pop	{r4-r7,lr}
	bx	lr

/*********************************************************************
 * 0: BANK
 *
 * Get soundbank (this is arm9 doing INIT)
 *
 * Parameters: [[#songs]] [[[mm_bank]]]
 *********************************************************************/
mmMSG_BANK:
	
	sub	count, #5
	
	rf16	r0, r1		// r0 = #songs
	rf24	r1, r2		// r1 = mm_bank
	add	r1, #0x2000000	//
	
	ldr	r2,=mmGetSoundBank
	bx	r2
	
/*********************************************************************
 * 1: SELCHAN
 *
 * Lock/Unlock channels
 *
 * Parameters: [[bitmask]] [cmd]
 *********************************************************************/
mmMSG_SELCHAN:
	sub	count, #3
	rf16	r0, r1
	rfb	r1
	cmp	r1, #0			// nonzero = lock channels
	ldreq	r1,=mmUnlockChannels	// zero = unlock channels
	ldrne	r1,=mmLockChannels	//
	bx	r1
	
/*********************************************************************
 * 2: START
 *
 * Start module
 *
 * Parameters: [[id]] [mode]
 *********************************************************************/
mmMSG_START:
	
	sub	count, #3
	rf16	r0, r1
	rfb	r1
	ldr	r2,=mmStart
	bx	r2

/*********************************************************************
 * 3: PAUSE
 *
 * Pause module
 *********************************************************************/
mmMSG_PAUSE:
	ldr	r0,=mmPause
	bx	r0
	
/*********************************************************************
 * 4: RESUME
 *
 * Resume module
 *********************************************************************/
mmMSG_RESUME:
	ldr	r0,=mmResume
	bx	r0
	
/*********************************************************************
 * 5: STOP
 *
 * Stop module
 *********************************************************************/
mmMSG_STOP:
	ldr	r0,=mmStop
	bx	r0
	
/*********************************************************************
 * 6: POSITION
 *
 * Set module position
 *
 * Parameters: [position]
 *********************************************************************/
mmMSG_POSITION:
	
	sub	count, #1
	rfb	r0
	ldr	r1,=mmPosition
	bx	r1

/*********************************************************************
 * 7: STARTSUB
 *
 * Start sub-module
 *
 * Parameters: [[id]]
 *********************************************************************/
mmMSG_STARTSUB:
	sub	count, #2
	rf16	r0, r1
	ldr	r1,=mmJingle
	bx	r1
	
/*********************************************************************
 * 8: MASTERVOL
 *
 * Set master module volume
 *
 * Parameters: [[volume]]
 *********************************************************************/
mmMSG_MASTERVOL:
	sub	count, #2
	rf16	r0, r1
	ldr	r1,=mmSetModuleVolume
	bx	r1
	
/*********************************************************************
 * 9: MASTERVOLSUB
 *
 * Set master sub-module volume
 *
 * Parameters: [[volume]]
 *********************************************************************/
mmMSG_MASTERVOLSUB:
	sub	count, #2
	rf16	r0, r1
	ldr	r1,=mmSetJingleVolume
	bx	r1

/*********************************************************************
 * A: MASTERTEMPO (todo)
 *
 * Set master module tempo
 *
 * Parameters: [[tempo]]
 *********************************************************************/
mmMSG_MASTERTEMPO:
	sub	count, #2
	rf16	r0, r1
	ldr	r1,=mmSetModuleTempo
	bx	r1
	
/*********************************************************************
 * B: MASTERPITCH (todo)
 *
 * Set master module pitch
 *
 * Parameters: [[pitch]]
 *********************************************************************/
mmMSG_MASTERPITCH:
	sub	count, #2
	rf16	r0, r1
	ldr	r1,=mmSetModulePitch
	bx	r1

/*********************************************************************
 * C: MASTEREFFECTVOL
 *
 * Set master effect volume
 *
 * Parameters: [[volume]]
 *********************************************************************/
mmMSG_MASTEREFFECTVOL:
	sub	count, #2
	rf16	r0, r1
	ldr	r1,=mmSetEffectsVolume
	bx	r1

/*********************************************************************
 * D: OPENSTREAM
 *
 * Open audio stream
 *
 * Parameters: [[[[wave]]]] [[clks]] [[len]] [format]
 *********************************************************************/
mmMSG_OPENSTREAM:
	sub	count, #9
	
	rf16	r0, r1			// r0 = wave
	rfb	r1			//
	orr	r0, r0, r1, lsl#16	//
	rfb	r1			//
	orr	r0, r0, r1, lsl#24	//
	
	rf16	r1, r2			// r1 = clks
	rf16	r2, r3			// r2 = len
	rfb	r3			// r3 = format
	
	bl	mmStreamBegin
	
	b	ProcessNextMessage

/*********************************************************************
 * E: CLOSESTREAM
 *
 * Close audio stream
 *
 * Parameters: ---
 *********************************************************************/
mmMSG_CLOSESTREAM:
	ldr	r0,=mmStreamEnd
	bx	r0

/*********************************************************************
 * F: SELECTMODE
 *
 * Select audio mode
 *
 * Parameters: [mode]
 *********************************************************************/
mmMSG_SELECTMODE:
	sub	count, #1
	rfb	r0
	ldr	r1,=mmSelectMode
	bx	r1
 
/*********************************************************************
 * 10: EFFECT
 *
 * Play effect
 *
 * Parameters: [[id]] [[handle]]
 *********************************************************************/
mmMSG_EFFECT:
	sub	count, #4
	
	rf16	r0, r1			// r0 = ssssssss
	mov	r1, #0x00000400		// r1 = hhhhrrrr
	rf16	r2, r3			//
	orr	r1, r2, lsl#16		//
	mov	r2, #0x00008100		// r2 = ----ppvv (80,ff)
	sub	r2, #0x00000001		//
	
	push	{r0-r2}
	mov	r0, sp
	
	ldr	r1,=mmEffectEx
	bl	_call_via_r1
	
	add	sp, #12
	b	ProcessNextMessage

/*********************************************************************
 * 11: EFFECTVOL
 * 
 * Set effect volume
 *
 * Parameters: [[handle]] [volume]
 *********************************************************************/
mmMSG_EFFECTVOL:
	sub	count, #3
	
	rf16	r0, r1
	rfb	r1
	ldr	r2,=mmEffectVolume
	bx	r2
	
/*********************************************************************
 * 12: EFFECTPAN
 *
 * Set effect panning
 *
 * Parameters: [[handle]] [panning]
 *********************************************************************/
mmMSG_EFFECTPAN:
	sub	count, #3
	
	rf16	r0, r1
	rfb	r1
	ldr	r2,=mmEffectPanning
	bx	r2
	
/*********************************************************************
 * 13: EFFECTRATE
 *
 * Set effect pitch
 *
 * Parameters: [[handle]] [[pitch]]
 *********************************************************************/
mmMSG_EFFECTRATE:
	
	sub	count, #4
	
	rf16	r0, r1
	rf16	r1, r2
	ldr	r2,=mmEffectRate
	bx	r2

/*********************************************************************
 * 14: EFFECTMULRATE
 *
 * Scale effect pitch
 *
 * Parameters: [[handle]] [[factor]]
 *********************************************************************/
mmMSG_EFFECTMULRATE:
	
	sub	count, #4
	
	rf16	r0, r1
	rf16	r1, r2
	ldr	r2,=mmEffectScaleRate
	bx	r2
	
/*********************************************************************
 * 15: EFFECTOPT
 *
 * Other effect commands
 *
 * Parameters: [[handle]] [operations]
 *
 * Operations:
 *   0 = Cancel
 *   1 = Release
 *   2 = ?
 *********************************************************************/
mmMSG_EFFECTOPT:

	sub	count, #3
	
	rf16	r0, r1
	rfb	r1
	
	cmp	r1, #0
	ldreq	r2,=mmEffectCancel
	bxeq	r2
	cmp	r1, #1
	ldreq	r2,=mmEffectRelease
	bxeq	r2
	
	1: b 1b

/*********************************************************************
 * 16: EFFECTEX
 *
 * Play effect with all parameters specified
 *
 * Parameters: [[[[source]]]] [[rate]] [[handle]] [vol] [pan]
 *********************************************************************/
mmMSG_EFFECTEX:
	
	sub	count, #10
	
	rfb	r0		// r0 = source
	rfb	r1		//
	orr	r0, r1, lsl#8	//
	rfb	r1		//
	orr	r0, r1, lsl#16	//
	rfb	r1		//
	orr	r0, r1, lsl#24	//
	
	rfb	r1		// r1 = rate, handle
	rfb	r2		//
	orr	r1, r2, lsl#8	//
	rfb	r2		//
	orr	r1, r2, lsl#16	//
	rfb	r2		//
	orr	r1, r2, lsl#24	//
	
	rf16	r2, r3		// r2 = volume,pan
	
	stmfd	sp!, {r0-r2}
	mov	r0, sp
	
	ldr	r1,=mmEffectEx
	bl	_call_via_r1
	
	add	sp, #12
	b	ProcessNextMessage
	


/*********************************************************************
 *
 * Reverb
 *
 *********************************************************************/
 


/*********************************************************************
 * 18: REVERBENABLE
 *
 * Enable reverb system
 *
 * Parameters: ---
 *********************************************************************/
mmMSG_REVERBENABLE:
	ldr	r0,=mmReverbEnable
	bx	r0
	
/*********************************************************************
 * 19: REVERBDISABLE
 *
 * Disable reverb system
 *
 * Parameters: ---
 *********************************************************************/
mmMSG_REVERBDISABLE:
	ldr	r0,=mmReverbDisable
	bx	r0

/*********************************************************************
 * 1A: REVERBCFG
 *
 * Configure reverb system
 *
 * Parameters: [[flags]] ::: [[[[memory]]]] [[delay]] [[rate]] [[feedback]] [panning]
 *********************************************************************/
mmMSG_REVERBCFG:
	
	sub	count, #2
	sub	sp, #24
	
	rf16	r0, r1
	strh	r0, [sp, #mmrc_flags]
	
	mov	r1, #1				// test bits 0 & 1
	tst	r1, r0, lsr#1			//
	
	ldrcsb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	// copy mem
	addcs	r5, #1<<(32-FIFO_SIZEB)		//
	strcsb	r3, [sp, #mmrc_memory]		//
						//
	ldrcsb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	//
	addcs	r5, #1<<(32-FIFO_SIZEB)		//
	strcsb	r3, [sp, #mmrc_memory+1]	//
						//
	ldrcsb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	//
	addcs	r5, #1<<(32-FIFO_SIZEB)		//
	strcsb	r3, [sp, #mmrc_memory+2]	//
						//
	ldrcsb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	//
	addcs	r5, #1<<(32-FIFO_SIZEB)		//
	strcsb	r3, [sp, #mmrc_memory+3]	//
						//
	subcs	count, #4			//
	
	ldrneb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	// copy delay
	addne	r5, #1<<(32-FIFO_SIZEB)		//
	strneb	r3, [sp, #mmrc_delay]		//
						//
	ldrneb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	//
	addne	r5, #1<<(32-FIFO_SIZEB)		//
	strneb	r3, [sp, #mmrc_delay+1]		//
						//
	subne	count, #2			//
	
	tst	r1, r0, lsr#3			// test bits 2 & 3
	
	ldrcsb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	// copy rate
	addcs	r5, #1<<(32-FIFO_SIZEB)		//
	strcsb	r3, [sp, #mmrc_rate]		//
						//
	ldrcsb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	//
	addcs	r5, #1<<(32-FIFO_SIZEB)		//
	strcsb	r3, [sp, #mmrc_rate+1]		//
						//
	subcs	count, #2			//
	
	ldrneb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	// copy feedback
	addne	r5, #1<<(32-FIFO_SIZEB)		//
	strneb	r3, [sp, #mmrc_feedback]	//
						//
	ldrneb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	//
	addne	r5, #1<<(32-FIFO_SIZEB)		//
	strneb	r3, [sp, #mmrc_feedback+1]	//
						//
	subne	count, #2			//
	
	tst	r1, r0, lsr#5			// test bits 4 & 5
	
	ldrcsb	r3, [r6, r5, lsr#32-FIFO_SIZEB]	// copy panning
	addcs	r5, #1<<(32-FIFO_SIZEB)		//
	strcsb	r3, [sp, #mmrc_panning]		//
						//
	subcs	count, #1			//
	
	mov	r0, sp
	ldr	r1,=mmReverbConfigure
	bl	_call_via_r1
	
	add	sp, #24
	
	b	ProcessNextMessage
	
/*********************************************************************
 * 1B: REVERBSTART
 *
 * Start reverb output.
 *
 * Parameters: [channels]
 *********************************************************************/
mmMSG_REVERBSTART:
	sub	count, #1
	
	rfb	r0
	ldr	r1,=mmReverbStart
	bx	r1
	
/*********************************************************************
 * 1C: REVERBSTOP
 *
 * Stop reverb output.
 *
 * Parameters: [channels]
 *********************************************************************/
mmMSG_REVERBSTOP:
	sub	count, #1
	
	rfb	r0
	ldr	r1,=mmReverbStop
	bx	r1

/*********************************************************************
 * 1D: EFFECTCANCELALL
 *
 * Stop all sound effects.
 *
 * Parameters: ---
 *********************************************************************/
mmMSG_EFFECTCANCELALL:
	ldr	r1,=mmEffectCancelAll
	bx	r1
