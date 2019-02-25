# Makefile for building visis.exe and isis.exe using BCC.

#DEBUG = -v
#LINKDEBUG = /v

TCDIR=c:\profiles\admini~1\tc\tc

.c.obj :
	tcc -c $(DEBUG) $*.c

.asm.obj :
	tasm -t -mx $*.asm

COMMONOBJ = isis.obj debug.obj movb.obj sio.obj sioutil.obj ctrlc.obj
COMMONLNK = isis debug movb sio sioutil ctrlc

all : isis.exe # visis.exe

# The V20 version of ISIS.

visis.exe : istart.obj run80.obj $(COMMONOBJ) makefile
	tlink istart run80 $(COMMONLNK),visis,visis,$(TCDIR)\lib\cs.lib $(LINKDEBUG)

# The normal, slow version of ISIS.  It's the same as visis,
# except that it uses sim80 instead of run80.

isis.exe : istart.obj sim80.obj $(COMMONOBJ) makefile
	tlink istart sim80 $(COMMONLNK),isis,isis,$(TCDIR)\lib\cs.lib $(LINKDEBUG)

blorch:
	tcc -L$(TCDIR)\lib -I$(TCDIR)\include isis.c debug.c sim80.asm

# Create a ZOO archive of the sources and executables for ISIS.

zoo :
	if exist $(TMP)\isis.zoo del $(TMP)\isis.zoo
	zoo a $(TMP)\isis read.me *.c *.h *.asm *.bat makefile *.exe
