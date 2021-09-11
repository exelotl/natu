/****************************************************************************
 *                                                          __              *
 *                ____ ___  ____ __  ______ ___  ____  ____/ /              *
 *               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               *
 *              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                *
 *             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 *
 *                                                                          *
 *                          Soundbank Interface                             *
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

#define SEEK_SET 0

//---------------------------------------------------------------------
	.BSS
	.ALIGN 2
//---------------------------------------------------------------------

/**********************************************************************
 * mmsAddress
 *
 * address of soundbank in memory (if using that mode)
 **********************************************************************/

mmsAddress:	.space 4

/**********************************************************************
 * mmsFile
 *
 * string containing filename of soundbank
 **********************************************************************/
 
mmsFile:	.space 64

//---------------------------------------------------------------------
	.TEXT
	.THUMB
	.ALIGN 2
//---------------------------------------------------------------------

/**********************************************************************
 * mmSoundBankInMemory( address )
 *
 * Setup default handler for a soundbank loaded in memory
 **********************************************************************/
						.global mmSoundBankInMemory
						.thumb_func
mmSoundBankInMemory:
	
	ldr	r1,=mmsAddress			// save soundbank address
	str	r0, [r1]			//
	
	ldr	r0,=mmsHandleMemoryOp		// set memory handler
	b	mmSetCustomSoundBankHandler	//
	
/**********************************************************************
 * mmSoundBankInFiles( filename )
 *
 * Setup default handler for a soundbank file
 **********************************************************************/ 
						.global mmSoundBankInFiles
						.thumb_func
mmSoundBankInFiles:

	ldr	r1,=mmsFile			// copy filename into memory
	mov	r2, #0				//
1:	ldrb	r3, [r0, r2]			//
	strb	r3, [r1, r2]			//
	add	r2, #1				//
	cmp	r3, #0				//
	bne	1b				//


	ldr	r0,=mmsHandleFileOp		// set memory handler
	b	mmSetCustomSoundBankHandler	//

/**********************************************************************
 * mmSetCustomSoundBankHandler
 *
 * Setup a custom soundbank interface
 **********************************************************************/
						.global mmSetCustomSoundBankHandler
						.thumb_func
mmSetCustomSoundBankHandler:

	ldr	r1,=mmcbMemory			// save handle
	str	r0, [r1]			//
	bx	lr				//
	
/**********************************************************************
 * mmsHandleMemoryOp( msg, param )
 *
 * Default soundbank handler (memory)
 **********************************************************************/
						.thumb_func
mmsHandleMemoryOp:
	
	ldr	r2,=mmsAddress			// r2 = soundbank address
	ldr	r2, [r2]			//
	mov	r3, r2				// r3 = soundbank address+12 (parapointers)
	add	r3, #12				//
	lsl	r1, #2				//
	
	cmp	r0, #MMCB_SONGREQUEST		// test message type
	beq	.mmshmo_songrequ		//
	cmp	r0, #MMCB_SAMPREQUEST		//
	beq	.mmshmo_samprequ		//
	bx	lr				//-unknown message
	
.mmshmo_songrequ:
	ldrh	r0, [r2]			// r0 = #samps * entry_size
	lsl	r0, #2				//
	add	r1, r0				// 
	ldr	r0, [r3, r1]			// return address of module ( address_table[#samps+param] )
	add	r0, r2				// 
	bx	lr				// 
	
.mmshmo_samprequ:
	ldr	r0, [r3, r1]			// read sample pointer ( address_table[param] )
	add	r0, r2				//
	bx	lr				//
	
/**********************************************************************
 * mmsHandleFileOp( msg, param )
 *
 * Default soundbank handler (filesystem)
 **********************************************************************/
						.global mmsHandleFileOp
						.thumb_func
mmsHandleFileOp:
	
	mov	r2, r0				// r2 = msg
	mov	r0, r1				// r0 = param
	
	cmp	r2, #MMCB_SONGREQUEST		// jump to message handler
	beq	.mmshfo_songrequ		//
	cmp	r2, #MMCB_SAMPREQUEST		//
	beq	.mmshfo_samprequ		//
	cmp	r2, #MMCB_DELETESAMPLE		//
	ble	.mmshfo_delete			//
	bx	lr				//-unknown message: ignore
	
//-------------------------------------
.mmshfo_songrequ:
//-------------------------------------
	mov	r1, #0				// load module into memory and return pointer
	b	mmLoadDataFromSoundBank		//
	
//-------------------------------------
.mmshfo_samprequ:
//-------------------------------------
	mov	r1, #1				// load sample into memory and return pointer
	b	mmLoadDataFromSoundBank		//
	
//-------------------------------------
.mmshfo_delete:
//-------------------------------------
	ldr	r1,=free			// free allocated memory (param = address)
	bx	r1				//

/**********************************************************************
 * mmLoadDataFromSoundBank( index, sample )
 *
 * load a file from the soundbank and return memory pointer
 **********************************************************************/
						.thumb_func
mmLoadDataFromSoundBank:
	
	push	{r0,r1,r4-r7,lr}		// preserve parameters, registers, lr

	
	ldr	r0,=mmsFile			// open soundbank
	adr	r1, mmstr_rb			// 
	bl	fopen				//
	mov	r4, r0				// r4 = file handle
	
	ldr	r5,=fread			// r5 = fread (for .readword)
	
	bl	.readword			// read first word (contains song/sample count)
	
	pop	{r0,r1,r2}			// pop song/sample count, index, and is_sample
	

	lsl	r0, #16				// r0 = sample_count * 4
	lsr	r0, #14				// 
	
	cmp	r2, #0				// seek to "index*4 + 12 (size of soundbank header) + sample_count*4"
	beq	1f				// 
	mov	r0, #0				//<- only add sample_count*4 if loading a module
1:	lsl	r1, #2				//
	add	r1, #12				// 
	add	r1, r0				//
	ldr	r6,=fseek			//
	mov	r0, r4				//
	mov	r2, #SEEK_SET			//
	blx	r6				// fseek( file, offset, SEEK_SET );

	bl	.readword			// read parapointer
	pop	{r7}				//

	mov	r0, r4				// seek to pointer
	mov	r1, r7				//
	mov	r2, #SEEK_SET			//
	blx	r6				//
	
	bl	.readword			// read first word (this is SIZE)

	mov	r0, r4				// seek to pointer again
	mov	r1, r7				//
	mov	r2, #SEEK_SET			//
	blx	r6				//
	
	ldr	r0, [sp]			// r0 = file size (dont pop yet)
	add	r0, #8				// r0 += file prefix size
	ldr	r1,=malloc			// allocate memory
	blx	r1				//
	pop	{r1}				// r1 = file size (pop now)
	add	r1, #8				//
	push	{r0}				// push memory pointer
	
	mov	r2, #1				// read file into memory
	mov	r3, r4				//
	blx	r5				//
	
	ldr	r1,=fclose			// close file
	mov	r0, r4				//
	blx	r1				//
	
	pop	{r0,r4-r7,pc}			// pop memory pointer (return value), preserved regs, & return
	
/**********************************************************************
 * .readword
 *
 * read word from file and push onto stack
 * requires r4 = file_handle, r5 = fread
 **********************************************************************/
						.thumb_func
.readword:

	sub	sp, #4				// allocate space on stack
	
	mov	r0, sp				// fread( stack, 4, 1, file_handle )
	mov	r1, #4				//
	mov	r2, #1				//
	mov	r3, r4				//
	bx	r5				//
	
/**********************************************************************
 * mmstr_rb
 *
 * string "rb" for fopen (read+binary)
 **********************************************************************/
	.align 2
mmstr_rb:
	.byte  'r', 'b', 0

.pool
