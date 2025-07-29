# ISIS-II Simulator for Linux, Win32, and MS-DOS

(*Note*: If you are reading this on Github, you can find the
original Fossil repository [here](https://www.bloovis.com/fossil/home/marka/fossils/isis/home)).

ISIS-II was an operating system developed by Intel in the mid-70s for
their MDS (Microprocessor Development System).  The MDS was an 8080-based
system that ran on 8-inch floppies.  It included an assembler, a compiler
for PL/M (a high-level programming language streamlined for microprocessors),
a linker, and associated tools.  (Read a history of the ISIS-II
project by its designer, Ken Burgett, [here](https://rogerarrick.com/kenburgett/)).

To make it possible to run ISIS-based tools (mainly compilers and related
tools), I've written this simulator for ISIS-II, which includes an 8080
simulator written in assembly language for speed.  It currently builds
and runs on:

* 32-bit or 64-bit Linux
* Windows, using MinGW
* MS-DOS, using Borland Turbo C

I originally wrote the simulator in the early 80s for MS-DOS.  See the
`dos` subdirectory for that older version of the simulator, including a
makefile that builds the simulator using Turbo C.

To clone this repository:

```
fossil clone https://www.bloovis.com/fossil/home/marka/fossils/isis
```

To build on Linux, or on Windows using MinGW, simply move to the `gnu` directory
and run `make`.  The resulting executable is called isis (isis.exe on Windows).
Then run `make test` to make sure that everything is
working; this will compile a simple PL/M program and run it on the
simulator.

This repository also includes free copies of Intel's linker, assembler, and PL/M
compiler that I obtained from Intel's web site.

In order to use the ISIS-II simulator on Linux, or on Windows under
MinGW, you must set environment variables that map directories to ISIS
drive names.  Take a look at `test/setup.sh` and `test/Makefile` for
examples.

As an example: On Linux, if you want to run the PL/M-80 compiler, which
is located in the `intel/plm80` directory, you would use this
command at the shell prompt to tell the simulator that ISIS-II
drive `:F1:` points to that directory:

    export ISIS_F1=intel/plm80

(Note that the environment variable uses upper-case letters.)

Then to run the PL/M-80 compiler, you could use this command:

    gnu/isis :f1:plm80 <arguments>

(Note that the drive letter and other arguments use lower-case letters.)

## OMF dumper

This repository also includes a simple program, `omfdump`, that dumps OMF files
(.obj) and libraries (.lib).  It will be built along with `isis` when
you run `make` in the `gnu` directory.
