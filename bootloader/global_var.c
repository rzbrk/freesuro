
#include <avr/io.h>
#include "asm_include.h"

volatile unsigned char flash_buffer[SPM_PAGESIZE];
volatile unsigned char int_buffer[3];

volatile unsigned char wait_send[]={"\n\r\n\r(c)Arexx Netherlands [BL-V1.03] / Wait...\n\r"};
volatile unsigned char flash_ok[]={"\n\rData transfer successfully!"};

volatile unsigned int  page_adr;	// flashpage-adresse
volatile unsigned char check_sum;	// chechsum für den record

volatile unsigned char rec_count;	// anzahl der byte im record
volatile unsigned char ist_count;	// anzahl der aktuell eingelesenen byte

volatile unsigned char flash_count;	// anzahl der eingelesenen byte im flash-puffer
volatile unsigned int  puffer_adr;	// aktulle adresse vom flash-puffer

