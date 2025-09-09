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
Routine to return the size of a CP/M file.  This allows one to seek the
appropriate size hole on the RT-11 disk.  The size is in 512-byte blocks.
Any size over 501 is impossible as there are not that many blocks on a
disk.  Larger sizes denote file not found.
*/

filesize(filename)
char *filename;
{
	int size;
	char fcb[36];
	if (setfcb(fcb,filename) || bdos(OPEN_FILE,fcb) == 255) return 1000;
	size = fcb[15];
	while (fcb[15] == 0x80)
	{
		++fcb[12];
		fcb[32] = 0;
		if (bdos(OPEN_FILE,fcb) == 255) break;
		size += fcb[15];
	}
	return size % 4 ? size / 4 + 1 : size / 4;
}

/*
Routine to convert a number from 0 to 12 into a month name.
*/

getmon(mnum,buffer)
int mnum;
char *buffer;
{
	switch(mnum)
	{
		case  1:		strcpy(buffer,"JAN");	break;
		case  2:		strcpy(buffer,"FEB");	break;
		case  3:		strcpy(buffer,"MAR");	break;
		case  4:		strcpy(buffer,"APR");	break;
		case  5:		strcpy(buffer,"MAY");	break;
		case  6:		strcpy(buffer,"JUN");	break;
		case  7:		strcpy(buffer,"JUL");	break;
		case  8:		strcpy(buffer,"AUG");	break;
		case  9:		strcpy(buffer,"SEP");	break;
		case 10:		strcpy(buffer,"OCT");	break;
		case 11:		strcpy(buffer,"NOV");	break;
		case 12:		strcpy(buffer,"DEC");	break;
		default:		strcpy(buffer,"   ");	break;
	}
}

/*
Routine to get a command from the user.
*/

getcom()
{
	char temp[20];
	puts("\nCommand? ");
	gets(temp);
	return toupper(temp[0]);
}

/*
Routine to quiz the user for an RT-11 file name.  He gets prompted with
the string prompt and quizzed until he enters a valid name.  The routine
returns the name in the array of int, and a value of 0 if the name is
null, 1 otherwise.
*/

get_RT_name(prompt,file_name)
char *prompt;
int *file_name;
{
	puts(prompt);
	while (!getfd(file_name))
	{
		puts("Error -- illegal file name.  Try again. ");
	}
	if (file_name[0] == 0 && file_name[1] == 0 && file_name[2] == 0)
		return 0;
	return 1;
}

/*
Routine to convert the name of an RT-11 file from radix 50 into an
ASCII string.  The file name comes over in the int array file_name
and the string goes back in the char array file_string.  Illegal
characters show up as *'s.  The function returns a pointer to the
string.
*/

sprint_name(file_name,file_string)
char *file_string;
int *file_name;
{
	int i, j;
	unsigned t;
	file_string[10] = '\0';
	file_string[6] = '.';
	for (i = 0; i < 3; i++)
	{
		t = file_name[i];
		for (j = 2; j >= 0; j--)
		{
			file_string[3 * i + j + (i == 2 ? 1 : 0)]
				= r50toa(t % 050);
			t /= 050;
		}
	}
	return file_string;
}

/*
Routine to print the name of an RT-11 file on the console.
All rules as sprint_name apply here.
*/

print_name(file_name)
int *file_name;
{
	char temp[11];
	puts(sprint_name(file_name,temp));
}

/*
Routine to convert a radix 50 character into an ASCII character.
The routine returns the character * if the rad 50 character is
illegal.
*/

r50toa(rad50)
char rad50;
{
	switch (rad50)
	{
		case 0:		return ' ';
		case 033:	return '$';
		case 034:	return '.';
	}
	if (rad50-- <= 031) return rad50 + 'A';
	if ((rad50 -= 035) <= 9) return rad50 + '0';
	return '*';
}
