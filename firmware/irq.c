#include <stdint.h>

#include "firmware.h"

#define IRQ_MASK_TIMER 0x4
#define IRQ_MASK_GPIO  0x5
#define IRQ_MASK_UART  0x6

void irq_timer_handler()
{
    print_str("IRQ timer\n");
    gpio_mode_setup(0xf);
    uint8_t gpio_val;
    gpio_val = gpio_get();
    gpio_setup(~gpio_val);
}

void irq_handler(uint32_t irq_mask)
{
    /* Iterate through every bit in irq_mask, because it's possible, that more than one interrupt
     * occured at once, so we need to handle them all. */

    uint8_t gpio_val;

    for (int i = 0; i < 32; i++) {
        if (((irq_mask >> (i - 1)) & 0x1) == 0) {
            continue;
        }
        switch (i) {
            case IRQ_MASK_TIMER:
                irq_timer_handler();
                break;
            case IRQ_MASK_GPIO:
                print_str("IRQ:gpio");
                break;
            case IRQ_MASK_UART:
                print_str("IRQ:uart");
                break;
            default:
                print_str("IRQ:unknown");
                break;
        }
    }
}

