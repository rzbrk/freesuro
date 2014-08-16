
#include <avr/io.h>
#include "asm_include.h"

volatile unsigned char flash_buffer[SPM_PAGESIZE];
volatile unsigned char int_buffer[3];

//volatile unsigned char wait_send[]={"\n\r\n\r(c)Arexx Netherlands [BL-V1.03] / Wait...\n\r"};
volatile unsigned char wait_send[]
    = {"\n\r\n\rFreesuro Bootloader / Wait...\n\r"};
volatile unsigned char flash_ok[] = {"\n\rData transfer successfully!"};

volatile unsigned int  page_adr;            // flashpage address
volatile unsigned char check_sum;           // chechsum for record of hex file

volatile unsigned char rec_len;             // record length
volatile unsigned char read_count;          // no of byte read in

volatile unsigned char buffer_count;        // no of byte in flash buffer
volatile unsigned int  buffer_addr;         // current address of flash buffer

