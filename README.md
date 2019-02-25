# ISIS-II Simulator for Linux

ISIS-II was an operating system developed by Intel in the mid-70s for
their MDS (Microprocessor Development System).  The MDS was an 8080-based
system that ran on 8-inch floppies.  It included an assembler, a compiler
for PL/M (a high-level programming language streamlined for microprocessors),
a linker, and associated tools.

To make it possible to run ISIS-based tools (mainly compilers and related
tools), I've written this simulator for ISIS-II, which includes an 8080
simulator written in assembly language for speed.  It currently builds
and runs on either 32-bit or 64-bit Linux.

I originally wrote the simulator in the early 80s for MS-DOS.  See the
`dos` subdirectory for that older version of the simulator, including a
makefile that builds the simulator using Turbo C.

This repository also includes free copies of Intel's linker, assembler, and PL/M
compiler that I obtained from Intel's web site.

On Linux, run `make` to build the simulator.  The resulting executable
is in `linux/isis`.  Then run `make test` to make sure that everything is
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
