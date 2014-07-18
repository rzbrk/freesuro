freesuro
========

Free and open source Asuro Bootloader and flashing tool

Important Notice!!
------------------

This software is currently completly untested and may not work
at all! It is not recommended to use it!

Setting of Fuse Bits
--------------------

Important notice: "0" means programmed, "1" means unprogrammed!

When using the external ceramic resonator with 8 MHz on the Asuro board,
set the fuse bits as following:

  CKOPT     = 0     Oscillator option
  SUT0      = 0     Select start-up time
  SUT1      = 0     Select start-up time
  CKSEL3    = 1     Select clock source
  CKSEL2    = 1     Select clock source
  CKSEL1    = 1     Select clock source
  CKSEL0    = 1     Select clock source

The size of the boot loader section in the flash memory of the microcontroller
shall be configured to be 2048 bytes or 1024 words.

  BOOTSZ0   = 0     Boot loader section size
  BOOTSZ1   = 0     Boot loader section size
  BOOTRST   = 0     Boot reset address (jump to boot loader section)
  
Please note, that when you change the size of the boot loader section you also
have to change the linker option in the make file:

  LDFLAGS += -Wl,--section-start=.text=0xHHHH -Wl,-Map=BootLoaderSerial.map
  
Replace 0xHHHH with the address of the beginning of the boot loader section in
bytes (_not_ words!). Refer to the following table:


   Boot loader  | Boot reset
   size (words) | (bytes)
  -------------------------------
            128 | 7936 or 0x1F00
            256 | 7680 or 0x1E00
            512 | 7168 or 0x1C00
           1024 | 6144 or 0x1800  <--- Default
           

