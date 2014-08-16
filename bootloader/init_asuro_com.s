
#include <avr/io.h>
#include "asm_include.h"

    .section .text
    .global init_asuro_com

/*
    Initialize the modules needed by the Asuro robot.
*/
init_asuro_com:
/*
    36khz ir-clk with timer2
*/
    ldi     temp1, BIT(WGM21) + BIT(COM20) + BIT(CS20)
    out     IO_REG(TCCR2), temp1
    ldi     temp1, 0x6E
    out     IO_REG(OCR2), temp1

/*
    Initialize ADC. ADC clock = system clock / 64
*/
    ldi     temp1, BIT(ADEN) + BIT(ADPS2) + BIT(ADPS1)
    out     IO_REG(ADCSRA), temp1           // adc init

    ldi     temp1, BIT(PB3) + BIT(PB0)
    out     IO_REG(DDRB), temp1             // ir-led-driver and status led1
    ldi     temp1, BIT(PD2)                 // status led2							
    out     IO_REG(DDRD), temp1

    sbi     IO_REG(DDRD), PD6               // red front led for battery
    ret

