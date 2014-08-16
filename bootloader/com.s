
#include <avr/io.h>
#include <compat/twi.h>
#include "asm_include.h"

    .section .text
    .global	com_get
    .global com_rdy
    .global com_put
    .global com_put_string

/******************************************************************************
	Read date from serial port
******************************************************************************/
com_get:
    sbis    IO_REG(UCSRA), RXC
    rjmp    com_get
    in      CHAR_GET_REG, IO_REG(UDR)
    ret

/******************************************************************************
    Test, if data is in the buffer
******************************************************************************/
com_rdy:
    sbis    IO_REG(UCSRA), RXC
    rjmp    no_data
    in      CHAR_GET_REG, IO_REG(UDR)       // data present in buffer
com_rdy_ret:
    ret
no_data:
    eor     CHAR_GET_REG, CHAR_GET_REG      // no data
    rjmp    com_rdy_ret

/******************************************************************************
    Send data over serial port
******************************************************************************/
com_put:
    sbis    IO_REG(UCSRA), UDRE
    rjmp    com_put                         // data left in buffer
    out     IO_REG(UDR), CHAR_PUT_REG       // send data
    ret

/******************************************************************************
    Send the data string in data buffer Z 
******************************************************************************/
com_put_string:
    ld      CHAR_PUT_REG, Z+
    tst     CHAR_PUT_REG
    breq    com_send_end
    rcall   com_put
    rjmp    com_put_string
com_send_end:
    ret
