###############################################################################
# Makefile for the project BootLoaderSerial
###############################################################################

## General Flags
PROJECT = BootLoaderSerial
MCU = atmega8
TARGET = BootLoaderSerial.elf
CC = avr-gcc

## Options common to compile, link and assembly rules
COMMON = -mmcu=$(MCU)

## Compile options common for all C compilation units.
CFLAGS = $(COMMON)
CFLAGS += -Wall -g3 -gdwarf-2 -DF_CPU=8000000UL  -Os -fsigned-char
CFLAGS += -Wp,-M,-MP,-MT,$(*F).o,-MF,dep/$(@F).d 

## Assembly specific flags
ASMFLAGS = $(COMMON)
ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2

## Linker flags
LDFLAGS = $(COMMON)
# Boot loader section 512 words/1024 bytes
#LDFLAGS += -Wl,--section-start=.text=0x1c00 -Wl,-Map=BootLoaderSerial.map
# Boot loader section 1024 words/2048 bytes
LDFLAGS += -Wl,--section-start=.text=0x1800 -Wl,-Map=BootLoaderSerial.map


## Intel Hex file production flags
HEX_FLASH_FLAGS = -R .eeprom

HEX_EEPROM_FLAGS = -j .eeprom
HEX_EEPROM_FLAGS += --set-section-flags=.eeprom="alloc,load"
HEX_EEPROM_FLAGS += --change-section-lma .eeprom=0


## Objects that must be built in order to link
OBJECTS = BootLoaderSerial.o asm_main.o com.o com_init.o flash_write.o global_var.o flash_get.o write_buffer.o wait_serial.o ascii_hex.o init_asuro_com.o 

## Build
all: $(TARGET) BootLoaderSerial.hex BootLoaderSerial.eep BootLoaderSerial.lss

## Compile
asm_main.o: asm_main.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

com.o: com.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

com_init.o: com_init.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

flash_write.o: flash_write.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

flash_get.o: flash_get.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

write_buffer.o: write_buffer.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

wait_serial.o: wait_serial.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

ascii_hex.o: ascii_hex.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

init_asuro_com.o: init_asuro_com.s
	$(CC) $(INCLUDES) $(ASMFLAGS) -c  $<

BootLoaderSerial.o: BootLoaderSerial.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

global_var.o: global_var.c
	$(CC) $(INCLUDES) $(CFLAGS) -c  $<

##Link
$(TARGET): $(OBJECTS)
	 $(CC) $(LDFLAGS) $(OBJECTS) $(LIBDIRS) $(LIBS) -o $(TARGET)

%.hex: $(TARGET)
	avr-objcopy -O ihex $(HEX_FLASH_FLAGS)  $< $@

%.eep: $(TARGET)
	avr-objcopy $(HEX_EEPROM_FLAGS) -O ihex $< $@

%.lss: $(TARGET)
	avr-objdump -h -S $< > $@

## Clean target
.PHONY: clean
clean:
	-rm -rf $(OBJECTS) BootLoaderSerial.elf dep/ BootLoaderSerial.hex BootLoaderSerial.eep BootLoaderSerial.lss BootLoaderSerial.map


## Other dependencies
-include $(shell mkdir dep 2>/dev/null) $(wildcard dep/*)

