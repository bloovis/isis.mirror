# Makefile for building isis on Linux or on Windows using MinGW.

DEBUG = -g

%.o : %.c
	gcc -c -Wall $(DEBUG) $<

# We used to build the 8080 similator with nasm.
# Now we build it with the GNU assembler.

#%.o : %.asm
#	nasm -f elf -o $@ $<

%.o : %.S
	gcc -c $<

OBJ = isis.o sim80.o trace.o debug.o 

.PHONY: all
all : isis omfdump

isis : $(OBJ) Makefile
	gcc -o isis $(DEBUG) $(OBJ)

omfdump : omfdump.o
	gcc -o omfdump omfdump.c

.PHONY: clean
clean :
	rm -f $(OBJ) isis omfdump.o omfdump

.PHONY: test
test:
	(cd ../test && . setup.sh && make)
