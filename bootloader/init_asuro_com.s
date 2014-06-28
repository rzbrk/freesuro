
#include <avr/io.h>
#include "asm_include.h"

	.section .text
	.global init_asuro_com

/*
	initialisiert die notwendigen module für den asuro
*/
init_asuro_com:

	ldi 	temp1, BIT(WGM21) + BIT(COM20) + BIT(CS20)	// 36khz ir-clk mit timer2
	out		IO_REG(TCCR2), temp1
	ldi		temp1, 0x6E
	out		IO_REG(OCR2), temp1

	ldi		temp1, BIT(ADEN) + BIT(ADPS2) + BIT(ADPS1)	// adc-clk = sys-clk/64 
	out		IO_REG(ADCSRA), temp1						// adc init

	ldi		temp1, BIT(PB3) + BIT(PB0)
	out		IO_REG(DDRB), temp1							// ir-led-driver und status-led1
	ldi		temp1, BIT(PD2)								// status-led2							
	out		IO_REG(DDRD), temp1

	sbi		IO_REG(DDRD), PD6							// rote front-led für batterie
	ret

