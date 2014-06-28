
#include <avr/io.h>
#include "asm_include.h"

            .section .text

			.global flash_write_puffer

/************************************************

	flash-seite schreiben: 
	
	flash-adresse im x-reg
	ram-adresse von datenpuffer im y-reg

*************************************************/
flash_write_puffer:
			in 		temp1, IO_REG(SREG)		// statusregister retten
			push	temp1					// auf dem stack sichern
			cli								// interrupts sperren
/*
	flash-adresse sichern
*/
			push	ZH
			push	ZL
/*
	eeprom zugriffe?
*/
floop1:
			sbic	IO_REG(EECR), EEWE		// eeprom zugriffe?
			rjmp	floop1
/*
	flash page immer erst löschen flash-adresse im x-register
*/
			ldi		temp1, (BIT(SPMEN) + BIT(PGERS))
			rcall	flash_wait				// warte bis fertig
/*
	counter init
*/
			ldi		temp2, (SPM_PAGESIZE/2)	// wir schreiben immer 2byte = 1word
/*
	inhalt vom ram ins flash kopieren
*/
flash_fill:
			ld		r0, Y+					// zwei byte aus dem ram holen
			ld		r1, Y+
			ldi		temp1, BIT(SPMEN)		// steuerbit
			rcall	flash_wait				// warte
			dec		temp2					// zähler dekrementieren
			breq	floop2					// 0=fertig kopiert
			adiw	ZL, 2					// auf nächste adresse zeigen
			rjmp	flash_fill				// und weiter
/*
	flash-adresse zurückholen
*/
floop2:
			pop		ZL
			pop		ZH
/*
	aus dem ram kopierte daten ins flash schreiben
*/
			ldi		temp1, (BIT(SPMEN) + BIT(PGWRT))
			rcall	flash_wait
/*
	re-enable rww section
*/
			ldi		temp1, (BIT(SPMEN) + BIT(RWWSRE))
			rcall	flash_wait
/*
	register zurückholen
*/
			pop		temp1					// statusregister vom stack laden
			out		IO_REG(SREG), temp1		// startusregister zurück
			ret

/****************************
	warte bis spm ausgeführt
*****************************/
flash_wait:
			out		IO_REG(SPMCR), temp1	// ins steuerregister schreiben
			spm
flash_wait2:
			in		temp1, IO_REG(SPMCR)	// lese steuerregister
			sbrc	temp1, SPMEN			// fertig?
			rjmp	flash_wait2				// nein
			ret								// ja






