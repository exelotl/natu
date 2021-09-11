/*** THIS FILE IS OUT OF DATE ***/

#include "mp_format_mas.inc"
#include "swi_nds.inc"
#include "mp_macros.inc"

@========================================================================================
@ Globals
@========================================================================================

.global mm_mixchannels
.global	mp_updatesound

.global mp_Mixer_Mix

.global mp_Mixer_Init
.global mp_Mixer_SetSource
.global mp_Mixer_SetRead
.global mp_Mixer_SetFreq
.global mp_Mixer_StopChannel
.global mp_Mixer_ResetChannels
.global mp_Mixer_ChannelEnabled

@========================================================================================
@ Definitions
@========================================================================================


.equ	MP_nDSCHANNELS,	16

@ MIXER CHANNEL FORMAT

.equ	CHN_SAMP,	0	@ 24-bit, MSB = enabled, other bits = read start
.equ	CHN_OFFS,	3	@ sample offset
.equ	CHN_FREQ,	4	@ timer value for hardware
.equ	CHN_VOL,	6	@ 0->127 + start bit
.equ	CHN_PAN,	7	@ 0->127
.equ	CHN_SIZE,	8

@ USER VOICE FORMAT

.equ	VOICE_SOURCE	,0
.equ	VOICE_LENGTH	,4
.equ	VOICE_LOOP	,8
.equ	VOICE_FREQ	,10
.equ	VOICE_FLAGS	,12
.equ	VOICE_FORMAT	,13
.equ	VOICE_REPEAT	,14
.equ	VOICE_VOLUME	,15
.equ	VOICE_PANNING	,16
.equ	VOICE_INDEX	,17
.equ	VOICE_SIZE	,20

.equ	VOICEF_FREQ	,2
.equ	VOICEF_VOL	,4
.equ	VOICEF_PAN	,8
.equ	VOICEF_SOURCE	,16
.equ	VOICEF_STOP	,32

@========================================================================================
@ Variables
@========================================================================================

.section .bss

.align 2

mp_updatesound:		.space 4
mm_mixchannels:		.space 4
mm_rdschannels:		.space CHN_SIZE*MP_nDSCHANNELS

@========================================================================================
@ Program
@========================================================================================

.section .text

.thumb
.align 2
.thumb_func
@----------------------------------------------------------------------------------------
mp_Mixer_Mix:
@----------------------------------------------------------------------------------------

@ preserve registers
	
	push	{r4-r7, lr}

@ make stack space for voice structure

	add	sp, #-VOICE_SIZE
	mov	r6, sp

@ also make a channel mask
	
	ldr	r0,=mm_mch_mask
	ldr	r1,=mm_sfx_mask
	ldr	r0,[r0]
	ldr	r1,[r1]
	orr	r0, r1
	push	{r0}

@ get channel pointer and load counter
	
	ldr	r4,=mm_rdschannels
	mov	r5, #0

@-------------------------------------------------------
.mpm_loop:
@-------------------------------------------------------

@ check channel mask

	ldr	r7, [sp]
	lsr	r7, r5
	lsr	r7, #1
	bcc	.mpm_skip

@ clear flags
	
	mov	r7, #0

@ get sample address

	ldr	r0, [r4, #CHN_SAMP]

@ 3 bytes, clear msb

	lsl	r0, #8

@ channel is disabled if zero

	beq	.mpm_disabled
	
@ add WRAM to address

	lsr	r0, #8
	mov	r1, #0x02
	lsl	r1, #24
	add	r0, r1

@ read flags

	ldrb	r2, [r4, #CHN_VOL]
	lsl	r2, #32-7
	bcc	.mpm_nostart
	
@-------------------------------------------
@ new note
@-------------------------------------------

	lsr	r2, #32-7
	strb	r2, [r4, #CHN_VOL]
	
@-------------------------------------------
@ setup source address and length/loop
@-------------------------------------------
	
	ldrb	r3, [r4, #CHN_OFFS]		@ sample offset...
	ldrb	r1, [r0, #C_SAMPLEN_FORMAT]	@ check sample format
	
	strb	r1, [r6, #VOICE_FORMAT]
	
	cmp	r1, #0				@ format == 8-bit??
	bne	1f
	lsl	r3, #8
	b	.mpm_validoffset
1:
	cmp	r1, #1				@ format == 16-bit??
	bne	.mpm_invalidoffset
	lsl	r3, #9
	b	.mpm_validoffset

.mpm_invalidoffset:
	mov	r3, #0				@ sample offset not supported for compressed samples!
.mpm_validoffset:
	
	mov	r1, r0
	add	r1, #C_SAMPLEN_DATA		@ add data offset
	add	r1, r3				@ add sample offset
	str	r1, [r6, #VOICE_SOURCE]		@ write to source address
	
	ldrb	r1, [r0, #C_SAMPLEN_REP]	@ get repeat mode
	strb	r1, [r6, #VOICE_REPEAT]		@ store to voice struct
	
	cmp	r1, #1				@ check for loop
	bne	.mpm_nlooping
	
	ldrh	r1, [r0, #C_SAMPLEN_LSTART]	@ read loop start from sample
	lsr	r3, #2
	sub	r1, r3				@ subtract sample offset
	bcs	1f				@ check for overflow

@ offset overflow! fix!

	ldr	r3, [r6, #VOICE_SOURCE]
	lsl	r1, #2
	add	r3, r1
	str	r3, [r6, #VOICE_SOURCE]
	mov	r1, #0
1:	
	strh	r1, [r6, #VOICE_LOOP]		@ save to PNT
	
	ldr	r1, [r0, #C_SAMPLEN_LEN]	@ read loop length from sample
	str	r1, [r6, #VOICE_LENGTH]		@ save to PNT
	
	b	.mpm_looping

@-----------------------------------
.mpm_nlooping:
@-----------------------------------

	mov	r1, #0
	strh	r1, [r6, #VOICE_LOOP] 

	ldr	r1, [r0, #C_SAMPLEN_LEN]
	lsr	r3, #2
	sub	r1, r3
	bcs	1f

@ overflow! fix!
	
	ldr	r3, [r6, #VOICE_SOURCE]
	lsl	r1, #2
	add	r3, r1
	str	r3, [r6, #VOICE_SOURCE]
	mov	r1, #0

1:
	
	str	r1, [r6, #VOICE_LENGTH]

.mpm_looping:
	
	add	r7, #VOICEF_SOURCE
	b	.mpm_started
	
.mpm_nostart:
.mpm_started:
	
@------------------------------------
@ set frequency
@------------------------------------
	
	ldrh	r1, [r4, #CHN_FREQ]
	strh	r1, [r6, #VOICE_FREQ]
	
@------------------------------------
@ set volume
@------------------------------------
	
	ldrb	r1, [r4, #CHN_VOL]
	strb	r1, [r6, #VOICE_VOLUME]
	
	ldrb	r1, [r4, #CHN_PAN]
	strb	r1, [r6, #VOICE_PANNING]
	
	add	r7, #VOICEF_FREQ+VOICEF_VOL+VOICEF_PAN
	
	b	.mpm_next
	
@------------------------------------
.mpm_disabled:
@------------------------------------
	
	mov	r7, #VOICEF_STOP
	
@------------------------------------
.mpm_next:
@------------------------------------
	
	strb	r7, [r6, #VOICE_FLAGS]
	strb	r5, [r6, #VOICE_INDEX]
	mov	r0, r6
	
	ldr	r2,=mp_updatesound
	ldr	r2, [r2]
	blx	r2
	cmp	r0, #0
	bne	1f
	mov	r0, #0
	str	r0, [r4, #CHN_SAMP]
1:	
	
@------------------------------------
.mpm_skip:
@------------------------------------
	
	add	r4, #CHN_SIZE		@ add to pointer
	add	r5, #1			@ count
	cmp	r5, #MP_nDSCHANNELS
	bne	.mpm_loop		@ loop
	
	add	sp, #VOICE_SIZE+4
	
	pop	{r4-r7, pc}
.pool
	
@--------------------------------------------------------------------------------------------------------
	
.align 2
.thumb_func
@------------------------------------------------------------------------------------------
mp_Mixer_Init:					@ params={}
@------------------------------------------------------------------------------------------
	
@ clear mixing channels
	
	ldr	r0,=mm_rdschannels
	ldr	r1,=mm_mixchannels
	str	r0,[r1]
	mov	r1, #MP_nDSCHANNELS
	mov	r3, #0
	
1:	str	r3, [r0, #CHN_SAMP]
	add	r0, #CHN_SIZE
	sub	r1, #1
	bne	1b
	
@ assume user initializes sound hardware
	
	bx	lr				@ finished

.align 2
.thumb_func
@------------------------------------------------------------------------------------------
mp_Mixer_SetSource: 			@ params={ channel, p_sample }
@------------------------------------------------------------------------------------------
	
	mov	r2, #CHN_SIZE		@ get channel pointer from index
	mul	r0, r2			@ ..
	ldr	r2,=mm_rdschannels	@ ..
	add	r0, r2			@ ..
	ldr	r2,=0x2000000		@ sub wram offset
	sub	r1, r2			@ 
	str	r1, [r0, #CHN_SAMP]	@ save to sample address
	ldrb	r1, [r0, #CHN_VOL]
	mov	r2, #128
	orr	r1, r2
	strb	r1, [r0, #CHN_VOL]	@ set start flag
	bx	lr

.align 2
.thumb_func
@------------------------------------------------------------------------------------------
mp_Mixer_SetRead:			@ params={ channel, value }
@------------------------------------------------------------------------------------------

	mov	r2, #CHN_SIZE		@ get channel pointer from index
	mul	r0, r2			@ ..
	ldr	r2,=mm_rdschannels		@ ..
	add	r0, r2			@ ..
	strb	r1, [r0, #CHN_OFFS]
	
	bx	lr
.pool

.align 2
.thumb_func
@------------------------------------------------------------------------------------------
mp_Mixer_SetFreq:			@ params={ channel, value }
@------------------------------------------------------------------------------------------

	@ formula = -(16756991)/hz
	
	mov	r2, #CHN_SIZE		@ get channel pointer
	mul	r0, r2, r0		@ ..
	ldr	r2,=mm_rdschannels
	add	r0, r0, r2
	push	{r0}
	ldr	r0,=16756991
	swi	SWI_DIVIDE
	pop	{r1}
	neg	r0, r0
	strh	r0, [r1, #CHN_FREQ]
	
	bx	lr
.pool

.thumb

.align 2
.thumb_func
@------------------------------------------------------------------------------------------
mp_Mixer_StopChannel:			@ params={ channel }
@------------------------------------------------------------------------------------------

	mov	r1, #CHN_SIZE		@ get channel pointer
	mul	r0, r1			@ ..
	ldr	r1,=mm_rdschannels
	add	r0, r1
	mov	r1, #0
	str	r1, [r0, #CHN_SAMP]
	bx	lr
.pool

.align 2
.thumb_func
@------------------------------------------------------------------------------------------
mp_Mixer_ChannelEnabled:
@------------------------------------------------------------------------------------------

	mov	r1, #CHN_SIZE
	mul	r0, r1
	ldr	r1,=mm_rdschannels
	add	r0, r1
	ldr	r0, [r0, #CHN_SAMP]
	lsl	r0, #8
	bx	lr

.align 2
.thumb_func
@------------------------------------------------------------------------------------------
mp_Mixer_ResetChannels:			@ params={}
@------------------------------------------------------------------------------------------

	push	{r4,r5}
	
	pop	{r4,r5}
	bx	lr

.end
