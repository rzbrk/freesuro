
#include <avr/io.h>
#include "asm_include.h"

    .section .text
    .global flash_write_puffer

/******************************************************************************
    Write fash page.
    
    Flash page address:             register x
    RAM address from data buffer:   register y
******************************************************************************/
flash_write_puffer:
    in      temp1, IO_REG(SREG)             // save status register
    push    temp1                           // ... to stack
    cli                                     // disable interrupts
/*
    Save flash address (register Z)
*/
    push    ZH
    push    ZL

/*
    Any access to eeprom going on?
*/
floop1:
    sbic    IO_REG(EECR), EEWE
    rjmp    floop1

/*
    Always delete flash before rewriting it. Flash address in register X.
*/
    ldi     temp1, (BIT(SPMEN) + BIT(PGERS))
    rcall   flash_wait                      // wait until complete

/*
    initialize counter
*/
    ldi     temp2, (SPM_PAGESIZE/2)         // writing in portions of
                                            // 2 byte = 1 word
/*
    Copy data RAM --> flash
*/
flash_fill:
    ld      r0, Y+                          // take two byte from RAM
    ld      r1, Y+
    ldi     temp1, BIT(SPMEN)               // control bit
    rcall   flash_wait                      // wait until complete
    dec     temp2                           // decrement counter
    breq    floop2                          // 0 => copying completed
    adiw    ZL, 2                           // point to next address
    rjmp    flash_fill                      // ... and go ahaed

/*
    recover flash address from stack
*/
floop2:
    pop     ZL
    pop     ZH

/*
    write copied data in RAM to flash
*/
    ldi     temp1, (BIT(SPMEN) + BIT(PGWRT))
    rcall   flash_wait

/*
    re-enable rww section
*/
    ldi     temp1, (BIT(SPMEN) + BIT(RWWSRE))
    rcall   flash_wait
/*
    Recover status register from stack
*/
    pop     temp1                           // recover status register
    out     IO_REG(SREG), temp1
    ret

/******************************************************************************
    Wait until SPM is completed
******************************************************************************/
flash_wait:
    out     IO_REG(SPMCR), temp1            // write to control register
    spm
flash_wait2:
    in      temp1, IO_REG(SPMCR)            // read control register
    sbrc    temp1, SPMEN                    // completed?
    rjmp    flash_wait2                     //  no
    ret                                     //  yes
