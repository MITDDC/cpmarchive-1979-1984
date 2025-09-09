/*
	SD.C
	Written by Leor Zolman, 3/82

	By saying: 
		A>sd foo
	this simulates:
		A>sid foo.com foo.sym
	SID.COM must reside in the current directory.
*/

main(argc,argv)
char **argv;
{
	char comname[20], symname[20];

	if (argc != 2) {
		puts("Usage: sd name <cr>\n");
		puts("(does: sid name.com name.sym)\n");
		exit();
	}

	strcpy(comname,argv[1]);
	strcpy(symname,comname);
	strcat(comname,".com");
	strcat(symname,".sym");
	execl("sid",comname,symname,0);
}
