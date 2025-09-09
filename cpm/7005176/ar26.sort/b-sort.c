/*
	B-SORT		a sorting program

	This is a self-contained file except for the standard included
	definitions and is part of the  larger development of a message-
	retrieval system. Since the algorithms involved are well known
	it is felt that putting this program in public domain would serve
	a useful purpose, namely provide some examples of some programming
	techniques using the 'C' language. The compiler used is the BDS
	vs 1.46 and use is made of at least one special feature of this
	compiler(see 'printf' function).

	Nominally this is a sorting program and can certainly be used for
	that purpose. However, since the main benefit of using a B-tree is
	when using disk-based structures, it is quite possible that this
	will not be your hot-dog sort utility. It is relatively fast though
	and I would be interested in any comparisons anyone makes. A later
	effort is planned to build a virtual memory support package which
	will then allow the 'nodes' of the b-tree to be stored as disk
	sectors and at that point this program will allow sorting of
	arbitrarily large text files. Again, that is still not the main
	objective for it, information retrieval is.

	I will not attempt to give even an introduction to B-trees here. My
	primary reference and, in fact, the bareface source of this program
	is N. Wirth's wonderful book "Algorithms+Data Structures=Programs".
	I passed this book up several times in the past, but when I was 
	looking for a treatment of this subject, I found that it had a very
	nice balance between explanation and example(the best way I learn)
	and since 'C' and PASCAL are 'kissin cousins', it was 'straight
	forward' to do the transcribing. So go to god and read section
	4.51 if you want to understand what is going on here. Also you can
	get a little contrast of the styles which result from the different
	features of the two languages(especially w re pointer variables).

	Things to note in this program which you may not already be
	familiar with are the following:

		1) A nested data structure(PAGE) is used. This is possible
		   in PASCAL and PL/I too and makes life a lot more pleasant.
		   Try doing the same thing in BASIC or FORTRAN, what a
		   mess! In a sense it would be easier in assembler.

		2) Note that the tree structure used is a balanced one
		   so that no single branch gets long at the expense of
		   others. To see the depth level of the tree, turn on
		   the SPRINT parameter and note the first column of the
		   output on any sort. There is a trade-off here, though
		   in that it takes longer to build the tree than if it
		   were just a binary tree(not an AVL though). Thats why
		   b-trees are best for retrieval rather than simple
		   sorts.

		3) The logic uses a rather interesting recursive structure
		   in which 'emerging' items are handed back through higher
		   levels until perhaps to the root of the tree. See the
		   variable called 'u' in function 'search'.

		4) The parameter KEYPTR allows the option of including the
		   string storage area in the nodes themselves as opposed
		   to allocated areas. The latter is faster since no move-
		   ment of strings is necessary after they have been given
		   initial allocations. However, for disk-based use the
		   strings(keys) would need to be in the nodes. To see the
		   difference in performance(big!) just undefine(comment
		   out) this parameter.

		5) For further perfomance comparison play with the FAST
		   parameter. If undefined, the compiler will build a
		   version of B-sort with a high-level version of two
		   block move operations. These same functions are imple-
		   mented in assembler code in the file BDSNEW.CSM. By
		   linking with that special library, you can get a version
		   of this program which runs quite a bit faster. Let me
		   know if you get any amazing results.

		6) One peculiarity of the 'C' language came up in an earlier
		   version of B-sort, it would not sort itself! Clue, this
		   had to do with the way that 'printf' works. See if you
		   can figure out how this happened and how it was fixed.

	I hope this program is useful for some in learning more about the
	'C' language and an interesting algorithm(the key to better software).
	If you make any improvements give me a copy. If you mutilate it, keep
	it to yourself.
				Jack Riley (303) 499-9169 RCPM, Boulder, CO.
*/

#include "bdscio1.h"	/* version with ALLOC_ON true */

#DEFINE N		2  /* half-size of b-tree node */

/* options for customizing the program */

#DEFINE FAST		/* uses external 'move' functions for assemlber vs */
/* #DEFINE SPRINT */		/* provides statistics on keys in output */
#DEFINE KEYPTR		/* uses pointer references to strings instead of
			   arrays in the b-tree nodes */
/* #DEFINE DIAGNOSE */	/* turns on voluminous trace information on actions
			   taken by program logic.. perhaps instructive */
/* special assigned values */

#DEFINE KEYSIZE		80
#DEFINE MAX_LEN		20
#DEFINE MAXPRINT	3000

/* dependent parameters */

#DEFINE NN		N+N
#DEFINE NM1		N-1
#DEFINE NM2		N-2
#DEFINE	NP1		N+1

/* structure definitions */

#DEFINE ITEM 		struct sitem
#DEFINE PAGE 		struct spage

ITEM {
#ifndef KEYPTR
	CHAR KEY[KEYSIZE];
#endif
#ifdef KEYPTR
	CHAR *KEY;
#endif
	PAGE *P;
	UNSIGNED COUNT;
	} oneitem;

PAGE {
	UNSIGNED M;
	PAGE *P0;
	ITEM E[NN];
	} onepage;

/* external variables */

PAGE *root,*q;
ITEM g;
FILE infile,l_buffer;
CHAR infilnam[MAX_LEN], instrg[MAXLINE], o_flg;
INT sizitem,sizpage, maxcount, nkeys, tokcount;

/* beginning of programs */

use_err() /* Usage message: */

       { printfc("\nERROR: Invalid parameter specification\n\n");
       printfc("Usage: b-sort <filename> <flag(s)>\n\n");
       printfc("       -o <filename> = Write output to named file\n");
       exit(0); }

main(argc,argv)
int argc;
char **argv;
{
	char *arg;

	o_flg=FALSE;		/* output file flag */

	if (argc < 2) use_err();

	strcpy(infilnam,*++argv);

	if( fopen(infilnam,infile) == ERROR )
		{ printfc("\nERROR: Unable to open input file: %s\n",infilnam);
		  EXIT(0); }

	if(--argc > 0)
	   if(*(arg=*++argv) == '-')
		if(tolower(*++arg) == 'o')
			{ o_flg++;
			if(--argc == 0)
				{printfc("\nneed output file name");use_err();}
			if(fcreat(*++argv,l_buffer) == ERROR)
			 {printfc("ERROR: Unable to create output file - %s\n",
						*argv); exit(0);}
			}

	_allocp=NULL;
	root=NULL; sizitem=sizeof(oneitem); sizpage=sizeof(onepage);
	tokcount=nkeys=0;

#ifdef DIAGNOSE
	printf("\n&root=%x,g=%x,sizi=%d,sizp=%d",&root,g,sizitem,sizpage);
#endif

	while( fgets(instrg,infile) )
		{
		if( trim(instrg) <= 0 ) continue;

		instrg[KEYSIZE-1]='\0';

#ifdef DIAGNOSE
		printf("\n\nsearch key= %s",instrg);
#endif
		if( search(instrg,root,g) )
			{ q=root; 
			 if( (root=alloc(sizpage)) == NULL)
				{ printfc("\nERROR unable to allocate page");
				  EXIT(0); }
#ifdef DIAGNOSE
printf("  root=%x, q=%x",root,q);
#endif

			root->M=1; root->P0=q; moveb(root->E[0] , g ,sizitem);

			}
		}

	printfc("\nEnd of input\n");

	printfc("\nnumber of unique keys=%d, total key count=%d\n",
					nkeys,tokcount);
	if(!o_flg) pause();

	maxcount=MAXPRINT; printtree(root,1);

	printf("\n");
	if(o_flg)
		{ putc(CPMEOF,l_buffer); fflush(l_buffer); fclose(l_buffer); }
}
CHAR search(x,a,v)
CHAR *x;
PAGE *a;
ITEM *v;
{
	INT i,k,l,r,cmp; PAGE *q,*b; ITEM u; CHAR *t;

/*	Search for key x on page a */

	if(a==NULL) 		/* ITEM with key x is not in tree */
		{ 
		++tokcount; ++nkeys; defkey(&v->KEY,x);

#ifdef DIAGNOSE
printf("\n             a ==  null v(=%x)->KEY=%s",v,v->KEY);
#endif

		v->COUNT=1;
		v->P=NULL;  return (TRUE) ; /* TRUE means not found */
		}
	else
		{ l=0; r=a->M-1;  /* binary array search */
		do {
		    k=(l+r)/2;
		    cmp= strcmp(x,t=(a->E[k].KEY));

#ifdef DIAGNOSE
printf("\ncmp=%d,r=%d,l=%d,a(=%x)->P0=%x/E[k=%d].P=%x/E[k].KEY=%x=%s",
			cmp,r,l,a,a->P0,k,a->E[k].P,t,t );
#endif

		    if( cmp <= 0) r=k-1;
		    if( cmp >= 0) l=k+1;

		   } while ( r >= l );

		if( cmp == 0 ) /* found it, bump counter */
			{ ++tokcount; ++a->E[k].COUNT;  return(FALSE); }

		else    /* test if item is not on this page   */
			{
			q = ( r < 0 ) ? a->P0 : a->E[r].P;

			if( !search(x,q,u) ) return(FALSE);
			}
		}

/* ---- insert an item */

	if (a->M < NN)
		{ /* page not full yet, add to it. 'Bump' items from r+1 to
							M-1 */
		movdnb( a->E[r+2] , a->E[r+1] , sizitem*((a->M++)-r-1) );
		moveb( a->E[r+1] , u , sizitem );

		return(FALSE);
		}
	else
		{ /* page full, split it and push center item upward in tree */
		if( (b = alloc(sizpage)) == NULL )
			printf("\nOut of memory");

#ifdef DIAGNOSE
printf("\n\n ******  new node at %x",b);
#endif

		if ( r <= NM1 ) /* put new item in old page */
			{
			if ( r == NM1 )  moveb( v , u , sizitem );
			else
				{ /* 'bump' down items from r+2 to N-1 */

				moveb( v , a->E[NM1] , sizitem );
				movdnb( a->E[r+2] , a->E[r+1] ,
							sizitem*(NM2-r) );
				moveb( a->E[r+1] , u , sizitem );
				}
			moveb( b->E[0] , a->E[N] , sizitem*N );
			}
		else
			{/* move upper N items and new item to new page */

			moveb( v , a->E[N] , sizitem ) ;

			if( (r = r - N) > 0 )	
				moveb( b->E[0] , a->E[NP1] , sizitem*r );

			moveb( b->E[r] , u , sizitem );

			if( (i = NM1-r) > 0 )
				moveb( b->E[r+1], a->E[NP1+r], sizitem * i );
			}

		a->M = b->M = N ; b->P0 = v->P; v->P = b ;
		}

	return (TRUE);
}
trim(strg)
char *strg;
{
	INT l;

	l=strlen(strg);
	while ( strg[l] <= ' ' )
		{ if( l <= 0 ) break;  strg[l--]='\0'; }
	return(l);
}
moveb(a,b,c)
char *a,*b;
int c;
{
	int i;
#ifdef FAST		/* use potentially faster move routine */
	move(a,b,c); return;
#endif
#ifndef FAST
	for ( i=0 ; i < c ; ++i ) a[i]=b[i] ;
#endif
}
movdnb(a,b,c)
char *a,*b;
int c;
{
	int i;
#ifdef FAST		/* use potentially faster move routine */
	movdn(a,b,c); return;
#endif
#ifndef FAST
	for ( ; --c >= 0 ; c ) a[c]=b[c] ;
#endif
}
printtree(p,l)
PAGE *p;
INT l;
{
	INT i,j;  CHAR *t;

	if(maxcount <= 0) return;

	if ( p != NULL )
		{

		printtree(p->P0, l+1 );

		for ( i=0; i <= (j=p->M-1) ; ++i )
			{ --maxcount;
			printf("\n");
#ifdef SPRINT
			printf(" %d %d ",l,p->E[i].COUNT );
#endif
			prints(p->E[i].KEY);

			printtree(p->E[i].P,l+1); 
			}
		}
}
defkey(a,b)
char **a,*b;
{
#ifdef KEYPTR
	if ( (*a=alloc(strlen(b)+1)) == NULL )
		{printfc("\ninsufficient string storage in defkey\n");EXIT(0);}
	strcpy(*a,b);
#endif
#ifndef KEYPTR
	strcpy(a,b);
#endif
}
prints(str)
char *str;
{
	if(o_flg)
		fputs(str,l_buffer);
	else
		puts(str);		/* and print out the line	 */
}
/* Note: The following two functions where obtained from the BDS STDLIB2.C
	 file and may be quite dependent on this compiler since the 'C'
	 language does specify where arguments are to be found.  */

printfc(format)
char *format;
{
	char line[MAXLINE];
	_spr(line,&format);	/* use "_spr" to form the output */

	puts(line);		/* and print out the line	 */
}
printf(format)
char *format;
{
	char line[MAXLINE];
	_spr(line,&format);	/* use "_spr" to form the output */

	prints(line);
}
fputs(s,iobuf)
char *s;
struct _buf *iobuf;
{
	char c;
	while (c = *s++) {
		if (c == '\r' || c == '\0') return;

		if (c == '\n') putc('\r',iobuf);
		if (putc(c,iobuf) == ERROR) return ERROR;
	}
	return OK;
}
    