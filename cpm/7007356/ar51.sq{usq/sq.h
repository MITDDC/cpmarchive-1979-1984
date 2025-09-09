/* Definitions and external declarations */
char	debug;	/* Boolean flag */

/* *** Stuff for first translation module *** */
int likect;	/*count of consecutive identical chars */
int lastchar, newchar;
char state;
/* states */
#define NOHIST	0 	/*don't consider previous input*/
#define SENTCHAR 1 	/*lastchar set, no lookahead yet */
#define SENDNEWC 2 	/*newchar set, previous sequence done */
#define SENDCNT 3 	/*newchar set, DLE sent, send count next */

/* *** Stuff for second translation module *** */
#define NOCHILD -1	/* indicates end of path through tree */
#define NUMNODES (NUMVALS + NUMVALS - 1)	/* nbr of nodes */

#define MAXCOUNT 65535	/* biggest unsigned integer */

/* The following array of structures are the nodes of the
 * binary trees. The first NUMVALS nodes becomethe leaves of the
 * final tree and represent the values of the data bytes being
 * encoded and the special endfile, SPEOF.
 * The remaining nodes become the internal nodes of the final tree.
 */

struct	nd {
	unsigned weight;	/* number of appearances */
	char tdepth;		/* length on longest path in tre*/
	int lchild, rchild;	/* indexes to next level */
} node[NUMNODES];

int dctreehd;	/*index to head node of final tree */

/* This is the encoding table:
 * The bit strings have first bit in  low bit.
 * Note that counts were scaled so code fits unsigned integer
 */

char codelen[NUMVALS];		/* number of bits in code */
unsigned code[NUMVALS];		/* code itself, right adjusted */
unsigned tcode;			/* temporary code value */


/* Variables used by encoding process */
int curin;	/* Value currently being encoded */
char cbitsrem;	/* Number of code string bits remaining */
unsigned ccode;	/* Current code shifted so next code bit is at right */
