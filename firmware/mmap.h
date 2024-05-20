#pragma once

#define MMIO32(addr) *((volatile uint32_t*)addr)

/* Global memory map. */
#define UART_BASE  (0x9000)
#define GPIO_BASE  (0x9100)
#define TIMER_BASE (0x9200)

/* Timer. */
#define TIMER_CTRL (TIMER_BASE + 0x0)
#define TIMER_CNT  (TIMER_BASE + 0x4)

#define TIMER_CTRL_ENABLE_IRQ_OFFSET (30)
#define TIMER_CTRL_ENABLE_CNT_OFFSET (31)

/* Uart. */
#define UART_TX     (UART_BASE + 0x0)
#define UART_RX     (UART_BASE + 0x4)
#define UART_STATUS (UART_BASE + 0x8)

#define UART_STATUS_TX_DONE (0)
#define UART_STATUS_TX_BUSY (1)
#define UART_STATUS_RX_DONE (2)

/* GPIO. */
#define GPIO_CTRL (GPIO_BASE + 0x0)
#define GPIO_VAL  (GPIO_BASE + 0x4)

