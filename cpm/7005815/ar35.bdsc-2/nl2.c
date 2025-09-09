/* L2.C	New linker for BDS C

		Written 1980 by Scott W. Layson
		This code is in the public domain.

This is an improved linker for BDS C CRL format.  It eliminates the
jump table at the beginning of each function in the object code,
thus saving up to 10% or so in code space with a slight improvement
in speed.  

Compile:   A>cc nl2.c -e4800 -o	(use -e4a00 if using CLINK instead of L2)
	   A>cc portio.c
link:	   A>l2 nl2 portio

		[81.4.27] Overlay capability now exists.  It works a bit
                     differently from CLINK:  the option
				   -ovl <base name> <origin>
				 causes symbols to be read from <base name>.sym
                     and produces a segment linked at <origin>.  It
                     also defaults the name of the overlay function to
                     that of the first .crl file (to override, put -m
                     after the -ovl), and replaces c.ccc with a jump
                     to that function.  Also note that the base
                     symbols are loaded at the very beginning, so name
                     conflicts are always resolved in favor of the
                     base.

Changes made by EBM:
	1) added -2 and -d flags
	2) fixed so that duplicates work right when two passes are made
	3) changed to use hashing for symbols
	4) added -f flag
	5) change "two-pass" processing to write file as it goes and go
	   back through for fixups (this removes the -2 flag)
	6) added -o flag for choosing output file name
	7) made symbols grow down from top so table size is variable;
	   also added more checks for various tables overflowing
*/


/**************** Globals ****************/

/*	#define SDOS				/* comment this out for CP/M */*/
/*	#define OVERLAYS			/* comment this out for shorter version */*/
/*	#define MARC				/* for MARC cross-linker version */*/


#include "bdscio.h"			/* for i/o buffer defs */

#define NUL		0
#define FLAG		char

#define STDOUT		1

int needfixups;			/* set if we need to go back through */

/* Sizes */
#define FNAMESIZE	 15		/* length of file names */
#define MAXPROGS	 30		/* max number of program files */
#define MAXLIBS	 20		/* max number of library files */

/* function table */
struct funct {
	char fname[9];
	FLAG flinkedp;			/* indicates whether found or external */
	unsigned faddr;		/* address of function (initially 0) */
	unsigned fchain;		/* chain of fixups */
	struct funct *next;		/* next one in same hash bucket */
	} *ftab, *ftabend;

/* Hash table */
struct funct *hashtab[256];

#define LINKED		1		/* (flinkedp) function really here */
#define EXTERNAL	2		/* function defined in separate symbol table */

char fdir[512];			/* CRL file function directory */

/* command line parameters etc. */
int nprogs, nlibs;
char progfiles [MAXPROGS][FNAMESIZE];	/* program file names */
char libfiles  [MAXLIBS] [FNAMESIZE];	/* library file names */
FLAG symsp,					/* write symbols to .sym file? */
	appstatsp,				/* append stats to .sym file? */
	sepstatsp;				/* write stats to .lnk file? */
FLAG maxmemp,					/* punt MARC shell? */
	marcp;					/* uses CM.CCC */
unsigned cccsize;				/* for fixup processing */
char mainfunct[10];
char objname[FNAMESIZE];			/* name for output file */
FLAG objset;					/* was -O specified ? */
FLAG ovlp;					/* make overlay? */
char symsfile[FNAMESIZE];		/* file with symbols (for overlays) */
FLAG	debug;					/* extra printouts */

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
union ptr exts;			/* start of externals */
union ptr acodend;			/* actual code-end address */
unsigned extspc;			/* size of externals */
unsigned origin;			/* origin of code */
unsigned buforg;			/* origin of code buffer */
unsigned jtsaved;			/* bytes of jump table saved */

char *lspace;				/* space to link in */
char *lspcend;				/* end of link area */
char *lodstart;			/* beginning of current file */
char *firstfree;			/* address of first byte above good stuff */


#include "portio.h"
struct iobuf ibuf, obuf;

/* BDS C i/o buffer */
char symbuf[BUFSIZ];

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
	puts ("Mark of the Unicorn Linker for BDS C, vsn. 2.1x\n");
	setup (argc, argv);
	if (!ovlp) makeext (&objname, "COM");
	else makeext (&objname, "OVL");
	if (ccreat (&obuf, &objname) < 0)
		Fatal ("Couldn't create binary file!");
	linkprog();
	linklibs();
	if (needfixups) dofixups();
	else wrtcom();
	if (symsp) wrtsyms();
	}


setup (argc, argv)			/* initialize function table, etc. */
	int argc;
	char **argv;
{
	int i;

	symsp = appstatsp = sepstatsp = maxmemp = marcp = FALSE;
	ovlp = needfixups = debug = objset = FALSE;
	nprogs = nlibs = 0;
	strcpy (&mainfunct, "MAIN");
	origin = 0x100;
	cmdline (argc, argv);
	lspace = endext();
	lspcend = topofmem() - 1024;
	loadccc();
	ftab = ftabend = lspcend;
#ifdef OVERLAYS
	if (ovlp) loadsyms();
#endif
	for (i = 0; i < 256; ++i) hashtab[i] = NULL;
	intern (&mainfunct);
	buforg = origin;
	jtsaved = 0;
	}


cmdline (argc, argv)		/* process command line */
	int argc;
	char **argv;
{
	int i, progp;

	if (argc < 1) {
		puts ("Usage is:\n");
		puts ("  l2 {program files} -l {library files}\n");
		puts ("Optional flags are:\n");
		puts ("  -w  to write symbol table (without stats)\n");
		puts ("  -wa write symbol table with stats appended\n");
		puts ("  -ws write symbol table and separate stats file\n");
		puts ("  -d  print extra, debugging info about each function\n");
		puts ("  -m  take next argument as name of main function\n");
		puts ("  -f  next argument is the name of a file of file names,\n");
		puts ("      one per line; those files will be included as if\n");
		puts ("      they were on the command line in the same place\n");
		puts ("  -o  take next argument as first name of output file\n");
		puts ("  -ovl symbol-file origin\n");
		puts ("      links an overlay where the main program symbols\n");
		puts ("      are in symbol-file and the overlay starts at the\n");
		puts ("      specified origin (origin is expressed in hex)\n");
		puts ("  -marc  link for the MARC operating system\n");
		exit (1);
		}
	progp = TRUE;
	for (i = 1; i < argc; ++i) {
		if (argv[i][0] == '-') {
			if (!strcmp (argv[i], "-L")) progp = FALSE;
			else if (!strcmp (argv[i], "-W")) symsp = TRUE;
			else if (!strcmp (argv[i], "-WA")) symsp = appstatsp = TRUE;
			else if (!strcmp (argv[i], "-WS")) symsp = sepstatsp = TRUE;
			else if (!strcmp (argv[i], "-M")) {
				if (++i >= argc) Fatal ("-m argument missing.\n");
				strcpy (&mainfunct, argv[i]);
				}
			else if (!strcmp (argv[i], "-D")) debug = TRUE;
			else if (!strcmp (argv[i], "-F")) {
				if (++i >= argc) Fatal ("-f argument missing.\n");
				getfiles (argv[i], progp);
				}
			else if (!strcmp (argv[i], "-O")) {
				if (++i >= argc) Fatal ("-o argument missing.\n");
				strcpy (&objname, argv[i]);
				objset = TRUE;
				}
#ifdef OVERLAYS
			else if (!strcmp (argv[i], "-OVL")) {
				ovlp = TRUE;
				if (i + 2 >= argc) Fatal ("-ovl argument missing.\n");
				strcpy (&symsfile, argv[++i]);
				sscanf (argv[++i], "%x", &origin);
				}
#endif
#ifdef MARC
			else if (!strcmp (argv[i], "-MARC")) {
				maxmemp = TRUE;
				marcp = TRUE;
				}
#endif
			else printf ("Unknown option: '%s'\n", argv[i]);
			}
		else {
			if (progp) {
				if (++nprogs >= MAXPROGS)
					Fatal ("Too many program files.\n");
				strcpy (&progfiles[nprogs - 1], argv[i]);
				}
			else	{
				if (++nlibs > (MAXLIBS - 2)) /* leave room for defaults */
					Fatal ("Too many library files.\n");
				strcpy (&libfiles[nlibs - 1], argv[i]);
				}
			}
		}
	if (ovlp) strcpy (&mainfunct, &progfiles[0]);
	if (!objset) strcpy (&objname, &progfiles[0]);
	strcpy (&libfiles[nlibs++], marcp ? "DEFFM" : "DEFF");
	strcpy (&libfiles[nlibs++], marcp ? "DEFF2M" : "DEFF2");
	}

getfiles(ffname, progp)		/* read a file of filenames */
	char *ffname;
	int progp;
{
	char buffer[FNAMESIZE], *p, *q;

	if (fopen (ffname, &symbuf) < 0)
		{printf ("Could not open %s.\n", ffname);
		return;
		}
	while (fgets (&buffer, &symbuf)) {
		if (progp ? (++nprogs >= MAXPROGS) : (++nlibs > (MAXLIBS - 2)))
			Fatal ("Too many %s files.", (progp ? "program" : "library"));
		p = (progp ? &progfiles[nprogs - 1] : &libfiles[nlibs - 1]);
		q = &buffer;
		while (*q != '\n') *p++ = *q++;
		*p = '\0';
		}
	fclose (&symbuf);
	}

loadccc()					/* load C.CCC (runtime library) */
{
	union ptr temp;
	unsigned len;

	codend.b = lspace;
	if (!ovlp) {
		if (copen (&ibuf, marcp ? "CM.CCC" : "C.CCC") < 0)
			Fatal ("Can't open C.CCC\n");
		if (cread (&ibuf, lspace, 128) < 128)	/* read a sector */
			Fatal ("C.CCC: read error!\n");
		temp.b = lspace + 0x17;
		len = *temp.w;						/* how long is it? */
		setmem (lspace + 128, len - 128, 0);	/* for file compares */
		cread (&ibuf, lspace + 128, len - 128);
		codend.b += len;
		cclose (&ibuf);
		}
	else codend.i++->opcode = JMP;
	cccsize = codend.b - lspace;
	firstfree = codend.b;
	}


linkprog()				/* link in all program files */
{
	int i;
	union ptr dirtmp;
	struct funct *fnct;

	for (i = 0; i < nprogs; ++i) {
		makeext (&progfiles[i], "CRL");
		if (copen (&ibuf, progfiles[i]) < 0) {
			printf ("Can't open %s\n", progfiles[i]);
			continue;
			}
		printf ("<< Loading %s >>\n", &progfiles[i]);
		readprog (i == 0);
		for (dirtmp.b = &fdir; *dirtmp.b != 0x80;) {
			fnct = intern (dirtmp.b);			/* for each module */
			skip7 (&dirtmp);					/* in directory */
			if (fnct->flinkedp) {
				puts ("Duplicate program function '");
				puts (&fnct->fname);
				puts ("', not linked.\n");
				}
			else linkmod (fnct, *dirtmp.w - 0x205);
			dirtmp.w++;
			}								/* intern & link it */
		cclose (&ibuf);
		}
	}


linklibs()				/* link in library files */
{
	int ifile;

	for (ifile = 0; ifile < nlibs; ++ifile) scanlib (ifile);
	while (missingp ()) {
		puts ("Enter the name of a file to be searched: ");
		gets (&libfiles[nlibs]);
		scanlib (nlibs++);
		}
	acodend.b = codend.b - lspace + buforg;		/* save that number! */
	if (!exts.b) exts.b = acodend.b;
	}


missingp()				/* are any functions missing?  print them out */
{
	int foundp;
	struct funct *fptr;

	foundp = FALSE;
	for (fptr = ftab - 1; fptr >= ftabend; --fptr)
		if (!fptr->flinkedp) {
			if (!foundp) puts ("*** Missing functions:\n");
			puts (&fptr->fname);
			puts ("\n");
			foundp = TRUE;
			}
	return (foundp);
	}


dofixups()				/* perform reverse scan for fixups */
{
	unsigned n;
	struct funct *fptr;

	puts ("\n** Processing fixups **\n");
	if (cwrite (&obuf, lspace, codend.b - lspace) == -1  ||
	    cflush (&obuf) < 0) Fatal ("Disk write error!\n");
	while (buforg != origin) {
		buforg -= origin;	/* make relative to actual file */
		buforg += 0x100;	/* insures overlap and record boundary */
		buforg &= ~0x7f;
		n = (lspcend - lspace) & ~0x7f;	/* even records */
		n = min (n, buforg);
		buforg -= n;
		if (buforg == 0)	/* let hackccc win */
			n = max (n, (cccsize + 0x7f) & ~0x7f);
		if (cseek (&obuf, buforg, ABSOLUTE) < 0  ||
		    cread (&obuf, lspace, n) != n) Fatal ("Disk I/O error!\n");
		codend.b = lspace + n;
		buforg += origin;
		if (debug) printf ("Fixing from 0x%x through 0x%x...\n",
					    buforg, buforg + n - 1);
		for (fptr = ftab - 1; fptr >= ftabend; --fptr)
			if (fptr->flinkedp == LINKED) chase (fptr);
		if (buforg == origin) hackccc ();
		if (cseek (&obuf, buforg - origin, ABSOLUTE) < 0  ||
		    cwrite (&obuf, lspace, n) < 0)
			Fatal ("Couldn't write fixups back!");
		}
     cclose (&obuf);
     stats (STDOUT);
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
	if (mainp) {
		cread (&ibuf, &extp, 1);
		cread (&ibuf, &extstmp, 2);
		cread (&ibuf, &extspc, 2);
		if (extp) exts.b = extstmp;
		else exts.b = 0;						/* will be set later */
		}
	else cseek (&ibuf, 5, RELATIVE);
	for (dir.b = &fdir; *dir.b != 0x80; nextd (&dir)); /* find end of dir */
	++dir.b;
	len = *dir.w - 0x205;
	readobj (len);
	}


readobj (len)				/* read in an object (program or lib funct) */
	unsigned len;
{
	if (codend.b + len >= lspcend) {
		pushout ();
		if (codend.b + len >= lspcend)
			Fatal ("Module won't fit in memory at all!\n");
		}
	lodstart = codend.b;
	if (cread (&ibuf, lodstart, len) < len) Fatal ("-- read error!\n");
	firstfree = codend.b + len;
	}


pushout ()
{
	if (!needfixups) {
		puts ("\n** Out of memory -- fixup scan required **\n");
		needfixups = TRUE;
		}
	if (cwrite (&obuf, lspace, codend.b - lspace) == -1)
		Fatal ("Disk write error!\n");
	buforg += codend.b - lspace;
	codend.b = lspace;
	}

scanlib (ifile)
	int ifile;
{
	struct funct *fptr;
	union ptr dirtmp;

	makeext (&libfiles[ifile], "CRL");
	if (copen (&ibuf, libfiles[ifile]) < 0) {
		printf ("Can't open %s\n", libfiles[ifile]);
		return;
		}
	printf ("<< Scanning %s >>\n", &libfiles[ifile]);
	if (cread (&ibuf, &fdir, 512) < 512)	/* read directory */
		Fatal ("-- Read error!\n");
	for (fptr = ftab - 1; fptr >= ftabend; --fptr)
		if (!fptr->flinkedp  &&
		    (dirtmp.b = dirsearch (&fptr->fname))) {
			readfunct (dirtmp.b);
			linkmod (fptr, 0);
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
	if (cseek (&ibuf, start, ABSOLUTE) < 0) Fatal (" -- read error!");
	readobj (len);
	}


linkmod (fnct, offset)					/* link in a module */
	struct funct *fnct;
	unsigned offset;
{
	union ptr finalloc, temp, body, code, jump;
	unsigned flen, nrelocs, jtsiz;
	struct funct *fptr;

	fnct->flinkedp = LINKED;
	finalloc.u = fnct->faddr = buforg + (codend.b - lspace);
	chase (fnct);
	if (debug)
		printf ("Linking function %s, bufptr = %x, fileptr = %x\n",
			   &fnct->fname, codend.u, finalloc.u);
	body.u = offset + strlen (&lodstart[offset]) + 3;
		/* only an offset here! */

	/* NOTE: everything is done relative to lodstart so that a possible
	   relocation performed by intern does not screw things up */
	jump.i = body.i + (lodstart[offset] ? 1 : 0);
	for (temp.u = offset; lodstart[temp.u];) {
		fptr = intern (&lodstart[temp.u]);
		jump.b = lodstart + jump.u;
		jump.i++->address = fptr;
		jump.u = jump.b - lodstart;
		temp.b = lodstart + temp.u;
		skip7 (&temp.b);
		temp.u = temp.b - lodstart;
		}
	temp.b = lodstart + temp.u;
	++temp.b;

	flen = *temp.w;
	code.b = lodstart + jump.u;
	body.b = lodstart + body.u;	/* now a pointer */
	temp.b = body.b + flen;		/* loc. of reloc parameters */
	nrelocs = *temp.w++;
	jtsiz = code.b - body.b;
	while (nrelocs--) relocate (*temp.w++, body.b, jtsiz,
						   finalloc.b, code.b, flen);
	flen -= jtsiz;
	jtsaved += jtsiz;
	movmem (code.b, codend.b, flen);
	codend.b += flen;
	}


relocate (param, body, jtsiz, base, code, flen)	/* do a relocation!! */
	unsigned param, jtsiz, base, flen;
	union ptr body, code;
{
	union ptr instr,					/* instruction involved */
			ref;						/* jump table link */
	struct funct *fnct;

	if (param == 1) return;				/* don't reloc jt skip */
	instr.b = body.b + param - 1;
	if (instr.i->address >= jtsiz)
		instr.i->address += base - jtsiz;			/* vanilla case */
	else {
		ref.b = instr.i->address + body.u;
		if (instr.i->opcode == LHLD) {
			instr.i->opcode = LXIH;
			--ref.b;
			}
		fnct = ref.i->address;
		if (fnct->flinkedp) instr.i->address = fnct->faddr;
		else	{
			instr.i->address = fnct->fchain;
			fnct->fchain = base + (instr.b + 1 - code.b);
			}
		}
	}


intern (name)				/* intern a function name in the table */
	char *name;
{
	struct funct *fptr;
	int hashcode;
	char *temp;
	unsigned amt;

	if (*name == 0x9D) name = "MAIN";		/* Why, Leor, WHY??? */
	hashcode = 0;
	temp = name;
	do {	if (*temp) hashcode += (hashcode + (*temp & 0x7F));
		else break;
		} while (!(*temp++ & 0x80));
	while (hashcode & ~0xFF) hashcode = (hashcode & 0xFF) + (hashcode >> 8);
	for (fptr = hashtab[hashcode]; fptr != NULL; fptr = fptr->next)
		if (!strcmp7 (name, fptr->fname)) return (fptr);

	lspcend = fptr = --ftabend;
	if (ftabend < firstfree) {
		pushout ();
		amt = firstfree - lodstart;
		movmem (lodstart, lspace, amt);
		lodstart = lspace;
		firstfree = lodstart + amt;
		if (ftabend < firstfree) Fatal ("No more symbol room.\n");
		}

	strcpy7 (fptr->fname, name);
	str7tont (fptr->fname);
	fptr->flinkedp = FALSE;
	fptr->faddr = 0;
	fptr->fchain = 0;
	fptr->next = hashtab[hashcode];
	return (hashtab[hashcode] = fptr);
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


chase (fptr)				/* chase chain of refs to function */
	struct funct *fptr;
{
	union ptr temp;

	while (fptr->fchain >= buforg) {
		if ((temp.b = lspace + (fptr->fchain - buforg)) >= codend.b)
			Fatal ("Chase error, function '%s', chain = 0x%x.\n",
				  &fptr->fname, fptr->fchain);
		fptr->fchain = *temp.w;
		*temp.w = fptr->faddr;
		}
	}


wrtcom()					/* write out com file (from in-mem link) */
{
	hackccc();
	if (cwrite (&obuf, lspace, codend.b - lspace) == -1  ||
	    cflush (&obuf) < 0) Fatal ("Disk write error!\n");
	cclose (&obuf);
	stats (STDOUT);
	}


hackccc()					/* store various goodies in C.CCC code */
{
	union ptr temp;
	struct funct *fptr;

	temp.b = lspace;
	fptr = intern (&mainfunct);
	if (!ovlp) {
		if (!marcp) {
			temp.i->opcode = LHLD;
			temp.i->address = 6;
			(++temp.i)->opcode = SPHL;
			temp.b = lspace + 0xF;			/* main function address */
			temp.i->address = fptr->faddr;
			}
		temp.b = lspace + 0x15;
		*temp.w++ = exts.u;
		++temp.w;
		*temp.w++ = acodend.u;
		*temp.w++ = exts.u + extspc;
		}
	else temp.i->address = fptr->faddr;		/* that's a JMP */
#ifdef MARC
	if (maxmemp) {
		temp.b = lspace + 0x258;
		temp.i->opcode = CALL;
		temp.i->address = 0x50;
		}
#endif
	}


wrtsyms()					/* write out symbol table */
{
	int i, fd, compar();
	struct funct *fptr;
	
	qsort (ftabend, ftab - ftabend, sizeof (*ftab), &compar);
	makeext (&objname, "SYM");
	if (fcreat (&objname, &symbuf) < 0)
		Fatal ("Can't create .SYM file\n");
	for (fptr = ftabend; fptr < ftab; ++fptr) {
		puthex (fptr->faddr, &symbuf);
		putc (' ', &symbuf);
		fputs (&fptr->fname, &symbuf);
		if (i % 4 == 3) fputs ("\n", &symbuf);
		else {
			if (strlen (&fptr->fname) < 3) putc ('\t', &symbuf);
			putc ('\t', &symbuf);
			}
		}
	if (i % 4) fputs ("\n", &symbuf);	
	if (appstatsp) stats (&symbuf);
	putc (CPMEOF, &symbuf);
	fflush (&symbuf);
	fclose (&symbuf);
	if (sepstatsp) {
		makeext (&objname, "LNK");
		if (fcreat (&objname, &symbuf) < 0)
			Fatal ("Can't create .LNK file\n");
		stats (&symbuf);
		putc (CPMEOF, &symbuf);
		fflush (&symbuf);
		fclose (&symbuf);
		}
	}


compar (f1, f2)			/* compare two symbol table entries by name */
	struct funct *f1, *f2;
{
/*	return (strcmp (&f1->fname, &f2->fname));	alphabetical order */
	return (f1->faddr > f2->faddr);			/* memory order */
	}


#ifdef OVERLAYS
loadsyms()				/* load base symbol table (for overlay) */
{						/* symbol table must be empty! */
	int nread;
	FLAG done;
	char *c;
	
	makeext (&symsfile, "SYM");
	if (fopen (&symsfile, &symbuf) < 0) 
		Fatal ("Can't open %s.\n", &symsfile);
	done = FALSE;
	while (!done) {
		if (lspcend - lspace < 0x80) Fatal ("No more room for symbols.");
		nread = fscanf (&symbuf, "%x%s\t%x%s\t%x%s\t%x%s\n",
					 &(ftabend[-1].faddr), &(ftabend[-1].fname),
					 &(ftabend[-2].faddr), &(ftabend[-2].fname),
					 &(ftabend[-3].faddr), &(ftabend[-3].fname),
					 &(ftabend[-4].faddr), &(ftabend[-4].fname));
		nread /= 2;
		if (nread < 4) done = TRUE;
		while (nread-- > 0) (--ftabend)->flinkedp = EXTERNAL;
		lspcend = ftabend;
		}
	fclose (&symbuf);
	}
#endif


stats (chan)				/* print statistics on chan */
	int chan;
{
	unsigned temp;

	fprintf (chan, "\n\nLink statistics:\n");
	fprintf (chan, "  Number of functions: %d\n", ftab - ftabend);
	fprintf (chan, "  Code ends at: 0x%x\n", acodend.u);
	fprintf (chan, "  Externals begin at: 0x%x\n", exts.u);
	fprintf (chan, "  Externals end at: 0x%x\n", exts.u + extspc);
	fprintf (chan, "  Jump table bytes saved: 0x%x\n", jtsaved);
	temp = lspcend;
	if (!needfixups)
		fprintf (chan,
			    "  Link space remaining: %dK\n", (temp - codend.u) / 1024);
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

	while (TRUE) {
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



/* END OF L2.C */
