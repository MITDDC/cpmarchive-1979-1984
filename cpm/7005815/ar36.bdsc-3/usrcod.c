/*
	USERCODE.C: A Nice Idea Killed By A Stupid CP/M MisFeature.....

	Idea: Extend the filename syntax for user with ALL file I/O to
	      allow a user area prefix of the form "n/" on all filenames.

	Written by Leor Zolman, 12/81  

        ****************************************************************
	**     	FOR CP/M 2.x SYSTEMS ONLY!!!                          **
        ****************************************************************


	Generalized replacements for "open", "creat" and "unlink"
	library functions, allowing a user area prefix to be attached
	to all filenames (except those used as arguments to the "rename"
	function). The new filename syntax becomes:

		[whitespace][nn/][d:][filename.ext]

	E.g, to reference file "foo.bar" on the currently logged disk in
	user area 7, you'd use:

		7/foo.bar

	To reference foo.bar in user area 9 on disk b:, you'd say:

		9/b:foo.bar

	and so on. The user area prefix must always come first if both it and
	a disk designator need to be specified. 

	NOTE: THIS WHOLE THING DOESN'T REALLY WORK FOR WRITING FILES INTO
	USER AREAS DIFFERENT FROM THE CURRENTLY ACTIVE USER AREA, BECAUSE
	GODDAMN CP/M DOESN'T LET YOU CLOSE A FILE THAT WAS OPENED IN A USER
	AREA DIFFERENT FROM THE CURRENTLY ACTIVE ONE. DAMN!!!!!!!!!!!!!!!!!!!

	To install this library, follow these steps:
		1) compile this file (USERCODE.C)
		2) invoke CLIB and give it the following commands:
			*o 0 usercode
			*o 1 deff2
			*e 1 open
			*a 0 open_old
			*e 1 creat
			*a 0 creat_old
			*e 1 unlink
			*a 0 unlink_old
			*c 0
			*q
		3) Link the programs you wish to have recognize the user code
		   on filenames by including "-f usercode" on the CLINK
		   command line.
*/

int open_old();
int creat_old();
int unlink_old();

open(filename, mode)
{
	return usercode(&open_old,filename,mode);
}

creat(filename)
{
	return usercode(&creat_old,filename);
}

unlink(filename)
{
	return usercode(&unlink_old,filename);
}

int usercode(funcptr, filename, extra_arg)
int (*funcptr)();
char *filename;
int extra_arg;
{
	int i, cur_user, new_user;
	char *savnam;

	while (isspace(*filename)) filename++;	/* skip over whitespace	*/
	savnam = filename;		/* save in case of false start	*/

	if (!isdigit(*filename)) return (*funcptr)(filename,extra_arg);

	cur_user = bdos(32, 0xff);	/* save current user number	*/
	new_user = atoi(filename);	/* get new user number		*/
	while (isdigit(*++filename))	/* skip over user number text	*/
		;
	if (*filename != '/' || new_user > 31)
		 return (*funcptr)(savnam,extra_arg);	
	bdos(32,new_user);
	i = (*funcptr)(filename + 1,extra_arg);
	bdos(32,cur_user);
	return i;
}

