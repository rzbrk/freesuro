    
#include <avr/io.h>
#include "asm_include.h"

    .section .text
    .global flash_get

/******************************************************************************
    When this routine was called, the first character of the hex file ":" 
    (the record mark) was already received. Now, read in the rest of the hex
    file and write it to flash. The received program will always be stored in
    the flash as from address 0. 
******************************************************************************/ 
flash_get:
    rcall   buffer_init                 // init page buffer pointer & counter

start_new:
    rcall   get_rec_len                 // read record len (no of data bytes)
    rcall   get_flash_addr              // read load offset of the record

/*
    The data type field of a record in a hex file is 0x00 for a normal
    record. Only the last line is :00000001FF with a data type field 0x01.
    Hence, if a data type field != 0x00 was received, the data transmission
    can be finished.
*/
    rcall   get_byte                    // read data type field of record
    tst     INT_REG_L                   // if != 0x00 => end of file record
    brne    data_end                    // ... end data transmission

    clr     temp1                       // temp1 = 0
    sts     read_count, temp1           // read_count = 0; no data read in
                                        // so far
/*
    Up from here the data bytes of the record are read in until the end
    of a record is reached. The bytes are saved in the page buffer.
*/
next_byte:
    rcall   get_byte                    // read in byte (already converted to
                                        // "real" hex, stored in INT_REG_L
    lds     temp1, check_sum            // load checksum => temp1
    add     temp1, INT_REG_L            // update checksum with byte read in
    sts     check_sum, temp1            // write back temp1 => checksum
	
    lds     XL, buffer_addr             // load current page buffer address
    lds     XH, buffer_addr+1           // register X as pointer
    st      X+, INT_REG_L               // save byte read in to page buffer
    sts     buffer_addr, XL             // write back buffer address
    sts     buffer_addr+1, XH

/*
    Increment the page buffer counter and see, if the page buffer is full.
    When page buffer is full, save the buffer to flash.
*/
    lds     XH, buffer_count            // no of bytes in page buffer
    inc     XH                          // plus one new value
    sts     buffer_count, XH            // write back number
    cpi     XH, SPM_PAGESIZE            // page buffer full?
    brne    dont_save                   //  no  => don't save yet
    rcall   save_buffer                 //  yes => save page bufferto flash

/*
    Increment the counter for the bytes read_in (read_count). When the end of
    the record is reached, check for checksum errors. Then, wait for the
    record mark character (":") of the next record.
*/
dont_save:
    lds     XH, read_count              // no of saved values of record
    inc     XH                          // plus one value
    sts     read_count, XH              // write back again
    lds     XL, rec_len                 // target number of values in current
                                        // record
    cp      XL, XH                      // all data bytes of record read in?
    brne    next_byte                   //  no => read in another byte

/*
    The checksum read in from the record is stored to INT_REG_L. The checksum
    computed from the record bytes individually read in is stored to INT_REG_H.
    Then, both variables are compared.
*/
    rcall   get_byte                    // last record value is checksum
                                        // => INT_REG_L
    lds     INT_REG_H, check_sum        // load current checksum => INT_REG_H
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
    lds     XH, buffer_count            // anzahl der werte im flash-puffer laden
    tst     XH                          // noch werte im puffer?
    breq    buffer_empty                // nein
    rcall   write_buffer                // ja, die restlichen byte im puffer schreiben
    
buffer_empty:
    rcall   wait_serial					
    tst     CHAR_GET_REG				
    brne    buffer_empty					
    ret

/******************************************************************************
    Read in two ascii-hex characters from the serial port ans convert them
    to a "real" hex file. The result is stored to variable INT_REG_L (in
    routine ascii_hex).
******************************************************************************/
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

/******************************************************************************
    Read the length of the record in the hex file and save the value to the
    variable rec_len. The length is given as a hex value (two ascii chars)
    right after the record mark (":"). The length is also the first value for
    the checksum of the record.
******************************************************************************/
get_rec_len:
    rcall   get_byte
    cpi     INT_REG_L, MAXRECLEN        // max 16 data bytes per record
    brge    error_trx                   // error if > 16!
    sts     rec_len, INT_REG_L          // save record length
    sts     check_sum, INT_REG_L        // initialize checksum		
    ret

/******************************************************************************
    Read the flash address of the record (load offset). The address is a
    16 bit value and counts to the checksum. Beside this, the address is not
    needed for the bootloader.
******************************************************************************/
get_flash_addr:
    rcall   get_byte                    // first byte
    lds     XL, check_sum
    add     XL, INT_REG_L
    sts     check_sum, XL
    rcall   get_byte                    // second byte
    lds     XL, check_sum
    add     XL, INT_REG_L
    sts     check_sum, XL
    ret

/******************************************************************************
    Initialize the flash buffer.
******************************************************************************/
buffer_init:
    clr     temp1
    sts     buffer_count, temp1         // buffer_count = 0
    ldi     temp1, lo8(flash_buffer)
    sts     buffer_addr, temp1          // low byte of flash buffer addr
    ldi     temp1, hi8(flash_buffer)
    sts     buffer_addr+1, temp1        // high byte of flash buffer addr
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
