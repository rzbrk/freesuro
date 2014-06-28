
#include <avr/io.h>
#include "asm_include.h"

	.section .text
	.global ascii_hex

/*********************************************
	wandelt eine ascii-hex-zahl
	aus zwei byte in einen hex-char-wert
	rückgabe in INT_REG_L
	in der hex-datei sind nur grossbuchstaben
**********************************************/
ascii_hex:

	ldi		ZL, lo8(int_buffer)			// zeiger auf zeichenkette			
	ldi		ZH, hi8(int_buffer)

	ld		temp1, Z+					// erstes zeichen
	rcall	hex_value					// umwandeln

	ldi		temp2, 16					// mit 16
	mul		temp1, temp2				// multiplizieren ergebnis in r0:r1

	ld		temp1, Z+					// zweites zeichen
	rcall	hex_value					// umwandeln
	mov		INT_REG_L, r0				// ergebnis bilden aus byte1 *16
	add		INT_REG_L, temp1			// plus rest aus byte2

	ret

/**************************
	ascii-hex-byte in zahl
***************************/
hex_value:
	cpi		temp1, 'A'					// ascii '0'-'9'?
	brlo	next_hex					// ja
	subi	temp1, 'A'					// nein
	subi	temp1, -10
	rjmp	hex_end

next_hex:
	subi	temp1, '0'

hex_end:
	ret


