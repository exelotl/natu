/****************************************************************************
 *                                                          __              *
 *                ____ ___  ____ __  ______ ___  ____  ____/ /              *
 *               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               *
 *              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                *
 *             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 *
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

.equ	FIFO_MAXMOD,	3

.struct 0		// mm_ds9_system
MMDS9S_MOD_COUNT:	.space 4
MMDS9S_SAMP_COUNT:	.space 4
MMDS9S_MEM_BANK:	.space 4
MMDS9S_FIFO_CHANNEL:	.space 4

//-----------------------------------------------------------------------------
	.BSS
	.ALIGN 2
//-----------------------------------------------------------------------------

/******************************************************************************
 * mmcbMemory : Word
 *
 * Function pointer to soundbank operation callback
 ******************************************************************************/
							.global mmcbMemory
mmcbMemory:	.space 4

/******************************************************************************
 * mmModuleCount : Word
 *
 * Number of modules in sound bank
 ******************************************************************************/
							.global mmModuleCount
mmModuleCount:	.space 4

/******************************************************************************
 * mmSampleCount : Word
 *
 * Number of samples in sound bank
 ******************************************************************************/
							.global mmSampleCount
mmSampleCount:	.space 4

/******************************************************************************
 * mmModuleBank : Word
 *
 * Address of module bank
 ******************************************************************************/
							.global mmMemoryBank
							.global mmModuleBank
mmMemoryBank:
mmModuleBank:	.space 4

/******************************************************************************
 * mmSampleBank : Word
 *
 * Address of sample bank
 ******************************************************************************/
							.global mmSampleBank
mmSampleBank:	.space 4

/******************************************************************************
 * mmCallback : Word
 *
 * Pointer to event handler
 ******************************************************************************/
							.global mmCallback
mmCallback: 	.space 4

/******************************************************************************
 * mmActiveStatus : Byte
 *
 * Record of playing status.
 ******************************************************************************/
							.global mmActiveStatus
mmActiveStatus:	.space 1

//-----------------------------------------------------------------------------
	.TEXT
	.THUMB
	.ALIGN 2
//-----------------------------------------------------------------------------

/******************************************************************************
 * mmActive
 *
 * Returns nonzero if module is playing
 ******************************************************************************/
						.global mmActive
						.thumb_func
mmActive:
	
	ldr	r0,=mmActiveStatus
	ldrb	r0, [r0]
	bx	lr

/******************************************************************************
 * mmSetEventHandler
 *
 * Set function for handling playback events
 ******************************************************************************/
						.global mmSetEventHandler
						.thumb_func
mmSetEventHandler:

	ldr	r1,=mmCallback
	str	r0, [r1]
	bx	lr

/******************************************************************************
 * mmInit( system )
 *
 * Initialize Maxmod (manual settings)
 ******************************************************************************/
						.global mmInit
						.thumb_func
mmInit:
	
	push	{r4-r7, lr}			// preserve registers
	mov	r7, r0				// r7 = system

	ldmia	r0!, {r1-r3}			// r1,r2,r3,r4 = mod_count, samp_count, mod_bank, samp_bank
	lsl	r4, r1, #2			//
	add	r4, r3				//
	ldr	r5,=mmModuleCount		// write to local memory
	stmia	r5!, {r1-r4}			//
	
	add	r1, r2				// clear the memory bank to zero
	beq	2f
	mov	r0, #0				//
1:	stmia	r3!, {r0}			//
	sub	r1, #1				//
	bne	1b				//
2:
	
	ldr	r0, [r7, #MMDS9S_FIFO_CHANNEL]	// setup communications
	bl	mmSetupComms			//

	ldr	r0, [r7, #MMDS9S_MOD_COUNT]	// send soundbank info to ARM7
	ldr	r1, [r7, #MMDS9S_MEM_BANK]
	bl	mmSendBank

	pop	{r4, r5,r6,r7, pc}		// pop regs and return

/******************************************************************************
 * mmInitDefault( soundbank filename )
 *
 * Initialize Maxmod with default setup
 ******************************************************************************/
						.global mmInitDefault
						.thumb_func
mmInitDefault:

	push	{r0, r4, r5, lr}

	ldr	r2,=fopen			// open soundbank
	ldr	r1,=mmstr_rbHAP			// "rb"
	blx	r2				//
	mov	r4, r0				// preserve FILE handle

	ldr	r5,=fread			// read first word (push on stack)
	sub	sp, #4				//
	mov	r0, sp				//
	mov	r1, #4				//
	mov	r2, #1				//
	mov	r3, r4				//
	blx	r5				//

	ldr	r1,=fclose			// close soundbank
	mov	r0, r4				//
	blx	r1				//

	pop	{r0}				// r0 = #samples | (#modules << 16)
	
	lsl	r1, r0, #16			// r1 = #samples (mask low hword)
	lsr	r1, #16				//
	lsr	r0, #16				// r0 = #modules (mask high hword)
	mov	r3, #FIFO_MAXMOD		// r3 = standard MAXMOD fifo channel
	push	{r0, r1, r2, r3}		// push onto stack, r2 = trash/spacer
	
	add	r0, r1				// allocate memory ((mod+samp)*4) for the memory bank
	lsl	r0, #2				// 
	ldr	r1,=malloc			//
	blx	r1				//
	str	r0, [sp, #MMDS9S_MEM_BANK]	//
	
	mov	r0, sp				// pass struct to mmInit
	bl	mmInit				//
	
	add	sp, #16				// clear data
	pop	{r0}				// r0 = soundbank filename
	bl	mmSoundBankInFiles		// setup soundbank handler
	
	pop	{r4, r5, pc}			// restore regs and return
	
.align 2
mmstr_rbHAP:
	.byte	'r', 'b', 0
	
.align 2

/******************************************************************************
 * mmInitDefaultMem( address of soundbank )
 *
 * Initialize maxmod with default setup 
 * (when the entire soundbank is loaded into memory)
 ******************************************************************************/
						.global mmInitDefaultMem
						.thumb_func
mmInitDefaultMem:
	push	{r4,lr}
	
	ldrh	r2, [r0, #0]			// r2 = #samples
	ldrh	r1, [r0, #2]			// r1 = #modules
	mov	r4, #FIFO_MAXMOD		// r3 = standard maxmod channel
	
	push	{r0,r1,r2,r3,r4}		// push data onto stack
	
	add	r0, r1, r2			// allocate memory for memory bank
	lsl	r0, #2				// size = (nsamples+nmodules) * 4
	ldr	r3,=malloc			//
	blx	r3				//
	str	r0, [sp, #MMDS9S_MEM_BANK+4]	//

	add	r0, sp, #4			// pass system struct to mmInit
	bl	mmInit				//
	
	pop	{r0}				// setup soundbank handler
	bl	mmSoundBankInMemory		// 
	
	pop	{r0-r3, r4, pc}			// trash registers and return

/******************************************************************************
 * mmSuspendIRQ_t
 *
 * Function to disable interrupts via the status register
 ******************************************************************************/
						.global mmSuspendIRQ_t
						.thumb_func
mmSuspendIRQ_t:
	ldr	r0,=1f
	bx	r0

.arm
.align 2
1:	mrs	r0, cpsr
	and	r1, r0, #0x80
	orr	r0, #0x80
	msr	cpsr, r0
	str	r1, previous_irq_state
	bx	lr
.thumb

/******************************************************************************
 * mmRestoreIRQ_t
 *
 * Function to enable interrupts via the status register
 ******************************************************************************/	
						.global	mmRestoreIRQ_t
						.thumb_func
mmRestoreIRQ_t:
	ldr	r0,=1f
	bx	r0

.arm
.align 2
1:	mrs	r0, cpsr
	ldr	r1, previous_irq_state
	bic	r0, #0x80
	orr	r0, r1
	msr	cpsr, r0
	bx	lr
		
.thumb

previous_irq_state:
	.space	4

.pool
