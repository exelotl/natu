/*
 * Memory Manager for GBA
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

@
@ Memory manager routines.
@
@ IMPORTANT: If used standalone, call acsl_initMemMgr before using!
@ (if using this library, crt0.s normally does this for you)
@

		.include "gba_constants.inc"
		.include "errnos.inc"

@ C interface
		.global	malloc
		.global	free

@ Internal functions exported
		.global	acsl_GetMem
		.global	acsl_FreeMem
		.global	acsl_initMemMgr

@ Variables exported
		.global	acsl_FreeList		@ Points to free memory list

HeapOrg		= __HEAP_START__
HeapEnd		= EWRAM_END

		.section .iwram
		.balign	4

FreeList:	.space	4
acsl_FreeList	= FreeList

		.section .text.ARM
		.balign	4

@ Allocation strategy:
@ It's similar to Turbo Pascal 6.0+ heap manager. Exceptions are: (1) the
@ pointer format is a 32-bit offset, not a 16-bit offset + a 16-bit segment,
@ and (2) granularity is 4-byte instead of 8-byte.
@
@ In an abstract sense, the heap is treated as a bitmap of allocated and
@ unallocated words. GetMem(size) finds a run of contiguous free words with
@ the given size, then marks them as allocated in the bitmap and returns the
@ pointer. FreeMem(pointer, size)  assumes that there is always a run of
@ allocated words at the given address, covering at least the given length,
@ to mark them as free. If that's not the case, memory corruption can result.
@ Of course things will go fine if the size passed to FreeMem always matches
@ the allocated size, and the free memory area is not touched by the
@ application.
@
@ In practice, there's no actual bitmap: the concept is actually implemented
@ as a linked list of free blocks, where every block that is not in the list
@ is considered allocated. The list resides in unallocated memory. THE LIST
@ MUST BE INITIALIZED by calling acsl_initMemMgr. Calling FreeMem may create
@ a new free block; in that case it gets inserted into the free blocks list
@ in ascending order. Order preservation helps with merging contiguous free
@ blocks. Note also that a buffer overflow is likely to corrupt the linked
@ list, as the control data is stored immediately after each allocated block.
@
@ - The labels HeapOrg and HeapEnd are the start and end of the heap.
@
@ - All blocks are 4-byte granular, so when a block is freed there's room for
@   at least one dword value.
@
@ - FreeList points to a free memory list. This list is present in unallocated
@   memory. When a block is freed causing a hole (i.e. it was not the last
@   block allocated) the memory manager puts a free-list entry in that just
@   unallocated memory (remember that, as allocation will always be at least
@   4 bytes in size, there will always be room for a free-list entry when the
@   block is deallocated).
@
@   The format of a free-list entry is:
@
@    Ofs  Size   Desc
@     0    4     Pointer to next entry in the free list (HeapEnd if last free
@                block). If the value is even, the other field is absent and
@                the block is assumed to be exactly 4 bytes long; in that
@                case the address of the next block is the value of this
@                field. If it is odd, the address of the next free block is
@                the value of this field - 1, and the other field is present.
@    (4)  (4)    Pointer to the end of this free block in bytes. Present only
@                when the previous field is odd. The size of the block is 4
@                when this field is absent, or the value of this field minus
@                the address of the start of this block when this field is
@                present.
@
@ - When allocating a block, the free list is checked for the first free block
@   where the requested size fits.
@
@   Allocation causes the free block in which the current one is allocated to
@   either be shrunk and its origin moved, or removed.
@
@ - Freeing a block is a more complex operation. Conceptually, it works in
@   two steps: first, insert a new free block in the list; then, normalize
@   the list so that there are no contiguous free blocks. The free list is
@   always in ascending order, so the first thing to do is check where in the
@   list the new free block needs to be inserted.
@
@   In practice, the normalization happens on the fly, by checking the
@   preceding and following blocks and merging the new free block with them
@   as it is created.

@ --------
@  GetMem
@ --------
@
@   Allocate memory block
@
@   Input:    r0   =  Amount of memory to allocate
@
@   Output:   r0   =  Pointer to the allocated memory, or 0 if not enough
@                     memory available.
@             CF   =  set if not enough memory, clear otherwise
@
@   Destroys: r1-r3

acsl_GetMem:	.arm

		stmdb	sp!,{r4-r5}

		@ r0 = size of block
		@ Note: malloc will always pass r0 > 4.

		ldr	r5,=FreeList
		ldr	r12,=HeapEnd

		adds	r0,3		@ Round up to the next multiple of 4
		bcs	gmError		@ If carry then len was > FFFFFFFC
					@ and would cause a wraparound -> Err
		bic	r0,3		@ 4-byte alignment (granularity)

		ldr	r3,=HeapOrg-HeapEnd	@ R3 = -max size
		cmn	r0,r3		@ Error if size > max size
		bhi	gmError		@ (avoids overflows in calculations)

		mov	r4,r5		@ previous pointer in r4
		ldr	r5,[r5]
		cmp	r5,r12		@ end of memory?
		bhs	gmError

gmNextFree:
		add	r2,r5,4	@ R2 = ^Last or place where ^Last is
		ldr	r1,[r5]		@ R1 = pointer to next free block
		tst	r1,1		@ Bit 0: islarge flag
		bicne	r1,1		@ Clear it so it's a valid pointer
		ldrne	r2,[r2]		@ Grab ^Last from this address

		@ r1 = address of next free block
		@ r2 = address of end of current block
		add	r3,r5,r0	@ candidate ptr + alloc size
		cmp	r3,r2		@ Is there room in this block?
		bls	gmFoundRoom	@ If so, jump to arrange stuff
		mov	r4,r5		@ R4 = previous block pointer
		mov	r5,r1		@ R5 = pointer to new block
		cmp	r5,r12		@ Last block?
		bls	gmNextFree	@ No, keep searching

gmError:
		subs	r0,r0		@ Return null pointer and CF=1
		ldmia	sp!,{r4-r5}
		bx	lr

gmFoundRoom:
		beq	gmVanishBlock	@ Fits exactly; this block disappears

		@ Shrink block; R3 holds where the shrunk free block should be
		sub	r12,r2,4	@ used to check if block length is 4
		cmp	r3,r12		@ is it?
		orrne	r1,1		@ set flag if not
		strne	r2,[r3,4]	@ store the end of block if not
		str	r1,[r3]		@ store pointer to next + islarge flag
		ldrh	r1,[r4]
		and	r1,1
		orr	r1,r3
		str	r1,[r4]		@ update pointer to previous block
		adds	r0,r5,0		@ Return allocated pointer and CF=0
		ldmia	sp!,{r4-r5}
		bx	lr

gmVanishBlock:
		@ Remove this block.

		ldrh	r0,[r4]		@ Get flag in bit 0 (reusing R0 here)
		and	r0,1		@ Isolate it
		bic	r1,1		@ Clear flag in pointer to next
		orr	r1,r0		@ Copy flag from previous pointer
		str	r1,[r4]		@ Overwrite previous pointer
		adds	r0,r5,0		@ Return allocated pointer and CF=0
		ldmia	sp!,{r4-r5}
		bx	lr

@ ---------
@  FreeMem
@ ---------
@
@   Releases memory allocated by GetMem
@
@   Input:    r0  = pointer to release
@             r1  = size to release
@
@   Output:   CF = 0 if successful, 1 if invalid block passed.
@
@   Destroys: r0-r3
acsl_FreeMem:	.arm
		stmdb	sp!,{r4-r5}

		@ Check the free block list, to see what blocks we need to
		@ modify

		@ The error checks have been disabled for speed.

		adds	r1,3		@ Round up to a multiple of 4 part 1/2
		bcs	fmError		@ If carry then len was > FFFFFFFC
					@ and would cause a wraparound -> Err
		bics	r1,3		@ Round up to 4-byte multiple part 2/2
		beq	fmError		@ Zero size -> Return

		add	r1,r0		@ R1 = end of block to free
		bcs	fmError		@ An overflow here would be a tragedy.
		ldr	r5,=FreeList
		mov	r2,r5

		@ Keep a delayed pointer and follow the chain
1:		mov	r3,r2		@ R3 = Delayed pointer to cur.free blk
		ldr	r2,[r2]		@ R2 = Current free block
		bic	r2,1		@ Clear islarge flag
		cmp	r1,r2		@ target blk end <= current blk start?
		bhi	1b		@ no, keep searching
		@ It's impossible under normal conditions that r1 > HeapEnd
		@ therefore the check that r1 <= r2 suffices for termination,
		@ no need to check for HeapEnd.

		@ We need to add a block between the previous block (in R3)
		@ and the current block (in R2).

		@ First, check if there's a block before us that is contiguous
		@ to us. If so, it needs to be extended rather than creating
		@ one.
		cmp	r3,r5		@ is there a previous block?
		beq	fmNoMergeHead	@ if not, we don't need to merge it

		@ Previous block present. Check if we need to add ourselves
		@ to it, by checking if the end of the block = ourselves.
		@ If not, we need to create a new one too.
		ldrh	r4,[r3]		@ get previous block's islarge flag
		tst	r4,1		@ set?
		add	r4,r3,4		@ prepare end = start + 4
		ldrne	r4,[r4]		@ read ptr to last if bit set

		@ We now have the end of the previous block in R4; if it
		@ doesn't equal the block to free, create a new one.
		cmp	r4,r0		@ does the block end at this one?
		moveq	r0,r3		@ move block pointer if so
		beq	fmCheckLast	@ don't create new block if so

@ Create a new head
fmNoMergeHead:	ldrh	r4,[r3]		@ get previous islarge flag
		and	r4,1		@ isolate it
		orr	r4,r0		@ merge flag w/ initial block address
		str	r4,[r3]		@ update last block's next ptr
					@ to point to us

fmCheckLast:	ldr	r5,=HeapEnd
		cmp	r2,r5		@ if next = HeapEnd, don't merge
		beq	fmNoMergeTail
		cmp	r1,r2		@ are we touching the next block?
		beq	fmMergeTail	@ merge both if so

fmNoMergeTail:	@ Adjust islarge in R2 and store it in [R0], and R1 in [R0+4].
		sub	r4,r1,4		@ use r4 to not need to restore r1
		cmp	r4,r0		@ Are we of size 4?
		orrne	r2,1		@ If not, set islarge flag
		str	r2,[r0]		@ Store pointer + islarge flag
		strne	r1,[r0,4]	@ Store Last
fmError:	ldmia	sp!,{r4-r5}	@ Pop and ret
		bx	lr

fmMergeTail:	ldr	r3,[r2]		@ Grab next block's next ptr
		tst	r3,1		@ Do the usual dance to get Last
		orr	r3,1		@ The new islarge will surely be set
		add	r1,r2,4
		ldrne	r1,[r1]
		str	r3,[r0]		@ Expand this block by using the next
		str	r1,[r0,4]	@ block's Next and Last pointers
		ldmia	sp!,{r4-r5}
		bx	lr

		.ltorg


		.text
		.thumb

@ Simulate BLX in ARMv4T

bxr2:		bx	r2

@ Front-end providing malloc() and free() semantics
@ R0 = size to allocate, returns R0 = pointer or NULL

malloc:		cmp	r0,0
		beq	maZero
		adds	r0,4		@ Add room for a word to the size
		push	{r0,lr}		@ Keep size we're requesting
		ldr	r2,=acsl_GetMem	@ Prepare for subroutine call
		bl	bxr2		@ Call R2
		pop	{r1,r2}		@ Size to R1, LR to R2
		bcs	maFail		@ If failed, set errno
		stmia	r0!,{r1}	@ Store size and increment
		bx	r2

maFail:		ldr	r1,=errno
		ldr	r3,=ENOMEM
		str	r3,[r1]
		bx	r2

maZero:		bx	lr

@ R0 = pointer to free; block length is stored and nonzero (but possibly odd)

free:		.thumb
		cmp	r0,0
		beq	maZero		@ just return
		push	{lr}
		subs	r0,4		@ Back to where length is stored
		ldr	r1,[r0]		@ Retrieve length (no ldmdb in thumb)
		ldr	r2,=acsl_FreeMem	@ Prepare for subroutine call
		bl	bxr2		@ Call R2
		pop	{r0}
		bx	r0

acsl_initMemMgr:
		.thumb

		@ We assume that HeapEnd - HeapOrg >= 8.
		ldr	r0,=HeapOrg
		ldr	r1,=FreeList
		str	r0,[r1]		@ [FreeList] = HeapOrg
		ldr	r1,=HeapEnd+1
		str	r1,[r0]		@ [HeapOrg] = HeapEnd + islarge
		subs	r1,1
		str	r1,[r0,4]	@ [HeapOrg+4] = HeapEnd

		bx	lr

		.ltorg
