
/***************************************************
	include-datei für i2c-funktionen im boot loader 

	auszug aus BootLoaderSerial.map

               	0x00001f0e                i2c_write
                0x00001f46                i2c_readNak
                0x00001f4a                i2c_readAck
                0x00001ed6                i2c_rep_start
                0x00001ece                i2c_start
                0x00001efe                i2c_stop
                0x00001f4c                i2c_read
                0x00001eea                i2c_start_wait
                0x00001ec4                i2c_init

****************************************************/

#define I2C_READ    1
#define I2C_WRITE   0

/* funktionsprototypen (pointer auf funktionen im boot loader */

unsigned char (*i2c_write)(unsigned char)      = 0x00001f0e;
unsigned char (*i2c_readNak)(void)             = 0x00001f46;
unsigned char (*i2c_readAck)(void)             = 0x00001f4a;
unsigned char (*i2c_rep_start)(unsigned char)  = 0x00001ed6;
unsigned char (*i2c_start)(unsigned char)      = 0x00001ece;
void          (*i2c_stop)(void)                = 0x00001efe;
unsigned char (*i2c_read)(unsigned char ack)   = 0x00001f4c;
void 		  (*i2c_start_wait)(unsigned char) = 0x00001eea;
void          (*i2c_init)(void)                = 0x00001ec4;

