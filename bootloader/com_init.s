
#include <avr/io.h>
#include <compat/twi.h>
#include "asm_include.h"

            .section .text
			.global	com_init

#define BAUDRATE 207	// 2400 Baud

/*
	formel: baudrate=(F_CPU / (UART_BAUD_RATE * 16L) - 1)
*/

/******************************
	initialisiere den com-port
	mit 2400 baud und 8n1
*******************************/
com_init:
	eor		temp1, temp1
	out		IO_REG(UBRRH), temp1
	ldi		temp1, BAUDRATE	
	out		IO_REG(UBRRL), temp1
	ldi		temp1, (BIT(RXEN) + BIT(TXEN))
	out		IO_REG(UCSRB), temp1
	ret

