

#include <avr/io.h>
#include "asm_include.h"

			.section .text
			.global wait_serial

/*******************************************
	warte auf ein zeichen vom com-port
********************************************/
wait_serial:
			clr		temp1
			clr		temp2
			ldi		temp3, SEKUNDE				// eine sekunde maximal warten

loop:		rcall	com_rdy						// ein zeichen empfangen?
			tst		CHAR_GET_REG				// teste register
			brne	loop_ende				    // ja, zeichen empfangen

			inc		temp1						// verschachtelte zeitschleife
			brne	loop
			inc		temp2
			brne	loop
			dec		temp3
			brne	loop
			
loop_ende:
			ret
