/*
    trace.c - instruction trace for ISIS-II simulator

    Copyright (C) 2019 Mark Alexander

    This file is part of Isis, an ISIS-II simulator

    Isis is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#include <stdio.h>

#include "isis.h"

// Pointer to base of 8080 memory.  The low 16 bits of this pointer
// are guaranteed to be zero, so that the similator only has to worry
// about manipulation the low 16 bits of registers.

extern BYTE *mem8080;

// Flag in instruction simulator to force call to trace8080 ()
// before each instruction is executed.

extern int trace;

// Public variables

static int dotrace;		// true if we are tracing instructions
static int step;		// true if we are single stepping

// Instruction table.

struct instr
{
  char * name;
  int size;
};

struct instr instab[256] =
{
  { "nop", 1 },
  { "lxi b,", 3 },
  { "stax b", 1 },
  { "inx b", 1 },
  { "inr b", 1 },
  { "dcr b", 1 },
  { "mvi b,", 2 },
  { "rlc", 1 },
  { "halt", 1 },
  { "dad b", 1 },
  { "ldax b", 1 },
  { "dcx b", 1 },
  { "inr c", 1 },
  { "dcr c", 1 },
  { "mvi c,", 2 },
  { "rrc", 1 },
  { "halt", 1 },
  { "lxi d,", 3 },
  { "stax d", 1 },
  { "inx d", 1 },
  { "inr d", 1 },
  { "dcr d", 1 },
  { "mvi d,", 2 },
  { "ral", 1 },
  { "halt", 1 },
  { "dad d", 1 },
  { "ldax d", 1 },
  { "dcx d", 1 },
  { "inr e", 1 },
  { "dcr e", 1 },
  { "mvi e,", 2 },
  { "rar", 1 },
  { "halt", 1 },
  { "lxi h,", 3 },
  { "shld", 3 },	/* 0x22 */
  { "inx h", 1 },
  { "inr h", 1 },
  { "dcr h", 1 },
  { "mvi h,", 2 },
  { "daa1", 1 },
  { "halt", 1 },
  { "dad h", 1 },
  { "lhld", 3 },
  { "dcx h", 1 },
  { "inrl", 1 },
  { "dcrl", 1 },
  { "mvi l,", 2 },
  { "cma", 1 },
  { "halt", 1 },
  { "lxi sp,", 3 },
  { "sta", 3 },
  { "inx sp", 1 },
  { "inr m", 1 },
  { "dcr m", 1 },
  { "mvi m,", 2 },
  { "stc", 1 },
  { "halt", 1 },
  { "dad sp", 1 },
  { "lda", 3 },
  { "dcx sp", 1 },
  { "inr a", 1 },
  { "dcr a", 1 },
  { "mvi a,", 2 },
  { "cmc", 1 },
  { "mov b,b", 1 },
  { "mov b,c", 1 },
  { "mov b,d", 1 },
  { "mov b,e", 1 },
  { "mov b,h", 1 },
  { "mov b,l", 1 },
  { "mov b,m", 1 },
  { "mov b,a", 1 },
  { "mov c,b", 1 },
  { "mov c,c", 1 },
  { "mov c,d", 1 },
  { "mov c,e", 1 },
  { "mov c,h", 1 },
  { "mov c,l", 1 },
  { "mov c,m", 1 },
  { "mov c,a", 1 },
  { "mov d,b", 1 },
  { "mov d,c", 1 },
  { "mov d,d", 1 },
  { "mov d,e", 1 },
  { "mov d,h", 1 },
  { "mov d,l", 1 },
  { "mov d,m", 1 },
  { "mov d,a", 1 },
  { "mov e,b", 1 },
  { "mov e,c", 1 },
  { "mov e,d", 1 },
  { "mov e,e", 1 },
  { "mov e,h", 1 },
  { "mov e,l", 1 },
  { "mov e,m", 1 },
  { "mov e,a", 1 },
  { "mov h,b", 1 },
  { "mov h,c", 1 },
  { "mov h,d", 1 },
  { "mov h,e", 1 },
  { "mov h,h", 1 },
  { "mov h,l", 1 },
  { "mov h,m", 1 },
  { "mov h,a", 1 },
  { "mov l,b", 1 },
  { "mov l,c", 1 },
  { "mov l,d", 1 },
  { "mov l,e", 1 },
  { "mov l,h", 1 },
  { "mov l,l", 1 },
  { "mov l,m", 1 },
  { "mov l,a", 1 },
  { "mov m,b", 1 },
  { "mov m,c", 1 },
  { "mov m,d", 1 },
  { "mov m,e", 1 },
  { "mov m,h", 1 },
  { "mov m,l", 1 },
  { "halt", 1 },
  { "mov m,a", 1 },
  { "mov a,b", 1 },
  { "mov a,c", 1 },
  { "mov a,d", 1 },
  { "mov a,e", 1 },
  { "mov a,h", 1 },
  { "mov a,l", 1 },
  { "mov a,m", 1 },
  { "mov a,a", 1 },
  { "add b", 1 },
  { "add c", 1 },
  { "add d", 1 },
  { "add e", 1 },
  { "add h", 1 },
  { "add l", 1 },
  { "add m", 1 },
  { "add a", 1 },
  { "adc b", 1 },
  { "adc c", 1 },
  { "adc d", 1 },
  { "adc e", 1 },
  { "adc h", 1 },
  { "adc l", 1 },
  { "adc m", 1 },
  { "adc a", 1 },
  { "sub b", 1 },
  { "sub c", 1 },
  { "sub d", 1 },
  { "sub e", 1 },
  { "sub h", 1 },
  { "sub l", 1 },
  { "sub m", 1 },
  { "sub a", 1 },
  { "sbb b", 1 },
  { "sbb c", 1 },
  { "sbb d", 1 },
  { "sbb e", 1 },
  { "sbb h", 1 },
  { "sbb l", 1 },
  { "sbb m", 1 },
  { "sbb a", 1 },
  { "ana b", 1 },
  { "ana c", 1 },
  { "ana d", 1 },
  { "ana e", 1 },
  { "ana h", 1 },
  { "ana l", 1 },
  { "ana m", 1 },
  { "ana a", 1 },
  { "xra b", 1 },
  { "xra c", 1 },
  { "xra d", 1 },
  { "xra e", 1 },
  { "xra h", 1 },
  { "xra l", 1 },
  { "xra m", 1 },
  { "xra a", 1 },
  { "ora b", 1 },
  { "ora c", 1 },
  { "ora d", 1 },
  { "ora e", 1 },
  { "ora h", 1 },
  { "ora l", 1 },
  { "ora m", 1 },
  { "ora a", 1 },
  { "cmp b", 1 },
  { "cmp c", 1 },
  { "cmp d", 1 },
  { "cmp e", 1 },
  { "cmp h", 1 },
  { "cmp l", 1 },
  { "cmp m", 1 },
  { "cmp a", 1 },
  { "rnz ", 1 },
  { "pop b", 1 },
  { "jnz", 3 },
  { "jmp", 3 },
  { "cnz", 3 },
  { "push b", 1 },
  { "adi", 2 },
  { "rst 0", 1 },
  { "rz", 1 },
  { "ret", 1 },
  { "jz", 3 },
  { "halt", 1 },
  { "cz", 3 },
  { "call", 3 },
  { "aci", 2 },
  { "rst 1", 1 },
  { "rnc", 1 },
  { "pop d", 1 },
  { "jnc", 3 },
  { "halt", 1 },
  { "cnc", 3 },
  { "push d", 1 },
  { "sui", 2 },
  { "rst 2", 1 },
  { "rc", 1 },
  { "halt", 1 },
  { "jc", 3 },
  { "halt", 1 },
  { "cc", 3 },
  { "halt", 1 },
  { "sbi", 2 },
  { "rst 3", 1 },
  { "rpo", 1 },
  { "pop h", 1 },
  { "jpo", 3 },
  { "xthl", 1 },
  { "cpo", 3 },
  { "push h", 1 },
  { "ani", 2 },
  { "rst 4", 1 },
  { "rpe", 1 },
  { "pchl", 1 },
  { "jpe", 3 },
  { "xchg", 1 },
  { "cpe", 3 },
  { "halt", 1 },
  { "xri", 2 },
  { "rst 5", 1 },
  { "rp", 1 },
  { "pop psw", 1 },
  { "jp", 3 },
  { "fetch", 1 },
  { "cp", 3 },
  { "push psw", 1 },
  { "ori", 2 },
  { "rst 6", 1 },
  { "rm", 1 },
  { "sphl", 1 },
  { "jm", 3 },
  { "fetch", 1 },
  { "cm", 3 },
  { "halt", 1 },
  { "cpi", 2 },
  { "rst 7", 1 }
};

void trace8080 ()
{
    static int first = 1;

    printf ("PC = %04X, step = %d, dotrace = %d\n", savepc, step, dotrace);

    if (step)
    {
	step = 0;
	trace = dotrace;
	debug ();
    }

    if (!dotrace)
	return;

    if (first)
    {
	printf("PSW  BC   DE   HL   SP   PC\n");
	first = 0;
    }

    // Print registers.

    printf ("%04x %04x %04x %04x %04x %04x: ",
	    savepsw, savebc, savede, savehl, savesp, savepc);

    // Print the current instruction

    disassemble (savepc);
}

// disassemble - print the instruction at the specified location,
// return the number of bytes in the instruction

int disassemble (WORD pc)
{
    BYTE * inst = &mem8080[pc];
    struct instr *itab;

    itab = &instab[inst[0] & 0xff];
    switch (itab->size)
    {
    case 3:
	printf ("%s %02x%02x\n", itab->name, inst[2] & 0xff, inst[1] & 0xff);
	break;
    case 2:
	printf ("%s %02x\n", itab->name, inst[1] & 0xff);
	break;
    case 1:
	printf ("%s\n", itab->name);
	break;
    }
    return (itab->size);
}

void single_step ()
{
    step = 1;		// force single stepping
    trace = 1;
}

void set_trace (int flag)
{
    dotrace = flag;	
    trace = 1;
}
