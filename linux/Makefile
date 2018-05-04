# Makefile for building isis on Linux using gcc and nasm

DEBUG = -g

%.o : ../%.c
	gcc -c -Wall $(DEBUG) $<

#%.o : ../%.asm
#	nasm -f elf -o $@ $<

%.o : ../%.S
	gcc -c $<

OBJ = isis.o sim80.o trace.o debug.o 

# FIXME: replace sioutil.omovb.o sio.o ctrlc.o

all : isis

# The normal, slow version of ISIS.  It's the same as visis,
# except that it uses sim80 instead of run80.

# FIXME: replace istart.o

isis : sim80.o $(OBJ) Makefile
	gcc -o isis $(DEBUG) $(OBJ)

clean :
	rm -f $(OBJ) isis
