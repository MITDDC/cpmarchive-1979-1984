/*
	RT-11 Adapter Package for CP/M

	Rev. 1.0 -- July, 1980

	Rev. 1.1 -- March 1981 consisting of adding a valid system date
			word to all files placed on the RT-11 disk and
			putting the volume ID on a disk when the directory
			is initialized.  This will keep RT-11 versions
			later than V02C from choking.

	copyright (c) 1980, William C. Colley, III

Global definitions and macro substitutions.
*/

/*	RT-11 directory entry types:	*/

#define	TENTAT		1
#define	EMPTY		2
#define	PERM		4
#define	ENDSEG		8

/*	BIOS calls:	*/

#define	SEL_DSK		9
#define	SET_TRK		10
#define	SET_SEC		11
#define	READ		13
#define	WRITE		14

/*	BDOS calls:	*/

#define	INIT_BDOS	13
#define	OPEN_FILE	15
#define	CLOSE_FILE	16
#define	READ_NEXT	20
#define	WRITE_NEXT	21
#define	MAKE_FILE	22
#define	SET_DMA		26

/*	CP/M default DMA address:	*/

#define	DMA_ADDR	0x80

/*	RT-11 directory buffer and associated values:	*/

struct dirseg
{
	unsigned total_segments;
	unsigned next_segment;
	unsigned highest_segment;
	unsigned extra_bytes;
	unsigned first_block;
	char entries[1024 - 10];
} directory;

int current_segment, file_start;
char *dir_pointer;

unsigned sysdate;		/*  System date word.  */
