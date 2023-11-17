/*
 * Unit test for our memory routines
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

		.bss
		.balign	4

@ TODO: check that FreeList pointer is a multiple of 4 (in particular that
@       the islarge flag is 0 always)

NWords = 16
HeapEnd = 0x02040000

		@ This is a map of occupied/free words.
		@ A 1 in a halfword indicates the word belongs to allocated
		@ space; a 0 indicates it belongs to free space.
RAMmap:		.space	NWords*4
RAMmapEnd:

RAMmap2:	.space	NWords*4


		.text
		.thumb

		.global	main

		.include "gba_constants.inc"
		.include "gba_moreconstants.inc"

main:
		@ Restrict the heap to 64 bytes (16 words)
		ldr	r0,=__bss_end__-HeapEnd
		negs	r0,r0
		subs	r0,NWords*4
		bl	GetMem

		@ Change mode
		ldr	r0,=1<<DC_BG2EN|0<<DC_FRAME|3<<DC_MODE
		ldr	r1,=REG_DISPCNT
		str	r0,[r1]

		bl	InitMap

		bl	Check

		movs	r0,0x40
		bl	GetMemChk

		movs	r4,r0
		adds	r0,4
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,16
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,8
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,12
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,20
		movs	r1,44
		bl	FreeMemChk

		movs	r0,r4
		movs	r1,4
		bl	FreeMemChk

		@ Empty at this point

		movs	r0,0x40
		bl	GetMemChk

		@ Full again

		movs	r0,r4
		adds	r0,0x3C
		movs	r1,4
		bl	FreeMemChk

		movs	r0,4
		bl	GetMemChk

		@ Full again

		movs	r0,r4
		adds	r0,0x38
		movs	r1,8
		bl	FreeMemChk

		movs	r0,8
		bl	GetMemChk

		@ Full again

		movs	r0,r4
		adds	r0,0x38
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x3C
		movs	r1,4
		bl	FreeMemChk

		movs	r0,8
		bl	GetMemChk

		@ Full again

		movs	r0,r4
		adds	r0,0x30
		movs	r1,8
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x38
		movs	r1,8
		bl	FreeMemChk

		movs	r0,0x10
		bl	GetMemChk

		@ Full again

		movs	r0,r4
		adds	r0,0x28
		movs	r1,8

		bl	FreeMemChk

		movs	r0,r4
		movs	r1,4
		bl	FreeMemChk
		movs	r0,4
		bl	GetMemChk

		movs	r0,r4
		movs	r1,8
		bl	FreeMemChk
		movs	r0,8
		bl	GetMemChk

		movs	r0,r4
		adds	r0,4
		movs	r1,8
		bl	FreeMemChk
		movs	r0,8
		bl	GetMemChk

		movs	r0,r4
		movs	r1,0x28
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x30
		movs	r1,0xC
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x3C
		movs	r1,4
		bl	FreeMemChk

		movs	r0,0x40
		bl	GetMemChk

		@ All full again

		movs	r0,r4
		adds	r0,0x20
		movs	r1,8
		bl	FreeMemChk

		movs	r0,r4
		movs	r1,8
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,8
		movs	r1,8
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x18
		movs	r1,8
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x10
		movs	r1,8
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x28
		movs	r1,0x40-0x28
		bl	FreeMemChk

		movs	r0,0x40
		bl	GetMemChk

		@ All full again

		movs	r0,r4
		adds	r0,4
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x3C
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x10
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x20
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x1C
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x14
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		adds	r0,0x18
		movs	r1,4
		bl	FreeMemChk

		movs	r0,r4
		movs	r1,4
		bl	FreeMemChk

		movs	r0,0x24-0x10
		bl	GetMemChk

		movs	r0,8
		bl	GetMemChk

		movs	r0,4
		bl	GetMemChk

		movs	r0,r4
		movs	r1,0x40
		bl	FreeMemChk

		@ All empty

		movs	r0,4
		bl	MallocChk
		movs	r4,r0
		movs	r0,16
		bl	MallocChk
		movs	r5,r0
		movs	r0,4
		bl	MallocChk
		movs	r6,r0

		movs	r0,r5
		movs	r1,4
		bl	ReallocChk

		movs	r0,r5
		movs	r1,8
		bl	ReallocChk

		movs	r0,r5
		movs	r1,12
		bl	ReallocChk

		movs	r0,r5
		movs	r1,16
		bl	ReallocChk

		movs	r0,r5
		movs	r1,20
		bl	ReallocChk
		movs	r5,r0

		movs	r0,r4
		bl	FreeChk
		movs	r0,r5
		bl	FreeChk
		movs	r0,r6
		bl	FreeChk

		@ Finish line (Success)
		ldr	r3,=0b0000001111100000
		b	FillScrAndHalt




		.ltorg

		@ Shortcuts to GetMem and FreeMem in thumb mode
GetMem:		.thumb
		ldr	r1,=acsl_GetMem
		bx	r1

FreeMem:	.thumb
		ldr	r2,=acsl_FreeMem
		bx	r2

		.ltorg


@ Memory manager internals
FreeList	= acsl_FreeList
HeapOrg		= HeapEnd - 0x40


InitMap:	movs	r0,0
		ldr	r1,=RAMmap
		movs	r2,NWords
1:		strh	r0,[r1]
		adds	r1,4
		subs	r2,1
		bhi	1b
		bx	lr

@ Similar to GetMem but updates our RAMmap instead
MapGetMem:	cmp	r0,0
		beq	mgmRet
		push	{r4-r5}
		adds	r0,3
		movs	r2,3
		bics	r0,r2
		ldr	r1,=RAMmap
		ldr	r2,=RAMmapEnd
		@ Find free position
mgmFindFree:	ldmia	r1!,{r3}
		cmp	r3,0
		beq	mgmFoundHole
mgmFindFreeChk:	cmp	r1,r2
		blo	mgmFindFree
mgmFindFreeErr:	subs	r0,r0
		pop	{r4-r5}
mgmRet:		bx	lr

mgmFoundHole:
		subs	r5,r1,4		@ remember start position of hole
		subs	r4,r0,4		@ copy length to count holes in r4
					@ (found 1 already)
mgmCheckFits:	beq	mgmFoundRoom	@ if length exhausted, we've found it
		cmp	r1,r2
		bhs	mgmFindFreeErr	@ if past limits, error
		ldmia	r1!,{r3}
		cmp	r3,0
		bne	mgmFindFreeChk	@ if occupied, keep searching
		subs	r4,4
		b	mgmCheckFits

mgmFoundRoom:	movs	r2,r0		@ length
		movs	r0,r5		@ return value = remembered position
		movs	r1,1
mgmSetAlloc:	stmia	r5!,{r1}
		subs	r2,4
		bne	mgmSetAlloc
		ldr	r1,=RAMmapEnd-HeapEnd
		subs	r0,r1
		pop	{r4-r5}
		bx	lr

		@ Test if a MapFreeMem of the requested block would be valid
		@ (Q for Query)
MapFreeMemQ:	adds	r1,3
		movs	r2,3
		bics	r1,r2
		cmp	r1,0
		beq	mfmqBadFree	@ length 0, bad
		cmp	r0,0
		beq	mfmqGoodFree	@ null pointer, good
		ldr	r2,=HeapOrg
		subs	r0,r2
		blo	mfmqBadFree
		ldr	r2,=RAMmap
		adds	r0,r2		@ r0 = corresponding position in map
		ldr	r3,=RAMmapEnd
1:		cmp	r0,r3
		bhs	mfmqBadFree
		ldmia	r0!,{r2}
		cmp	r2,0
		beq	mfmqBadFree
		subs	r1,4
		bhi	1b
mfmqGoodFree:	movs	r0,1
		adds	r0,0		@ clear carry
		bx	lr

mfmqBadFree:	subs	r0,r0		@ set carry
		bx	lr

@ Like MapFreeMemQ but silent, and updating the map
MapFreeMem:	cmp	r0,0
		beq	2f
		ldr	r2,=RAMmapEnd-HeapEnd
		adds	r0,r2
		movs	r2,0
1:		stmia	r0!,{r2}
		subs	r1,4
		bhi	1b
2:		bx	lr

		.ltorg

		@ Test if the memory manager's free list and the miniature
		@ memory map coincide. Tests also the consistency of the
		@ free list.
compareWithMap:	push	{r4-r5}
		@ Pointers to both arrays
		ldr	r4,=RAMmap
		ldr	r5,=HeapOrg

		ldr	r1,=FreeList
		ldr	r1,[r1]		@ grab data at FreeList
		movs	r2,3
		tst	r1,r2
		bne	cwmBad		@ bits 0-1 should be clear, else error
		ldr	r2,=HeapEnd
		cmp	r1,r2
		bhi	cwmBad		@ if [FreeList] > HeapEnd, bad
		subs	r1,r5
		blo	cwmBad		@ if [FreeList] < HeapOrg, bad
		beq	cwmNoLeadBlock	@ if [FreeList] = HeapOrg, no l.block
		@ r1 = index of first free
		movs	r0,0		@ start at index 0
1:		ldrh	r2,[r4,r0]
		adds	r0,4
		cmp	r2,0		@ check if all of them are allocated
		beq	cwmBad		@ empty cell found means error
		cmp	r0,r1		@ while running index < ind.of empty
		blo	1b
		bne	cwmBad		@ consistency check
cwmNoLeadBlock:
		@ at this point, previous pointer and map index are in sync,
		@ and r1 is the common index and points to a free list entry
		@ or end
		ldr	r2,=HeapEnd
		adds	r0,r5,r1	@ pointer into heap
		cmp	r0,r2
		beq	cwmGood		@ if end, all fine
		bhi	cwmBad		@ but never higher
		ldr	r2,[r0]		@ grab next block pointer
		@ Apply sanity checks on this entry
		@ 1. Next mod 4 < 2
		@ 2. Last mod 4 = 0
		@ 3. Current + 4 < Last or Next is odd
		@ 4. Next <= HeapEnd
		@ 5. Last < Next or Last <= Next = HeapEnd
		@ 6. map[i] = 0 for Current <= i < Last
		movs	r1,2
		tst	r2,r1
		bne	cwmBad
		adds	r3,r0,4		@ end of block pointer if islarge = 0
		movs	r1,1
		tst	r2,r1		@ check islarge bit
		beq	cwmCommon

		subs	r2,1		@ clear bit
		ldr	r3,[r3]
		movs	r1,3
		tst	r3,r1
		bne	cwmBad		@ none of these bits should be set
		adds	r0,4
		cmp	r0,r3		@ assert(current + 4 < last)
		bhs	cwmBad		@ bad if not
		subs	r0,4
cwmCommon:
		ldr	r1,=HeapEnd
		cmp	r2,r1		@ assert(Next <= HeapEnd)
		bhi	cwmBad		@ bad if not
		bne	cwmLastLtNext	@ if Next!=HeapEnd, check Last < Next
		@ Check Last <= HeapEnd
		cmp	r3,r2		@ assert(Last <= Next)
		bhi	cwmBad		@ bad if not
		b	1f		@ skip check of Last < Next
cwmLastLtNext:	cmp	r3,r2		@ assert(Last < Next)
		bhs	cwmBad
1:
		subs	r3,r5		@ convert Last to index
		subs	r0,r5		@ convert Current to index
		subs	r2,r5		@ convert Next to index
1:		ldrh	r1,[r4,r0]	@ check that map[i]=0 for Cur<=i<Last
		adds	r0,4
		cmp	r1,0
		bne	cwmBad
		cmp	r0,r3		@ last?
		bne	1b		@ jump if not yet

		movs	r1,RAMmapEnd-RAMmap
		cmp	r0,r1		@ end of array?
		beq	cwmGood		@ finished if so

		@ check that map[i] = 1 for Last <= i < Next

1:		ldrh	r1,[r4,r0]	@ check that map[i]=1 for Last<=i<Next
		adds	r0,4
		cmp	r1,0
		beq	cwmBad
		cmp	r0,r2
		blo	1b
		movs	r1,r2
		b	cwmNoLeadBlock

cwmBad:		subs	r0,r0
		pop	{r4-r5}
		bx	lr
cwmGood:	movs	r0,1
		adds	r0,0
		pop	{r4-r5}
		bx	lr

compareMaps:	@ Strategy 2: Create a parallel map based on the free list
		@ then compare the maps. If they differ, there's an error.
		ldr	r0,=RAMmap2
		movs	r1,1
		movs	r2,NWords*4
1:		stmia	r0!,{r1}
		subs	r2,4
		bne	1b

		ldr	r0,=FreeList
		ldr	r0,[r0]
		movs	r1,3
		tst	r0,r1		@ First pointer mod 4 = 0?
		bne	cmBad		@ Jump if not
		ldr	r1,=HeapOrg
		cmp	r0,r1
		blo	cmBad
		ldr	r1,=HeapEnd
		cmp	r0,r1
		bhi	cmBad
cmNext:
		ldr	r1,=HeapEnd
		cmp	r0,r1
		beq	cmGood
		ldr	r2,[r0]		@ Next
		adds	r3,r0,4		@ EOB = Current + 4
		movs	r1,2
		tst	r2,r1
		bne	cmBad		@ bit 1 should be clear
		movs	r1,1
		tst	r2,r1
		beq	cmGotSize	@ If not islarge, skip checks
		subs	r2,1		@ Clear islarge
		@ Validation of EOB
		ldr	r1,=HeapEnd	@ there must be room for EOB
		cmp	r3,r1
		bhs	cmBad
		ldr	r3,[r3]		@ Grab EOB
		movs	r1,3
		tst	r3,r1		@ EOB mod 4 = 0?
		bne	cmBad		@ Jump if not
		cmp	r3,r0		@ EOB <= Current?
		bls	cmBad		@ bad if so
		subs	r3,4		@ we're in islarge mode
		cmp	r3,r0		@ EOB <= Current + 4?
		bls	cmBad		@ bad if so
		adds	r3,4		@ restore original value

cmGotSize:
		@ Implement:
		@ if EOB > HeapEnd: Error
		@ If EOB = HeapEnd:
		@    if Next != HeapEnd: Error
		@ else if EOB >= Next: Error

		ldr	r1,=HeapEnd
		cmp	r3,r1		@ EOB > HeapEnd?
		bhi	cmBad		@ bad if so
		bne	cmNextChk	@ jump if EOB < HeapEnd
		cmp	r2,r1		@ Next should be = HeapEnd
		bne	cmBad		@ too, else bad
		b	cmSizeOk	@ Size checks passed
cmNextChk:	cmp	r3,r2
		bhs	cmBad		@ Err if EOB >= Next
cmSizeOk:
		cmp	r2,r0		@ Next <= Cur?
		bls	cmBad		@ Bad if so
		cmp	r2,r1		@ Next > HeapEnd?
		bhi	cmBad		@ Bad if so

		ldr	r1,=HeapOrg
		subs	r0,r1
		blo	cmBad
		subs	r3,r1
		ldr	r1,=RAMmap2
		adds	r0,r1
		adds	r3,r1
		movs	r1,0
1:		stmia	r0!,{r1}
		cmp	r0,r3
		blo	1b
		movs	r0,r2		@ Next
		b	cmNext
cmBad:		subs	r0,r0
		bx	lr
cmGood:		ldr	r2,=RAMmap
		ldr	r3,=RAMmap2
1:		ldr	r0,[r2]
		adds	r2,4
		ldr	r1,[r3]
		adds	r3,4
		cmp	r0,r1
		bne	cmBad
		ldr	r1,=RAMmapEnd
		cmp	r2,r1
		blo	1b
		movs	r0,1
		adds	r0,0
		bx	lr

Check:		push	{lr}
		bl	compareWithMap
		adds	r0,0		@ clears carry
		beq	Fatal
		bl	compareMaps
		adds	r0,0		@ clears carry
		beq	Fatal

		push	{r4-r7}
		ldr	r0,=RAMmap
		ldr	r1,=VRAM+240*2+4
2:		ldr	r2,[r0]
		ldr	r3,=0b00011100111001110001110011100111
		cmp	r2,0
		beq	1f
		ldr	r3,=0b00111101111011110011110111101111
1:		stmia	r1!,{r3}
		@stmia	r1!,{r3}
		adds	r0,4
		ldr	r3,=RAMmapEnd
		cmp	r0,r3
		bne	1f
		ldr	r3,=480-4*NWords
		adds	r1,r3
1:		ldr	r3,=RAMmap2+4*NWords
		cmp	r0,r3
		blo	2b
		ldr	r0,=REG_KEYINPUT
1:		ldr	r1,[r0]
		movs	r2,1<<2
		tst	r1,r2
		beq	2f
		movs	r2,1<<3
		tst	r1,r2
		bne	1b
1:		ldr	r1,[r0]
		tst	r1,r2
		beq	1b
2:
		pop	{r4-r7}

		pop	{r0}
		bx	r0

Fatal:		movs	r3,31
FillScrAndHalt:	ldr	r1,=VRAM+240*2*60
		movs	r0,r3
		ldr	r2,=VRAM+240*2*100
1:		strh	r0,[r1]
		adds	r1,2
		cmp	r1,r2
		blo	1b

		.balign	4
		swi	3
		b	.-2

GetMemChk:	push	{r4,lr}
		movs	r4,r0
		bl	GetMem
		movs	r1,r4
		movs	r4,r0
		movs	r0,r1
		bl	MapGetMem
		cmp	r0,r4
		bne	gmcFatal
		movs	r4,r0
		bl	Check
		movs	r0,r4
		pop	{r4}
		pop	{r1}
		bx	r1
gmcFatal:	add	sp,8
		b	Fatal

FreeMemChk:	push	{r4-r5,lr}
		movs	r4,r0
		movs	r5,r1
		bl	MapFreeMemQ
		bcs	fmcFatal
		movs	r0,r4
		movs	r1,r5
		bl	MapFreeMem
		movs	r0,r4
		movs	r1,r5
		bl	FreeMem
		bl	Check
		pop	{r4-r5}
		pop	{r0}
		bx	r0

fmcFatal:	add	sp,12
		b	Fatal


MallocChk:	push	{r4,lr}
		movs	r4,r0
		bl	malloc
		subs	r0,4
		movs	r1,r4
		movs	r4,r0
		adds	r0,r1,4
		bl	MapGetMem
		cmp	r0,r4
		bne	mcFatal
		bl	Check
		adds	r0,r4,4
		pop	{r4}
		pop	{r1}
		bx	r1
mcFatal:	add	sp,8
		b	Fatal

FreeChk:	push	{r4-r5,lr}
		subs	r0,4
		ldr	r1,[r0]
		movs	r4,r0
		movs	r5,r1
		bl	MapFreeMemQ
		bcs	fcFatal
		movs	r0,r4
		movs	r1,r5
		bl	MapFreeMem
		adds	r0,r4,4
		bl	free
		bl	Check
		pop	{r4-r5}
		pop	{r0}
		bx	r0

fcFatal:	add	sp,12
		b	Fatal


@ R0 = pointer, R1 = current size, R2 = new size
MapRealloc:	push	{r4-r5,lr}

		movs	r5,r0
		ldr	r3,=RAMmapEnd-HeapEnd
		adds	r0,r3	@ make R0 relative to RAMmap
		movs	r4,r1
		@ Check that it is allocated
1:		ldmia	r0!,{r3}
		cmp	r3,0
		beq	mraFatal
		subs	r4,4
		bhi	1b

		subs	r2,r1
		mov	r12,r2
		beq	mraRetOrig
		blo	mraShrink

1:		ldmia	r0!,{r3}
		cmp	r3,0
		bne	mraMove
		subs	r2,4
		bne	1b
		mov	r2,r12
		subs	r0,r2
		movs	r4,1
1:		stmia	r0!,{r4}
		subs	r2,4
		bne	1b
		b	mraRetOrig

mraMove:	mov	r0,r12
		adds	r0,r1
		movs	r4,r1
		bl	MapGetMem
		movs	r1,r4
		movs	r4,r0
		movs	r0,r5
		bl	MapFreeMem
		movs	r0,r4
		b	mraDone

mraShrink:	movs	r1,0
1:		subs	r0,4
		str	r1,[r0]
		adds	r2,4
		bne	1b

mraRetOrig:	movs	r0,r5
mraDone:	pop	{r4-r5}
		pop	{r3}
		bx	r3

mraFatal:	add	sp,12
		b	Fatal


ReallocChk:	push	{r4-r6,lr}
		subs	r4,r0,4
		ldr	r5,[r4]		@ orig size in R5
		adds	r6,r1,4		@ target size in R6 (+ size word)
		bl	realloc
		subs	r0,4
		ldr	r2,[r0]		@ get stored target size
		cmp	r2,r6		@ does it match requested target size?
		bne	racFatal
		@ target sizes match, R2 = target size
		movs	r6,r0		@ save return value in R6

		movs	r0,r4		@ orig pointer
		movs	r1,r5		@ orig size in R1, target size in R2
		bl	MapRealloc
		@ compare return values
		cmp	r0,r6
		bne	racFatal

		bl	Check
		adds	r0,r6,4

		pop	{r4-r6}
		pop	{r1}
		bx	r1

racFatal:	add	sp,16
		b	Fatal

		.ltorg
