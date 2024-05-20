#include <stdint.h>

#include "mmap.h"

void set_timer_cnt(uint32_t val)
{
    MMIO32(TIMER_CTRL) |= val;
}

void enable_timer_irq(void)
{
    MMIO32(TIMER_CTRL) |= (1 << TIMER_CTRL_ENABLE_IRQ_OFFSET);
}

void enable_timer_cnt(void)
{
    MMIO32(TIMER_CTRL) |= (1 << TIMER_CTRL_ENABLE_CNT_OFFSET);
}

uint32_t get_timer_cnt(void)
{
    return MMIO32(TIMER_CNT);
}

