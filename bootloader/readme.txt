----------------------------------------------------------------------

  Freesuro bootloader and flash tool
  ==================================

 - Is free software (GNU GPL v2)

 - Is based on the Arexx Asuro Atmega8 bootloader V1.03 originally
   written by Peter Wilbert in 2006.

 - Can be used together with the OCConsole terminal program which is
   freeware and can be found at the Internet.

 - Can be compiled with avr-gcc (*nix) or WinAVR (Windows) which are
   also free software. avr-gcc is usually included in the standard
   repositories and WinAVR can be downloaded from the website
   http://winavr.sourceforge.net/.


  For beginners
  =============

 The bootloader is a small program that can be programmed into the
 Atmega8 by some specific Atmega programming tool. It only needs to
 be programmed once.
 
 This bootloader assumes that an infrared communication circuitry
 is available at the RX/TX pins as is used by the Asuro robot.
 
 After programming at startup of the Atmega8 the Atmega8 bootloader
 will wait a few seconds for receiving data on its serial input and
 stores received data as a user program into it's flash memory.
 Serial data (a .hex file) can be send by OCConsole to the Atmega8.


