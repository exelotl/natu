// From https://github.com/AntonioND/gba-bootstrap

    .section    .gba_crt0, "ax"
    .global     entrypoint
    .cpu        arm7tdmi

    .arm

entrypoint:
    b       header_end

    .fill   156, 1, 0   // Nintendo Logo
    .fill   12, 1, 0    // Game Title
    .fill   4, 1, 0     // Game Code
    .byte   0x30, 0x30  // Maker Code ("00")
    .byte   0x96        // Fixed Value (must be 0x96)
    .byte   0x00        // Main unit code
    .byte   0x00        // Device Type
    .fill   7, 1, 0     // Reserved Area
    .byte   0x00        // Software version
    .byte   0x00        // Complement check (header checksum)
    .byte   0x00, 0x00  // Reserved Area

header_end:
    b       start_vector

    // Multiboot Header Entries
    .byte   0           // Boot mode
    .byte   0           // Slave ID Number
    .fill   26, 1, 0    // Not used
    .word   0           // JOYBUS entrypoint

    .align

start_vector:

    // Disable interrupts
    mov     r0, #0x4000000
    mov     r1, #0
    str     r1, [r0, #0x208] // IME

    // Setup IRQ mode stack
    mov     r0, #0x12
    msr     cpsr, r0
    ldr     sp, =__STACK_IRQ_END__

    // Setup system mode stack
    mov     r0, #0x1F
    msr     cpsr, r0
    ldr     sp, =__STACK_USR_END__

    // Switch to Thumb mode
    add     r0, pc, #1
    bx      r0

    .thumb

    // Clear IWRAM
    ldr     r0, =#0x3000000
    ldr     r1, =#(32 * 1024)
    bl      mem_zero

    // Copy data section from ROM to RAM
    ldr     r0, =__DATA_LMA__
    ldr     r1, =__DATA_START__
    ldr     r2, =__DATA_SIZE__
    bl      mem_copy

    // Copy IWRAM data from ROM to RAM
    ldr     r0, =__IWRAM_LMA__
    ldr     r1, =__IWRAM_START__
    ldr     r2, =__IWRAM_SIZE__
    bl      mem_copy

    // Clear EWRAM
    ldr     r0, =#0x2000000
    ldr     r1, =#(256 * 1024)
    bl      mem_zero

    // Copy EWRAM data from ROM to RAM
    ldr     r0, =__EWRAM_LMA__
    ldr     r1, =__EWRAM_START__
    ldr     r2, =__EWRAM_SIZE__
    bl      mem_copy

    // Global constructors
    ldr     r2, =__libc_init_array
    bl      blx_r2_trampoline

    // Call main()
    mov     r0, #0 // int argc
    mov     r1, #0 // char *argv[]
    ldr     r2, =main
    bl      blx_r2_trampoline

    // Global destructors
    ldr     r2, =__libc_fini_array
    bl      blx_r2_trampoline

    // If main() returns, reboot the GBA using SoftReset
    swi     #0x00

// r0 = Base address
// r1 = Size
mem_zero:
    and     r1, r1
    beq     2f // Return if size is 0

    mov     r2, #0
1:
    stmia   r0!, {r2}
    sub     r1, #4
    bne     1b

2:
    bx      lr

// r0 = Source address
// r1 = Destination address
// r2 = Size
mem_copy:
    and     r2, r2
    beq     2f // Return if size is 0

1:
    ldmia   r0!, {r3}
    stmia   r1!, {r3}
    sub     r2, #4
    bne     1b

2:
    bx      lr

// r2 = Address to jump to
blx_r2_trampoline:
    bx      r2

    .align
    .pool
    .end
