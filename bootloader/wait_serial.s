

#include <avr/io.h>
#include "asm_include.h"

    .section .text
    .global wait_serial

/******************************************************************************
    Wait for character on serial port.
******************************************************************************/
wait_serial:
    clr     temp1
    clr     temp2
    ldi     temp3, SECONDS				// Wait

loop:
    rcall   com_rdy                     // Receiped char?
    tst     CHAR_GET_REG                // teste register
    brne	loop_end                    // yes

    inc     temp1                       // nested loop
    brne    loop
    inc     temp2
    brne    loop
    dec     temp3
    brne    loop
			
loop_end:
    ret
