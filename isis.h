/*
    isis.h - definitions and declarations for ISIS-II emulator

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

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long LONG;
#define MLOCAL static
#define EXTERN extern
#define TRUE 1
#define FALSE 0

// BSD-like versions of memory region operations

#define movb(s,d,c) memcpy((d),(s),(c))
#define setb(v,b,c) memset((b),(v),(c))

// Functions from debug.c

void debug (void);
void print (const char *s);
void phexw (WORD w);
void phexb (BYTE b);
void phexn (BYTE n);

// External variables and functions in sim80.asm

extern WORD savepsw;	// 8080 psw
extern WORD savebc;	// 8080 bc registers
extern WORD savede;	// 8080 de registers
extern WORD savehl;	// 8080 hl registers
extern WORD savesp;	// 8080 stack register
extern WORD savepc;	// 8080 program counter */

void go8080 ();		// main instruction simulator entry point

// Functions and variables in trace.c.

void trace8080 ();
int disassemble (WORD pc);
void single_step ();
void set_trace (int flag);
