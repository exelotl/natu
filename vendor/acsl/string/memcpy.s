/*
 * memcpy implementation for GBA
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

		.global	memcpy
@		.global	acsl_memcpyS
@		.global	acsl_memcpyNS

		.section .text.ARM
		.arm

@ void *memcpy(void *dest, const void *src, size_t n);

@ Version for operands synced (same value % 4)
acsl_memcpyS:	@ Preparatory step: copy a byte if address is odd
		movs	r3,r1,lsr 1
		ldrbcs	r3,[r1],1
		strbcs	r3,[r0],1
		subscs	r2,1

@ This can be commented out because the threshold indicates a minimum length
@ of 12
/*
		beq	finish	@ Note: this prevents using a null pointer
		cmp	r2,2
		bls	epilogue
*/

		@ Preparatory step: copy a halfword if address % 4 = 2
		movs	r3,r1,lsr 2
		ldrhcs	r3,[r1],2
		strhcs	r3,[r0],2
		subscs	r2,2
@ This can be commented out because the threshold indicates a minimum length
@ of 12
/*
		beq	finish
*/

		subs	r2,88
		blo	copyWords

		stmfd	sp!,{r4-r12,lr}

1:		ldmia	r1!,{r3-r12,lr}
		stmia	r0!,{r3-r12,lr}
		ldmia	r1!,{r3-r12,lr}
		stmia	r0!,{r3-r12,lr}
		subs	r2,88
		bhs	1b

		ldmfd	sp!,{r4-r12,lr}

copyWords:	add	r2,88
		subs	r2,4
		blo	copyBytes
1:		ldr	r3,[r1],4
		str	r3,[r0],4
		subs	r2,4
		bhs	1b
copyBytes:	adds	r2,4
		beq	finish
		subs	r2,2
epilogue:	blo	1f
		ldrh	r3,[r1],2
		strh	r3,[r0],2
		beq	finish
1:		ldrb	r3,[r1]
		strb	r3,[r0]
finish:		mov	r0,r12
		bx	lr

@ Version for operands unsynced (different values % 4)
acsl_memcpyNS:	subs	r2,8
		blo	onebyone
1:		ldrb	r3,[r1],1
		strb	r3,[r0],1
		ldrb	r3,[r1],1
		strb	r3,[r0],1
		ldrb	r3,[r1],1
		strb	r3,[r0],1
		ldrb	r3,[r1],1
		strb	r3,[r0],1
		ldrb	r3,[r1],1
		strb	r3,[r0],1
		ldrb	r3,[r1],1
		strb	r3,[r0],1
		ldrb	r3,[r1],1
		strb	r3,[r0],1
		ldrb	r3,[r1],1
		strb	r3,[r0],1
		subs	r2,8
		bhs	1b

onebyone:	adds	r2,8
1:		ldrb	r3,[r1],1
		strb	r3,[r0],1
		subs	r2,1
		bhi	1b

		mov	r0,r12
		bx	lr

		.ltorg

		.text
		.thumb

@ Choose which version to run
memcpy:		cmp	r2,0
		beq	bxlr
		mov	r12,r0
		subs	r3,r0,r1
		lsls	r3,30		@ check if bits 0 and 1 are the same
		bne	unsynced	@ if not, make a byte-by-byte copy
		cmp	r2,12		@ threshold
		blo	unsynced	@ for short runs, unaligned is faster
		ldr	r3,=acsl_memcpyS	@ if so, make an aligned copy
		bx	r3

unsynced:	ldr	r3,=acsl_memcpyNS
		bx	r3

bxlr:		bx	lr

		.ltorg
