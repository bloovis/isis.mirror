# Makefile for building isis on Linux using gcc and gas

DEBUG = -g

%.o : ../%.c
	gcc -c -Wall $(DEBUG) $<

# We used to build the 8080 similator with nasm.
# Now we build it with the GNU assembler.

#%.o : ../%.asm
#	nasm -f elf -o $@ $<

%.o : ../%.S
	gcc -c $<

OBJ = isis.o sim80.o trace.o debug.o 

all : isis

isis : $(OBJ) Makefile
	gcc -o isis $(DEBUG) $(OBJ)

clean :
	rm -f $(OBJ) isis
