/* MAKOVL.C	Overlay builder/manager

	This code is in the public domain.
	Created from L2.C 81.10.29 Gyro

This is a variation on L2.C that creates relocatable overlays
according to an overlay descriptor file.

Command format:

	makovl <root name> <overlay name> {<CRL file>} [-l {<CRL file>}] [-nd]

Overlay descriptor file, <root name>.DES, contains:

	<overlay slot size> <relocation info size>
	<CRL file> ... (default search list)
	... (more default search list)
	<blank line>
	<overlay name> <slot number>
		<function name>  <comments or whatnot>
		<function name>  <comments or whatnot>
		... (an entry for each top-level function in the overlay)
	<blank line>
	<overlay name> <slot number>
		<function name>  <comments or whatnot>
		<function name>  <comments or whatnot>
		...
	... (an entry for each overlay in the file)


Overlay segments are of length <overlay slot size> bytes, of which the
last <relocation info size> bytes holds a list of relocation offsets. 
This is a null-terminated string of byte values giving the difference
between successive addresses to be relocated; a value of 255 means to
add 255 to the next byte value to get the offset.  The first offset is
relative to -1 (so that we can relocate the first word of the
overlay).  At the beginning of the overlay is a table of addresses of
top-level functions, one address for each function listed for that
overlay in the descriptor file.

The -l option works as for L2: CRL files listed before the -l are
loaded in entirety; those after are just scanned for needed functions. 
Any functions specified in the default search list in the overlay
descriptor file are also scanned, unless the -nd (no default) option
is given.

The overlay, once created, is written into <root name>.OVL, at address
<slot number> * <overlay slot size>.

*/


/**************** Globals ****************/

#define SDOS				/* comment this out for CP/M */

#include "bdscio.h"			/* for i/o buffer defs */

#define NUL		0
#define FLAG		char
#define repeat 	while (1)

#define STDOUT		1


/* function table */
struct funct {
	char fname[9];
	FLAG flinkedp;			/* in memory already? */
	char *faddr;			/* address of first ref link if not linked */
	} ftab [300];
int nfuncts;				/* no. of functions in table */

#define LINKED		255		/* (flinkedp) function really here */
#define EXTERNAL	254		/* function defined in separate symbol table */

char fdir [512];			/* CRL file function directory */

/* command line parameters etc. */
char rootname[15];			/* name of root program */
char ovlname[40];			/* name of overlay to be built */
int nprogs, nlibs;
char progfiles [20] [15];	/* program file names */
char libfiles [30] [15];		/* library file names */
FLAG srchdefs;				/* search default libraries? */

/* overlay description */
int ovlsize, relsize;		/* size of overlay slot & of relocation info */
int ovlslot;				/* slot # to put overlay in */
char topfuncts[10][32];		/* names of top level functions */
int ntops;				/* number of top level functions */
char *relstart;			/* beginning of relocation info */
char *relnext;				/* next relocation value */
char *reladdr;				/* last address relocated */


/* useful things to have defined */
struct inst {
	char opcode;
	char *address;
	};

union ptr {
	unsigned u;			/* an int */
	unsigned *w;			/* a word ptr */
	char *b;				/* a byte ptr */
	struct inst *i;		/* an instruction ptr */
	};


/* Link control variables */

union ptr codend;			/* last used byte of code buffer + 1 */
union ptr acodend;			/* actual code-end address */
unsigned origin;			/* origin of code */
unsigned buforg;			/* origin of code buffer */

char *lspace;				/* space to link in */
char *lspcend;				/* end of link area */
char *lodstart;			/* beginning of current file */


/* i/o buffer */
struct iobuf {
	int fd;
	int isect;			/* currently buffered sector */
	int nextc;			/* index of next char in buffer */
	char buff [128];
	} ibuf, obuf;

/* BDS C i/o buffer */
char bdsbuf[BUFSIZ];

/* seek opcodes */
#define ABSOLUTE 0
#define RELATIVE 1

#define INPUT 0
#define UPDATE 2

#define TRUE (-1)
#define FALSE 0
#define NULL 0

/* 8080 instructions */
#define LHLD 0x2A
#define LXIH 0x21
#define SPHL 0xF9
#define JMP  0xC3
#define CALL 0xCD

/* strcmp7 locals, made global for speed */
char _c1, _c2, _end1, _end2;

/**************** End of Globals ****************/



main (argc, argv)
	int argc;
	char **argv;
{
	puts ("Mark of the Unicorn Overlay Builder, vsn. 1.0\n");
	setup (argc, argv);
	linkprog();
	linklibs();
	listfuns();
	wrtovl();
	}


setup (argc, argv)			/* initialize function table, etc. */
	int argc;
	char **argv;
{
	nprogs = 0;
	nlibs = 0;
	origin = buforg = 0;
	nfuncts = 0;
	srchdefs = TRUE;
	cmdline (argc, argv);
	lspace = endext();
	lspcend = topofmem() - 1024;
	getdesc();
	loadsyms();
	}


cmdline (argc, argv)		/* process command line */
	int argc;
	char **argv;
{
	int i, progp;

	if (argc <= 2) {
		puts ("Usage is:\n");
		puts ("  makovl <root name> <overlay name> {<CRL file>} [-l {<CRL file>}]");
		exit (1);
		}
	strcpy (&rootname, argv[1]);
	strcpy (&ovlname, argv[2]);
	progp = TRUE;
	for (i = 3; i < argc; ++i) {
		if (argv[i][0] == '-') {
			if (!strcmp (argv[i], "-L")) progp = FALSE;
			else if (match (argv[i], "-ND")) srchdefs = FALSE;
			else printf ("Unknown option: '%s'\n", argv[i]);
			}
		else {
			if (progp) strcpy (&progfiles[nprogs++], argv[i]);
			else strcpy (&libfiles[nlibs++], argv[i]);
			}
		}
	}


getdesc()					/* get & process overlay description */
{
	makeext (&rootname, "DES");
	if (fopen (&rootname, &bdsbuf) < 0)
		Fatal ("Can't open overlay descriptor file '%s'.\n", &rootname);
	if (fscanf (&bdsbuf, "%d%d", &ovlsize, &relsize) < 2
	    ||  ovlsize <= relsize) {
		Fatal ("Error in descriptor file: bad overlay/relocation sizes.\n");
		}
	getlibs();
	findovl();
	readfuns();
	fclose (&bdsbuf);
	}


getlibs()					/* get default search list */
{
	char line[MAXLINE], *cp, *dest;
	
	repeat {
		if (!fgets (&line, &bdsbuf)  ||  !line[0]) break;
		if (!srchdefs) continue;
		cp = &line;
		repeat {
			while (isspace (*cp)) ++cp;
			if (!*cp) break;
			dest = &libfiles[nlibs++];
			while (*cp  &&  !isspace (*cp)) *dest++ = *cp++;
			*dest = NUL;
			}
		}
	}


findovl()					/* find description of overlay */
{
	char tname[40];
	int nread;
	FLAG skipping, found;
	
	skipping = found = FALSE;
	while (!found
		  &&  (nread = fscanf (&bdsbuf, "%s%d", &tname, &ovlslot)) >= 0) {
		if (nread) {
			if (!skipping) {
				if (match (&tname, &ovlname)) found = TRUE;
				else skipping = TRUE;
				}
			}
		else skipping = FALSE;
		}
	if (!found)
		Fatal ("Can't find description of overlay '%s'.\n", &ovlname);
	if (nread < 2) 
		Fatal ("No slot number present for overlay '%s'.\n", &tname);
	printf ("Building overlay %s, for slot %d.\n", &tname, ovlslot);
	}


readfuns()
{
	char tname[40];
	struct funct *fnct;
	
	ntops = 0;
	RelInit();
	codend.b = lspace;				/* build table of functions */
	puts ("Functions included:\n");
	while (fscanf (&bdsbuf, "%s", &tname) > 0) {
		printf ("%-10s", &tname);
		upcase (&tname);
		tname[8] = NUL;			/* limit size */
		fnct = intern (&tname);
		*codend.w = fnct->faddr;		/* link in reference */
		RelAccum (codend.w);		/* relocate this address */
		fnct->faddr = codend.w++;
		ntops++;
		}
	puts ("\n\n");
	}


linkprog()				/* link in all program files */
{
	int i;
	union ptr dirtmp;
	struct funct *fnct;

	for (i=0; i<nprogs; ++i) {
		makeext (&progfiles[i], "CRL");
		if (copen (&ibuf, progfiles[i]) < 0) {
			printf ("Can't open %s\n", progfiles[i]);
			continue;
			}
		printf ("Loading %s\n", &progfiles[i]);
		readprog (i==0);
		for (dirtmp.b=&fdir; *dirtmp.b != 0x80;) {
			fnct = intern (dirtmp.b);			/* for each module */
			skip7 (&dirtmp);					/* in directory */
			if (!fnct->flinkedp)
				linkmod (fnct, lodstart + *dirtmp.w - 0x205);
			else {
				puts ("  Duplicate program function '");
				puts (&fnct->fname);
				puts ("', not linked.\n");
				}
			dirtmp.w++;
			}								/* intern & link it */
		cclose (&ibuf);
		}
	}


linklibs()				/* link in library files */
{
	int ifile;

	for (ifile = 0; ifile < nlibs; ++ifile) scanlib (ifile);
	while (missingp()) {
		puts ("Enter the name of a file to be searched: ");
		gets (&libfiles[nlibs]);
		upcase (&libfiles[nlibs]);
		scanlib (nlibs++);
		}
	acodend.b = codend.b - lspace + buforg;		/* save that number! */
	}


missingp()				/* are any functions missing?  print them out */
{
	int i, foundp;

	foundp = FALSE;
	for (i=0; i<nfuncts; ++i)
		if (!ftab[i].flinkedp) {
			if (!foundp) puts ("*** Missing functions:\n");
			puts (&ftab[i].fname);
			puts ("\n");
			foundp = TRUE;
			}
	return (foundp);
	}


readprog (mainp)			/* read in a program file */
	FLAG mainp;
{
	char extp;							/* was -e used? */
	char *extstmp;
	union ptr dir;
	unsigned len;

	if (cread (&ibuf, &fdir, 512) < 512)			/* read directory */
		Fatal ("-- read error!\n");
	cseek (&ibuf, 5, RELATIVE);
	for (dir.b=&fdir; *dir.b != 0x80; nextd (&dir));	/* find end of dir */
	++dir.b;
	len = *dir.w - 0x205;
	readobj (len);
	}


readobj (len)				/* read in an object (program or lib funct) */
	unsigned len;
{
	if (codend.b + len >= lspcend) Fatal ("-- out of memory!\n");
	lodstart = codend.b;
	if (cread (&ibuf, lodstart, len) < len)
		Fatal ("-- read error (read 0x%x)!\n", len);
	}


scanlib (ifile)
	int ifile;
{
	int i;
	union ptr dirtmp;

	makeext (&libfiles[ifile], "CRL");
	if (copen (&ibuf, libfiles[ifile]) < 0) {
		printf ("Can't open %s\n", libfiles[ifile]);
		return;
		}
	printf ("Scanning %s\n", &libfiles[ifile]);
	if (cread (&ibuf, &fdir, 512) < 512)	/* read directory */
		Fatal ("-- Read error (directory)!\n");
	for (i=0; i<nfuncts; ++i) {			/* scan needed functions */
		if (!ftab[i].flinkedp
		    && (dirtmp.b = dirsearch (&ftab[i].fname))) {
			readfunct (dirtmp.b);
			linkmod (&ftab[i], lodstart);
			}
		}
	cclose (&ibuf);
	}


readfunct (direntry)			/* read a function (from a library) */
	union ptr direntry;
{
	unsigned start, len;

	skip7 (&direntry);
	start = *direntry.w++;
	skip7 (&direntry);
	len = *direntry.w - start;
	if (cseek (&ibuf, start, ABSOLUTE) < 0)
		Fatal (" -- read error (seek 0x%x)!", start);
	readobj (len);
	}


linkmod (fnct, modstart)			/* link in a module */
	struct funct *fnct;
	union ptr	modstart;					/* loc. of module in memory */

{
	union ptr temp,
			jump,					/* jump table temp */
			body,					/* loc. of function in memory */
			code,					/* loc. of code proper in mem. */
			finalloc;					/* runtime loc. of function */
	unsigned flen, nrelocs, jtsiz, offset;

	fnct->flinkedp = LINKED;
	finalloc.b = codend.b - lspace + buforg;
	chase (fnct->faddr, finalloc.b);
	fnct->faddr = finalloc.b;
	body.b = modstart.b + strlen(modstart.b) + 3; /* loc. of function body */
	jump.i = body.i + (*modstart.b ? 1 : 0);
	for (temp.b = modstart.b; *temp.b; skip7(&temp)) {
		jump.i->address = intern (temp.b);
		++jump.i;
		}
	++temp.b;
	flen = *temp.w;
	code.b = jump.b;
	temp.b = body.b + flen;				/* loc. of reloc parameters */
	nrelocs = *temp.w++;
	jtsiz = code.b - body.b;
	offset = code.b - codend.b;
	while (nrelocs--) relocate (*temp.w++, body.b, jtsiz,
						   finalloc.b, offset, flen);
	flen -= jtsiz;
	movmem (code.b, codend.b, flen);
	codend.b += flen;
	}


relocate (param, body, jtsiz, base, offset, flen)	/* do a relocation!! */
	unsigned param, jtsiz, base, offset, flen;
	union ptr body;
{
	union ptr instr,					/* instruction involved */
			ref;						/* jump table link */
	struct funct *fnct;

	if (param == 1  &&  jtsiz) return;		/* don't reloc jt skip */
	instr.b = body.b + param - 1;
	if (instr.i->address >= jtsiz) {
		instr.i->address += base - jtsiz;
		RelAccum (body.b + param - offset);
		}
	else {
		ref.b = instr.i->address + body.u;
		if (instr.i->opcode == LHLD) {
			instr.i->opcode = LXIH;
			--ref.b;
			}
		fnct = ref.i->address;
		instr.i->address = fnct->faddr;		/* link in */
		if (!fnct->flinkedp)
			fnct->faddr = instr.b + 1 - offset;	/* new list head */
		if (fnct->flinkedp != EXTERNAL) RelAccum (instr.b + 1 - offset);
		}
	}


intern (name)				/* intern a function name in the table */
	char *name;
{
	struct funct *fptr;

	if (*name == 0x9D) name = "MAIN";		/* Why, Leor, WHY??? */
	for (fptr = &ftab[nfuncts-1]; fptr >= ftab; --fptr) 
		if (!strcmp7 (name, fptr->fname)) break;
	if (fptr < ftab) {
		fptr = &ftab[nfuncts];
		strcpy7 (fptr->fname, name);
		str7tont (fptr->fname);
		fptr->flinkedp = FALSE;
		fptr->faddr = NULL;
		++nfuncts;
		}
	return (fptr);
	}


dirsearch (name)			/* search directory for a function */
	char *name;
{
	union ptr temp;

	for (temp.b = &fdir; *temp.b != 0x80; nextd (&temp))
		if (!strcmp7 (name, temp.b)) return (temp.b);
	return (NULL);
	}


nextd (ptrp)				/* move this pointer to the next dir entry */
	union ptr *ptrp;
{
	skip7 (ptrp);
	++(*ptrp).w;
	}


chase (head, loc)			/* chase chain of refs to function */
	union ptr head;
	unsigned loc;
{
	union ptr temp;

	while (head.w) {
		temp.w = *head.w;
		*head.w = loc;
		head.u = temp.u;
		}
	}


RelInit()					/* initialize relocation accumulator */
{
	relstart = relnext = lspace;
	lspace += relsize;				/* allocate some memory for relocs */
	reladdr = lspace - 1;
	}


RelAccum (addr)			/* note another relocation */
	char *addr;
{
	unsigned delta;
	
	if (relnext - relstart >= relsize) {
		Deadly ("Out of relocation bytes (limit is %d)\n", relsize);
		relnext = relstart;
		}
	delta = addr - reladdr;
	if (delta >= 255) {
		*relnext++ = 255;
		*relnext++ = delta - 255;
		}
	else *relnext++ = delta;
	reladdr = addr;
	}


RelFini()					/* end of relocations */
{
	printf ("Relocation bytes used: %d (limit is %d)\n",
			   relnext - relstart, relsize);
	*relnext = NUL;
	}


wrtovl()					/* write overlay into slot */
{
	int ovlfd;
	
	RelFini();
	if (codend.b > lspace + ovlsize - relsize)
		Deadly ("Code too long!\n");
	movmem (relstart, lspace + ovlsize - relsize, relsize);
	makeext (&rootname, "OVL");
	if ((ovlfd = open (&rootname, UPDATE)) < 0)
		Fatal ("Can't open overlay file '%s'.\n", rootname);
	if (seek (ovlfd, ovlslot * ovlsize / 128, ABSOLUTE) == -1
	    ||  write (ovlfd, lspace, ovlsize / 128) == -1)
		Fatal ("Disk write error.  Check slot # and size of .OVL file.\n");
	close (ovlfd);
	}


listfuns()				/* list functions linked */
{
	int i, compar();
	
	for (i = 0; i < ntops; ++i) ftab[i].flinkedp = i;
	while (i < nfuncts  &&  ftab[i].flinkedp == EXTERNAL) i++;
	arydel (&ftab, nfuncts, sizeof(*ftab), ntops, i);
	nfuncts -= i - ntops;
	qsort (&ftab, nfuncts, sizeof(*ftab), &compar);
	ftab[nfuncts].faddr = acodend.b;
	puts ("\nContents of overlay:\n");
	puts ("Entry no.   Name        Start     Length\n");
	for (i = 0; i < nfuncts; ++i) {
		if (ftab[i].flinkedp < 255) printf ("%8d", ftab[i].flinkedp);
		else puts ("        ");
		printf ("    %-8s    0x%4x    0x%4x\n",
			   ftab[i].fname, ftab[i].faddr,
			   ftab[i+1].faddr - ftab[i].faddr);
		}
	printf ("End address: 0x%x\n", acodend.u);
	i = ovlsize - relsize - acodend.u;
	printf ("Code bytes remaining: 0x%x = %d.\n\n", i, i);
	}


compar (f1, f2)			/* compare two symbol table entries by name */
	struct funct *f1, *f2;
{
/*	return (strcmp (&f1->fname, &f2->fname));	alphabetical order */
	return (f1->faddr > f2->faddr);			/* memory order */
	}


loadsyms()				/* load base symbol table (for overlay) */
{						/* symbol table must be empty! */
	int nread;
	FLAG done;
	char *c;
	
	makeext (&rootname, "SYM");
	if (fopen (&rootname, &bdsbuf) < 0) 
		Fatal ("Can't open %s.\n", &rootname);
	done = FALSE;
	while (!done) {
		nread = fscanf (&bdsbuf, "%x%s%x%s%x%s%x%s",
					 &(ftab[nfuncts].faddr), &(ftab[nfuncts].fname),
					 &(ftab[nfuncts+1].faddr), &(ftab[nfuncts+1].fname),
					 &(ftab[nfuncts+2].faddr), &(ftab[nfuncts+2].fname),
					 &(ftab[nfuncts+3].faddr), &(ftab[nfuncts+3].fname));
		nread /= 2;
		if (nread < 4) done = TRUE;
		while (nread-- > 0) ftab[nfuncts++].flinkedp = EXTERNAL;
		}
	fclose (&bdsbuf);
	}


makeext (fname, ext)		/* force a file extension to ext */
	char *fname, *ext;
{
	while (*fname && (*fname != '.')) {
		*fname = toupper (*fname);		/* upcase as well */
		++fname;
		}
	*fname++ = '.';
	strcpy (fname, ext);
	}


strcmp7 (s1, s2)			/* compare two bit-7-terminated strings */
	char *s1, *s2;			/* also works for non-null NUL-term strings */
{
/*	char c1, c2, end1, end2;		(These are now global for speed) */

	repeat {
 		_c1 = *s1++;
		_c2 = *s2++;
		_end1 = (_c1 & 0x80) | !*s1;
		_end2 = (_c2 & 0x80) | !*s2;
		if ((_c1 &= 0x7F) < (_c2 &= 0x7F)) return (-1);
		if (_c1 > _c2  ||  (_end2  &&  !_end1)) return (1);
		if (_end1  &&  !_end2) return (-1);
		if (_end1  &&  _end2) return (0);
		}
	}


strcpy7 (s1, s2)			/* copy s2 into s1 */
	char *s1, *s2;
{
	do {
		*s1 = *s2;
		if (!*(s2+1)) {				/* works even if */
			*s1 |= 0x80;				/* s2 is null-term */
			break;
			}
		++s1;
		} while (!(*s2++ & 0x80));
	}


skip7 (ptr7)				/* move this pointer past a string */
	char **ptr7;
{
	while (!(*(*ptr7)++ & 0x80));
	}


str7tont (s)				/* add null at end */
	char *s;
{
	while (!(*s & 0x80)) {
		if (!*s) return;		/* already nul term! */
		s++;
		}
	*s = *s & 0x7F;
	*++s = NUL;
	}


puthex (n, obuf)			/* output a hex word, with leading 0s */
	unsigned n;
	char *obuf;
{
	int i, nyb;
	
	for (i = 3; i >= 0; --i) {
		nyb = (n >> (i * 4)) & 0xF;
		nyb += (nyb > 9) ? 'A' - 10 : '0';
		putc (nyb, obuf);
		}
	}


Fatal (arg1, arg2, arg3, arg4)	/* lose, lose */
	char *arg1, *arg2, *arg3, *arg4;
{
	printf (arg1, arg2, arg3, arg4);
	exit (1);
	}


Deadly (arg1, arg2, arg3, arg4)	/* partially-recoverable error */
	char *arg1, *arg2, *arg3, *arg4;
{
	printf (arg1, arg2, arg3, arg4);
	puts ("   -- overlay being generated anyway, for debugging.\n");
	}


exit (status)				/* exit the program */
	int status;
{
	if (status == 1) {
#ifdef SDOS
		unlink ("a:$$$$.cmd");
#else
		unlink ("a:$$$.sub");
#endif
		}
	bios (1);					/* bye! */
	}


/* End of MAKOVL.C  --  link and store relocatable overlay */
