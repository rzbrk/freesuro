
#define BIT(n) (1<<(n))
#define IO_REG(n) _SFR_IO_ADDR(n)

#define sbi(p,b) p|=(1<<(b))
#define cbi(p,b) p&=(~(1<<(b)))

/******************************************************************************
    register definitions
******************************************************************************/
#define CHAR_GET_REG r24                // register for returning a char 
#define CHAR_PUT_REG r25                // register for returning a char
#define CHAR_RET_REG r24                // register for returning a char

#define INT_REG_H r25                   // register for int high byte
#define INT_REG_L r24                   // register for int low  byte

#define temp1 r16                       // working register
#define temp2 r17                       // working register
#define temp3 r18                       // working register
#define temp4 r19                       // working register

#define STARTCHAR ':'                   // start char for a record within a
                                        // *.hex file
#define SECONDS 2                       // for loop

#define MAXRECLEN 17                    // maximum number of data in record
                                        // (= 16) plus 1. This is necessary,
                                        // because there is no brgt, only a
                                        // brge (break-if-greater-or-equal)
                                        // command in AVR assembler.

#define BATT_MIN 770                    // lower battery treshold,
                                        // approx. 4,2V
