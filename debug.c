/*  primitive 8080 debugger for ISIS-II programs */

#include <unistd.h>
#include <stdio.h>

#include "isis.h"

// externals from isis.c

extern char * mem8080;

// local variables

static char cmdline[81];	/* command line */
static char *cptr;		/* pointer to command line */
static WORD listptr;		/* next location to list (disassemble) */
static WORD dispptr;		/* next location to display in hex */
static WORD breakpt1 = 0;	// address of breakpoint #1 (0 if no breakpt)
static char brkdata1;		// original contents of breakpoint location #1
static WORD breakpt2 = 0;	// address of breakpoint #2 (0 if no breakpt)
static char brkdata2;		// original contents of breakpoint location #2


/*  GETHEX - get a 16-bit hex number */

static int gethex (WORD *valptr)
{
    WORD count,c;

    *valptr = 0;
    for (count = 0; ; count++,cptr++)
    {
	c = *cptr;
	if (c >= '0' && c <= '9') c -= '0';
	else if (c >= 'A' && c <= 'F') c -= 'A' - 10;
	else return (count);
	*valptr = (*valptr << 4) + c;
    }
}

/* GO command */

static int gcmd (void)
{
    WORD newpc, newbrk;
    WORD gotpc;

    gotpc = gethex((WORD *)&newpc);

    // Handle breakpoint 1

    if (*cptr++ == ',')
    {
	if (!gethex((WORD *)&newbrk))
	{
	    print("Illegal breakpoint\n");
	    return (FALSE);
	}
	breakpt1 = newbrk;
	brkdata1 = mem8080[breakpt1];
	mem8080[breakpt1] = 8;
    }

    // Handle breakpoint 2

    if (*cptr++ == ',')
    {
	if (!gethex((WORD *)&newbrk))
	{
	    print("Illegal breakpoint\n");
	    mem8080[breakpt1] = brkdata1;
	    breakpt1 = 0;
	    return (FALSE);
	}
	breakpt2 = newbrk;
	brkdata2 = mem8080[breakpt2];
	mem8080[breakpt2] = 8;
    }

    if (gotpc) savepc = newpc;
    return (TRUE);
}

/*  DISPLAY command */

static void dcmd (void)
{
    WORD newptr;
    WORD count;
    BYTE c;

    if (gethex((WORD *)&newptr))
	dispptr = newptr;
    else newptr = dispptr;
    for (count = 0; count < 64; count++)
    {
	if ((count & 0xf) == 0)
	{
	    phexw((WORD)dispptr);
	    print(" ");
	}
	print(" ");
	phexb(mem8080[dispptr++]);
	if ((count & 0xf) == 0xf)
	{
	    print("   ");
	    while (newptr < dispptr)
	    {
		c = mem8080[newptr++] & 0x7f;
		if (c < ' ') c = '.';
		write(1,&c,1);
	    }
	    print("\r\n");
	}
    }
}

/* XCMD - print register values */

BYTE *flagchar = "SZ-A-P-C";

static void xcmd (void)
{
    WORD flags, count;

    print("A=");
    phexb(savepsw);
    print(" BC=");
    phexw(savebc);
    print(" DE=");
    phexw(savede);
    print(" HL=");
    phexw(savehl);
    print(" M=");
    phexb(mem8080[savehl]);
    print(" SP=");
    phexw((WORD)savesp);
    print(" FLAGS=");
    flags = savepsw;
    for (count = 0; count < 8; count++)
    {
	if (flags & 0x8000)
	    write(1,flagchar+count,1);
	else
	    print("-");
	flags <<= 1;
    }
    print("\n");
    print("PC=");
    phexw((WORD)savepc);
    print("  ");
    disassemble (savepc);
}


/* LCMD - disassemble stuff */

static void lcmd (void)
{
    WORD newptr;
    WORD count;

    if (gethex((WORD *)&newptr))
	listptr = newptr;
    for (count = 0; count < 12; count++)
    {
	printf ("%X: ", listptr);
	listptr += disassemble (listptr);
    }
}

void debug (void)
{
    if (savepc - 1 == breakpt1 || savepc - 1 == breakpt2)
    {
	print("Breakpoint\n");
	savepc--;

	// Restore contents of breakpoint 1
	if (breakpt1)
	    mem8080[breakpt1] = brkdata1;
	breakpt1 = 0;

	// Restore contents of breakpoint 2
	if (breakpt2)
	    mem8080[breakpt2] = brkdata2;
	breakpt2 = 0;
    }

    xcmd();
    listptr = savepc;
    for (;;)
    {
	int nchars;

	print("-");
	nchars = read(0,cmdline,sizeof(cmdline)-1);
	if (nchars < 0)
	    return;
	cmdline[nchars] = 0;
	for (cptr = cmdline; *cptr != '\0'; cptr++)
	    if (*cptr >= 'a') *cptr -= 'a' - 'A';
	cptr = cmdline;
	switch(*cptr++)
	{
	case 'G':
	    if (gcmd()) return;
	    return;		// resume execution of 8080 program
	case 'D':
	    dcmd();
	    break;
	case 'X':
	    xcmd();
	    break;
	case 'L':
	    lcmd();
	    break;
	case 'S':
	    single_step ();	// force single stepping
	    return;		// resume execution of 8080 program
	default:
	    printf ("valid commands:\n");
	    printf (" g        go\n");
	    printf (" d[NNNN]  display memory [at address]\n");
	    printf (" x        examine registers registers\n");
	    printf (" l[NNNN]  disassemble instructions [at address]\n");
	    printf (" s        single step\n");
	}
    }
}

// phexw - print hex word

void phexw (WORD w)
{
    phexb(w >> 8);
    phexb(w);
}

// phexb - print hex byte

void phexb (BYTE b)
{
    phexn(b >> 4);
    phexn(b);
}

// phexn - print hex nibble

void phexn (BYTE n)
{
    write(1,"0123456789ABCDEF"+(n & 15),1);
}

// print - print a null terminated string on the console

void print (const char *s)
{
  write(1, s, strlen(s));
}
