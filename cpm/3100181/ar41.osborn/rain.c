#include "a:bdscio.h"

/* TERMINAL RAIN */
/* Adapted from Berkeley's "rain" for the Osbourne 1 */
/* By Dan Sunday.  4-1-82 */



main(argc,argv)
char *argv[];
{
        int x, y, j, t;
        int xpos[5], ypos[5];
	int xloc, yloc;

	nrand(-1,0x74b5,0xc3b6,0x4dd3);
	puts(CLEARS);	/* clear the screen */
	cursor(26,26);	/* hide the cursor */

        for (j=5;--j>=0;) {
                xpos[j] = (nrand(1) & 0x1f) + (nrand(1) & 0xf) + 2;
                ypos[j] = (nrand(1) & 0xf) + (nrand(1) & 3) + 2;
        }


        for (j=0;;) {
                xloc = x = (nrand(1) & 0x1f) + (nrand(1) & 0xf) + 2;
                yloc = y = (nrand(1) & 0xf) + (nrand(1) & 3) + 2;
                pushch(yloc,xloc,'.');
                yloc = ypos[j];
		xloc = xpos[j];
                pushch(yloc,xloc,'o');

                if (j==0) j=4; 
                else --j;
                yloc = ypos[j];
		xloc = xpos[j];
                pushch(yloc,xloc,'O');

                if (j==0) j=4; 
                else --j;

                yloc = ypos[j]-1;
		xloc = xpos[j];
                pushch(yloc,xloc,'-');

                ++yloc;
		--xloc;
                pushstr(yloc,xloc,"|.|");

		++yloc;
		++xloc;
                pushch(yloc,xloc,'-');

                if (j==0) j=4; 
                else --j;

                yloc = ypos[j]-2;
		xloc = xpos[j];
                pushch(yloc,xloc,'-');

		++yloc;
		--xloc;
                pushstr(yloc,xloc,"/ \\");

		++yloc;
		--xloc;
                pushstr(yloc,xloc,"| O |");

		++yloc;
		++xloc;
                pushstr(yloc,xloc,"\\ /");

		++yloc;
		++xloc;
                pushch(yloc,xloc,'-');

                if (j==0) j=4; 
                else --j;

                yloc = ypos[j]-2;
		xloc = xpos[j];
                pushch(yloc,xloc,' ');

		++yloc;
		--xloc;
                pushstr(yloc,xloc,"    ");

		++yloc;
		--xloc;
                pushstr(yloc,xloc,"     ");

		++yloc;
		++xloc;
                pushstr(yloc,xloc,"    ");

		++yloc;
		++xloc;
                pushch(yloc,xloc,' ');

                xpos[j]=x; 
                ypos[j]=y;

	t = 2000;
	while (t--)
		;
	if (isakey()) {
		if (fetch() == (CTRL 'c')) {
			puts(CLEARS);
			exit(0);
		}
	}
        }
}


cursor (y,x)		/* move cursor to (y,x) */
{
	puts("\033=");
	putch (y+' ');
	putch (x+' ');
}


isakey()
{	return bios(2);
}


fetch()
{	return bios(3);
}


pushch (y,x,c)
char c;
{
	char *p;
	p = (y << 7) + x + 0xf000;
	*p = c;
}


pushstr (y,x,s)
char *s;
{
	char *p;
	p = (y << 7) + x + 0xf000;
	while (*s)
		*p++ = *s++;
}
