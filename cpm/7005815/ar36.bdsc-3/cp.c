/*
	CP.C
	Written by Leor Zolman, 3/18/82

	CP either copies a file from any disk and user area to any other
	disk and user area, or copies a list of files from the current
	disk and user area to some other disk and/or user area.

	Usage:
		A>cp [user#/][d:]<filename> [user#/][d:][<filename>] <cr>
	or	A>cp [user#/][d:]<filename> . <cr>
	or	A>cp <afn>  { <user#/> or <d:> } <cr>

	Note that the filename portion of the last argument is optional
	when only one file is being copied, but not allowed when multiple
	files are being copied.
	If one file is being copied and the destination filename is omitted,
 	CP attempts to copy to the disk and/or user number specified, leaving
	the filename the same. For example, to copy *.com into user area 7:

		cp  *.com  7/ 

	If the entire second argument is a single dot (.), then the destin-
	ation is the CURRENT disk and user area. For example, to copy foo.c
	into the current directory from user area 4:

		cp 4/foo.c .

	Link with:
		A>clink cp -f usercode -f wildexp
	(or) 	A>l2 cp usercode wildexp
*/

#include "bdscio.h"

main(argc,argv)
char **argv;
{
	int i,j,c,loop;
	int fd1,fd2;
	int bufsects;
	unsigned bufsize;
	unsigned corebuf;
	char cur_disk;			/* currently logged-in disk */
	int orig_user;			/* original user area */
	int source_user;		/* source user area */
	int dest_user;			/* destination user area */
	char destname[30];
	char *lastarg;

	wildexp(&argc,&argv);

	cur_disk = 'A' + bdos(25);
	lastarg = argv[argc - 1];

	if (argc < 3 || (argc > 3 &&
	    !((c = lastarg[strlen(lastarg)-1]) == '/' || c == ':')))
	{
		printf("Usages: cp [u/][d:]filename [u/][d:]newname <cr>\n");
		printf("	cp [u/][d:]filename u/ <cr>\n");
		printf("	cp [u/][d:]filename d: <cr>\n");
		printf("	cp [u/][d:]filename .  <cr>\n");
		printf("	cp <afn>  { <u/> or <d:> or <u/d:> }\n");
		exit();
	}

	corebuf = sbrk(256);
	for (bufsize = 256; sbrk(256) != ERROR; bufsize += 256)
		;
	bufsects = bufsize / SECSIZ;


   for (loop = 1; loop < argc-1; loop++)
   {
					/* get current user number */
	source_user = dest_user = orig_user  = bdos(32,0xff);

	if ((fd1 = open(argv[loop],0)) == ERROR) {
		printf("Can't open %s\n",argv[loop]);
		exit();
	}

	strcpy(destname,lastarg);
	if (hasuno(destname))
		dest_user = atoi(destname);
	if (hasuno(argv[loop]))
		source_user = atoi(argv[loop]);

	if ( (c = destname[strlen(destname) - 1])=='/' || c == ':' ||
		  				!strcmp(destname,"."))
	{
		if (!strcmp(destname,"."))
			sprintf(destname,"%d/%c:",orig_user,cur_disk);
		for (i = strlen(argv[loop]) - 1; i >= 0; i--)
			if (argv[loop][i] == '/' || argv[loop][i] == ':')
				break;				
		strcat(destname,&argv[loop][i+1]);
	}

	if ((fd2 = creat(destname)) == ERROR) {
  	printf("Can't create %s\n",destname);
		exit();
	}

	printf("\t copying %s\n",argv[loop]);

	while (1)
	{
		bdos(32,source_user);
		if (kbhit()) getchar();
		if (!(i = read(fd1,corebuf,bufsects))) break;
		bdos(32,dest_user);
		if (kbhit()) getchar();
		if (write(fd2,corebuf,i) != i) {
			printf("Write error. Disk full?\n");
			exit();
		}
	}

	bdos(32,dest_user);
	if (close(fd2) == ERROR) {
		printf("Can't close the output file.\7\n");;
	}
	bdos(32,orig_user);
	fabort(fd1);
   }
}

/*
	Return true if the string arg is a filename prefixed by "nn/",
	where "nn" is a user number:
*/

int hasuno(str)
char *str;
{
	char c;
	int sum;

	sum = 0;

	if (!isdigit(*str)) return FALSE;

	while (isdigit(c = *str++))
		sum = sum * 10 + c - '0';
	return (c == '/') ? (sum >= 0 && sum < 32) : FALSE;
}

