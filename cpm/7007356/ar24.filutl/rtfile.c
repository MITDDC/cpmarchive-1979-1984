/*
	RT-11 Adapter Package for CP/M

	Rev. 1.0 -- July 1980

	Rev. 1.1 -- March 1981 consisting of adding a valid system date
			word to all files placed on the RT-11 disk and
			putting the volume ID on a disk when the directory
			is initialized.  This will keep RT-11 versions
			later than V02C from choking.

	copyright (c) 1980, William C. Colley, III

This group of functions implements enough of RT-11 to allow the rest of
the package to work.  The functions are built and named as per the
RT-11 Software Support Manual for version 2C of RT-11.
*/

#include "RT11.H"

/*
Routine to look up an RT-11 file.  The routine accepts a file name as an
array of int and returns 0 if the file was not found, 1 otherwise.
The length of the file can be extracted thru dir_pointer, and the
starting block of the file appears in file_start.
*/

lookup(file_name)
int *file_name;
{
	usrcom();
	return dleet(file_name);
}

/*
Routine to rename an RT-11 file.  Pass the old and new names.  The routine
returns 0 if the file doesn't exist, 1 otherwise.
*/

rename(old_file,new_file)
int *old_file, *new_file;
{
	char i;
	usrcom();
	if (!dleet(old_file)) return 0;
	for (i = 0; i < 3; i++) _putword(dir_pointer,i+1,new_file[i]);
	*dir_pointer = 0;
	*(dir_pointer + 1) = TENTAT;
	clocom(new_file);
	return 1;
}

/*
Routine to delete an RT-11 file.  Pass the routine the file name as an
array of int.  If the file does not exist, the routine returns 0, else
it returns 1.
*/

delete(file_name)
int *file_name;
{
	usrcom();
	if (!dleet(file_name)) return 0;
	*dir_pointer = 0;
	*(dir_pointer + 1) = EMPTY;
	consol(0);
	segrw(WRITE,current_segment);
	return 1;
}

/*
Routine to build a tentative entry in the directory.  Routine requires
a file name in an array of int, and the size of the file required.  The
routine returns 0 if the entry is not possible, or the first block of
the file if it is.  If the entry fails, the appropriate diagnostic is printed.
*/

enter(file_name,size)
int *file_name, size;
{
	char *save_pntr, i;
	unsigned ret_value;
	usrcom();
	do
	{
retry:		consol(0);
		while (entry(EMPTY))
		{
			if (size <= _getword(dir_pointer,4))
			{
				save_pntr = dir_pointer;
				ret_value = file_start;
				while (entry(EMPTY)) incr1();
				if (dir_pointer > &directory.entries[1000] -
					directory.extra_bytes)
				{
					ret_value = current_segment;
					if (extend())
					{
						blkchk(ret_value);
						goto retry;
					}
					puts("\nError -- directory full\n");
					return 0;
				}
				dir_pointer = save_pntr;
				_expand(dir_pointer);
				*dir_pointer++ = 0;
				*dir_pointer++ = TENTAT;
				for (i = 0; i < 3; i++)
				{
					_putword(dir_pointer,i,file_name[i]);
				}
				_putword(dir_pointer,3,size);
				_putword(dir_pointer,5,sysdate);
				incr1();
				_putword(dir_pointer,3,
					_getword(dir_pointer,3) - size);
				segrw(WRITE,current_segment);
				return ret_value;
			}
			incr1();
		}
	}
	while (nxblk());
	puts("\nError -- no large enough gaps\n");
	return 0;
}

/*
Routine to extend an RT-11 directory by splitting a directory segment.
The routine returns 0 if no directory segment is available, 1 otherwise.
*/

extend()
{
	struct dirseg temp_seg;
	int t, newseg;
	emt_375(READ,0,2,temp_seg);
	if (temp_seg.highest_segment >= temp_seg.total_segments) return 0;
	newseg = temp_seg.highest_segment;
	temp_seg.highest_segment++;
	emt_375(WRITE,0,2,temp_seg);
	movmem(directory,temp_seg,1024);
	blkchk(current_segment);
	for (t = (1024 - 10) / (14 + directory.extra_bytes);
		t > 0; t--) incr1();
	*dir_pointer = 0;
	*(dir_pointer + 1) = EMPTY;
	temp_seg.next_segment = directory.next_segment;
	directory.next_segment = newseg;
	segrw(WRITE,current_segment);
	temp_seg.first_block = file_start;
	movmem(temp_seg,directory,10);
	movmem(temp_seg.entries + (dir_pointer - directory.entries),
		directory.entries, directory.entries + 1024 - dir_pointer);
	segrw(WRITE,newseg);
	current_segment = newseg;
	blkchk(newseg);
	return 1;
}

/*
Routine to close an RT-11 file.  The file name comes over in radix 50 in
the array file_name.  The routine returns 0 if no file by that name was
around to close, 1 otherwise.
*/

klose(file_name)
int *file_name;
{
	char i;
	blkchk(1);
	do
	{
		while(entry(TENTAT))
		{
			for (i = 0; i < 3; i++)
			{
				if (_getword(dir_pointer,i+1) !=
					file_name[i]) break;
			}
			if (i == 3)
			{
				clocom(file_name);
				return 1;
			}
			incr1();
		}
	}
	while (nxblk());
	return 0;
}
	
/*
Routine that continues close and rename operations.
*/

clocom(file_name)
int *file_name;
{
	char *tdptr;
	int tseg;
	tdptr = dir_pointer;
	tseg = current_segment;
	if (dleet(file_name))
	{
		*dir_pointer = 0;
		*(dir_pointer + 1) = EMPTY;
		if (tseg != current_segment)
		{
			consol(0);
			segrw(WRITE,current_segment);
		}
	}
	blkchk(tseg);
	dir_pointer = tdptr;
	*tdptr++ = 0;
	*tdptr = PERM;
	consol(0);
	segrw(WRITE,current_segment);
}	

/*
Routine to get an RT-11 file name from the console.  The name is packed
into the int array file_name in radix 50.  The routine returns 0
if the file name is not legal, 1 otherwise.
*/

getfd(file_name)
int *file_name;
{
	char c, i, j, name[20], *pntr;
	pntr = gets(name);
	file_name[0] = file_name[1] = file_name[2] = 0;
	for (i = 0; i < 2; i++)
	{
		for (j = 0; j < 3; j++)
		{
			c = *pntr;
			if (c == '.' || c == '\0') c = ' ';
			else pntr++;
			if ((c = ator50(c)) == 255) return 0;
			file_name[i] = file_name[i] * 050 + c;
		}
	}
	if (*pntr == '.') pntr++;
	for (i = 0; i < 3; i++)
	{
		c = *pntr;
		if (c == '\0') c = ' ';
		else pntr++;
		if ((c = ator50(c)) == 255) return 0;
		file_name[2] = file_name[2] * 050 + c;
	}
	return 1;
}

/*
Routine to set up an RT-11 file I/O operation.
*/

usrcom()
{
	current_segment = 0;
	blkchk(1);
}

/*
Routine to scan the directory for a file of a specified name.  The routine
is passed the file name in radix 50 as an array of int.  The routine returns
0 if the file is not found, 1 otherwise.
*/

dleet(file_name)
int *file_name;
{
	char i;
	blkchk(1);
	do
	{
		while(entry(PERM))
		{
			for (i = 0; i < 3; i++)
			{
				if (_getword(dir_pointer,i+1) !=
					file_name[i]) break;
			}
			if (i == 3) return 1;
			incr1();
		}
	}
	while (nxblk());
	return 0;
}

/*
Routine to get the next directory segment into core.  The routine returns
0 if no next segment exists, 1 otherwise.
*/

nxblk()
{
	if (directory.next_segment == 0) return 0;
	blkchk(directory.next_segment);
	return 1;
}

/*
Routine to find out if the requested directory segment is in core.  If it
isn't, the segment is read in.
*/

blkchk(segment)
int segment;
{
	if (segment != current_segment)
	{
		current_segment = segment;
		segrw(READ,segment);
	}
	dir_pointer = directory.entries;
	file_start = directory.first_block;
}

/*
Function to read/write a directory segment.  Parameters passed are the
directory segment desired, and a read/write flag as per emt_375.
*/

segrw(read_write,segment)
int segment;
char read_write;
{
	emt_375(read_write,segment * 2 + 4,2,directory);
}

/*
Routine to find a specified file type in a directory segment.
The routine starts from the current value of dir_pointer, and
returns either 0 if the type isn't found or 1 if it is.
*/

entry(type)
char type;
{
	char t;
	while (1)
	{
		if ((t = *(dir_pointer + 1)) == type) return 1;
		if (t == ENDSEG) return 0;
		incr1();
	}
}

/*
Routine to increment the directory pointer to the next entry in the
directory.
*/

incr1()
{
	file_start += _getword(dir_pointer,4);
	dir_pointer += 14 + directory.extra_bytes;
}

/*
Routine to compress the stray tentatives and empties out of a directory
segment.  The file name file_name gives a tentative file that is to be
exempt from the compression (i. e., there is only one active channel).
If no files are to be exempt, pass 0 for file_name.
*/

consol(file_name)
int *file_name;
{
	char i, *next;
	dir_pointer = directory.entries;
	while (entry(TENTAT))
	{
		if (file_name != 0)
		{
			for (i = 0; i < 3; i++)
			{
				if (_getword(dir_pointer,i+1) !=
					file_name[i]) break;
			}
		}
		else i = 0;
		if (i != 3)
		{
			*dir_pointer = 0;
			*(dir_pointer + 1) = EMPTY;
		}
		incr1();
	}
	dir_pointer = directory.entries;
	while (entry(EMPTY))
	{
		next = dir_pointer + 14 + directory.extra_bytes;
		if (*(next + 1) == EMPTY)
		{
			_putword(dir_pointer,4,_getword(next,4) +
				_getword(dir_pointer,4));
			_squeez(next);
			continue;
		}
		if (_getword(dir_pointer,4) == 0)
		{
			if (*(dir_pointer - 13 -
				directory.extra_bytes) == PERM)
			{
				_squeez(dir_pointer);
				continue;
			}
		}
		incr1();
	}
	blkchk(current_segment);
}

/*
This routine emulates the block read/write EMT call (#375).  You pass the
routine a starting block number, a block count, and an appropriate core
buffer.  The routine reads or writes the blocks and returns.  A read is
done if the read/write flag has value READ, and a write is done if the
read/write flag is WRITE.  Each block is 512 bytes.
*/

emt_375(read_write,start_block,block_count,core_buffer)
int start_block, block_count;
char read_write, *core_buffer;
{
	char i;
	while (--block_count >= 0)
	{
		for (i = 0; i < 4; i++)
		{
			bios(SEL_DSK,1);
			bdos(SET_DMA,core_buffer);
			_find(start_block,i);
			bios(read_write,0);
			bdos(SET_DMA,DMA_ADDR);
			bios(SEL_DSK,0);
			core_buffer += 128;
		}
	start_block++;
	}
}

/*
Internal function to map an RT-11 block number and sector number inside the
block into a physical sector number.  The sectors within a block are numbered
from 0 to 3.
*/

_find(block,sector)
int block;
char sector;
{
	int r, s, t;
	r = (block - 6) * 2 + (sector >> 1);
	sector &= 001;
	t = (r + 12) / 13;
	r = (r + 12) % 13;
	s = t * 6 + r * 4 + (r > 6 ? 1 : 0);
	if (sector) s += (r == 6 ? 3 : 2);
	t++;
	bios(SET_TRK,t);
	bios(SET_SEC,s % 26 + 1);
}

/*
Internal routine to extract a word from a core buffer that is an array of
char.  The array is passed, as is the word number desired.  The function
returns the word.
*/

_getword(buffer,word_number)
unsigned word_number;
char *buffer;
{
	buffer += word_number << 1;
	return *buffer++ + (*buffer << 8);
}

/*
Internal routine to place a word into the core buffer that is an array of char.
The array is passed, as is the word number desired, and the word itself.
*/

_putword(buffer,word_number,word)
unsigned word_number, word;
char *buffer;
{
	buffer += word_number << 1;
	*buffer++ = word & 0xff;
	*buffer = word >> 8;
}

/*
Internal routine to compress an entry out of a directory segment.
The address of the entry is passed.
*/

_squeez(entry)
char *entry;
{
	char *next;
	next = entry + 14 + directory.extra_bytes;
	movmem(next,entry,&directory.entries[1014] - next);
}		

/*
Internal routine to splice an entry into a directory segment.
The address of the disired entry is passed.
*/

_expand(entry)
char *entry;
{
	char *next;
	next = entry + 14 + directory.extra_bytes;
	movmem(entry,next,&directory.entries[1014] - next);
}

/*
Routine to map a character into its radix 50 representation.  The function
returns the rad 50 version or 255 if no rad 50 version exists.
*/

ator50(ascii)
char ascii;
{
	switch(ascii)
	{
		case ' ':	return 0;
		case '$':	return 033;
		case '.':	return 034;
	}
	ascii = toupper(ascii);
	if ((ascii -= '0') <= 9) return ascii + 036;
	if ((ascii -= ('A' - '0')) <= ('Z' - 'A')) return ascii + 1;
	return 255;
}
