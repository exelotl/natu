/*
 *
 * Linker script for ACSL
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

ENTRY(_start)

MEMORY
{
  EWRAM (WX) : ORIGIN = 0x02000000, LENGTH = 256K
  IWRAM (WX) : ORIGIN = 0x03000000, LENGTH = 32K
  ROM (RX) : ORIGIN = 0x08000000, LENGTH = 32M
}

SECTIONS
{
  /* To ROM */
  .text :
  {
    *(.gbaheader)
    *(.text)
    . = ALIGN(4);
    __text_end = .;
  } > ROM

  /* To ROM */
  .rodata :
  {
    *(.rodata .rodata.*)
    . = ALIGN(4);
  } > ROM

  /* To ROM ? */
  .ARM.extab :
  {
    *(.ARM.extab)
  } > ROM
  PROVIDE_HIDDEN (__extab_end = .);

  /* To ROM ? */
  .ARM.exidx :
  {
    *(.ARM.exidx)
  } > ROM
  . = ALIGN(4);
  PROVIDE_HIDDEN (__exidx_end = .);
  __romonly_end = .;

  /* To ROM but copied to IWRAM */
  /* Note: Uses an ELF standard section name in order to configure section
     flags to sensible values, even if the purpose is not correct. */
  .fini : AT (__romonly_end)
  {
    __armtext_start = .;
    *(.text.ARM .text.ARM.*)
    . = ALIGN(4);
    __armtext_end = .;
  } > IWRAM
  __armtext_size = SIZEOF(.fini);
  __armtext_load_start = LOADADDR(.fini);

  /* To ROM but copied to EWRAM */
  .data : AT (__romonly_end + __armtext_size)
  {
    __data_start = .;
    *(.data .data.*)
    . = ALIGN(4);
    __data_end = .;
  } > EWRAM
  __data_size = SIZEOF(.data);
  __data_load_start = LOADADDR(.data);

  /* To EWRAM after the copy of initialized data */
  .bss :
  {
    *(.bss .bss.*)
    . = ALIGN(4);
  } > EWRAM
  __bss_end__ = .;

  /* To IWRAM after the copy of the ARM-mode code */
  .iwram :
  {
    *(.iwram .iwram.*)
  } > IWRAM
}
