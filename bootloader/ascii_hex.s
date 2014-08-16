
#include <avr/io.h>
#include "asm_include.h"

    .section .text
    .global ascii_hex

/******************************************************************************
    Converts numbers in ascii hex string (2 bytes) into a "real" hex
    number (1 byte), e.g.:
    
    "1A" (2 bytes) --> 0x1a (1 byte)
    
    The return value is stored in INT_REG_L.
    
    Note: The ascii hex string only contains upper case characters.
******************************************************************************/
ascii_hex:

    ldi     ZL, lo8(int_buffer)             // pointer to string			
    ldi     ZH, hi8(int_buffer)

    ld      temp1, Z+                       // first character
    rcall   hex_value                       // convert

    ldi     temp2, 16                       // multiply with 16
    mul     temp1, temp2                    // ... and move result to r0:r1

    ld      temp1, Z+                       // second character
    rcall   hex_value                       // convert
    mov     INT_REG_L, r0                   // compute result from byte1 *16
    add     INT_REG_L, temp1                // ... and add the rest from byte2

    ret

/**************************
    one ascii-hex-byte --> number
***************************/
hex_value:
    cpi     temp1, 'A'                      // ascii '0'-'9'?
    brlo    next_hex                        //  yes
    subi    temp1, 'A'                      //  no
    subi    temp1, -10
    rjmp    hex_end

next_hex:
    subi    temp1, '0'

hex_end:
    ret
