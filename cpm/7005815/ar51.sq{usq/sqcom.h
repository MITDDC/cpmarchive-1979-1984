/* Definitions and external declarations */
#define RECOGNIZE 0xFF76	/* unlikely pattern */
/* *** Stuff for first translation module *** */
#define DLE 0x90

unsigned crc;	/* error check code */
char outdrv[3];	/* current output drive (string) */

/* *** Stuff for second translation module *** */
#define SPEOF 256	/* special endfile token */
#define NUMVALS 257	/* 256 data values plus SPEOF*/
