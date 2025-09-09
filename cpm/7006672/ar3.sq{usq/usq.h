#define LARGE 30000

/* Decoding tree */
struct {
	int children[2];	/* left, right */
} dnode[NUMVALS - 1];

int bpos;	/* last bit position read */
int curin;	/* last byte value read */

/* Variables associated with repetition decoding */
int repct;	/*Number of times to retirn value*/
int value;	/*current byte value or EOF */

/* Original file name without drive */
char origname[14];
