
/******************************************************************************

    Author:     Peter Wilbert
    (c):        Arexx / Netherlands
    Version:    1.03 

    Date:       20.05.06    Initial version (Peter Wilbert)
                16.08.14    Minor code refactoring.

    This bootloader only processes *.hex files.
    Please ensure proper setting of the fuse bits.
	
******************************************************************************/ 

#include <avr/io.h>
#include "asm_include.h"

////////////////////////////////////////////////////////////////////////
//#define BOOTLOADER_INTERRUPT	// bootloader interrupt vectors enable//
////////////////////////////////////////////////////////////////////////

    .section .text
    .global asm_main

asm_main:

/*
    IMPORTANT NOTE REGARDING INTERRUPTS
    ===================================
	
	If you want to enable interrupts within the bootloader, remove the "//"
	characters in front of the the line above containing
	#define BOOT_INTERRUPT.
	
	Please note, when you jump to the main program via ijmp, you have to
	redirect the interrupts to $0000. Otherwise, the interrupts of the
	bootloader will be used instead of those from the main program.
*/

#ifdef BOOTLOADER_INTERRUPT

    ldi     temp1, 0x01                     // table with interrupt vectors
    out     IO_REG(GICR), temp1             // move to bootloader flash
    ldi     temp1, 0x02
    out     IO_REG(GICR), temp1

#endif

    rcall   com_init                        // init serial port with 2400 baud
    rcall   init_asuro_com                  // init IR communication and status
                                            // led
    ldi     ZL, lo8(wait_send);             // start string
	ldi		ZH, hi8(wait_send);			
	rcall	com_put_string                  // send start string

main_loop:
/*
    Initialize adc channel 5 for battery undervoltage check (2.56V).
*/
    ldi     temp1, BIT(REFS0) + BIT(REFS1) + 0x05;
    out     IO_REG(ADMUX), temp1

/*
    let the status led flash
*/
    brts    loop2                           // if t-flag is set
    sbi     IO_REG(PORTB), PB0              // led on
    cbi     IO_REG(PORTD), PD2              // led off
    set                                     // set t-flag
    rjmp    loop3

loop2:
    cbi     IO_REG(PORTB), PB0              // led off
    sbi	    IO_REG(PORTD), PD2              // led on
    cbi	    IO_REG(PORTD), PD6              // led off
    clt                                     // clear t-flag

/*
    Any data at serial port?
*/
loop3:
    rcall   wait_serial                     // wait for char on serial port
    cpi     CHAR_GET_REG, STARTCHAR         // equal start char?
    breq    start_rec                       // yes: start data transmission

/*
    Measure battery voltage and compare with threshold BATT_MIN.
*/
    sbi	    IO_REG(ADCSRA), ADSC

batt_loop:
	sbic    IO_REG(ADCSRA), ADSC
	rjmp    batt_loop
	in      temp1, IO_REG(ADCL)
	in      INT_REG_H, IO_REG(ADCH)
	clr	    INT_REG_L
	add	    INT_REG_L, temp1
	adc	    INT_REG_H, r1
	subi    INT_REG_L, lo8(BATT_MIN)
	sbci    INT_REG_H, hi8(BATT_MIN) 
	brcc    batt_ok                         // battery voltage ok!

/*
    Battery voltage below threshold BATT_MIN.
*/
    sbi     IO_REG(PORTD), PD6

batt_ok:
/*
	Initialize adc channel 4 for button
*/
    ldi	    temp1, BIT(REFS0) + 0x04
    out	    IO_REG(ADMUX), temp1

/*
	Check if button is pressed.
*/
    sbi	    IO_REG(ADCSRA), ADSC            // start adc conversion

adc_loop:
    sbic    IO_REG(ADCSRA), ADSC            // wait until conversion comleted
    rjmp    adc_loop
    in      temp1, IO_REG(ADCH)             // read bit10 and Bit9 of adc
    tst     temp1
    breq    adc_loop1                       // 0 => button pressed
    rjmp    main_loop                       // wait

/*
    Wait until the button is released.
*/
adc_loop1:
    cbi     IO_REG(PORTB), PB0              // led off
    cbi     IO_REG(PORTD), PD2              // led off
    cbi     IO_REG(PORTD), PD6              // led off

adc_loop2:
    sbi     IO_REG(ADCSRA), ADSC            // start adc conversion

adc_loop3:
    sbic    IO_REG(ADCSRA), ADSC            // wait until conversion completed
    rjmp    adc_loop3
    in      temp1, IO_REG(ADCH)             // read bit10 and Bit9 of adc
    tst     temp1
    breq    adc_loop2                       // warte until button is high
    sbi     IO_REG(PORTB), PB0              // led on
    clr     ZL                              // set reset vector = 0
    clr     ZH
    ijmp                                    // indirect jump to reset vector

/*
    Receive start character ":"
*/
start_rec:
    sbi     IO_REG(PORTB), PB0              // led on
    sbi     IO_REG(PORTD), PD2              // led on
    cbi     IO_REG(PORTD), PD6              // led off
    clr     temp1
    sts     page_adr, temp1                 // init address of flash page with 0
    sts     page_adr+1, temp1               // program will be stored after
                                            // address 0
    rcall   flash_get                       // read in flash data
    cbi     IO_REG(PORTB), PB0              // led off
    cbi     IO_REG(PORTD), PD2              // led off
    sbi     IO_REG(PORTD), PD6              // led on
    rcall   wait_serial                     // wait for 1 second
    cbi     IO_REG(PORTD), PD6              // led off
    ldi     ZL, lo8(flash_ok);              // send start string
    ldi     ZH, hi8(flash_ok);
    rcall   com_put_string                  // send start string

	ldi		ZL, lo8(__vectors)              // address bootloader start
	ldi		ZH, hi8(__vectors)
	ijmp                                    // indirect jump to main program

/* *** END *** */

