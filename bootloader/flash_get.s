
#include <avr/io.h>
#include "asm_include.h"

	.section .text
	.global flash_get

/*************************************************************
	der erste doppelpunkt aus der hex-datei wurde empfangen
	jetzt den rest der daten einlesen und ins flash schreiben
	das empfangene programm wird immer ab flash-adresse 0 
	abgespeichert!
**************************************************************/
flash_get:
	rcall	puffer_init					// init flash-puffer-pointer und counter

starte_neu:
	rcall	get_rec_val					// anzahl der datenbyte im aktuellen record
	rcall	get_flash_adr				// flash-adresse einlesen
	rcall	get_byte					// die datenart im record
	tst		INT_REG_L					// <> 0 = datenende
	brne	daten_ende					// ende der daten�bertragung
	clr		temp1						// l�sche datencounter
	sts		ist_count, temp1			// noch keine record-daten eingelesen

next_wert:
	rcall	get_byte					// ein byte einlesen und kovertieren
	lds		temp1, check_sum			// checksum laden
	add		temp1, INT_REG_L			// aktuellen wert zur checksum addieren
	sts		check_sum, temp1			// checksum wieder abspeichern
	
	lds		XL, puffer_adr				// aktuelle flash-pufferadresse laden
	lds		XH, puffer_adr+1			// x-reg als pointer
	st		X+, INT_REG_L				// wert im flash-puffer abspeichen
	sts		puffer_adr, XL				// puffer-adresse wieder sichern
	sts		puffer_adr+1, XH

	lds		XH, flash_count				// anzahl der werte im flash-puffer
	inc		XH							// plus einem neuen wert
	sts		flash_count, XH				// anzahl wieder abspeichern
	cpi		XH, SPM_PAGESIZE			// eine seite im flash-puffer voll?
	brne	dont_save					// nein, dann noch nicht speichern
	rcall	save_buffer					// ja, seite im flash abspeichern

dont_save:
	lds		XH,ist_count				// anzahl der gespeicherten record-werte
	inc		XH							// plus ein wert
	sts		ist_count, XH				// und wieder abspeichern
	lds		XL, rec_count				// sollanzahl der werte im aktuellen record
	cp		XL, XH						// alle datenbytes des records eingelesen?
	brne	next_wert					// nein, es sind noch daten im record, weitermachen

	rcall	get_byte					// der letzte record-wert ist die checksum
	lds		INT_REG_H, check_sum		// lade die aktuelle checksum
	neg		INT_REG_H					// bilde das zweierkomplement
	cp		INT_REG_L, INT_REG_H		// vergleiche die checksum
	brne	error_trx					// fehler die werte sind nicht gleich!

warte_start:							// warte auf startzeichen f�r neuen record
	rcall	wait_serial					// hole zeichen vom com-port	
	tst		CHAR_GET_REG				// teste zeichen
	breq	error_trx					// kein zeichen = fehler bei der daten�bertragung
	cpi		CHAR_GET_REG, STARTZEICHEN	// ist es das startzeichen?
	brne	warte_start					// nein, dann warte
	rjmp	starte_neu					// neuen record einlesen
	
daten_ende:
	lds		XH, flash_count				// anzahl der werte im flash-puffer laden
	tst		XH							// noch werte im puffer?
	breq	keine_daten					// nein
	rcall	write_buffer				// ja, die restlichen byte im puffer schreiben

keine_daten:
	rcall	wait_serial					
	tst		CHAR_GET_REG				
	brne	keine_daten					
	ret

/*****************************************
	lese zwei byte ascii-hex vom com-port
	und wandel sie in eine zahl (1 byte)
******************************************/
get_byte:
	ldi		ZL, lo8(int_buffer)				
	ldi		ZH, hi8(int_buffer)
	rcall	wait_serial
	tst		CHAR_GET_REG
	breq	error_trx
	st		Z+, CHAR_GET_REG	
	rcall	wait_serial
	tst		CHAR_GET_REG
	breq	error_trx
	st		Z+, CHAR_GET_REG	
	rcall	ascii_hex
	ret

/*****************************************
	lese anzahl der datenbytes im record
	und initialisiere die record-checksum
******************************************/
get_rec_val:
	rcall	get_byte
	cpi		INT_REG_L, MAXRECORDS	// maximal 16 datenbyte in einem record
	brge	error_trx				// fehler anzahl > 16!
	sts		rec_count, INT_REG_L	// anzahl abspeichern
	sts		check_sum, INT_REG_L	// checksum init		
	ret

/********************************
	lese die flash-adresse
	und addiere sie zur checksum
*********************************/
get_flash_adr:
	rcall	get_byte
	lds		XL, check_sum
	add		XL, INT_REG_L
	sts		check_sum, XL
	rcall	get_byte
	lds		XL, check_sum
	add		XL, INT_REG_L
	sts		check_sum, XL
	ret

/**********************************
	initialisiere den flash-puffer
***********************************/
puffer_init:
	clr		temp1
	sts		flash_count, temp1
	ldi		temp1, lo8(flash_buffer)
	sts		puffer_adr, temp1
	ldi		temp1, hi8(flash_buffer)
	sts		puffer_adr+1, temp1
	ret
	
/***********************************
	flash-puffer im flash speichern
************************************/
save_buffer:
	rcall	write_buffer
	rcall	puffer_init
	ret

/**************************
 	error daten�bertragung
***************************/
error_trx:
	sbi		IO_REG(PORTD), PD2			// led on

error_out:
	brts	loop_err					// tflag im statusregister gesetzt?
	sbi		IO_REG(PORTB), PB0			// led on
	set									// setze tflag im sr
	rjmp	loop_err2	

loop_err:
	cbi		IO_REG(PORTB), PB0			// led off
	clt									// l�sche tflag im sr

loop_err2:								// warteschleife
	clr		temp1
	clr		temp2
	ldi		temp3, 3

loop_err3:
	inc		temp1
	brne	loop_err3
	inc		temp2
	brne	loop_err3
	dec		temp3
	brne	loop_err3

	rjmp	error_out


