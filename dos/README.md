# MS-DOS version of the ISIS-II simulator

This directory contains the source for the MS-DOS-hosted version
of the ISIS-II simulator.  This source code is much older than
the Linux version found in the `gnu` directory.

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

In order to use the ISIS-II simulator on MS-DOS,
you must set environment variables that map directories to ISIS
drive names.  Take a look at `test/setup.bat` for an
example.

if you want to run the PL/M-80 compiler, which
is located in the `intel/plm80` directory, you would use this
command at the shell prompt to tell the simulator that ISIS-II
drive `:F1:` points to that directory:

    set :f1:=intel/plm80

(Note that the environment variable uses upper-case letters.  Note also
that forward slashes are used.  It is a little known fact that the DOS
file system APIs accept forward slashes as well as backslashes as
directory separators.  However, the command shell, cmd.exe, doesn't like
forward slashes; it interprets them as option characters.)

Then to run the PL/M-80 compiler, you could use this command:

    dos\isis :f1:plm80 <arguments>

(Note that the drive letter and other arguments use lower-case letters.)
