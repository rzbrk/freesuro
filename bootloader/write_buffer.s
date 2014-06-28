
#include <avr/io.h>
#include "asm_include.h"

	.section .text
	.global write_buffer

/********************************
	speichert den empfangspuffer
	in der aktuellen flash-seite
*********************************/
write_buffer:
		lds		ZL, page_adr					// flash address
		lds		ZH, page_adr+1					// gültige page
		ldi		YH, hi8(flash_buffer)			// ram-pointer
		ldi		YL, lo8(flash_buffer)			// address
		rcall	flash_write_puffer				// ram-parameter ins flash schreiben
		ldi		temp1, -1						// für übertrag
		subi	ZL, -SPM_PAGESIZE				// nächste seite im flash berechnen
		sbc		ZH, temp1						// -borrow
		sts		page_adr, ZL					// aktuelle flash-adresse 
		sts		page_adr+1, ZH					// wieder abspeichern
		ret										// zurück
