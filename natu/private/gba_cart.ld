/* From https://github.com/AntonioND/gba-bootstrap */

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(entrypoint)

MEMORY {
    ROM     : ORIGIN = 0x08000000, LENGTH = 32M
    IWRAM   : ORIGIN = 0x03000000, LENGTH = 32K
    EWRAM   : ORIGIN = 0x02000000, LENGTH = 256K
}

/* Set stack pointers the same way as the BIOS */

__STACK_SVC_SIZE__      = 0x40;
__STACK_IRQ_SIZE__      = 0xA0;
__STACK_USR_SIZE_MIN__  = 0x200; /* Minimum size, the real size may be bigger */

__STACK_END__       = ORIGIN(IWRAM) + LENGTH(IWRAM) - 0x20; /* Used by BIOS */
__STACK_SVC_END__   = __STACK_END__;
__STACK_SVC_START__ = __STACK_SVC_END__ - __STACK_SVC_SIZE__;
__STACK_IRQ_END__   = __STACK_SVC_START__;
__STACK_IRQ_START__ = __STACK_IRQ_END__ - __STACK_IRQ_SIZE__;
__STACK_USR_END__   = __STACK_IRQ_START__;
__STACK_USR_START__ = __STACK_USR_END__ - __STACK_USR_SIZE_MIN__;
__STACK_START__     = __STACK_USR_START__;

SECTIONS
{
    /*
     * ROM sections
     * ============
     */

    /* Header and crt0 */

    .gba_crt0 : ALIGN(4)
    {
        KEEP (*(.gba_crt0))
    } > ROM

    /* Code */

    .text : ALIGN(4)
    {
        *(.text)
        *(.text*)
        *(.gnu.linkonce.t.*) /* Used for vague linking */

        /* ARM/Thumb interworking code */
        *(.glue_7)  /* glue arm to thumb code */
        *(.glue_7t) /* glue thumb to arm code */

        /* Array of functions to be called at the start of the program */
        KEEP(*(.init))
        /* Array of functions to be called at the end of the program */
        KEEP(*(.fini))
    } > ROM

    /* Read-only data */

    .rodata : ALIGN(4)
    {
        *(.rodata)
        *(.rodata*)
        *(.gnu.linkonce.r.*) /* Used for vague linking */
    } > ROM

    /*
     * Required by libgcc for exception handling?
     * https://stackoverflow.com/q/9752000
     */
    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    }
    .ARM.exidx :
    {
        PROVIDE_HIDDEN(__exidx_start = .);
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN(__exidx_end = .);
    }

    /* Array of functions to be called during initialization of the program */

    .preinit_array : ALIGN(4)
    {
        __preinit_array_start = .;
        KEEP(*(.preinit_array*))
        __preinit_array_end = .;
    } > ROM

    /*
     * Array of functions to be called during initialization of the program.
     * They are called after calling everything in .preinit_array
     */

    .init_array : ALIGN(4)
    {
        __init_array_start = .;
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array*))
        __init_array_end = .;
    } > ROM

    /* Array of functions called when the program ends. */

    .fini_array : ALIGN(4)
    {
        __fini_array_start = .;
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array*))
        __fini_array_end = .;
    } > ROM

    /*
     * IWRAM sections
     * ==============
     */

    /* Uninitialized variables */

    .bss (NOLOAD) : ALIGN(4)
    {
        *(.bss)
        *(.bss*)
        *(.gnu.linkonce.b.*) /* Used for vague linking */
        *(COMMON) /* In case -fcommon is used in gcc (not used by default) */
        . = ALIGN(4);
    } > IWRAM

    __IWRAM_BSS_START__ = ADDR(.bss);
    __IWRAM_BSS_SIZE__ = SIZEOF(.bss);
    __IWRAM_BSS_END__ = __IWRAM_BSS_START__ + __IWRAM_BSS_SIZE__;

    /* Read-write data goes into IWRAM */

    .data : ALIGN(4)
    {
        __DATA_START__ = .;
        *(.data)
        *(.data*)
        *(.gnu.linkonce.d.*) /* Used for vague linking */
        . = ALIGN(4);
        __DATA_END__ = .;
    } > IWRAM AT> ROM

    __DATA_SIZE__ = __DATA_END__ - __DATA_START__;
    __DATA_LMA__ = LOADADDR(.data);

    /* Sections that the user requests to add to IWRAM */

    .iwram : ALIGN(4)
    {
        __IWRAM_START__ = .;
        *(.iwram)
        *(.iwram*)
        *iwram.*(.text*)
        *iwram.*(.data*)
        . = ALIGN(4);
        __IWRAM_END__ = .;
    } > IWRAM AT> ROM

    __IWRAM_SIZE__ = __IWRAM_END__ - __IWRAM_START__;
    __IWRAM_LMA__ = LOADADDR(.iwram);

    /* The stack goes afterwards, check that there aren't overflows */

    ASSERT(__IWRAM_END__ <= __STACK_START__,
           "Not enough free IWRAM for stack")

    /* Calculate real size of the user stack */

    __STACK_USR_SIZE__ = __STACK_USR_END__ - __IWRAM_END__;

    /*
     * EWRAM sections
     * ==============
     */

    /*
     * Uninitialized data explicitly placed in EWRAM. This section must be
     * called ".sbss" for compatibility with devkitARM.
     */

    .sbss (NOLOAD) : ALIGN(4)
    {
        *(.sbss)
        *(.sbss*)
        . = ALIGN(4);
    } > EWRAM

    /* Initialized data explicitly placed in EWRAM */

    .ewram : ALIGN(4)
    {
        __EWRAM_START__ = .;
        *(.ewram)
        *(.ewram*)
        *ewram.*(.text*)
        *ewram.*(.data*)
        . = ALIGN(4);
        __EWRAM_END__ = .;
    } > EWRAM AT > ROM

    __EWRAM_SIZE__ = __EWRAM_END__ - __EWRAM_START__;
    __EWRAM_LMA__ = LOADADDR(.ewram);

    /* The heap information should be after the last EWRAM section */

    __HEAP_START__  = __EWRAM_END__;
    __HEAP_END__    = ORIGIN(EWRAM) + LENGTH(EWRAM);
    __HEAP_SIZE__   = __HEAP_END__ - __HEAP_START__;
}
