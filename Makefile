# Top-level Makefile for isis.  So far, building is only supported on Linux.

.PHONY: build
build:
	(cd linux && make)

.PHONY: test
test:
	(cd test && . setup.sh && make)

.PHONY: archive
archive:
	tar --exclude=CVS -cvz -f isis.tgz Makefile *.c *.asm *.h \
	  linux/Makefile intel test/Makefile test/*.plm test/*.asm test/setup.*
