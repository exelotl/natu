/*
 * realloc implementation for GBA
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

		.global	realloc

		.include "gba_constants.inc"
		.include "errnos.inc"

HeapOrg		= __sbss_end__
HeapEnd		= EWRAM_END

		.text
		.thumb

@ void *realloc(void *ptr, size_t size);

realloc:	cmp	r0,0
		beq	doMalloc	@ null pointer is like malloc

		cmp	r1,0
		beq	doFree		@ size zero does a free of r0

		adds	r1,7		@ add 3 + size word length
		bcs	reallocFail	@ value too high, don't confuse with 0
		lsrs	r1,2		@ round new size to a word multiple
		lsls	r1,2
		ldr	r3,=HeapOrg-HeapEnd	@ -max_size
		cmn	r1,r3		@ is r1 > max_size?
		bhi	reallocFail	@ fail if so (prevents overflows)
		subs	r2,r0,4
		ldr	r2,[r2]		@ grab old block size
		adds	r2,3
		lsrs	r2,2		@ round old too
		lsls	r2,2
		cmp	r1,r2		@ is new size > old size?
		bhi	growAlloc	@ jump if so
		beq	bxlr		@ no need to do anything if equal

		@ New size < old size; shrink the block by freeing the
		@ unnecessary chunk.

		push	{r0,lr}		@ we'll need it preserved

		subs	r0,4		@ go to beginning of block
		str	r1,[r0]
		adds	r0,r1		@ point to end of new block
		subs	r1,r2,r1	@ deallocate (oldsize - newsize) bytes
		bl	acsl_FreeMem

		pop	{r0,r1}		@ return the same chunk
		bx	r1

bxlr:		bx	lr

reallocFail:	ldr	r1,=errno
		ldr	r0,=ENOMEM
		str	r0,[r1]
		subs	r0,r0
		bx	lr

		@ Allocate more room if possible
		@ We need to go through the free list to determine whether
		@ there's a free block after this one, and if so, whether
		@ there's room for the requested size. If there is, change
		@ allocation to match. If not, we use the slow route of
		@ malloc + copy + free.
growAlloc:
		push	{r5-r7}
		subs	r0,4
		mov	r12,r0		@ save original pointer
		adds	r0,r2		@ pointer to allocate at
		ldr	r5,=acsl_FreeList

		movs	r3,1		@ constant - a Thumb limitation

gaFindPlace:	movs	r2,r5		@ previous pointer in R2
		ldr	r5,[r5]		@ pointer to free block in R5
		bics	r5,r3		@ clear islarge bit
		cmp	r5,r0		@ are we at the free block next to us?
		bhi	gaSlowMethod	@ if past, do malloc + copy + free
		bne	gaFindPlace	@ if we're not there, loop

		@ There's a free spot after the requested block. Check if
		@ there's enough free space to accomodate the requested size.

		ldr	r0,=HeapEnd	@ R5 = R0 so we don't need R0
		cmp	r5,r0		@ were we at the end of the heap?
		bhs	gaSlowMethod	@ try the slow route if so
		ldr	r6,[r5]		@ grab next pointer + islarge flag
		adds	r7,r5,4		@ end of free block pointer
		tst	r6,r3		@ is it large?
		beq	1f		@ branch if not
		bics	r6,r3		@ clear islarge
		ldr	r7,[r7]		@ end of block field present, grab it
1:		mov	r0,r12		@ recover block start
		adds	r0,r1		@ end of new block
		cmp	r0,r7		@ cmp new block end w/ free block end
		bhi	gaSlowMethod	@ if greater, it doesn't fit; try slow
		beq	gaKillBlock	@ if equal, kill the free block

		@ Move free block after this so it starts at the end of new
		ldr	r5,[r2]		@ Get islarge from old pointer
		ands	r5,r3		@ Isolate the bit
		orrs	r5,r0		@ Replace with new address
		str	r5,[r2]		@ Store new pointer
		adds	r0,4		@ cur + 4
		cmp	r7,r0		@ is last = cur + 4?
		beq	1f		@ leave islarge clear if not
		orrs	r6,r3		@ set islarge
		str	r7,[r0]		@ store free block end
1:		subs	r0,4		@ restore pointer to free block
		str	r6,[r0]		@ store next pointer + islarge flag
gaFixLength:	mov	r0,r12		@ restore orig pointer
		str	r1,[r0]		@ store new length
		adds	r0,4		@ restore pointer
gaRet:		pop	{r5-r7}
		bx	lr		@ return

		@ Delete the free block after us from the list
gaKillBlock:	ldr	r5,[r2]		@ Get islarge from old pointer
		ands	r5,r3		@ Isolate the bit
		orrs	r5,r6		@ Replace with next address
		str	r5,[r2]		@ Store new pointer in prev
		b	gaFixLength

		@ Allocate new block with new size, copy from old to new and
		@ free old.
gaSlowMethod:
		mov	r6,lr		@ save LR
		mov	r5,r12		@ R12 will be lost after the calls
		subs	r0,r1,4		@ size parameter to malloc = new size
		bl	malloc
		mov	lr,r6		@ restore LR for possible early return
		cmp	r0,0		@ malloc returned NULL? (out of mem?)
		beq	gaRet		@ Return zero if so, else R0 = dest
		adds	r1,r5,4		@ second parameter = start of block
		ldr	r2,[r5]		@ Re-retrieve old length, 3rd param
		subs	r2,4
		movs	r7,r0		@ save for returning it at the end
		bl	memcpy
		adds	r0,r5,4		@ free initial block
		bl	free
		mov	lr,r6
		movs	r0,r7
		b	gaRet

doMalloc:	movs	r0,r1		@ size is first arg, not second
		b	malloc

doFree:		push	{lr}
		bl	free
		pop	{r1}
		subs	r0,r0		@ return NULL
		bx	r1

		.ltorg
