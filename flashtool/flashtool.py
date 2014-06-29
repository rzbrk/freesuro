#!/usr/bin/python

import os, sys, serial, time
import serial.tools.list_ports

#-----------------------------------------------------------------------------

#####
#
# Define global constants
#
#####

# Maximum program size in flash (reduced by the size of the bootloader
# program).
MAX_PROG_SIZE = 7000

# Wait time for the bootloader (multiple of 0.1 seconds)
BOOTL_TIMEOUT = 50

# Serial port settings
BAUD = 2400
BYTESIZE = 8
PARITY = 'N'
STOPBITS = 1
TIMEOUT = 0
XONXOFF = 0
RTSCTS = 0

#-----------------------------------------------------------------------------

#####
#
# Prints help message and exits.
#
#####
def helpmsg():
    print "Usage: ./flashtool.py <SerialPort> <HexFile>"
    exit(1)

#####
#
# Search if the given port exists. If not, exits.
#
#####
def searchport(port_regexp):
    for port, desc, hwid in serial.tools.list_ports.grep(port_regexp):
        return port
    else:
        print "Cannot find serial port", port_regexp
        exit(1)

#####
#
# Checks, if file exists and is readable. If not, exits.
#
#####
def fileexist(file):
    import os, os.path
    if not os.path.isfile(file) or not os.access(file, os.R_OK):
        print "Cannot find file or file is not readable", file
        exit(1)

#####
#
# For a given string of hex values with the last value beeing the checksum
# verify the checksum. If checksum is verified, return True, else False
#
#####
def checksum(hexstr):
    crc = int(hexstr[len(hexstr)-2:len(hexstr)], 16)

    # Compute the sum for all hex values except the checksum
    sum = 0 # Initialize sum
    for i in range(0, len(hexstr)/2-1):
        number = hexstr[2*i:2*i+2]
        sum = sum + int(number, 16)

    # Compute sum modulo 256
    sum = sum % 256
    
    # Compute not(sum) + 1
    sum = 256 - sum
    
    return sum == crc
        
#####
#
# Read in the hex file and check for validity. Returns an array with the
# individual lines of the hex file.
#
#####
def readhexfile(hexfile):
    # The intel hex file is an ordinary ascii file. Open it and read in
    # the lines
    fh = open(hexfile, 'r')
    lines = fh.readlines()
    fh.close()    

    # A format description of the intel hex file can be found here:
    # https://en.wikipedia.org/wiki/Intel_HEX
    # Usually the last line is ':00000001FF'
    if len(lines) < 2:
        print "Hex file empty or invalid"
        exit(1)
    
    # Check if the file is valid intel hex. If not, exit with error
    # message.
    for l in lines:
        # Trim whitespace
        l = l.strip(' \t\n\r')

        # Line must start with ':'
        if l[0:1] != ':':
            print "File is not a valid intel hex file"
            exit(1)

        # If it's not the last line, compute the check sum
        if l != ':00000001FF' and l != '':
            ll = l.lstrip(':')
            
            # There must be an even number of characters without ':'
            if (len(ll) % 2) != 0:
                print "File is not a valid intel hex file"
                exit(1)
            
            # Compute the checksum.
            if not checksum(ll):
                print "Checksum error in intel hex file"
                exit(1)

    # Finally, return the content (lines) of the hex file.
    return lines    

#####
#
# Returns the size of a hex file.
#
#####
def hexsize(codelines):

    # From the second to last line the file size can be calculated
    byte_count=int(codelines[-2][1:3], 16)
    address=int(codelines[-2][3:7], 16)
    
    # The size of the hex file is the sum of the address and the byte_count
    # of the second to last line
    return address + byte_count

#####
#
# The main program.
#
#####
def main(argv=sys.argv):
    # Get serial port parameter
    try:
        argv[1]
    except IndexError:
        helpmsg()
    port_regexp = argv[1]

    # Get hex file parameter
    try:
        argv[2]
    except IndexError:
        helpmsg()
    hexfile = argv[2]

    # See if serial port exists
    port = searchport(port_regexp)

    # See if file exist
    fileexist(hexfile)

    # Read in hex file
    code = readhexfile(hexfile)

    # Size of hex file
    size = hexsize(code)

    # Check if hex file is too large. If so, exit with error message.
    if size > MAX_PROG_SIZE:
        print "Program file size >", MAX_PROG_SIZE, "Bytes. Too large for Atmega8"
        exit(1)

    print
    print "((( Freesuro Flash Tool )))"
    print
    print "Port:        ", port
    print "Hex file:    ", hexfile
    print "Hex size:    ", size, "Bytes"
    print
    print
    
    # Read in the hex file
    fh = open(hexfile, 'r')
    code = fh.readlines()
    fh.close()
    
    # Open serial port
    ser = serial.Serial()
    ser.port = port
    ser.baudrate = BAUD
    ser.bytesize = BYTESIZE
    ser.parity = PARITY
    ser.stopbits = STOPBITS
    ser.timeout = TIMEOUT
    ser.xonxoff = XONXOFF
    ser.rtscts = RTSCTS
    try:
        ser.open()
    except:
        print "Cannot open serial port", port
        exit(1)

    # Wait for the bootloader to show up on the serial connection. Therefore,
    # wait for any character received over the serial port.
    sys.stdout.write("Wait for the bootloader ")
    timeout = BOOTL_TIMEOUT
    found_bootl = False
    while timeout > 0 and not found_bootl:
        sys.stdout.write(".")
        sys.stdout.flush()
        timeout -= 1 # Decrement timeout variable

        if ser.inWaiting() > 0:
            found_bootl = True
        time.sleep (0.1)

    # If a bootloader was found, then send the content of the hex file over
    # the serial port
    if found_bootl:
        print " FOUND!"
        print
        print "Write hex to Asuro ..."
        for line in code:
            ser.write(line)
            sys.stdout.write("  ")
            sys.stdout.write(line)
            # Wait for the TX buffer to be written to the microcontroller.
            # The wait time is calculated from the line length, the baud
            # rate plus additional 5 percent.
            wait = 1.05 * 10 * len(line) / BAUD
            time.sleep (wait)
        print
        print "Done!"
        print
    else:
        print " :("
        print
        print "No bootloader found!"
    
    # Close serial port
    ser.close
    exit(0)

#-----------------------------------------------------------------------------

if __name__ == "__main__":
    sys.exit(main())
