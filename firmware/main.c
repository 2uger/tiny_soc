#include "firmware.h"

void shell(void)
{
    char c;
    while (1) {
        print_str("input>");
        c = getchar();
        while (c > 32 && c < 127) {
            putchar(c);
            c = getchar();
        }
        print_str("\n");
    }
}

void main(void)
{
    set_timer_cnt(0x5f5e100 / 5000);
    enable_timer_irq();
    enable_timer_cnt();

    enable_irq();

    print_str("Custom software running on my custom SOC!!!.\n");
    while (1) {};

    __asm__ volatile("ebreak");
}

