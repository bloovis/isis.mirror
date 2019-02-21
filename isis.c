/*  isis.c - ISIS-II simulator for IBM PC */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/fcntl.h>
#include <sys/stat.h>

#include "isis.h"

// Single step flag

extern int step;

// Pointer to base of 8080 memory.  The low 16 bits of this pointer
// are guaranteed to be zero, so that the simulator only has to worry
// about manipulation the low 16 bits of registers.

BYTE *mem8080;

// True if tracing system calls

int tracesys;

// True if we should run the debugger before starting the loaded program.

int debugger;

// ISIS, MDS Monitor entry points and special locations

#define ISIS	0x40		/* ISIS entry point */
#define FCBS	0x50		/* place to stash FCBS */
#define	CI	0xF803		/* console input */
#define	CO	0xF809		/* console output */
#define	CSTS	0xF812		/* console input status */
#define	MEMCK	0xF81B		/* compute size of memory */

// IOBYTE, and its bit definitions

#define IOBYTE	(BYTE *)3	/* address of IOBYTE */
#define	CONBIT	3		/* console bit mask */
#define	CRTCON	1		/* console = crt */
#define	USRCON	3		/* console = user defined */

// instruction sequence to break emulation

BYTE brk_8088[] =
{
	0xfd,		/* illegal instruction */
	0xc9		/* RET */
};

// ISIS file control block structure

typedef struct fcb
{
    WORD    f_fd;	    /* host file descriptor, or -1 if FCB not used */
    WORD    f_access;	    /* ISIS access code */
    WORD    f_led;	    /* true if this is a line edited file */
    WORD    f_count;	    /* number of bytes in line edit buffer */
    WORD    f_index;	    /* index into line edit buffer */
    BYTE    f_lbuf[122];    /* line edit buffer */
} FCB;

#define NFCBS 10	    /* allow up to 10 open files */
#if 0
FCB fcbs[NFCBS];
#else
FCB *fcbs;
#endif
#define UNUSED_FD ((WORD)-1)

// ISIS-II system call parameter block formats

typedef struct oblk	/* OPEN call */
{
    WORD    o_aft;	/* pointer to AFTN */
    WORD    o_file;	/* pointer to filename (BYTE *) */
    WORD    o_access;	/* read = 1, write = 2, update = 3 */
    WORD    o_echo;	/* if nonzero, aftn of echo output file */
    WORD    o_stat;	/* pointer to status (WORD *) */
}  OBLK;

typedef struct rblk	/* READ call */
{
    WORD    r_aft;	/* file aftn */
    WORD    r_buf;	/* pointer to buffer (BYTE *) */
    WORD    r_cnt;	/* number of bytes to read */
    WORD    r_act;	/* pointer to actual no. of bytes read (WORD *) */
    WORD    r_stat;	/* pointer to status (WORD *) */
} RBLK;

typedef struct wblk	/* WRITE call */
{
    WORD    w_aft;	/* file aftn */
    WORD    w_buf;	/* pointer to buffer (BYTE *) */
    WORD    w_cnt;	/* number of bytes to write */
    WORD    w_stat;	/* pointer to status (WORD *) */
} WBLK;

typedef struct sblk	/* SEEK call */
{
    WORD    s_aft;	/* file aftn */
    WORD    s_mode;	/* type of seek */
    WORD    s_blks;	/* pointer to blks (WORD *) */
    WORD    s_nbyte;	/* pointer to nbyte (WORD *) */
    WORD    s_stat;	/* pointer to status (WORD *) */
} SBLK;

typedef struct rsblk	/* RESCAN call */
{
    WORD    rs_aft;	/* file aftn */
    WORD    rs_stat;	/* pointer to status (WORD *) */
} RSBLK;

typedef struct cblk	/* CLOSE call */
{
    WORD    c_aft;	/* file aftn */
    WORD    c_stat;	/* pointer to status (WORD *) */
} CBLK;

typedef struct dblk	/* DELETE call */
{
    WORD    d_file;	/* pointer to filename */
    WORD    d_stat;	/* pointer to status (WORD *) */
} DBLK;

typedef struct rnblk	/* RENAME call */
{
    WORD    rn_file1;	/* old filename */
    WORD    rn_file2;	/* pointer to new filename */
    WORD    rn_stat;	/* pointer to status (WORD *) */
} RNBLK;

typedef struct lblk	/* LOAD call */
{
    WORD    l_file;	/* pointer to filename */
    WORD    l_bias;	/* address bias */
    WORD    l_switch;	/* control switch */
    WORD    l_enad;	/* pointer to entry address (BYTE **) */
    WORD    l_stat;	/* pointer to status (WORD *) */
} LBLK;

typedef struct eblk	/* ERROR call */
{
    WORD    e_ernum;	/* error number */
    WORD    e_stat;	/* pointer to status (WORD *)*/
} EBLK;

typedef struct whblk	/* WHOCON call */
{
    WORD    wh_aft;	/* file aftn */
    WORD    wh_buf;	/* pointer to buffer (BYTE *) */
    WORD    wh_stat;	/* pointer to status (WORD *) */
} WHBLK;

typedef struct spblk	/* SPATH call */
{
    WORD    sp_file;	/* pointer to filename */
    WORD    sp_buf;	/* pointer to buffer (BYTE *) */
    WORD    sp_stat;	/* pointer to status (WORD *) */
} SPBLK;


// Miscellaneous global variables.

static char fname1[65];
static char fname2[65];


// MONITOR - handle MDS monitor calls

void monitor ()
{
    WORD c;

    switch ((WORD)(savepc - 1))
    {
    case CI:	/* console input */
	c = getchar ();
	savepsw = (savepsw & 0xff00) | c;	/* return char in A reg	*/
	break;
    case CO:	/* console output */
	c = savebc & 0xff;			/* character in C reg	*/
	putchar (c);
	break;
    case CSTS:		/* console status */
	savepsw = (savepsw & 0xff00);		/* return char in A reg	*/
#if 0
	if (c)
	    savepsw |= 0xff;
#endif
	break;
    case MEMCK:
	savebc = (savebc & 0xff) | 0xf500;	/* top of memory is F5FF */
	savepsw |= 0xff;			/* to keep MPPROM happy */
	break;
    }
}

// cvtfname - convert an ISIS-II filename to a zero-terminated host filename

void cvtfname(
  WORD nameadr,		// 8080 address of name
  char * dest,		// buffer to store converted name
  int cvtdevice)	// if true, convert device name prefix
{
    const char * name = (const char *)&mem8080[nameadr];
    int		 count;
    char	 c;
    char	 device[8];	// ISIS_XX, where XX is F0, F1, etc.
    const char * env;

    // Skip leading spaces

    while (*name == ' ')
	name++;
    count = 0;

    // Check for ISIS device name :XX:.  If present, look up the
    // the environment variable ISIS_XX, and if found, use the found value.
    // This allows the user to define ISIS drive names, for example:
    //		setenv ISIS_F0 ../plm80
    //		setenv ISIS_F1 ../plm80/includes

    if (name[0] == ':' && name[3] == ':' && cvtdevice)
    {
	// Copy the device name, converting to upper case.

	strcpy (device, "ISIS_XX");
	if (name[1] >= 'a' && name[1] <= 'z')
	    device[5] = name[1] - 'a' + 'A';
	else
	    device[5] = name[1];
	if (name[2] >= 'a' && name[2] <= 'z')
	    device[6] = name[2] - 'a' + 'A';
	else
	    device[6] = name[2];

	// Look up the definition of the device name.  If found,
	// copy its value.

	if ((env = getenv(device)) != 0)	/* is it defined?	*/
	{
	    strcpy(dest,env);		/* copy the definition		*/
	    dest += (count = strlen(dest)); /* look at the end		*/
	    if (*(dest-1) != '/')	/* is last character a slash ?	*/
	    {
		*dest++ = '/';		/* no - append one		*/
		count++;
	    }
	    name += 4;			/* skip over device name	*/
	}
    }

    /* copy the rest of the filename, up to the first non-filename
     * type character (e.g space).
     */
    while (count < sizeof(fname1))
    {
	c = *name++;
#if 0	// FIXME - should we convert to uppercase always?
	if (c >= 'a' && c <= 'z') c -= 'a' - 'A';
#else
	if (c >= 'A' && c <= 'Z') c -= 'A' - 'a';
#endif
	if (c == ':' || c == '.' || c == '/' || c == '\\'
	    || (c >= 'A' && c <= 'Z')
	    || (c >= 'a' && c <= 'z')
	    || (c >= '0' && c <= '9'))
	{
	    *dest++ = c;
	    count++;
	}
	else		/* must be end of filename */
	{
	    *dest = 0;	 /* terminate converted filename with null */
	    return;
	}
    }
}


// skipdrv - skip past the drive part of an ISIS filename

const char * skipdrv (const char * fname)
{
    if (*fname == ':')          /* skip past ISIS-II drive code :F0: etc. */
    {
	fname++;
	while (*fname)
	    if (*fname++ == ':') break;
    }
    return (fname);
}


//  SETSTAT - set ISIS-II function call return status, print a message
//   if tracing is enabled.

void setstat (WORD stat, WORD val)
{
    *(WORD *)&mem8080[stat] = val;
    if (tracesys)
	printf (" status=%x\n", val);
}


// setword - store a 16-bit word in ISIS-II memory

void setword (WORD addr, WORD val)
{
    *(WORD *)&mem8080[addr] = val;
}


// getword - fetch a 16-bit word from ISIS-II memory

WORD getword (WORD addr)
{
    return *(WORD *)&mem8080[addr];
}


// GETFCB - check for valid open file, return FCB indexed by AFTN

FCB *getfcb (WORD aftn, WORD stat)
{
    if (aftn >= NFCBS || fcbs[aftn].f_fd == UNUSED_FD)
    {
	setstat(stat, 2);	// AFTN does not specify an open file
	return (0);
    }
    return (&fcbs[aftn]);
}


//  IOPEN - ISIS-II OPEN call

void iopen (OBLK *pblk)
{
    WORD		aft;
    const char *	fname;
    FCB *		f;

    cvtfname (pblk->o_file, fname1, 1);  /* convert filename */

    if (tracesys)
	printf ("OPEN: name=%Xh (%s), aftnptr=%Xh, access=%Xh, echoaftn=%Xh\n",
	       pblk->o_file, fname1, pblk->o_aft, pblk->o_access, pblk->o_echo);

    if (strcmp(fname1,":co:") == 0)
    {
	setword (pblk->o_aft, 0);
	setword (pblk->o_stat, 0);
	return;
    }
    if (strcmp(fname1,":ci:") == 0)
    {
	setword (pblk->o_aft, 1);
	setword (pblk->o_stat, 0);
	return;
    }

    // search for a free FCB

    for (aft = 2; aft < NFCBS; aft++)
	if (fcbs[aft].f_fd == UNUSED_FD) break;
    if (aft == NFCBS)	    /* no more FCBs */
	return (setstat(pblk->o_stat, 3));
    f = &fcbs[aft];

    // call host operating system to open the file

    fname = skipdrv(fname1);
    switch (pblk->o_access)
    {
	case 1: 		    /* open for read */
	    f->f_fd = open(fname, O_RDONLY);
	    break;
	case 2: 		    /* open for write */
	    f->f_fd = creat(fname, S_IRUSR|S_IWUSR);
	    break;
	case 3: 		    /* open for update */
	    f->f_fd = open(fname, O_RDWR|O_CREAT, S_IRUSR|S_IWUSR);
	    break;
	default:
	    setstat(pblk->o_stat, 33);
	    return;
    }
    if (f->f_fd == UNUSED_FD)
    {
	if (pblk->o_access > 1)
	  {
	    setstat(pblk->o_stat, 14);	   /* unable to open for write */
	    return;
	  }
	else
	  {
	    setstat(pblk->o_stat, 13);    /* unable to open for read */
	    return;
	  }
    }

    // set up other fields in FCB

    f->f_access = pblk->o_access;	/* save access code */
    f->f_led = pblk->o_echo;		/* line-editing flag */
    f->f_count = f->f_index = 0;   	/* line-editing buffer indexes */
    setword (pblk->o_aft, aft); 	/* return AFTN to caller */
    setword (pblk->o_stat, 0);		/* status is OK */

    if (tracesys)
	printf (" aftn=%x\n", aft);
}


/***********************************************************************
* IREAD - ISIS-II READ call
***********************************************************************/

void iread(RBLK *pblk)
{
    FCB *f;
    int nchars;
    BYTE c;

    if (tracesys)
	printf ("READ: aft=%x, buf=%x, count=%x, actptr=%x, statptr=%x\n",
		pblk->r_aft, pblk->r_buf, pblk->r_cnt, pblk->r_act, pblk->r_stat);

    if ((f = getfcb (pblk->r_aft, pblk->r_stat)) == 0)
        return;
    if (f->f_access != 1 && f->f_access != 3)
      {
	setstat(pblk->r_stat, 8);    /* attempt to read file open for output */
	return;
      }
    if (f->f_led)		 /* line-edited file? */
    {
	if (f->f_index == f->f_count)	/* line buffer empty */
	{
	    if (pblk->r_aft == 1)   /* :CI: has to be handled specially */
	    {
		nchars = read (0, f->f_lbuf, sizeof(f->f_lbuf));
#ifdef __linux__
		/* Replace \n with \r\n */
		if (nchars != 0 && nchars < sizeof(f->f_lbuf) &&
		    f->f_lbuf[nchars-1] == '\n')
		{
		    f->f_lbuf[nchars-1] = '\r';
		    f->f_lbuf[nchars]   = '\n';
		    nchars++;
		}
#endif	/* __linux__ */
	    }
	    else		/* normal disk file - read up to CR/LF */
	    {
		nchars = 0;
		c = 0;
		while (c != '\n' && nchars < sizeof(f->f_lbuf))
		{
		    if (read (f->f_fd, &c, 1) != 1) break;
		    if (c == 0x1a) continue;	    /* ignore CTRL/Z */
		    f->f_lbuf[nchars++] = c;
		}
	    }
	    f->f_count = nchars;
	    f->f_index = 0;
	}
	if ((nchars = f->f_count - f->f_index) > pblk->r_cnt)
	    nchars = pblk->r_cnt;
	movb (&f->f_lbuf[f->f_index], &mem8080[pblk->r_buf], nchars);
	f->f_index += nchars;
	setword (pblk->r_stat, 0);
    }
    else		    /* not a line-edited file */
    {
	nchars = read (f->f_fd, &mem8080[pblk->r_buf], pblk->r_cnt);
	if (nchars == -1)   /* disk error */
	  {
	    setstat (pblk->r_stat, 24);	   /* ISIS disk error code */
	    return;
	  }
	else
	  setword (pblk->r_stat, 0);
    }

    if (tracesys)
	printf (" actual=%x\n", nchars);

    setword (pblk->r_act, nchars);	/* return actual no. of bytes read */
}


/***********************************************************************
* IWRITE - ISIS-II WRITE call
***********************************************************************/

void iwrite(WBLK *pblk)
{
    FCB *f;
    WORD nchars;

    if ((f = getfcb (pblk->w_aft, pblk->w_stat)) == 0) return;
    if (f->f_access != 2 && f->f_access != 3)
      {
	setstat (pblk->w_stat, 6);	/* attempt to write file open for input */
	return;
      }
    nchars = write (f->f_fd, &mem8080[pblk->w_buf], pblk->w_cnt);

    if (tracesys)
    {
	printf ("WRITE: aftn=%x, buf=%x, buf[0]=%x, count=%x, statptr=%x,",
		pblk->w_aft, pblk->w_buf, mem8080[pblk->w_buf], pblk->w_cnt, pblk->w_stat);
	printf (" actual=%x\n", nchars);
    }

#if 0
    if (nchars >= 500)
      {
	printf ("Setting trace flag because nchars is %d!\n", nchars);
	trace = 1;	// HACK!!!!
      }
#endif

    if (nchars != pblk->w_cnt)
	setstat (pblk->w_stat, 7);
    else
	setword (pblk->w_stat, 0);
}


/***********************************************************************
* ICLOSE - ISIS-II CLOSE call
***********************************************************************/

void iclose(CBLK *pblk)
{
    FCB *f;

    if (tracesys)
	printf ("CLOSE: aftn=%x, statptr=%x\n", pblk->c_aft, pblk->c_stat);

    if ((f = getfcb (pblk->c_aft, pblk->c_stat)) == 0) return;
    if (pblk->c_aft < 2)    /* ignore attempts to close console files */
    {
	setword (pblk->c_stat, 0);
	return;
    }
    if (close(f->f_fd) == -1)
    {
	setstat(pblk->c_stat, 24);
	return;
    }
    else
    {
	setword (pblk->c_stat, 0);
    }
    f->f_fd = UNUSED_FD;	    /* mark FCB as unused */
}


/***********************************************************************
* IDELETE - ISIS-II DELETE call
***********************************************************************/

void idelete(DBLK *pblk)
{
    cvtfname(pblk->d_file,fname1,1);

    if (tracesys)
	printf("DELETE: name=%s, statptr=%Xh\n", fname1, pblk->d_stat);

    if (unlink(skipdrv(fname1)) == -1)
	setstat (pblk->d_stat, 13);
    else
        setword (pblk->d_stat, 0);
}


/***********************************************************************
* IRENAME - ISIS-II RENAME call
***********************************************************************/

void irename (RNBLK *pblk)
{
    cvtfname(pblk->rn_file1,fname1,1);	/* convert old filename */
    cvtfname(pblk->rn_file2,fname2,1);	/* convert new filename */

    if (tracesys)
	printf ("RENAME: old=%s, new=%s, statptr=%Xh\n", fname1, fname2,
		pblk->rn_stat);

    if (rename(fname1,fname2) == -1)
      setstat(pblk->rn_stat, 13);
    else
      setword (pblk->rn_stat, 0);
}


/***********************************************************************
* ISEEK - ISIS-II SEEK call
***********************************************************************/

void iseek (SBLK *pblk)
{
    FCB *f;
    LONG offset;	    /* PC-DOS lseek offset */
    WORD mode;		    /* PC-DOS lseek mode */

    if ((f = getfcb (pblk->s_aft, pblk->s_stat)) == 0)
      return;
    if (pblk->s_aft < 2)    /* ignore attempts to close console files */
      return (setstat (pblk->s_stat, 19)); /* attempt to seek on non-disk file */

    // compute host file system offset from ISIS-II offset

    offset = getword (pblk->s_blks) & 0x7fff;
    offset = (offset << 7) + getword (pblk->s_nbyte);

    if (tracesys)
	printf ("SEEK: aftn=%Xh, mode=%Xh, blk=%Xh, byte=%Xh, statptr=%Xh\n",
		pblk->s_aft, pblk->s_mode, pblk->s_blks, pblk->s_nbyte, pblk->s_stat);

    // convert ISIS-II seek mode to host seek mode

    switch (pblk->s_mode)
    {
    case 0: 	/* return current position */
	offset = 0;
	mode = SEEK_CUR;
	break;
    case 1: 	/* move marker backwards */
	offset = -offset;
	mode = SEEK_CUR;
	break;
    case 2: 	/* move to specific position */
	mode = SEEK_SET;
	break;
    case 3: 	/* move forward */
	mode = SEEK_CUR;
	break;
    case 4: 	/* move to end of file */
	offset = 0;
	mode = SEEK_END;
	break;
    default:
	return (setstat(pblk->s_stat, 27));   /* incorrect mode parameter */
	return;
    }

    if (tracesys)
	printf (" desired offset %lXh, seek mode %d, ", offset, mode);

    offset = lseek(f->f_fd,offset,mode);    /* get new file position */

    if (tracesys)
	printf (" result offset %lXh\n", offset);

    if (pblk->s_mode == 0)	    /* return current position to caller? */
    {
	setword (pblk->s_nbyte, offset & 0x7f);
	setword (pblk->s_blks, offset >> 7);
    }
    if (offset == -1)
	setstat (pblk->s_stat, 20);	    /* bad seek */
    else
	setstat (pblk->s_stat, 0);
}


/***********************************************************************
*  IRESCAN - ISIS-II RESCAN call
***********************************************************************/

void irescan(RSBLK *pblk)
{
    FCB *f;

    if (tracesys)
	printf("RESCAN: aftn=%Xh, statptr=%Xh\n", pblk->rs_aft, pblk->rs_stat);

    if ((f = getfcb (pblk->rs_aft, pblk->rs_stat)) == 0) return;
    if (!f->f_led)	/* not line-edited file */
      {
	setstat(pblk->rs_stat, 21);
	return;
      }
    f->f_index = 0;
    setword (pblk->rs_stat, 0);
}


/***********************************************************************
*  ILOAD - ISIS-II LOAD call
***********************************************************************/

void iload(LBLK *pblk)
{
    FILE * f;		/* file handle */
    WORD dataptr;	/* pointer to where data record is to load (BYTE *) */
    WORD entrypt;	/* entry point (BYTE *) */
    WORD bias;		/* copy of pblk->l_bias */
    WORD mode;		/* copy of pblk->l_switch */
    WORD enad;		/* copy of pblk->l_enad (BYTE **) */
    WORD stat; 		/* copy of pblk->l_stat (WORD *) */
    WORD count;
    BYTE type,done;

    // copy important parameters from parameter block
    bias = pblk->l_bias;
    mode = pblk->l_switch;
    enad = pblk->l_enad;
    stat = pblk->l_stat;

    // convert the filename
    cvtfname(pblk->l_file,fname1,1);

    if (tracesys)
	printf ("LOAD: file=%s, bias=%x, switch=%x, enad=%x, statptr=%x\n",
		fname1, bias, mode, enad, stat);

    if ((f = fopen (skipdrv(fname1), "rb")) == NULL)
      {
	setstat(stat, 13);
	return;
      }

    // size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
    // read (f, buf, n) -> fread (buf, 1, n, f)
    for (done = FALSE; !done; )
    {
	fread (&type, sizeof (type), 1, f);
	fread (&count, sizeof (count), 1, f);
	switch (type)
	{
	    case 0x02:
	    case 0x08:
	    case 0x0e:
	    case 0x10:
	    case 0x12:
	    case 0x16:
	    case 0x18:
	    case 0x20:	    /* ignored record */
		fseek (f, (long)count, SEEK_CUR);
		break;
	    case 0x06:	    /* content record */
		fread (&type, sizeof(type), 1, f);	// ignore this byte
		fread (&dataptr, sizeof(dataptr), 1, f);
		if (dataptr < 0x3000)
		{
		    setstat(stat, 16);
		    done = TRUE;
		    break;
		}
		fread(&mem8080[dataptr+bias], 1, count-4, f);
		fread(&type, sizeof(type), 1, f); // skip checksum - should check */
		break;
	    case 0x04:	    /* end record */
		fread(&type, sizeof(type), 1, f);	// skip module type
		fread(&type, sizeof(type), 1, f);	// skip the zero byte
		fread(&entrypt, sizeof(entrypt), 1, f);	// read the entry point
		done = TRUE;
		if (mode == 0)		/* don't return status if chaining */
		    setword (stat, 0);
		break;
	    default:	    /* illegal record type */
		setstat (stat, 16);
		done = TRUE;
		break;
	}
    }
    fclose(f);
    switch (mode)
    {
	case 0: 	    /* just return to caller */
	    *(WORD *)&mem8080[enad] = entrypt;
	    break;
	case 1: 	    /* transfer control to loaded program */
	    savepc = entrypt;
//	    savesp = cstack;
	    break;
	default:
	    setstat(stat, 33);     /* illegal system call parameter */
	    return;
    }

    if (tracesys)
	printf (" entry=%x, last dataptr=%x\n", entrypt, dataptr);

}


/***********************************************************************
*  IERROR - ISIS-II ERROR call
***********************************************************************/

static const char * errormsg (WORD stat)
{
    const char * msg;

    switch (stat)
    {
    case 2:
	msg = "AFTN does not specify open file";
	break;
    case 3:
	msg = "Too many open files";
	break;
    case 7:
	msg = "Unable to write to disk";
	break;
    case 8:
	msg = "Attempt to read file open for output";
	break;
    case 13:
	msg = "No such file";
	break;
    case 14:
	msg = "Unable to open output file";
    case 16:
	msg = "Illegal load record";
	break;
    case 19:
	msg = "Attempt to seek on non-disk file";
	break;
    case 20:
	msg = "Seek error";
	break;
    case 21:
	msg = "Attempt to rescan non-line-edited file";
	break;
    case 24:
	msg = "Host system file I/O error";
	break;
    case 27:
	msg = "Incorrect MODE parm to SEEK";
	break;
    case 33:
	msg = "Illegal system call parm";
	break;
    default:
	msg = "Unknown error";
	break;
    }
    return msg;
}

static void ierror(EBLK *pblk)
{
    const char * msg;

    msg = errormsg (pblk->e_ernum);
    printf ("\nISIS-II Error %Xh: %s\n", pblk->e_ernum, msg);
    setword (pblk->e_stat, 0);
}


/***********************************************************************
*  IWHOCON - ISIS-II WHOCON call
***********************************************************************/

void iwhocon (WHBLK *pblk)
{
    BYTE *buf;
    FCB *f;

    if (tracesys)
	printf("WHOCON: aft=%Xh, buf=%Xh\n",pblk->wh_aft, pblk->wh_buf);

    if ((f = getfcb (pblk->wh_aft, pblk->wh_stat)) == 0) return;
    buf = &mem8080[pblk->wh_buf];	/* point to first byte in buffer */
    if (f->f_fd == 0)			/* stdin */
    {
	memcpy (buf, ":CI: ", 5);
    }
    else if (f->f_fd == 1)		/* stdout */
    {
	memcpy (buf, ":CO: ", 5);
    }
    setword (pblk->wh_stat, 0);     /* return good status */
}


/***********************************************************************
*  ISPATH - ISIS-II SPATH call
***********************************************************************/

void ispath (SPBLK *pblk)
{
    BYTE *buf;
    char *fname;
    BYTE c;

    cvtfname(pblk->sp_file,fname1,0); /* convert the filename */

    if (tracesys)
	printf("SPATH: file=%s, buf=%Xh, statptr=%Xh\n",
	       fname1, pblk->sp_buf, pblk->sp_stat);

    buf = &mem8080[pblk->sp_buf];   /* point to first byte in buffer */
    fname = fname1;		    /* point to converted filename */
    if (strcmp(fname,":CI:") == 0)
    {
	buf[0] = 8;		    /* device number 8 for crt input */
	buf[10] = 0;		    /* device type 0 for seq input */
    }
    else if (strcmp(fname,":CO:") == 0)
    {
	buf[0] = 9;		    /* device number 9 for crt output */
	buf[10] = 1;		    /* device type 0 for seq output */
    }
    else				/* must be a disk file */
    {
	buf[0] = 0;			/* device number 0 for drive 0 */
	buf[10] = 3;		    	/* device type 3 for random access */
	buf[11] = 4;		    	/* drive type 4 is hard disk */
	if (fname[0] == ':' && fname[3] == ':')
	{
	    if (fname[1] == 'F' || fname[1] == 'f')
		buf[0] = fname[2] - '0';	/* use actual drive no. */
	    fname += 4;			/* skip over device name */
	}
    }

    if (tracesys)
	printf ("\n devno=%Xh, devtype=%Xh, drvtype=%Xh, fname=",
	        buf[0], buf[10], buf[11]);

    buf++;			    /* pointer to filename part of buffer */
    setb(0,buf,9);		    /* zero fill filename portion of buffer */
    while (*fname && *fname != '.') /* copy the filename into buffer */
    {
        c = *fname++;		    /* Convert character to upper case */
	if (c >= 'a' && c <= 'z')
	    c -= 'a' - 'A';

	if (tracesys)
	    putchar (c);

	*buf++ = c;
    }

    if (tracesys)
	printf(", ext=");

    if (*fname) fname++;	    /* skip past the '.' */
    buf = &mem8080[pblk->sp_buf + 7];	    /* point to extension part of buffer */
    while (*fname)		    /* copy the extension into the buffer */
    {
        c = *fname++;		    /* Convert character to upper case */
	if (c >= 'a' && c <= 'z')
	    c -= 'a' - 'A';

	if (tracesys)
	    putchar (c);

	*buf++ = c;
    }

    if (tracesys)
	printf ("\n");

    setword (pblk->sp_stat, 0);     /* return good status */
}


/***********************************************************************
*  CLEANUP - clean up serial I/O vectors and exit if control-C is hit
***********************************************************************/

void cleanup (void)
{
/*    siouninit(); */
    exit(0);
}

/***********************************************************************
* ISIS - handle RETEM (return from 8080 emulation) (ISIS or MONITOR call)
*
* This routine is called from run80 or sim80 after the 8080 program
* returns from emulation with a RETEM.  This happens when the
* the RETEM instruction at 38H is executed as a result of a RST 7
* instruction.  There are RST 7 instructions at the ISIS entry
* point at 40H, as well as all MDS monitor entry points at F8xxH.
***********************************************************************/

void isis (void)
{
    if (mem8080[savepc-1] == 8)		// breakpoint instruction?
    {
	debug ();
	return;
    }
    if ((WORD)savepc != 0x41)			/* not an ISIS-II call?	*/
    {
	monitor();			/* must be an MDS monitor call */
	return;
    }
    switch(savebc & 0xff)   /* it's an ISIS-II trap - do the right thing */
    {
	case 0:
	    iopen((OBLK *)&mem8080[savede]);	/* OPEN call */
	    break;
	case 1:
	    iclose((CBLK *)&mem8080[savede]);	/* CLOSE call */
	    break;
	case 2:
	    idelete((DBLK *)&mem8080[savede]);	/* DELETE call */
	    break;
	case 3:
	    iread((RBLK *)&mem8080[savede]);	/* READ call */
	    break;
	case 4:
	    iwrite((WBLK *)&mem8080[savede]);	/* WRITE call */
	    break;
	case 5:
	    iseek((SBLK *)&mem8080[savede]);	/* SEEK call */
	    break;
	case 6:
	    iload((LBLK *)&mem8080[savede]);	/* LOAD call */
	    break;
	case 7:
	    irename((RNBLK *)&mem8080[savede]);	/* RENAME call */
	    break;
	case 9:
	    cleanup();
	    break;
	case 11:
	    irescan((RSBLK *)&mem8080[savede]);	/* RESCAN call */
	    break;
	case 12:		/* ERROR call */
	    ierror((EBLK *)&mem8080[savede]);
	    break;
	case 13:
	    iwhocon((WHBLK *)&mem8080[savede]);
	    break;
	case 14:		/* SPATH call */
	    ispath((SPBLK *)&mem8080[savede]);
	    break;
	default:
	    printf("\nIllegal ISIS-II function call %Xh\n", savebc & 0xff);
	    break;
    }
}

/***********************************************************************
*  INITISIS - initialize the first two FCBs for :CI: and :CO:,
*     clear the rest of the FCBs
***********************************************************************/

static void usage ()
{
    printf ("usage: isis [-t] [-s] [-d] program args...\n");
    printf (" -t  enable instruction tracing\n");
    printf (" -s  enable ISIS-II system call tracing\n");
    printf (" -d  run 8080 debugger\n");
    exit (1);
}

void initisis (int argc, char *argv[])
{
    FCB *f;
    int aft;
    LBLK pblk;
    WORD stat;
    int i;
    const char * firstarg;

    // The FCBs are put in 8080 memory space for consistency.
    fcbs = (FCB *) &mem8080[FCBS];

    // set up FCB 0 for console output file
    f = &fcbs[0];		/* pointer to FCB for :CO: */
    f->f_fd = 1;		/* file handle = 1 */
    f->f_access = 2;	/* write only */
    f->f_led = 0;		/* not line-edited */

    // set up FCB 1 for console input file
    f = &fcbs[1];		/* point to FCB for :CO: */
    f->f_fd = 0;		/* file handle = 0 */
    f->f_access = 1;	/* read only */
    f->f_led = 0xff00;	/* it's line-edited */

    // Copy command line arguments to FCB 1's line edit buffer

    f->f_lbuf[0] = '\0';
    firstarg = NULL;
    for (i = 1; i < argc; i++)
    {
	const char *arg = argv[i];
	if (strcmp (arg, "-t") == 0)
	    set_trace (1);
	else if (strcmp (arg, "-s") == 0)
	    tracesys = 1;
	else if (strcmp (arg, "-d") == 0)
	    debugger = 1;
	else if (strcmp (arg, "--help") == 0)
	    usage ();
	else
	{
	    if (strlen (arg) + strlen ((const char *)f->f_lbuf) + 3 > sizeof (f->f_lbuf))
		break;
	    if (strlen((const char *) f->f_lbuf) != 0)
		strcat ((char *)f->f_lbuf, " ");
	    strcat ((char *)f->f_lbuf, arg);
	    if (firstarg == NULL)
		firstarg = arg;
	}
    }

    // If no arguments specified, print usage and exit

    if (firstarg == NULL)
	usage ();

    // Append CRLF to command line.

    strcat ((char *)f->f_lbuf, "\r\n");
    f->f_count = strlen ((const char *)f->f_lbuf);
    f->f_index = 0;

    if (tracesys)
    {
	printf ("cmd line: ");
	for (i = 0; i < f->f_count; i++)
	  printf ("%02x ", f->f_lbuf[i] & 0xff);
	printf("\n");
    }

    // Mark remaining FCBs as unused.
    for (aft = 2; aft < NFCBS; aft++)
	fcbs[aft].f_fd = UNUSED_FD;	/* mark it as unused */

    // skip past leading spaces on command line to find program name
    while (f->f_lbuf[f->f_index] == ' ')
	f->f_index++;

    // Removing the high 16 bits of the address works because the
    // buffer is in 8080 memory space.  But it causes a gcc warning.

    pblk.l_file = (WORD) (long) &f->f_lbuf[f->f_index];

    // skip read pointer past filename to command to tail
    while (f->f_lbuf[f->f_index] != ' ' && f->f_lbuf[f->f_index] != '\r')
	f->f_index++;

    // Load program specified on command line.
    pblk.l_bias = 0;
    pblk.l_switch = 0;
    pblk.l_enad = 0;			// Store entrypoint at mem[0]
    pblk.l_stat = 2;			// Store status at mem[2]
    iload(&pblk);				// Load the program
    savepc = *(WORD *)&mem8080[0];	// Get entrypoint
    stat = *(WORD *)&mem8080[2];		// Get status
    if (stat != 0)
    {
	printf("Unable to load %s: %s\n", firstarg, errormsg(stat));
	exit (1);
    }
}


/***********************************************************************
*  MAIN ROUTINE - initialize MDS memory, ISIS-II file system,
*    then load program specified on command line and run it.
***********************************************************************/

int main (int argc, char *argv[])
{
    BYTE *brkinst;
    WORD sizebrk;
    long base;

    /* Allocate the 8080 memory.  This is very wasteful, but we do
     * this to ensure that the low 16 bits of the pointer will be zero.
     */
    base = (long) malloc (0x20000);
    base = (base + 0xffff) & ~0xffff;
    mem8080 = (BYTE *)base;
    
    brkinst = brk_8088;
    sizebrk = sizeof(brk_8088);

    /* Poke instructions to break emulation at ISIS and monitor
     * entry points.  On the V20, these instruction are {RST 7, RET},
     * and the code at the RST 7 interrupt handler actually breaks
     * emulation.
     */
    movb (brkinst, &mem8080[ISIS],  sizebrk);
    movb (brkinst, &mem8080[CI],    sizebrk);
    movb (brkinst, &mem8080[CO],    sizebrk);
    movb (brkinst, &mem8080[CSTS],  sizebrk);
    movb (brkinst, &mem8080[MEMCK], sizebrk);

    /* Initialize ISIS-II file system and command tail,
     * then load the program.
     */
    initisis (argc, argv);

    if (debugger)
	single_step ();

    /* Start the loaded program.
     */
    go8080();
    return 0;
}
