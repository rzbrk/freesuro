
#include <avr/io.h>
#include "asm_include.h"

    .section .text
    .global write_buffer

/******************************************************************************
    Stores the received buffer to current flash page.
******************************************************************************/
write_buffer:
    lds     ZL, page_adr                    // flash address
    lds     ZH, page_adr+1                  // valid page
    ldi     YH, hi8(flash_buffer)           // RAM pointer
    ldi     YL, lo8(flash_buffer)           // address
    rcall   flash_write_puffer              // write RAM parameter to flash
    ldi     temp1, -1                       // (fuer uebertrag?)
    subi    ZL, -SPM_PAGESIZE               // compute next page in flash
    sbc     ZH, temp1                       // -borrow
    sts     page_adr, ZL                    // current flash address 
    sts     page_adr+1, ZH                  // save again
    ret
