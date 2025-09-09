
/* 
	This program is a simple example of how to use
	Bob Mathias's floating point package.
	After compiling this and the FLOAT.C library, link by saying:

	A>clink floatsum -f float <cr>

	Note: the "printf" function resulting from this linkage
	will support the "e" and "f" floating point conversion
	characters, but the regular "printf" would not. The reason:
	the special version of "_spr" in the FLOAT.C source file
	is loaded before the library version of "_spr", and
	thus supports the extra features.
*/

main()
{
	char s1[5], s2[5];
	char string[30];
	char sb[30];
	int i;
	atof(s1,"0");
	while (1) {
		printf("sum = %10.6f\n",s1);
		printf("\nEnter a floating number: ");
		fpadd(s1,s1,atof(s2,gets(string)));
	}
}

