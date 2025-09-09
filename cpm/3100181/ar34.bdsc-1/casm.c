/*
	CASM.C	-- written by Leor Zolman, 2/82

	CP/M ASM preprocessor: renders MAC.COM and CMAC.LIB unnecessary.

	See CASM.DOC for info.

	Compile and link with:

		cc casm.c -o -e4800

		l2 casm usercode
	(or)	clink casm -f usercode

	(you can skip linking in 'usercode' if you don't care about being
	 able to specify user areas in filenames for the INCLUDE op, but in
	 that case be sure to comment out the USERAREAS define.)
*/

#include <bdscio.h>

#define USERAREAS 1		/* comment this out if you don't care about */
				/* default user areas for included files    */

#define TPALOC	0x100		/* base of TPA in your system 	*/
#define	EQUMAX	500		/* maximum number of EQU ops	*/
#define FUNCMAX	100		/* maximum number of functions  */
#define NFMAX	100		/* maximum number of external
				   functions in one function 	*/
#define LABMAX	150		/* max number of local labels in one func */
#define TXTBUFSIZE 2000		/* max # of chars for labels and needed
				   function names for a single function	*/
#define DEFUSER	"2/"		/* default user area for include files	*/
#define DEFDISK "C:"		/* default disk for include files	*/
#define CASMEXT	".CSM"		/* extension on input files 	*/
#define ASMEXT	".ASM"		/* extension on output files	*/
#define DIRSIZE	512		/* max # of byte in CRL directory 	*/

		/* Global data used throughout processing
		   of the intput file:			*/

char	fbuf[BUFSIZ];		/* I/O buffer for main input file	*/
char	incbuf[BUFSIZ];		/* I/O buffer for included file 	*/
char	obuf[BUFSIZ];		/* I/O buffer for output file		*/

char	*cbufp;			/* pointer to currently active input buf */
char	*cfilnam;		/* pointer to name of current input file */
char	nambuf[30],		/* filenames for current intput */
	nambuf2[30],		/* and output files.		*/
	onambuf[30];

char	*equtab[EQUMAX];	/* table of absolute symbols	*/
int	equcount;		/* # of entries in equtab	*/

char	*fnames[FUNCMAX];	/* list of functions in the source file */
int	fcount;			/* # of entries in fnames		*/

int	lino,savlino;		/* line number values used for error 	*/
				/* reporting.				*/

char	doingfunc;		/* true if currently processing a function */

char	errf;			/* true if an error has been detected	*/

		/* Global data used during the processing of a
		   single function in the source file:		*/

char	*nflist[NFMAX];		/* list of needed functions for a function */
int	nfcount;		/* number of entries in nflist	*/

struct {
	char *labnam;		/* name of function label */
	char defined;		/* whether it has been defined yet */
} lablist[LABMAX];

int	labcount;		/* number of local labels in a function */

char	txtbuf[TXTBUFSIZE],	/* where text of needed function names	*/
	*txtbufp;		/* and function labels go		*/

char 	linbuf[150],		/* text line buffers	*/
	linsav[150],
	workbuf[150],
	pbuf[150], *pbufp;

char	*cfunam;		/* pointer to name of current function */
int	relblc;			/* relocation object count for a function */

char	pastnfs;		/* true if we've passed all needed function */
				/* declarations ("external" pseudo ops)	    */

int	argcnt;			/* values set by the "parse_line" function */
char	*label,
	*op,
	*argsp,
	*args[40];

char 	*gpcptr;		/* general-purpose text pointer	*/

/*
 * Open main input file, open output file, initialize needed globals
 * and process the file:
 */

main(aarghc,aarghv)
char **aarghv;
{
	int i,j,k;
	char c;

	puts("BD Software CRL-format ASM Preprocessor v1.46\n");

	initequ();		/* initialize EQU table with reserved words */
	fcount = 0;		/* haven't seen any functions yet */
	doingfunc = 0;		/* not currently processing a function */
	errf = 0;		/* no errors yet */

	if (aarghc != 2)
		exit(puts("Usage:\ncasm <filename>\n"));

				/* set up filenames with proper extensions: */

	for (i = 0; (c = aarghv[1][i]) && c != '.'; i++)
		nambuf[i] = c;
	nambuf[i] = '\0';
	strcpy(onambuf,nambuf);
	strcat(nambuf,CASMEXT);		/* input filename */
	cbufp = fbuf;			/* buffer pointer */
	cfilnam = nambuf;		/* current filename pointer */
	if (fopen(cfilnam,cbufp) == ERROR)
		exit(printf("Can't open %s\n",cfilnam));

	strcat(onambuf,ASMEXT);		/* output filename */
	if (fcreat(onambuf,obuf) == ERROR)
		exit(printf("Can't open %s\n",onambuf));

					/* begin writing output file */
	fprintf(obuf,"\nTPALOC\t\tEQU\t%04xH\n",TPALOC);

	lino = 1;			/* initialize line count */

	while (get_line()) {		/* main loop */
		process_line();		/* process lines till EOF */
		lino++;
	}

	if (doingfunc)			/* if ends inside a function, error */
		abort("File ends, but last function is unterminated\n");

	fputs("\nEND$CRL\t\tEQU\t$-TPALOC\n",obuf);	/* end of functions */
	fputs("SECTORS$ EQU ($-TPALOC)/256+1 ;USE FOR \"SAVE\" !.\n",obuf);
	putdir();			/* now spit out CRL directory */
	fputs("\t\tEND\n",obuf);	/* end of file */
	putc(CPMEOF,obuf);		/* CP/M EOF character */
	fclose(cbufp);			/* close input file */
	fflush(obuf);			/* flush and close output file */
	fclose(obuf);
	if (errf)
		printf("Fix those errors and try again...\n");
	else
		printf("\n%s is ready to be assembled.\n",onambuf);
}

/*
 * Get a line of text from input stream, and process
 * "include" ops on the fly:
 */

int get_line()
{
	int i;

	if (!fgets(linbuf,cbufp)) {		/* on EOF: */
		if (cbufp == incbuf) {		/* in an "include" file? */
			fabort(cbufp->_fd);		/* close the file */
			cbufp = fbuf;		/* go back to mainline file */
			cfilnam = nambuf;
			lino = savlino + 1;
			return get_line();
		}
		else return NULL;
	}

	parse_line();				/* not EOF. Parse line */
	if (streq(op,"INCLUDE")  ||		/* check for file inclusion */
	    streq(op,"MACLIB")) {
		if (cbufp == incbuf)		/* if already in an include, */
		 abort("Only one level of inclusion is supported"); /* error */
		if (!argsp)
		 abort("No filename specified");
		cbufp = incbuf;			/* set up for inclusion */
		savlino = lino;
		lino = 1;

		for (i = 0; !isspace(argsp[i]); i++)	/* put null after */
			;				/* filename	  */
		argsp[i] = '\0';

		*nambuf2 = '\0';

		if (*argsp == '<') {		/* look for magic delimiters */
#ifdef USERAREAS
			strcpy(nambuf2,DEFUSER);
#endif
			if (argsp[2] != ':')	/* if no explicit disk given */
				strcat(nambuf2,DEFDISK); /* then use default */
			strcat(nambuf2,argsp+1);
			if (nambuf2[i = strlen(nambuf2) - 1] == '>')
				nambuf2[i] = '\0';
		} else if (*argsp == '"') {
			strcpy(nambuf2,argsp+1);
			if (nambuf2[i = strlen(nambuf2) - 1] == '"')
				nambuf2[i] = '\0';
		} else
			strcpy(nambuf2,argsp);

		if (fopen(nambuf2,cbufp) == ERROR) {
			if (nambuf2[strlen(nambuf2) - 1] != '.') {
				strcat(nambuf2,".LIB");
				if (fopen(nambuf2,cbufp) != ERROR)
					goto ok;
			}			    
			printf("Can't open %s\n",nambuf2);
			abort("Missing include file");
		}

	ok:	cfilnam = nambuf2;
		return get_line();
	}
	return 1;
}

parse_line()
{
	int i;
	char c;

	label = op = argsp = NULL;
	argcnt = 0;

	strcpy2(pbuf,linbuf);
	strcpy2(linsav,linbuf);
	pbufp = pbuf;

	if (!isspace(c = *pbufp)) {
		if (c == ';')
			return;		/* totally ignore comment lines */
		label = pbufp;		/* set pointer to label	*/
		while (isidchr(*pbufp))	/* pass over the label identifier */
			pbufp++;
		*pbufp++ = '\0';	/* place null after the identifier */
	}

	skip_wsp(&pbufp);
	if (!*pbufp || *pbufp == ';')
		return;
	op = pbufp;			/* set pointer to operation mnemonic */
	while (isalpha(*pbufp))
		pbufp++;  		/* skip over the op 		*/
	if (*pbufp) *pbufp++ = '\0';	/* place null after the op	*/


					/* now process arguments	*/
	skip_wsp(&pbufp);
	if (!*pbufp || *pbufp == ';')
		return;
	argsp = linsav + (pbufp - pbuf);	/* set pointer to arg list */

					/* create vector of ptrs to all args
					   that are possibly relocatable */
	for (argcnt = 0; argcnt < 40;) {
		while (!isidstrt(c = *pbufp))
			if (!c || c == ';')
				return;
			else
				pbufp++;

		if (isidchr(*(pbufp - 1))) {
			pbufp++;
			continue;
		}

		args[argcnt++] = pbufp;			
		while (isidchr(*pbufp)) pbufp++;
		if (*pbufp) *pbufp++ = '\0';
	}
	error("Too many operands in this instruction for me to handle\n");
}

process_line()
{
	char *cptr, c;
	int i,j;

	if (op) {
			/* check for definitions of global data that will be
			   exempt from relocation when encountered in the
			   argument field of assembly instructions: 	   */

	   if (streq(op,"EQU") || streq(op,"SET") ||
		(!doingfunc &&
			(streq(op,"DS") || streq(op,"DB") || streq(op,"DW"))))
	   {
		fputs(linbuf,obuf);
		cptr = sbrk2(strlen(label) + 1);
		strcpy(cptr,label);
		equtab[equcount++] = cptr;
		if (equcount >= EQUMAX)
			abort(
		  "Too many EQU lines...increase 'EQUMAX' and recompile CASM");
		return;
	   }

	   if (streq(op,"EXTERNAL")) {
		if (!doingfunc) abort(
		 "'External's for a function must appear inside the function");
		if (pastnfs) error(
		 "Externals must all be together at start of function\n");
		for (i = 0; i < argcnt; i++) {
			nflist[nfcount++] = txtbufp;
			strcpy(txtbufp,args[i]);
			bumptxtp(args[i]);
		}
		if (nfcount >= NFMAX) {
		  printf("Too many external functions in function \"%s\"\n",
					cfunam);
		  abort("Change the NFMAX constant and recompile CASM");
		}
		return;
	   }

	   if (streq(op,"FUNCTION")) {
		if (!fcount) {
			fputs("\n; dummy external data information:\n",obuf);
			fputs("\t\tORG\tTPALOC+200H\n",obuf);
			fputs("\t\tDB\t0,0,0,0,0\n",obuf);
		}

		if (doingfunc) {
			printf("'Function' op encountered in a function.\n");
			abort("Did you forget an 'endfunc' op?");
		}
		if (!argcnt)
			abort("A name is required for the 'function' op");

		cfunam = sbrk2(strlen(args[0]) + 1);
		fnames[fcount++] = cfunam;
		strcpy(cfunam,args[0]);

		printf("Processing the %s function...          \r",cfunam);

		doingfunc = 1;
		txtbufp = txtbuf;
		labcount = 0;
		nfcount = 0;
		pastnfs = 0;
		fprintf(obuf,"\n\n; The \"%s\" function:\n",cfunam);
		fprintf(obuf,"%s$BEG\tEQU\t$-TPALOC\n",cfunam);
		return;
	   }

	   if (streq(op,"ENDFUNC") || streq(op,"ENDFUNCTION")) {
		if (!doingfunc)
		  abort("'Endfunc' op encountered while not in a function");

		if (!pastnfs) flushnfs();    /* flush needed function list */
		fprintf(obuf,"%s$END\tEQU\t$\n",cfunam);
		doreloc();		     /* flush relocation parameters */

		for (i = 0; i < labcount; i++)	/* detect undefined labels */
		  if (!lablist[i].defined) {
			printf("The label %s in function %s is undefined\n",
					lablist[i].labnam,cfunam);
			errf = 1;
		  }
		doingfunc = 0;
		return;
	   }
	}

	if (streq(op,"RELOC") || streq(op,"DWREL") || streq(op,"DIRECT") ||
	    streq(op,"ENDDIR") || streq(op,"EXREL") || streq(op,"EXDWREL") ||
	    streq(op,"PRELUDE") || streq(op,"POSTLUDE") || streq(op,"DEFINE"))
		error("Old macro leftover from \"CMAC.LIB\" days...\n");

				/* No special pseudo ops, so now process
				   the line as a line of assemby code: 	*/

	if (streq(op,"END")) return;		/* don't allow "end" yet     */

	if (!doingfunc || (!label && !op))	/* if nothing interesting on */
		return fputs(linbuf,obuf);	/* line, ignore it	*/

	if (!pastnfs)				/* if haven't flushed needed */
		flushnfs();			/* function list yet, do it  */

						/* check for possible label  */
	if (label) {
		fprintf(obuf,"%s$L$%s\t\tEQU\t$-%s$STRT\n",
			cfunam, label, cfunam);
		for (i=0; linbuf[i]; i++)
			if (isspace(linbuf[i]) || linbuf[i] == ':')
				break;
			else
				linbuf[i] = ' ';
		if (linbuf[i] == ':') linbuf[i] = ' ';
		for (i = 0; i < labcount; i++)	  /* check if in label table */
		  if (streq(label,lablist[i].labnam)) {	        /* if found, */
			if (lablist[i].defined) {  /* check for redefinition */
				error("Re-defined label:");
				printf("%s, in function %s\n",
						lablist[i].labnam,cfunam);
			}
			 else
				lablist[i].defined = 1;
			goto out;
		  }
		lablist[i].labnam = txtbufp;	/* add new entry to */
		lablist[i].defined = 1;		/* label list 	    */
		strcpy(txtbufp,label);
		bumptxtp(label);
		labcount++;
	}
out:
	if (!op) return fputs(linbuf,obuf);	/* if label only, all done   */

						/* if a non-relocatable op,  */
	if (norelop(op)) return fputs(linbuf,obuf);	/* then we're done   */

	if (argcnt && doingfunc)
	  for (i = 0; i < argcnt; i++) {
		if (norel(args[i])) continue;
		if (gpcptr = isef(args[i]))
		   sprintf(workbuf,"%s$EF$%s-%s$STRT",
				cfunam,gpcptr,cfunam);
		else {
			sprintf(workbuf,"%s$L$%s",cfunam,args[i]);
			for (j = 0; j < labcount; j++)
				if (streq(args[i],lablist[j].labnam))
					goto out2;
			lablist[j].labnam = txtbufp;	/* add new entry to */
			lablist[j].defined = 0;		/* label list 	    */
			strcpy(txtbufp,args[i]);
			bumptxtp(txtbufp);
			labcount++;
		}		   

	out2:
		replstr(linbuf, workbuf, args[i] - pbuf, strlen(args[i]));

		if (streq(op,"DW")) {
			fprintf(obuf,"%s$R%03d\tEQU\t$-%s$STRT\n",
				cfunam, relblc++, cfunam);
			if (argcnt > 1)
			  error("Only one relocatable value allowed per DW\n");
		}
		else
			fprintf(obuf,"%s$R%03d\tEQU\t$+1-%s$STRT\n",
				cfunam, relblc++, cfunam);
		break;
	  }
	fputs(linbuf,obuf);
}


/*
	Test for ops in which there is guanranteed to be no need
	for generation of relocation parameters. Note that the list
	of non-relocatable ops doesn't necessarily have to be complete,
	because for any op that doesn't match, an argument must still
	pass other tests before it is deemed relocatable. This only
	speeds things up by telling the program not to bother checking
	the arguments.
*/

norelop(op)
char *op;
{
	if (streq(op,"MOV")) return 1;
	if (streq(op,"INR")) return 1;
	if (streq(op,"DCR")) return 1;
	if (streq(op,"INX")) return 1;
	if (streq(op,"DCX")) return 1;
	if (streq(op,"DAD")) return 1;
	if (streq(op,"MVI")) return 1;
	if (streq(op,"DB")) return 1;
	if (streq(op,"DS")) return 1;
	if (op[2] == 'I') {
		if (streq(op,"CPI")) return 1;
		if (streq(op,"ORI")) return 1;
		if (streq(op,"ANI")) return 1;
		if (streq(op,"ADI")) return 1;
		if (streq(op,"SUI")) return 1;
		if (streq(op,"SBI")) return 1;
		if (streq(op,"XRI")) return 1;
		if (streq(op,"ACI")) return 1;
	}
	if (streq(op,"ORG")) return 1;
	if (streq(op,"TITLE")) return 1;
	if (streq(op,"PAGE")) return 1;
	if (streq(op,"IF")) return 1;
	if (streq(op,"EJECT")) return 1;
	if (streq(op,"MACRO")) return 1;
	return 0;
}


flushnfs()
{
	int i,j, length;

	pastnfs = 1;
	relblc = 0;

	fputs("\n\n; List of needed functions:\n",obuf);
	for (i=0; i < nfcount; i++) {
		strcpy(workbuf,"\t\tDB\t'");
		length = strlen(nflist[i]);
		length = length < 8 ? length : 8;
		for (j = 0; j < length - 1; j++)
			workbuf[6+j] = nflist[i][j];
		workbuf[6+j] = '\0';
		fprintf(obuf,"%s','%c'+80H\n",workbuf,nflist[i][j]);
	}

	fputs("\t\tDB\t0\n",obuf);
	fputs("\n; Length of body:\n",obuf);
	fprintf(obuf,"\t\tDW\t%s$END-$-2\n",cfunam);
	fputs("\n; Body:\n",obuf);
	fprintf(obuf,"%s$STRT\tEQU\t$\n",cfunam);
	if (nfcount) {
		fprintf(obuf,"%s$R%03d\tEQU\t$+1-%s$STRT\n",
			cfunam,relblc++,cfunam);
		fprintf(obuf,"\t\tJMP\t%s$STRTC-%s$STRT\n",cfunam,cfunam);
	}
	fprintf(obuf,"%s$EF$%s\tEQU\t%s$STRT\n",cfunam,cfunam,cfunam);
	for (i=0; i < nfcount; i++)
		fprintf(obuf,"%s$EF$%s\tJMP\t0\n",cfunam,nflist[i]);
	fprintf(obuf,"\n%s$STRTC\tEQU\t$\n",cfunam);
}


doreloc()
{
	int i;
	fputs("\n; Relocation parameters:\n",obuf);
	fprintf(obuf,"\t\tDW\t%d\n",relblc);
	for(i = 0; i < relblc; i++)
		fprintf(obuf,"\t\tDW\t%s$R%03d\n",cfunam,i);
	fputs("\n",obuf);
}


putdir()
{
	int i,j, length;
	int bytecount;

	bytecount = 0;

	fputs("\n\t\tORG\tTPALOC\n\n; Directory:\n",obuf);
	for (i = 0; i < fcount; i++) {
		strcpy(workbuf,"\t\tDB\t'");
		length = strlen(fnames[i]);
		length = length < 8 ? length : 8;
		for (j = 0; j < length - 1; j++)
			workbuf[6+j] = fnames[i][j];
		workbuf[6+j] = '\0';
		fprintf(obuf,"%s','%c'+80H\n",workbuf,fnames[i][j]);
		fprintf(obuf,"\t\tDW\t%s$BEG\n",fnames[i]);
		bytecount += (length + 2);
	}
	fputs("\t\tDB\t80H\n\t\tDW\tEND$CRL\n",obuf);

	bytecount += 3;
	if (bytecount > DIRSIZE) {
		printf("CRL Directory size will exceed 512 bytes;\n");
		printf("Break the file up into smaller chunks, please!\n");
		exit(-1);
	}
}


initequ()
{
	equtab[0] = "A";
	equtab[1] = "B";
	equtab[2] = "C";
	equtab[3] = "D";
	equtab[4] = "E";
	equtab[5] = "H";
	equtab[6] = "L";
	equtab[7] = "M";
	equtab[8] = "SP";
	equtab[9] = "PSW";
	equtab[10]= "AND";
	equtab[11]= "OR";
	equtab[12]= "MOD";
	equtab[13]= "NOT";
	equtab[14]= "XOR";
	equtab[15]= "SHL";
	equtab[16]= "SHR";
	equcount = 14;
}


int isidchr(c)	/* return true if c is legal character in identifier */
char c;
{	
	return isalpha(c) || c == '$' || isdigit(c) || c == '.';
}


int isidstrt(c)	/* return true if c is legal as first char of idenfitier */
char c;
{
	return isalpha(c);
}


int streq(s1, s2)	/* return true if the two strings are equal */
char *s1, *s2;
{
	if (*s1 != *s2) return 0;	/* special case for speed */
	while (*s1) if (*s1++ != *s2++) return 0;
	return (*s2) ? 0 : 1;
}


skip_wsp(strptr)	/* skip white space at *strptr and modify the ptr */
char **strptr;
{
	while (isspace(**strptr)) (*strptr)++;
}


strcpy2(s1,s2)	/* copy s2 to s1, converting to upper case as we go */
char *s1, *s2;
{
	while (*s2)
	     *s1++ = toupper(*s2++);
	*s1 = '\0';
}


/*
	General-purpose string-replacement function:
		'string'	is pointer to entire string,
		'insstr'	is pointer to string to be inserted,
		'pos'		is the position in 'string' where 'insstr'
				is to be inserted
		'lenold'	is the length of the substring in 'string'
				that is being replaced.
*/

replstr(string, insstr, pos, lenold)
char *string, *insstr;
{
	int length, i, j, k, x;

	length = strlen(string);
	x = strlen(insstr);
	k = x - lenold;
	i = string + pos + lenold;
	if (k) movmem(i, i+k, length - (pos + lenold) + 1);
	for (i = 0, j = pos; i < x; i++, j++)
		string[j] = insstr[i];
}


error(msg)
char *msg;
{
	printf("\n\7%s: %d: %s ",cfilnam,lino,msg);
	errf = 1;
}


abort(msg)
char *msg;
{
	error(msg);
	putchar('\n');
	if (cbufp == incbuf) fclose(incbuf);
	fclose(fbuf);
	exit(-1);
}


sbrk2(n)	/* allocate storage and check for out of space condition */
{
	int i;
	if ((i = sbrk(n)) == ERROR)
		abort("Out of storage allocation space\n");
	return i;
}

bumptxtp(str)	/* bump txtbufp by size of given string + 1 */
char *str;
{
	txtbufp += strlen(str) + 1;
	if (txtbufp >= txtbuf + (TXTBUFSIZE - 8))
	 abort("Out of text space. Increase TXTBUFSIZE and recompile CASM");
}


int norel(id)	/* return true if identifier is exempt from relocatetion */
char *id;
{
	if (isequ(id)) return 1;
	return 0;
}


int isequ(str)	/* return true if given string is in the EQU table */
char *str;
{
	int i;
	for (i = 0; i < equcount; i++)
		if (streq(str,equtab[i]))
			return 1;
	return 0;
}


char *isef(str)	/* return nflist entry if given string is an external */
char *str;	/* function name */
{
	int i;
	for (i = 0; i < nfcount; i++)
		if (streq(str,nflist[i]))
			return nflist[i];
	return 0;
}

