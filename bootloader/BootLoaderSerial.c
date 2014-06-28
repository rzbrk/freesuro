
/**************************************************
	-------->>>>> programm-doku siehe asm_main.s
***************************************************/

#include <avr/io.h>


int main(void)
{
	asm("rjmp asm_main");
	return(0);
}
