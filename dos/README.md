# MS-DOS version of the ISIS-II simulator

This directory contains the source for the MS-DOS-hosted version
of the ISIS-II simulator.  This source code is much older than
the Linux version found in the parent directory.

The simulator is compiled with Borland Turbo C version 2 and Turbo
Assembler version 2, but it does not use any Borland startup code or
library code (except for two shift functions).  Instead, it uses its
own startup code and DOS interface library.  This ensures that the
combined code and data of executable does not exceed 0x3000 bytes in
length.  That restriction is necessary because 8080 code is loaded
into memory above that address.

To build the simulator, ensure that Turbo C (tcc) and Turbo Assembler (tasm)
are installed and located in the PATH environment variable.  Then build
using Turbo C's `make`:

    make

To test the simulator, move to the `..\test` directory, and run
these commands:

    setup
    make -fmakefile.dos

This will build and run a small PL/M-80 program, and assemble and output in hex
a small 8080 assembly language file.
