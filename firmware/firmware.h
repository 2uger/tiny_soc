#pragma once

#include <stdint.h>
#include <stdbool.h>

// main.c
void shell(void);
void main(void);

// irq.c
void irq_handler(uint32_t);
void enable_irq(void);
void disable_irq(void);

// print.c
char getchar(void);
void putchar(char ch);
void print_str(const char *p);
void print_dec(unsigned int val);
void print_hex(unsigned int val, int digits);

// gpio.c
void gpio_setup(uint8_t);
uint8_t gpio_get(void);
void gpio_mode_setup(uint8_t);


// timer.c
void set_timer_cnt(uint32_t);
uint32_t get_timer_cnt(void);
void enable_timer_irq(void);
void enable_timer_cnt(void);

