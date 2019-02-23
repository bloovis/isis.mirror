# ISIS-II Simulator for Linux

ISIS-II was an operating system developed by Intel in the mid-70s for
their MDS (Microprocessor Development System).  The MDS was an 8080-based
system that ran on 8-inch floppies.  It included an assembler, a compiler
for PL/M (a high-level programming language streamlined for microprocessors),
a linker, and associated tools.

It's unlikely this ancient software would be useful now.
The 8080 processor, though very popular in the 70s, quickly gave
way to the 16-bit 8086, which evolved into the CPUs that power most PCs
nowadays.  It's likely that very few embedded systems in the world
today use the 8080, or its very similar competitor, the Zilog Z80.

But we can still see the 8080 influence even in these modern
processors, for good or ill.  And I like the idea of keeping around
old software just to remind myself of the good old days, when
chips and systems were so simple that one person could easily
comprehend them in their entirety.

So I've written this simulator for ISIS-II, which includes an 8080
simulator written in assembly language for speed.  It currently builds
and runs on either 32-bit or 64-bit Linux.  It was originally written
back in the 80s for DOS, but I haven't done the necessary work to
update it to work on Win32.

The package includes free copies of Intel's linker, assembler, and PL/M
compiler that I obtained from Intel's web site.  After you unpack
the tar file, run `make` to build the simulator.
The resulting executable is in `linux/isis`.

Then run `make test` to make sure that everything is
working; this will compile a simple PL/M program and run it on the
simulator.  You must be using bash as your shell for this to work.

In order to use the ISIS-II simulator, you must set environment
variables that map directories to ISIS drive names.
Take a look at `test/setup.sh` and `test/Makefile` for examples.

As an example, if you want to run the PL/M-80 compiler, which
is located in the `intel/plm80` directory, you would use this
command at the shell prompt to tell the simulator that ISIS-II
drive `:F1:` points to that directory:

    export ISIS_F1=intel/plm80

(Note that the environment variable uses upper-case letters.)

Then to run the PL/M-80 compiler, you could use this command:

    linux/isis :f1:plm80 <arguments>

(Note that the drive letter and other arguments use lower-case letters.)
