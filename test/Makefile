# Makefile to test ISIS-II simulator on Linux, or Windows using MinGW.
# This assumes that ISIS_F1, ISIS_F2, and ISIS_F3 environment variables
# have been previously set up by sourcing setup.csh or setup.sh in
# tcsh or bash, respectively.

ISIS=../gnu/isis

.PHONY: all
all : run testasm.hex

.PHONY: run
run : chug
	$(ISIS) chug

chug : chug.obj
	$(ISIS) :f2:link chug.obj,:f2:system.lib,:f2:plm80.lib to chug.lnk
	$(ISIS) :f2:locate chug.lnk to chug
	$(ISIS) chug

chug.obj : chug.plm
	$(ISIS) :f1:plm80 chug.plm

testasm.hex : testasm.obj
	$(ISIS) :f2:objhex testasm.obj to testasm.hex
	cat testasm.hex

testasm.obj : testasm.asm
	$(ISIS) :f3:asm80 testasm.asm

.PHONY: clean
clean :
	rm -f *.obj *.lnk *.hex *.lst chug
