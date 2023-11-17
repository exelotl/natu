/****************************************************************************
 *                                                          __              *
 *                ____ ___  ____ __  ______ ___  ____  ____/ /              *
 *               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               *
 *              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                *
 *             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 *
 *                                                                          *
 *                          DS Memory Operations                            *
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

	.global mmLoad
	.global mmUnload

	.global	mmLoadEffect
	.global	mmUnloadEffect

@----------------------------------------------
	
#include "mp_defs.inc"
#include "mp_format_mas.inc"

@----------------------------------------------

.text
.thumb
.align 2

.thumb_func
@--------------------------------------------------------------------------------
mmLoad:			@ params={ module_ID }
@--------------------------------------------------------------------------------
	
	push	{r4-r7, lr}
	ldr	r7,=mmcbMemory
	ldr	r7, [r7]
	
@---------------------------------------
@ check for existing module
@---------------------------------------
	
	ldr	r1,=mmModuleBank
	ldr	r1, [r1]
	lsl	r2, r0, #2
	add	r4, r1, r2
	ldr	r2, [r4]
	cmp	r2, #0
	beq	1f
	
	pop	{r4-r7, pc}
	
@---------------------------------------
@ load module into memory
@---------------------------------------
	
1:	mov	r1, r0
	mov	r0, #MMCB_SONGREQUEST
	
	blx	r7
	str	r0, [r4]
	
	mov	r4, r0
	add	r4, #8
	
@---------------------------------------
@ load samples into memory
@---------------------------------------
	
@ calculate sample numbers offset
	ldrb	r0, [r4, #C_MAS_INSTN]
	ldrb	r6, [r4, #C_MAS_SAMPN]
	mov	r5, r4
	add	r5, #255
	add	r5, #C_MAS_TABLES-255
	lsl	r0, #2
	add	r5, r0
	
@ r5 = sample table
	
@ load samples...
	
.mppl_samples:
	ldr	r0, [r5]
	add	r5, #4
	add	r0, r4
	ldrh	r0, [r0, #C_MASS_MSLID]
	
	bl	mmLoadEffect
	
	sub	r6, #1
	bne	.mppl_samples
	
@----------------------------------------	
@ ready for playback! :D
@----------------------------------------
	bl	mmFlushBank @ arm function
	
	pop	{r4-r7, pc}
.pool
.align 2
	
.thumb_func
@--------------------------------------------------------------------------------
mmUnload:		@ params={ module_ID }
@--------------------------------------------------------------------------------
	
	push	{r4-r7, lr}
	push	{r0}
	ldr	r7,=mmcbMemory
	ldr	r7, [r7]
	mov	r6, #0
	ldr	r1,=mmModuleBank
	ldr	r1, [r1]
	lsl	r0, #2
	ldr	r4, [r1, r0]
	cmp	r4, #0
	beq	1f
	
	add	r4, r4, #8
	mov	r6, r4
	ldrb	r5, [r4, #C_MAS_SAMPN]
	
	ldrb	r0, [r4, #C_MAS_INSTN]
	lsl	r0, #2
	add	r4, r0
	add	r4, #255
	add	r4, #C_MAS_TABLES-255
	
@------------------------------------
@ free samples
@------------------------------------
	
3:	ldr	r0, [r4]
	add	r0, r6
	add	r4, #4
	ldrh	r0, [r0, #C_MASS_MSLID]
	
	bl	mmUnloadEffect
	
	sub	r5, #1		@ dec sample counter
	bne	3b
	
@------------------------------------
@ free module
@------------------------------------
	
	pop	{r0}
	lsl	r0, #2
	ldr	r2,=mmModuleBank
	ldr	r2, [r2]
	ldr	r1, [r2,r0]
	mov	r3, #0
	str	r3, [r2,r0]
	mov	r0, #MMCB_DELETESONG
	blx	r7

@------------------------------------
@ flush bank
@------------------------------------

	bl	mmFlushBank

1:	pop	{r4-r7, pc}
.pool
.align 2

.thumb_func
@--------------------------------------------------------
mmLoadEffect:		@ params={ msl_id }
@--------------------------------------------------------
	
@ load a sample into memory
@ OR increase instance count of existing sample
	
	push	{lr}
	
	ldr	r1,=mmSampleBank	@ get sample bank
	ldr	r1, [r1]
	
	lsl	r2, r0, #2		@ read sample entry
	ldr	r3, [r1, r2]
	cmp	r3, #0			@ check if instance exists
	bne	.mppls_exists
	
	push	{r1-r2}
	mov	r1, r0			@ no instance
	mov	r0, #MMCB_SAMPREQUEST	@ request sample from user
	ldr	r2,=mmcbMemory
	ldr	r2, [r2]
	blx	r2
	pop	{r1-r2}
	lsl	r0, #8			@ clear high byte of address
	lsr	r3, r0, #8		@ 
	
.mppls_exists:
	
	ldr	r0,=0x1000000		@ increment instance count
	add	r3, r0
	str	r3, [r1, r2]		@ write sample entry
	
	bl	mmFlushBank
	
	pop	{pc}
.pool
.align 2

.thumb_func
@--------------------------------------------------------------------------------
mmUnloadEffect:		@ params={ msl_id }
@--------------------------------------------------------------------------------

@ decrease instance counter
@ unload sample from memory if zero

	push	{lr}
	
	ldr	r1,=mmSampleBank	@ get sample bank
	ldr	r1, [r1]
	
	lsl	r0, #2			@ load sample entry
	ldr	r2, [r1, r0]
	lsr	r3, r2, #24		@ mask counter value
	
	beq	1f			@ exit if already zero
	ldr	r3,=0x1000000		@ subtract 1 from instance counter
	sub	r2, r3
	lsr	r3, r2, #24		@ mask counter vaue
	bne	2f			@ skip unload if sample
					@   is still referenced
	
	push	{r0-r2, r7}
	ldr	r3,=0x2000000		@ unload sample from memory
	add	r1, r2, r3		@ param_b = sample address
	mov	r0, #MMCB_DELETESAMPLE	@ param_a = message
	ldr	r7,=mmcbMemory		@ jump to callback
	ldr	r7, [r7]
	blx	r7
	pop	{r0-r2, r7}
	
1:
	mov	r2, #0			@ clear sample entry
	
2:
	str	r2, [r1, r0]		@ save sample entry
	
	bl	mmFlushBank
	
	pop	{pc}
	
.pool

