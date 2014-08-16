
#include <avr/io.h>
#include <compat/twi.h>
#include "asm_include.h"

    .section .text
    .global	com_init

#define BAUDRATE 207                        // 2400 Baud

/*
    Formula to compute the baudrate:
    baudrate=(F_CPU / (UART_BAUD_RATE * 16L) - 1)
*/

/******************************************************************************
    Initialize the serial port with 2400 baud and 8m1
******************************************************************************/
com_init:
    eor     temp1, temp1
    out     IO_REG(UBRRH), temp1
    ldi     temp1, BAUDRATE	
    out     IO_REG(UBRRL), temp1
    ldi     temp1, (BIT(RXEN) + BIT(TXEN))
    out     IO_REG(UCSRB), temp1
    ret
