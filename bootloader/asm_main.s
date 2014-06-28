
/*****************************************************************************************

	autor: 		peter wilbert
	(c):		Arexx / Netherlands
	version: 	1.03 

	datum: 		20.05.06	projektstart

	das bootloader-programm verarbeitet nur *.hex-dateien!
	damit der bootloader funktioniert, müssen die configurations bits richtig eingestellt 
	werden! die linkadresse ist 0x1c00 = 1kb beim atmega8
	( siehe [projekt][configuration options][custom options][linker options] )
	
******************************************************************************************/ 

#include <avr/io.h>
#include "asm_include.h"

////////////////////////////////////////////////////////////////////////
//#define BOOTLOADER_INTERRUPT	// bootloader interrupt vectors enable//
////////////////////////////////////////////////////////////////////////

	.section .text
	.global asm_main

asm_main:

/*
								ACHTUNG!!!
								===============
	wenn du mit interrupts im bootloader arbeiten möchtest, muss du den kommentar
	bei #define BOOT_INTERRUPT entfernen. wenn du aber zum anwenderprogramm mit
	ijmp springst, muss du vorher die interrupts wieder nach $0000 umleiten, sonst
	werden immer die vectoren im bootloader angesprungen und nicht die im anwender-
	programm!!!

	wichtig: die interruptvektoren in den boot-loader-flash-rom-bereich umleiten
			 wenn erforderlich!
*/
#ifdef BOOTLOADER_INTERRUPT

	ldi		temp1, 0x01						// interruptvektoren-tabelle
	out		IO_REG(GICR), temp1				// ins boot loader flash verschieben
	ldi		temp1, 0x02
	out		IO_REG(GICR), temp1

#endif

	rcall	com_init					// init com-port-verbindung mit 2400 baud
	rcall	init_asuro_com				// ir-com und status-led initialisieren
	ldi		ZL, lo8(wait_send);			// startstring senden
	ldi		ZH, hi8(wait_send);			
	rcall	com_put_string				// startstring senden


main_loop:
/*
	vref 2,56v für batterie-spannungs-überprüfung
	an adc-kanal 5 vorbereiten!
*/
	ldi 	temp1, BIT(REFS0) + BIT(REFS1) + 0x05;
	out		IO_REG(ADMUX), temp1
/*
	blinklicht erzeugen
*/
	brts	loop2						// wenn t-flag gesetzt ist
	sbi		IO_REG(PORTB), PB0			// led on
	cbi		IO_REG(PORTD), PD2			// led off
	set									// set t-flag
	rjmp	loop3	

loop2:
	cbi		IO_REG(PORTB), PB0			// led off
	sbi		IO_REG(PORTD), PD2			// led on
	cbi		IO_REG(PORTD), PD6			// led off
	clt									// clear t-flag
/*
	daten am com-port?
*/
loop3:
	rcall	wait_serial					// warte auf ein zeichen vom com-port
	cpi		CHAR_GET_REG, STARTZEICHEN	// war es das startzeichen?
	breq	start_rec					// ja, dann startet die datenübertragung
/*
	versorgungs-spannung messen
	und mit min-wert vergleichen
*/
	sbi		IO_REG(ADCSRA), ADSC

batt_loop:
	sbic	IO_REG(ADCSRA), ADSC
	rjmp	batt_loop
	in		temp1, IO_REG(ADCL)
	in		INT_REG_H, IO_REG(ADCH)
	clr		INT_REG_L
	add		INT_REG_L, temp1
	adc		INT_REG_H, r1
	subi	INT_REG_L, lo8(BATT_MIN)
	sbci	INT_REG_H, hi8(BATT_MIN) 
	brcc	batt_ok						// spannung ok!
/*
	versorgungs-spannung zu gering
*/
	sbi		IO_REG(PORTD), PD6

batt_ok:
/*
	adc für taster initialisieren
*/
	ldi		temp1, BIT(REFS0) + 0x04	// adc-kanal 4 für tasterabfrage
	out		IO_REG(ADMUX), temp1
/*
	taster gedrückt?
*/
	sbi		IO_REG(ADCSRA), ADSC		// starte adc conversion

adc_loop:
	sbic	IO_REG(ADCSRA), ADSC		// warte bis conversion ok
	rjmp	adc_loop
	in		temp1, IO_REG(ADCH)			// lese bit10 und Bit9 des adc
	tst		temp1
	breq	adc_loop1					// 0 = taster betätigt
	rjmp	main_loop					// warte
/*
	warte bis taster wieder losgelassen wird
*/
adc_loop1:
	cbi		IO_REG(PORTB), PB0			// led off
	cbi		IO_REG(PORTD), PD2			// led off
	cbi		IO_REG(PORTD), PD6			// led off

adc_loop2:
	sbi		IO_REG(ADCSRA), ADSC		// starte adc conversion

adc_loop3:
	sbic	IO_REG(ADCSRA), ADSC		// warte bis conversion ok
	rjmp	adc_loop3
	in		temp1, IO_REG(ADCH)			// lese bit10 und Bit9 des adc
	tst		temp1
	breq	adc_loop2					// warte bis taster wieder h ist
	sbi		IO_REG(PORTB), PB0			// led on
	clr		ZL							// adresse 0 = reset vector
	clr		ZH
	ijmp 								// indirect jump zum reset vector
/*
	start-zeichen ':' empfangen
*/
start_rec:
	sbi		IO_REG(PORTB), PB0			// led on
	sbi		IO_REG(PORTD), PD2			// led on
	cbi		IO_REG(PORTD), PD6			// led off
	clr		temp1						
	sts		page_adr, temp1				// flash-page-adress mit 0 initialisieren
	sts		page_adr+1, temp1			// programm wird immer ab adresse 0 gespeichert
	rcall	flash_get					// flashdaten einlesen
	cbi		IO_REG(PORTB), PB0			// led off
	cbi		IO_REG(PORTD), PD2			// led off
	sbi		IO_REG(PORTD), PD6			// led on
	rcall	wait_serial					// wartezeit eine sekunde
	cbi		IO_REG(PORTD), PD6			// led off
	ldi		ZL, lo8(flash_ok);			// startstring senden
	ldi		ZH, hi8(flash_ok);			
	rcall	com_put_string				// startstring senden

	ldi		ZL, lo8(__vectors)			// adresse bootloader-start
	ldi		ZH, hi8(__vectors)
	ijmp 								// indirect jump zum programmstart

/* *** END *** */

