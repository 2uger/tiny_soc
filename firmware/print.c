#include "firmware.h"
#include "mmap.h"

char getchar()
{
    while((MMIO32(UART_STATUS) & (1 << UART_STATUS_RX_DONE)) == 0) {};
    return MMIO32(UART_RX);
}

void putchar(char ch)
{
    while((MMIO32(UART_STATUS) & (1 << UART_STATUS_TX_BUSY))) {};
    MMIO32(UART_TX) = ch;
    while((MMIO32(UART_STATUS) & (1 << UART_STATUS_TX_DONE)) == 0) {};
}

void print_str(const char *p)
{
    while (*p != 0) {
        if (*p == '\n') {
            putchar(*(p++));
            putchar('\r');
        } else {
            putchar(*(p++));
        }
    }
}

void print_dec(unsigned int val)
{
    char buffer[10];
    char *p = buffer;
    while (val || p == buffer) {
        *(p++) = val % 10;
        val = val / 10;
    }
    while (p != buffer) {
        putchar('0' + *(--p));
    }
}

void print_hex(unsigned int val, int digits)
{
    for (int i = (4*digits)-4; i >= 0; i -= 4)
        putchar("0123456789ABCDEF"[(val >> i) % 16]);
}

