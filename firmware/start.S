#include "custom_ops.S"

    .section .text
    .global start
    .global irq_vec
    .global enable_irq
    .global disable_irq
start:
    li sp, 0x8000

    call main

    ebreak

.balign 16
irq_vec:
    /* Save registers. */
    li t0, 0x2000
    sw gp, 0*4(t0)
    sw x1, 1*4(t0)
    sw x2, 2*4(t0)
    sw x3, 3*4(t0)
    sw x4, 4*4(t0)
    sw x5, 5*4(t0)
    sw x6, 6*4(t0)
    sw x7, 7*4(t0)
    sw x8, 8*4(t0)
    sw x9, 9*4(t0)
    sw x10, 10*4(t0)
    sw x11, 11*4(t0)
    sw x12, 12*4(t0)
    sw x13, 13*4(t0)
    sw x14, 14*4(t0)
    sw x15, 15*4(t0)
    sw x16, 16*4(t0)
    sw x17, 17*4(t0)
    sw x18, 18*4(t0)
    sw x19, 19*4(t0)
    sw x20, 20*4(t0)
    sw x21, 21*4(t0)
    sw x22, 22*4(t0)
    sw x23, 23*4(t0)
    sw x24, 24*4(t0)
    sw x25, 25*4(t0)
    sw x26, 26*4(t0)
    sw x27, 27*4(t0)
    sw x28, 28*4(t0)
    sw x29, 29*4(t0)
    sw x30, 30*4(t0)
    sw x31, 31*4(t0)

    addi a0, x4, 0
    
    call irq_handler

    /* Restore registers. */
    li t0, 0x2000
    lw gp, 0*4(t0)
    lw x1, 1*4(t0)
    lw x2, 2*4(t0)
    //lw x3, 3*4(t0)
    lw x4, 4*4(t0)
    lw x5, 5*4(t0)
    lw x6, 6*4(t0)
    lw x7, 7*4(t0)
    lw x8, 8*4(t0)
    lw x9, 9*4(t0)
    lw x10, 10*4(t0)
    lw x11, 11*4(t0)
    lw x12, 12*4(t0)
    lw x13, 13*4(t0)
    lw x14, 14*4(t0)
    lw x15, 15*4(t0)
    lw x16, 16*4(t0)
    lw x17, 17*4(t0)
    lw x18, 18*4(t0)
    lw x19, 19*4(t0)
    lw x20, 20*4(t0)
    lw x21, 21*4(t0)
    lw x22, 22*4(t0)
    lw x23, 23*4(t0)
    lw x24, 24*4(t0)
    lw x25, 25*4(t0)
    lw x26, 26*4(t0)
    lw x27, 27*4(t0)
    lw x28, 28*4(t0)
    lw x29, 29*4(t0)
    lw x30, 30*4(t0)
    lw x31, 31*4(t0)

    picorv32_retirq_insn()

enable_irq:
    picorv32_maskirq_insn(zero, zero)
    ret

disable_irq:
    li t3, 0xffffffff
    picorv32_maskirq_insn(t3, t3)
    ret
    
