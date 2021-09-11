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

.global mmFlushBank

.text
.thumb
.align 2

.thumb_func
@-------------------------------------------------------
mmFlushBank:
@-------------------------------------------------------

	ldr	r0,=mmMemoryBank	@{get memory bank address
	ldr	r0, [r0]		@}
	ldr	r1,=mmModuleCount	@{
	ldr	r1, [r1]		@
	ldr	r2,=mmSampleCount	@ get memory bank size (mods+samps)
	ldr	r2, [r2]		@
	add	r1, r2			@}
	
	lsr	r0, #5			@{align memory bank address
	lsl	r0, #5			@}(is this neccesary?)
	add	r1, r1, #1		@-catch last bit (bug? should be #8?)
	 
@ r0 = bank address
@ r1 = module+sample count
@ cache line size == 32
	
	ldr	r3,=.flushbank		@{switch to arm (for cp15 instructions)
	bx	r3			@}

.arm
.align 2
	 
.flushbank:
	mcr	p15, 0, r0, c7, c14, 1	@-clean and invalidate cache line
	add	r0, r0, #32		@-next 32 bytes...
	subs	r1, #8			@-sub 8 (words)
	bpl	.flushbank		@-loop
	
	bx	lr

.pool
