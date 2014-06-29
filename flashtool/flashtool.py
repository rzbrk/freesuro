#!/usr/bin/python

import os, sys, serial, time
import serial.tools.list_ports
import constants as const

#-----------------------------------------------------------------------------

#
# Prints help message and exits.
#
def helpmsg():
    print "Usage: ./flashtool.py <SerialPort> <HexFile>"
    exit(1)

#
# Search if the given port exists. If not, exits.
#
def searchport(port_regexp):
    for port, desc, hwid in serial.tools.list_ports.grep(port_regexp):
        return port
    else:
        print "Cannot find serial port", port_regexp
        exit(1)

#
# Checks, if file exists and is readable. If not, exits.
#
def fileexist(file):
    import os, os.path
    if not os.path.isfile(file) or not os.access(file, os.R_OK):
        print "Cannot find file or file is not readable", file
        exit(1)
        
#
# Returns the size of a hex file.
#
def hexsize(hexfile):
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

    # From the second to last line the file size can be calculated
    byte_count=int(lines[-2][1:3], 16)
    address=int(lines[-2][3:7], 16)
    
    # The size of the hex file is the sum of the address and the byte_count
    # of the second to last line
    return address + byte_count

#
# The main program.
#
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

    # Size of hex file
    size = hexsize(hexfile)

    # Check if hex file is too large. If so, exit with error message.
    if size > const.MAX_PROG_SIZE:
        print "Program file size >", const.MAX_PROG_SIZE, "Bytes. Too large for Atmega8"
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
    file_cont = fh.readlines()
    fh.close()
    
    # Open serial port
    ser = serial.Serial()
    ser.port = port
    ser.baudrate = const.BAUD
    ser.bytesize = const.BYTESIZE
    ser.parity = const.PARITY
    ser.stopbits = const.STOPBITS
    ser.timeout = const.TIMEOUT
    ser.xonxoff = const.XONXOFF
    ser.rtscts = const.RTSCTS
    try:
        ser.open()
    except:
        print "Cannot open serial port", port
        exit(1)

    # Wait for the bootloader to show up on the serial connection. Therefore,
    # wait for any character received over the serial port.
    sys.stdout.write("Wait for the bootloader ")
    timeout = const.BOOTL_TIMEOUT
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
        for l in file_cont:
            ser.write(l)
            sys.stdout.write("  ")
            sys.stdout.write(l)
            # Wait for the TX buffer to be written to the microcontroller.
            # The wait time is calculated from the line length, the baud
            # rate plus additional 5 percent.
            wait = 1.05 * 10 * len(l) / const.BAUD
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
