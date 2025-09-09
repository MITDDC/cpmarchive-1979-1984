/*
	NOBOOT.C	written by Leor Zolman
			3/82

	Given a list of C-generated COM files (linked with the standard
	distribution version of the C.CCC run-time package), this program
	changes those COM files so that they do not perform a warm-boot after
	their execution is complete, but instead preserve the CCP (Console
	Command Processor) that is in memory when execution begins and
	return to the CCP directly following execution.

	NOTE: If a command is the object of a pipe operation using DIO,
	then a warm-boot will always occur after its execution, whether
	or not NOBOOT has been applied to it.

	link by:
		A>clink noboot wildexp
	(or)	A>l2 noboot wildexp
*/

#include "bdscio.h"

main(argc,argv)
char **argv;
{
   int fd;
   int i;
   char c;
   char nambuf[30];
   char workbuf[0x500];
   int loop;

   if (argc == 1) {
 	puts("Usage: noboot <list of C-generated COM file names>\n");
	exit();
   }

   for (loop = 1; loop < argc; loop++)
   {
	puts("NOBOOT-ing ");
	puts(argv[loop]);
	putchar('\n');

	for (i=0; (c = argv[loop][i]) && c != '.'; i++)
		 nambuf[i] = c;
	nambuf[i] = '\0';
	strcat(nambuf,".COM");

	if ((fd = open(nambuf,2)) == ERROR) {
		puts("Can't open: ");
		puts(nambuf);
		exit();
	}

	i = read(fd,workbuf+0x100,8);
	if (i != 8) puts("Couldn't read in at least 8 sectors...\n");

	workbuf[0x100] = 0x21;
	workbuf[0x101] = 0x00;
	workbuf[0x102] = 0x00;
	workbuf[0x103] = 0x39;
	workbuf[0x104] = 0x22;
	workbuf[0x105] = 0x79;
	workbuf[0x106] = 0x05;
	workbuf[0x107] = 0xcd;
	workbuf[0x108] = 0x34;
	workbuf[0x109] = 0x01;
	workbuf[0x10a] = 0xf9;

	workbuf[0x12f] = 0x2a;
	workbuf[0x130] = 0x79;
	workbuf[0x131] = 0x05;
	workbuf[0x132] = 0xf9;
	workbuf[0x133] = 0xc9;

	workbuf[0x134] = 0x2a;
	workbuf[0x135] = 0x06;
	workbuf[0x136] = 0x00;
	workbuf[0x137] = 0x11;
	workbuf[0x138] = 0xcc;
	workbuf[0x139] = 0xf7;
	workbuf[0x13a] = 0x19;
	workbuf[0x13b] = 0xc9;
	workbuf[0x13c] = 0x00;
	workbuf[0x13d] = 0x00;
	workbuf[0x13e] = 0x00;

	workbuf[0x443] = 0xc3;
	workbuf[0x444] = 0x2f;
	workbuf[0x445] = 0x01;

	seek(fd,0,0);
	if (write(fd,workbuf+0x100,8) != 8) {
		puts("Write error.\n");
		exit();
	}

	if (close(fd) == ERROR) {
		puts("Close error\n");
	}
   }
}
