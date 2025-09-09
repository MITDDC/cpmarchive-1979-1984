#include <bdscio.h>
#include <dio.h>
#include "sqcom.h"
#include "sq.h"
#define STDERR 4	/* error stream - always console */

/******** Second translation - bytes to variable length bit strings *********/


/* This translation uses the Huffman algorithm to develop a
 * binary tree representing the decoding information for
 * a variable length bit string code for each input value.
 * Each string's length is in inverse proportion to its
 * frequency of appearance in the incoming data stream.
 * The encoding table is derived from the decoding table.
 *
 * The range of valid values into the Huffman algorithm are
 * the values of a byte stored in an integer plus the special
 * endfile value chosen to be an adjacent value. Overall, 0-SPEOF.
 *
 * The "node" array of structures contains the nodes of the
 * binary tree. The first NUMVALS nodes are the leaves of the
 * tree and represent the values of the data bytes being
 * encoded and the special endfile, SPEOF.
 * The remaining nodes become the internal nodes of the tree.
 *
 * In the original design it was believed that
 * a Huffman code would fit in the same number of
 * bits that will hold the sum of all the counts.
 * That was disproven by a user's file and was a rare but
 * infamous bug. This version attempts to choose among equally
 * weighted subtrees according to their maximum depths to avoid
 * unnecessarily long codes. In case that is not sufficient
 * to guarantee codes <= 16 bits long, we initially scale
 * the counts so the total fits in an unsigned integer, but
 * if codes longer than 16 bits are generated the counts are
 * rescaled to a lower ceiling and code generation is retried.
 */

/* Initialize the Huffman translation. This requires reading
 * the input file through any preceding translation functions
 * to get the frequency distribution of the various values.
 */

init_huff(ib)          
struct _buf *ib;
{
	int c, i;
	int btlist[NUMVALS];	/* list of intermediate binary trees */
	int listlen;		/* length of btlist */
	unsigned *wp;	/* simplifies weight counting */
	unsigned ceiling;	/* limit for scaling */

	/* Initialize tree nodes to no weight, no children */
	init_tree();

	/* Build frequency info in tree */
	do {
		c = getcnr(ib);        
		if(c == EOF)
			c = SPEOF;
		if(*(wp = &node[c].weight) !=  MAXCOUNT)
			++(*wp);
	} while(c != SPEOF);

	pcounts();	/* debugging aid */
	
	ceiling = MAXCOUNT;

	do {	/* Keep trying to scale and encode */
		if(ceiling != MAXCOUNT)
			printf("*** rescaling ***, ");
		scale(ceiling);
		ceiling /= 2;	/* in case we rescale */
		pcounts();	/* debugging aid */

		/* Build list of single node binary trees having
		 * leaves for the input values with non-zero counts
		 */
		for(i = listlen = 0; i < NUMVALS; ++i)
			if(node[i].weight != 0) {
				node[i].tdepth = 0;
				btlist[listlen++] = i;
			}

		/* Arrange list of trees into a heap with the entry
		 * indexing the node with the least weight at the top.
		 */
		heap(btlist, listlen);

		/* Convert the list of trees to a single decoding tree */
		bld_tree(btlist, listlen);

		/* Initialize the encoding table */
		init_enc();

		/* Try to build encoding table.
		 * Fail if any code is > 16 bits long.
		 */
	} while(buildenc(0, dctreehd) == ERROR);
	phuff();	/* debugging aid */

	/* Initialize encoding variables */
	cbitsrem = 0;	/*force initial read */
	curin = 0;	/*anything but endfile*/
}

/* The count of number of occurrances of each input value
 * have already been prevented from exceeding MAXCOUNT.
 * Now we must scale them so that their sum doesn't exceed
 * ceiling and yet no non-zero count can become zero.
 * This scaling prevents errors in the weights of the
 * interior nodes of the Huffman tree and also ensures that
 * the codes will fit in an unsigned integer. Rescaling is
 * used if necessary to limit the code length.
 */

scale(ceil)
unsigned ceil;	/* upper limit on total weight */
{
	int c, ovflw, divisor, i;
	unsigned w, sum;
	char increased;		/* flag */

	do {
		for(i = sum = ovflw = 0; i < NUMVALS; ++i) {
			if(node[i].weight > (ceil - sum))
				++ovflw;
			sum += node[i].weight;
		}

		divisor = ovflw + 1;

		/* Ensure no non-zero values are lost */
		increased = FALSE;
		for(i = 0; i < NUMVALS; ++i) {
			w = node[i].weight;
			if (w < divisor && w > 0) {
				/* Don't fail to provide a code if it's used at all */
				node[i].weight = divisor;
				increased = TRUE;
			}
		}
	} while(increased);

	/* Scaling factor choosen, now scale */
	if(divisor > 1)
		for(i = 0; i < NUMVALS; ++i)
			node[i].weight /= divisor;
}

/* heap() and adjust() maintain a list of binary trees as a
 * heap with the top indexing the binary tree on the list
 * which has the least weight or, in case of equal weights,
 * least depth in its longest path. The depth part is not
 * strictly necessary, but tends to avoid long codes which
 * might provoke rescaling.
 */

heap(list, length)
int list[], length;
{
	int i;

	for(i = (length - 2) / 2; i >= 0; --i)
		adjust(list, i, length - 1);
}

/* Make a heap from a heap with a new top */

adjust(list, top, bottom)
int list[], top, bottom;
{
	int k, temp;

	k = 2 * top + 1;	/* left child of top */
	temp = list[top];	/* remember root node of top tree */
	if( k <= bottom) {
		if( k < bottom && cmptrees(list[k], list[k + 1]))
			++k;

		/* k indexes "smaller" child (in heap of trees) of top */
		/* now make top index "smaller" of old top and smallest child */
		if(cmptrees(temp, list[k])) {
			list[top] = list[k];
			list[k] = temp;
			/* Make the changed list a heap */
			adjust(list, k, bottom); /*recursive*/
		}
	}
}

/* Compare two trees, if a > b return true, else return false
 * note comparison rules in previous comments.
 */

char	/* Boolean */
cmptrees(a, b)
int a, b;	/* root nodes of trees */
{
	if(node[a].weight > node[b].weight)
		return TRUE;
	if(node[a].weight == node[b].weight)
		if(node[a].tdepth > node[b].tdepth)
			return TRUE;
	return FALSE;
}

/* HUFFMAN ALGORITHM: develops the single element trees
 * into a single binary tree by forming subtrees rooted in
 * interior nodes having weights equal to the sum of weights of all
 * their descendents and having depth counts indicating the
 * depth of their longest paths.
 *
 * When all trees have been formed into a single tree satisfying
 * the heap property (on weight, with depth as a tie breaker)
 * then the binary code assigned to a leaf (value to be encoded)
 * is then the series of left (0) and right (1)
 * paths leading from the root to the leaf.
 * Note that trees are removed from the heaped list by
 * moving the last element over the top element and
 * reheaping the shorter list.
 */

bld_tree(list, len)
int list[];
int len;
{
	int freenode;		/* next free node in tree */
	int lch, rch;		/* temporaries for left, right children */
	struct nd *frnp;	/* free node pointer */
	int i;

	/* Initialize index to next available (non-leaf) node.
	 * Lower numbered nodes correspond to leaves (data values).
	 */
	freenode = NUMVALS;

	while(len > 1) {
		/* Take from list two btrees with least weight
		 * and build an interior node pointing to them.
		 * This forms a new tree.
		 */
		lch = list[0];	/* This one will be left child */

		/* delete top (least) tree from the list of trees */
		list[0] = list[--len];
		adjust(list, 0, len - 1);

		/* Take new top (least) tree. Reuse list slot later */
		rch = list[0];	/* This one will be right child */

		/* Form new tree from the two least trees using
		 * a free node as root. Put the new tree in the list.
		 */
		frnp = &node[freenode];	/* address of next free node */
		list[0] = freenode++;	/* put at top for now */
		frnp->lchild = lch;
		frnp->rchild = rch;
		frnp->weight = node[lch].weight + node[rch].weight;
		frnp->tdepth = 1 + maxchar(node[lch].tdepth, node[rch].tdepth);
		/* reheap list  to get least tree at top*/
		adjust(list, 0, len - 1);
	}
	dctreehd = list[0];	/*head of final tree */
}

char
maxchar(a, b)
char a, b;
{
	return a > b ? a : b;
}
/* Initialize all nodes to single element binary trees
 * with zero weight and depth.
 */

init_tree()
{
	int i;

	for(i = 0; i < NUMNODES; ++i) {
		node[i].weight = 0;
		node[i].tdepth = 0;
		node[i].lchild = NOCHILD;
		node[i].rchild = NOCHILD;
	}
}

init_enc()
{
	int i;

	/* Initialize encoding table */
	for(i = 0; i < NUMVALS; ++i) {
		codelen[i] = 0;
	}
}

/* Recursive routine to walk the indicated subtree and level
 * and maintain the current path code in bstree. When a leaf
 * is found the entire code string and length are put into
 * the encoding table entry for the leaf's data value.
 *
 * Returns ERROR if codes are too long.
 */

int		/* returns ERROR or NULL */
buildenc(level, root)
int level;/* level of tree being examined, from zero */
int root; /* root of subtree is also data value if leaf */
{
	int l, r;

	l = node[root].lchild;
	r = node[root].rchild;

	if( l == NOCHILD && r == NOCHILD) {
		/* Leaf. Previous path determines bit string
		 * code of length level (bits 0 to level - 1).
		 * Ensures unused code bits are zero.
		 */
		codelen[root] = level;
		code[root] = tcode & ((~0) >> (16 - level));
		return (level > 16) ? ERROR : NULL;
	} else {
		if( l != NOCHILD) {
			/* Clear path bit and continue deeper */
			tcode &= ~(1 << level);
			/* NOTE RECURSION */
			if(buildenc(level + 1, l) == ERROR)
				return ERROR;
		}
		if(r != NOCHILD) {
			/* Set path bit and continue deeper */
			tcode |= 1 << level;
			/* NOTE RECURSION */
			if(buildenc(level + 1, r) == ERROR)
				return ERROR;
		}
	}
	return NULL;	/* if we got here we're ok so far */
}

/* Write out the header of the compressed file */

wrt_head(ob, infile)
struct _buf *ob;
char *infile;	/* input file name (w/ or w/o drive) */
{
	int i, k, l, r;
	int numnodes;		/* nbr of nodes in simplified tree */

	putwe(RECOGNIZE, ob);	/* identifies as compressed */
	putwe(crc, ob);		/* unsigned sum of original data */

	/* Record the original file name w/o drive */
	if(*(infile + 1) == ':')
		infile += 2;	/* skip drive */

	do {
		putce(*infile, ob);
	} while(*(infile++) != '\0');


	/* Write out a simplified decoding tree. Only the interior
	 * nodes are written. When a child is a leaf index
	 * (representing a data value) it is recoded as
	 * -(index + 1) to distinguish it from interior indexes
	 * which are recoded as positive indexes in the new tree.
	 * Note that this tree will be empty for an empty file.
	 */

	numnodes = dctreehd < NUMVALS ? 0 : dctreehd - (NUMVALS -1);
	putwe(numnodes, ob);

	for(k = 0, i = dctreehd; k < numnodes; ++k, --i) {
		l = node[i].lchild;
		r = node[i].rchild;
		l = l < NUMVALS ? -(l + 1) : dctreehd - l;
		r = r < NUMVALS ? -(r + 1) : dctreehd - r;
		putwe(l, ob);	/* left child */
		putwe(r, ob);	/* right child */
	}
}

/* Get an encoded byte or EOF. Reads from specified stream AS NEEDED.
 *
 * There are two unsynchronized bit-byte relationships here.
 * The input stream bytes are converted to bit strings of
 * various lengths via the static variables named c...
 * These bit strings are concatenated without padding to
 * become the stream of encoded result bytes, which this
 * function returns one at a time. The EOF (end of file) is
 * converted to SPEOF for convenience and encoded like any
 * other input value. True EOF is returned after that.
 *
 * The original gethuff() called a seperate function,
 * getbit(), but that more readable version was too slow.
 */

int		/*  Returns byte values except for EOF */
gethuff(ib)
struct _buf *ib;
{
	char rbyte;	/* Result byte value */
	char need, take;	/* numbers of bits */

	rbyte = 0;
	need = 8;	/* build one byte per call */

	/* Loop to build a byte of encoded data
	 * Initialization forces read the first time
	 */

loop:
	if(cbitsrem >= need) {
		/* Current code fullfills our needs */
		if(need == 0)
			return rbyte;
		/* Take what we need */
 		rbyte |= ccode << (8 - need);
		/* And leave the rest */
		ccode >>= need;
		cbitsrem -= need;
		return rbyte;
	}

	/* We need more than current code */
	if(cbitsrem > 0) {
		/* Take what there is */
		rbyte |= ccode << (8 - need);
		need -= cbitsrem;
	}
	/* No more bits in current code string */
	if(curin == SPEOF) {
		/* The end of file token has been encoded. If
		 * result byte has data return it and do EOF next time
		 */
		cbitsrem = 0;

		/*NOTE: +0 is to fight compiler bug? */
		return (need == 8) ? EOF : rbyte + 0;
	}

	/* Get an input byte */
	if((curin = getcnr(ib)) == EOF)
		curin = SPEOF;	/* convenient for encoding */

	/* Get the new byte's code */
	ccode = code[curin];
	cbitsrem = codelen[curin];

	goto loop;
}
