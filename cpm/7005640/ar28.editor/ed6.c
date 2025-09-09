/*
Screen editor:  terminal output module
Source:  ed6.ccc
This file was created by the configuration program:
Version 2:  September 6, 1981.
*/

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/*
Define the current coordinates of the cursor.
*/

/*
Return the current coordinates of the cursor.
*/

outgetx()
{
	return(outx);
}

outgety()
{
	return(outy);
}

/*
Output one printable character to the screen.
*/

outchar(c) char c;
{
	syscout(c);
	outx++;
	return(c);
}

/*
Position cursor to position x,y on screen.
0,0 is the top left corner.
*/

outxy(x,y) int x,y;
{
	outx=x;
	outy=y;
	syscout(27);
	syscout('Y');
	syscout(y+32);
	syscout(x+32);
}

/*
Erase the entire screen.
Make sure the rightmost column is erased.
*/

outclr()
{
int k;
	syscout(12);
/*	k=0;
	while (k<SCRNL) {
		outxy(0,k++);
		outdelln();
	}
	outxy(0,0);
*/
}

/*
Delete the line on which the cursor rests.
Leave the cursor at the left margin.
*/

outdelln()
{
	outxy(0,outy);
	outdeol();
}

/*
Delete to end of line.
Assume the last column is blank.
*/

outdeol()
{
	syscout(27);
	syscout('K');
}

/*
Return yes if terminal has indicated hardware scroll.
*/

outhasup()
{
	return(YES);
}

outhasdn()
{
	return(YES);
}

/*
Scroll the screen up.
Assume the cursor is on the bottom line.
*/

outsup()
{
	syscout(10);
/*	outxy(0,0); /* set cursor to home */
	syscout(27);
	syscout('R'); /* delete line */
	outxy(0,23); /* reset cursor to bottom line */
*/
}

/*
Scroll screen down.
Assume the cursor is on the top line.
*/

outsdn()
{
	syscout(27);
	syscout('L');
}
