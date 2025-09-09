/* RESTRICT.C

This routine was written for programs intended for use on remote systems
or any other system where access must be limited to a certain range of
user areas. A program calls restrict(*argv) and restrict will only return
if the user number contained in *argv (if any) is less than or equal to
MAXUSR. Of course this routine has no practical application in any file
NOT compiled by BDS C v1.50 or higher. It was specifically written for
BDS C v1.50, since it is the latest BDS C and the only one to allow user
area specification without special code.

		Written by S. Kluger
		El Paso RCPM/CBBS
		(915) 598-1668
*/

#define MAXUSR 4	/* highest directly accessible user area */

restrict(fn)
char *fn;
{
	int fsl,usrar;
		usrar = 0;
		if ((fsl = matchr(fn,'/')) == 1)
		{
			usrar = (fn[fsl-1] - '0');
		}else
		if ((fsl = matchr(fn,'/')) == 2)
		{
			usrar=(fn[fsl-1]-'0') + ((fn[fsl-2]-'0') * 10);
		}
		if (usrar > MAXUSR){
			printf("\nIllegal user area specified.\n");
			exit();
		}
}

char matchr(st,ch)
char *st,ch;
{
	int i;
	for(i=0; st[i]; i++){
		if(st[i] == ch) return(i);
	}
	return(0);
}
