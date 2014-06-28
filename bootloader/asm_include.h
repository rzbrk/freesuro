
#define BIT(n) (1<<(n))
#define IO_REG(n) _SFR_IO_ADDR(n)

#define sbi(p,b) p|=(1<<(b))
#define cbi(p,b) p&=(~(1<<(b)))

/*************************
	registerdefinitionen
**************************/
#define CHAR_GET_REG r24	// register f�r char-r�ckgabe 
#define CHAR_PUT_REG r25	// register f�r char-�bergabe
#define CHAR_RET_REG r24	// register f�r char-r�ckgabe 

#define INT_REG_H r25		// register f�r int high byte
#define INT_REG_L r24		// register f�r int low  byte

#define temp1 r16			// arbeitsregister
#define temp2 r17
#define temp3 r18
#define temp4 r19

#define STARTZEICHEN ':'	// startzeichen f�r einen record
#define SEKUNDE 2			// f�r zeitschleife

#define MAXRECORDS 17		// wert f�r maximale anzahl daten im record

#define BATT_MIN 770  		// minimalster batterie-wert ca. 4,2V
