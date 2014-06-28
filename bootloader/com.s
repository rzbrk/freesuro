
#include <avr/io.h>
#include <compat/twi.h>
#include "asm_include.h"

            .section .text

			.global	com_get
			.global com_rdy
			.global com_put
			.global com_put_string

/************************************
	hole daten vom seriellen port
*************************************/
com_get:
		sbis	IO_REG(UCSRA), RXC
		rjmp	com_get
		in		CHAR_GET_REG, IO_REG(UDR)
		ret

/***********************************
	teste ob daten im datenregister
************************************/
com_rdy:
		sbis	IO_REG(UCSRA), RXC
		rjmp	no_data
		in		CHAR_GET_REG, IO_REG(UDR)		// daten im datenregister
com_rdy_ret:
		ret	
no_data:
		eor		CHAR_GET_REG, CHAR_GET_REG		// keine daten im datenregister
		rjmp 	com_rdy_ret

/*******************************************
	sende datenbyte über den seriellen port
********************************************/
com_put:
		sbis	IO_REG(UCSRA), UDRE
		rjmp	com_put							// noch daten im sendepuffer
		out		IO_REG(UDR), CHAR_PUT_REG		// sende daten
		ret

/******************************************
	sende daten-string aus dem datenpuffer
*******************************************/
com_put_string:
		ld		CHAR_PUT_REG, Z+
		tst		CHAR_PUT_REG
		breq	com_send_end
		rcall	com_put
		rjmp	com_put_string
com_send_end:
		ret








