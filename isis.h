// isis.h - definitions and declarations for ISIS-II emulator

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
