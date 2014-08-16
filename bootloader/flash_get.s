    
#include <avr/io.h>
#include "asm_include.h"

    .section .text
    .global flash_get

/******************************************************************************
    Wenn this routine was called, the first character of the hex file ":" was
    already receipt. Now, read in the rest of the hex file and write it to
    flash. The receipt program will always be stored in the flash as from
    address 0.
******************************************************************************/
flash_get:
    rcall   buffer_init                 // init flash buffer pointer & counter

start_new:
    rcall   get_rec_val                 // no of data byte in current record
    rcall   get_flash_adr               // read in flash address
    rcall   get_byte                    // data type in record
    tst     INT_REG_L                   // if != 0 => data end
    brne    data_end                    // ... end data transmission
    clr     temp1                       // erase data counter
    sts     read_count, temp1           // no data read in so far

next_byte:
    rcall   get_byte                    // read in byte (already converted to
                                        // "real" hex
    lds     temp1, check_sum            // load checksum value
    add     temp1, INT_REG_L            // update checksum with byte in temp1
    sts     check_sum, temp1            // write back checksum
	
    lds     XL, buffer_adr              // load current flash buffer address
    lds     XH, buffer_adr+1            // register X as pointer
    st      X+, INT_REG_L               // save value to flash buffer
    sts     buffer_adr, XL              // write back buffer address
    sts     buffer_adr+1, XH

    lds     XH, flash_count             // no of values in flash buffer
    inc     XH                          // plus one new value
    sts     flash_count, XH             // write back number
    cpi     XH, SPM_PAGESIZE            // page in flash buffer full?
    brne    dont_save                   //  no  => don't save yet
    rcall   save_buffer                 //  yes => save page to flash

dont_save:
    lds     XH,read_count               // no of saved values in record
    inc     XH                          // plus one value
    sts     read_count, XH              // write back again
    lds     XL, rec_count               // target number of values in current
                                        // record
    cp      XL, XH                      // all data bytes of record read in?
    brne    next_byte                   //  no => data left in record; go ahead

    rcall   get_byte                    // last record value is checksum
    lds     INT_REG_H, check_sum        // load current checksum
    neg     INT_REG_H                   // compute complement on two
    cp      INT_REG_L, INT_REG_H        // compare checksum
    brne    error_trx                   // error, if computed and transmitted
                                        // checksum are not equal

wait_startchar:                         // wait on start char of new record
    rcall   wait_serial                 // read in char from serial port	
    tst     CHAR_GET_REG                // test char
    breq    error_trx                   // noc har => data transmission failed
    cpi     CHAR_GET_REG, STARTCHAR     // is it equal start char ":"
    brne    wait_startchar              //  no => wait
    rjmp    start_new                   //  yes => read in new record

data_end:
    lds     XH, flash_count             // anzahl der werte im flash-puffer laden
    tst     XH                          // noch werte im puffer?
    breq    buffer_empty                 // nein
    rcall   write_buffer                // ja, die restlichen byte im puffer schreiben
    
buffer_empty:
    rcall   wait_serial					
    tst     CHAR_GET_REG				
    brne    buffer_empty					
    ret

/*****************************************
	lese zwei byte ascii-hex vom com-port
	und wandel sie in eine zahl (1 byte)
******************************************/
get_byte:
    ldi     ZL, lo8(int_buffer)				
    ldi     ZH, hi8(int_buffer)
    rcall   wait_serial
    tst     CHAR_GET_REG
    breq    error_trx
    st      Z+, CHAR_GET_REG	
    rcall   wait_serial
    tst     CHAR_GET_REG
    breq    error_trx
    st      Z+, CHAR_GET_REG	
    rcall   ascii_hex
    ret

/*****************************************
	lese anzahl der datenbytes im record
	und initialisiere die record-checksum
******************************************/
get_rec_val:
    rcall   get_byte
    cpi     INT_REG_L, MAXRECORDS       // maximal 16 datenbyte in einem record
    brge    error_trx                   // fehler anzahl > 16!
    sts     rec_count, INT_REG_L        // anzahl abspeichern
    sts     check_sum, INT_REG_L        // checksum init		
    ret

/********************************
	lese die flash-adresse
	und addiere sie zur checksum
*********************************/
get_flash_adr:
    rcall   get_byte
    lds     XL, check_sum
    add     XL, INT_REG_L
    sts     check_sum, XL
    rcall   get_byte
    lds     XL, check_sum
    add     XL, INT_REG_L
    sts     check_sum, XL
    ret

/**********************************
	initialisiere den flash-puffer
***********************************/
buffer_init:
    clr     temp1
    sts     flash_count, temp1
    ldi     temp1, lo8(flash_buffer)
    sts     buffer_adr, temp1
    ldi     temp1, hi8(flash_buffer)
    sts     buffer_adr+1, temp1
    ret
	
/***********************************
	flash-puffer im flash speichern
************************************/
save_buffer:
    rcall   write_buffer
    rcall   buffer_init
    ret

/**************************
 	error datenübertragung
***************************/
error_trx:
    sbi     IO_REG(PORTD), PD2          // led on

error_out:
    brts    loop_err                    // tflag im statusregister gesetzt?
    sbi     IO_REG(PORTB), PB0          // led on
    set                                 // setze tflag im sr
    rjmp    loop_err2	

loop_err:
    cbi     IO_REG(PORTB), PB0          // led off
    clt                                 // lösche tflag im sr

loop_err2:                              // warteschleife
    clr     temp1
    clr     temp2
    ldi     temp3, 3

loop_err3:
    inc     temp1
    brne    loop_err3
    inc     temp2
    brne    loop_err3
    dec     temp3
    brne    loop_err3

    rjmp    error_out
