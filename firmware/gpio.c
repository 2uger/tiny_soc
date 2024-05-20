#include "firmware.h"
#include "mmap.h"

void gpio_setup(uint8_t val)
{
    MMIO32(GPIO_VAL) = val;
}

uint8_t gpio_get()
{
    return MMIO32(GPIO_VAL);
}

void gpio_mode_setup(uint8_t mode)
{
    MMIO32(GPIO_CTRL) = mode;
}

