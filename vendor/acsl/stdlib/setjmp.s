/* This is a simple version of setjmp and longjmp.

   Nick Clifton, Cygnus Solutions, 13 June 1997.

 * Modified by Pedro Gimeno, Jul 2021 - simplify and make thumb-only.
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

Copyright (c) 1994, 1997, 2001, 2002, 2003, 2004 Red Hat Incorporated.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    The name of Red Hat Incorporated may not be used to endorse
    or promote products derived from this software without specific
    prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL RED HAT INCORPORATED BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/
		.syntax	unified
		.cpu	arm7tdmi

		.global	setjmp
		.global	longjmp

		.section .text.f.setjmp
		.thumb
setjmp:
		/* Save registers in jump buffer.  */
		stmia	r0!, {r4, r5, r6, r7}
		mov	r1, r8
		mov	r2, r9
		mov	r3, r10
		mov	r4, r11
		mov	r5, sp
		mov	r6, lr
		stmia	r0!, {r1, r2, r3, r4, r5, r6}
		subs	r0, r0, 4*(6+4)
		/* Restore callee-saved low regs.  */
		ldmia	r0!, {r4, r5, r6, r7}
		/* Return zero.  */
		movs	r0, 0
		bx	lr

		.section .text.f.longjmp
		.thumb

longjmp:
		/* Restore High regs.  */
		adds	r0, r0, 16
		ldmia	r0!, {r2, r3, r4, r5, r6}
		mov	r8, r2
		mov	r9, r3
		mov	r10, r4
		mov	r11, r5
		mov	sp, r6
		ldmia	r0!, {r3} /* lr */
		/* Restore low regs.  */
		subs	r0, r0, 4*(6+4)
		ldmia	r0!, {r4, r5, r6, r7}
		/* Return the result argument, or 1 if it is zero.  */
		movs	r0, r1
		bne	1f
		movs	r0, #1
1:
		bx	r3
