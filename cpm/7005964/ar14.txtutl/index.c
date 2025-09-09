/********************************************************
*							*
*			INDEX				*
*	       Text file index generator.		*
*							*
*		  T. Jennings 7/21/81			*
*		  221 W. Springfield St.		*
*		  Boston MA 02118			*
*		 					*
*							*
*********************************************************

	INDEX Generates an ASCII WordStar (or equiv.) compatible
	index from a text file. Words to be indexed are marked
	with a control character. Entire phrases can be indexed
	as well, by marking both ends with a different character.

	The index generated will be sorted alphabetically, with
	the first character of all entries in caps. Each entry
	will contain the page number as well.

	Two control characters, ^K and ^P are used. ^K marks
	single words, and ^P marks phrases. Phrases too long
	will be truncated to fit.

Examples: 
	The sixth word in this ^Ksentence will be put in the index.

	^PThis entire phrase^P will be indexed.

	The index for these two items, once printed, would look
	like:

	Sentence .................................... 2
	This entire phrase .......................... 3

See INDEX.DOC for details
*/

#include <bdscio.h>
#define WORD_MARK 0x0b			/* The single word marker */
#define	PHRASE_MARK 0x10		/* Phrase marker */
#define CONTROLZ 0x1a
#define CR 0x0d				/* useful ASCII characters */
#define LF 0x0a
#define WORD_LEN 39			/* maximum word or phrase size */
#define LAST_COL 40			/* column to start page # */
#define PAGE_LEN 66			/* default lines per page */
#define DEF_LMARGIN 8			/* default left margin, */
#define DEF_RMARGIN 72			/* ... and right margin */

char c;					/* a useful variable for everyone */
int char_count;				/* # characters looked at in file, */
int word_count;				/* # words looked at */
int line_count;				/* ditto lines */
int this_line;				/* current line #/page */
int entries;				/* # entries in index */
int this_page;				/* current page */
int page_size;				/* current max page length */
int lmargin,rmargin;			/* current left and right margins */
int found_index;			/* true if old index found */

char inbuf[BUFSIZ];			/* text input buffer */
char outbuf[BUFSIZ];
char inname[12];			/* where we save ASCII filenames */
char outname[12];
char tempname[12];

char pile[32768];	/* kludge */	/* Awaiting dynamic storage */
char *i;				/* index pointer */
char *pointers[1024];			/* pile pointers for sorting */
change_page()				/* dummy function to start a new */
{}					/* page here. */
/* System interface for INDEX. Make sure theres at least one argument (the
filename). Open it for reading, (error check) make a temporary file for
output (filename.$I$) (error check). Then...

1/	Read the file sequentially, looking for marked words, 	[ index()  ]
2/	Cleanup the pile of entries (remove leading blanks, convert each
	1st character to uper case)				[ cleanup() ]
3/	Sort the pile alphabeticlly				[ sort()   ]
4/	Dump the pile to the disk, expanding each to correct width,
	and removing duplicate entries				[ dump()  ]
5/	Return to CP/M
 */
main(argc,argv)
int argc;
char *argv[];
{
	printf ("\nINDEX-- Text file Index generator (c) T. Jennings 7/21/81");
	page_size =PAGE_LEN;
	lmargin =DEF_LMARGIN;
	rmargin =DEF_RMARGIN;
	found_index =FALSE;

	if (--argc >0)
	{	strcpy (inname,argv[1]);	/* save the names, */
		strcpy (outname,argv[1]);

		if (fopen(inname,inbuf) ==ERROR) /* try to open source file,*/
		{	printf ("\nCan't open %s",inname);
			exit();
		}
		add_ext (outname,"$I$");	/* make the output file, */
		if (fcreat(outname,outbuf) ==ERROR) /* reuse and destroy name*/
		{	printf ("\nCan't create temporary file %s",outname);
			exit();
		}
	}
	else
	{	printf ("\nSpecify a file to make an index from");
		exit();
	}
	printf ("\nAdding an index to %s (removing any old index first)",inname);
	index();		/* scan the file, */
	cleanup();		/* convert each 1st char to upper case */
	printf ("\nSorting, ");
	sort();			/* sort it, */
	printf ("saving it, ");
	dump();			/* write it to the disk, */
	printf ("cleaning up, ");

	strcpy (tempname,inname);/* delete any .BAK */
	add_ext (tempname,"BAK");
	unlink (tempname);
	rename (inname,tempname);/* rename original to .BAK, */
	rename (outname,inname); /* rename new to original */

	printf ("done.\n");
	exit();			/* exit. */
}
/* Read the input file, and make a list of words to index. Maintain
the global variables indicating word count, etc. Leave a pile of
strings, followed by the page #, terminated with a control-z. 

When done, PILE[] will have sequential null terminated strings, terminated
by a single control-z. Each pointer in POINTERS[] will point to the start
of each string, with the last pointing to the control-z.

KLUDGE: No limit check is done on the size of the pile, nor the size
of POINTERS. (currently 1024 entries, 32 char. each) */

index()
{
int inword;			/* blank or character flag */
int gotword;			/* true if saving this word */
int gotphrase;			/* true if saving this phrase */
int entry_len;			/* size of word or phrase */
char linebuf[132];		/* character line buffer */
int j;
int last_char_blank;		/* suppress mult. spaces 'tween lines */
int k;
	inword =FALSE;		/* no word yet, */
	gotword =FALSE;		/* no marked word found, */
	gotphrase =FALSE;	/* no marked phrase found, */
	last_char_blank =FALSE;	/* too early... */

	i =pile; 		/* set the pointers, ... */
	k=0;
	char_count =0;
	word_count =0;		/* and our booleans */
	line_count =0;
	entries =0;
	this_page =1;
	this_line =1;

	while (fill_line(linebuf) !=CONTROLZ)		/* while not EOF, */
	{	if (scan_line(linebuf) ==TRUE)		/* look for dot cmds */
			break;				/* get next line */
		j=0;
		++line_count;				/* count total lines,*/
		if (this_line++ >= page_size)		/* current line, */
		{	this_line =1;
			++this_page;
		}
		while ((c =linebuf[j++]) !=0x00)	/* while not end/line*/
		{	++char_count;
			if (c== ' ')
			{	inword =FALSE;		/* end of a word */
				if (gotword)		/* if we were looking*/
				{	++i;		/* leave null to mark*/
					sprintf(i,"%2d",this_page);
					while (*i++);	/* point to next */
 					++entries;	/* count another */
					gotword =FALSE;	/* done with word */
				}
			}
			else if (inword ==FALSE)	/* non-white char */
			{	inword =TRUE;
				++word_count;
			}

			if (c==WORD_MARK)	/* new word to save */
			{	gotword =TRUE;	/* start saving next char */
				entry_len =0;
				pointers[k++] =i;/* set the pointer */
			}
			else if (c== PHRASE_MARK)
			{	if (gotphrase)	/* if we had one before, */
				{	++i;	/* let the last null mark it */
					sprintf(i,"%2d",this_page);
					while (*i++);
					++entries; /* counter another */
					gotphrase =FALSE;
				}
				else /* new phrase */
				{	gotphrase =TRUE; /* else start now. */
					entry_len =0;	/* just starting */
					pointers[k++] =i;/* point to it */
				}
			}
            /* see if we should store a character */
			else if (  (gotphrase || gotword) &&
				   (entry_len++ <WORD_LEN) &&
				   (c >=' ') && (c !='.') &&
				   !(last_char_blank && c==' ')  )
			{	*i++ =c;	/* were saving now */
				*i =0x00;	/* null terminate it always, */
				last_char_blank= (c==' '? TRUE : FALSE);
			}
		}
	}
	*i =CONTROLZ;			/* mark the top of the pile, */
	pointers[k++] =i;		/* set its pointer */
	printf ("\n Put %d words in the index ",entries);
	printf ("out of a total of %d words.",word_count);
	return;
}
/* Sort routine. The array (pile) contains the index entries in no particular
order. Array of pointers points to each entry. Put the entire pile in ascending
alphabetic order. Very rude sort routine. (interchange) */

sort()
{
int first,last;
char *temp;
int changing;

	do
	{
		first =0;
		last =1;
		changing =FALSE;
		while (*pointers[last] !=CONTROLZ)
		{	if (comp (pointers[first],pointers[last]) >0)
			{	temp =pointers[first];
				pointers[first] =pointers[last];
				pointers[last] =temp;
				changing =TRUE;
			}
			++first; ++last;
		}
	}
	while (changing);	/* until we make a do-nothing pass */
	return;						
}
/* Compare two strings. Return 0 if equal, >0 if first is greater than last,
<0 if first less than last. Ignores case. */

int comp(first,last)
char *first;
char *last;
{
int i;
	while (toupper(*first) ==toupper(*last) )
	{	if (*first == 0x00)		/* stop at the null(if we got*/
			return (0)		/* this far, it matched */
		;
	++first; ++last;
	}
	i =(toupper(*first) -toupper(*last));	/* mismatch */
	return (i);
}
/* Compare two strings, of a given length. Check only for equality. Return
0 if equal, else 1. */

compl(length,first,last)
int length;
char *first,*last;
{
	for (; length >0; length--)
	{	if (  (toupper(*first++)) != (toupper(*last++))  )
			return (1)
		;
	}
	return (0);
}
/* Dump the pile to the disk. Convert each entry to a single line, making each
an even number of columns wide. Put the page number at the end. Look for
duplicate entries, and remove them. */
dump()
{
int column;
int i,x;
char *current_entry;
char *j;
char c;
int local_i;

	column =0;
	i =0;
	if (found_index ==FALSE)		/* dont duplicate this */
	{	sendstr ("\015\012.pa");	/* if its already there */
		sendstr ("\015\012..index\015\012");
	}
	while (*pointers[i] !=CONTROLZ)
	{	j =pointers[i++];		/* send chars until null */
		if (*j !=0xff)			/* if its a deleted dup copy, */
		{					/* skip this */
			current_entry =j;		/* else save a copy, */
			for (x =lmargin; x>0; x--)	/* tab to left margin */
				putc(' ',outbuf)
			;
			while (c =*j++)
			{	putc (c,outbuf);
				++column;
			}
			while (column++ <LAST_COL)	/* make an entry */
				putc ('.',outbuf)	/* tab over, */
			;
			putc (' ',outbuf);		/* type the page # */
			while (c =*j++)
				putc (c,outbuf)
			;
/* Look for duplicate entries; if we find one, remove it (mark 0xff) and 
output it's page # on the current one. If more than 5, stop, and start the
rest on the next line. */
			local_i =0;
			if (*pointers[i] !=CONTROLZ)
			{	while ((comp(current_entry,pointers[i+local_i]) ==0) && (local_i <6) )
				{	j =pointers[i+local_i++];
					*j =0xff;	/* mark it removed */
					while (*j++)	/* skip the entry, */
					;
					putc (',',outbuf);/* type a comma, */
					while (c =*j++)	/* send the page # */
						putc (c,outbuf)
					;
				}
			}
			putc (CR,outbuf);		/* new line, */
			putc (LF,outbuf);
			column =0;			/* next line */
		}
	}
	putc (CONTROLZ,outbuf);
	fflush (outbuf);
	fclose (outbuf);
	return;
}
/* Fill a line buffer with characters. Convert all white_space characters
to a single blank, put a null at the end. Copy each character to the output
file. */

fill_line(buffer)
char buffer[];
{
int i;
char c;
char d;
int temp;
int inblank;				/* true to suppress blanks */

	inblank =FALSE;
	i=0;

	do
	{	temp =getc(inbuf);
		if (temp ==ERROR)
			return (CONTROLZ)	/* check physical end */
		;
		d =temp;			/* type conversion */
		if (d ==CONTROLZ)		/* dont send the control-z */
			return (d)
		;
		putc (d,outbuf);
		c =d&0x7f;
		if (c== ' ' || c== ',' || c== '\t' || c==CR || c==LF
		   || c=='!' || c==';' || c==':' )
			c=' '
		;
		if ((c !=' ') || (inblank==FALSE))
		{	buffer[i++] =c;
			buffer[i] =0x00;
		}
		inblank =(c ==' ' ? TRUE : FALSE);
		d &=0x7f;
	}
	while	((d !=LF) && (d !=CONTROLZ) && (i <132))
	;
	return(d);
}
/* Scan for dot commands. When and if we find a dot command, fool the 
caller into thinking that the line we were passed is now empty. 
If we find the index mark, "..index", set the flag so we dont duplicate
it at dump time. */

scan_line(buffer)
char *buffer;
{
int i;
	while (*buffer ==' ')		/* skip leading blanks, */
		++buffer
	;
	if (*buffer =='.')		/* as per WS specs, must be first atom */
	{	if (compl (3,buffer,".pa") ==0)
		{	++this_page;
			this_line =0;
		}
		else if (compl (7,buffer,"..index") ==0)
		{	*buffer =0x00;
			found_index =TRUE;
			return (TRUE);
		}
	}
	return (FALSE);
}
/* Clean up the pile by converting each first character to upper
case. Deletes leading blanks by adjusting the pointer, but only if
the string is more than 1 char long. */

cleanup()
{
int i;
char c;
	i =0;
	while ((c= toupper(*pointers[i])) !=CONTROLZ)
	{	if ((*pointers[i] ==' ') && (*pointers[i+1] !=0x00))
		{	++(pointers[i]);
			c =toupper(*pointers[i]);
		}
		*pointers[i++] =c;
	}
	return;
}
/* Replace the extention on a filename, to the string we are passed. Note that
only the first 3 chars are significant, and it is assumed the filename exists
and is legal. */
add_ext(filename,ext)
char *filename;
char *ext;
{
int i;
	for (i=0; (i<9); i++)		/* look for the dot, or 8 chars, */
	{	if ((*filename =='.') || (*filename ==0x00))
			break
		;
		filename++;
	}
	*filename++ ='.';		/* add a dot, */
	while (*filename++ =*ext++)	/* the new extention */
	;
}
/* Send an ascii string to the output file */
sendstr(string)
char *string;
{
	while (*string)
	{	putc (*string++,outbuf);
	}
}
