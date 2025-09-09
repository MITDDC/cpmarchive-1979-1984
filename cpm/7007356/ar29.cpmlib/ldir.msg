	*		*		*
File:	LDIR.MSG		Date: 82-11-14
To:	All Remote System Operators
From:	Gary P. Novosielski	CIS[70160,120]
Subj:	Library Directory program

There have been several requests from RCPM and other remote
system operators for a utility to allow callers to see the
directory of .LBR files available on the system.  LDIR is
such a program.

LDIR performs no other function besides displaying the
directory of .LBR files, and can be made available to
callers as a .COM file.  While the LU library utility can
also perform this function, it would be sucide to leave this
out in a useable form, since it could be used to introduce
any arbitrary .COM file onto the system.

There has been a difference of opinion on whether .LBR's should
be squeezed before transmission, or whether the indivudual
members should be squeezed before being added to the .LBR.
There are good arguments for both sides, but since squeezing
an entire library would render the directory unreadable, I
suggest taking the latter alternative, and leaving the library
as an unsqueezed .LBR rather than a .LQR file.

Experimentation has shown that on many libraries, there will
be a slight cost in library size by opting for this method,
but the visibility of the directory would seem to outweigh this
objection.  Of course any or all members of the unsqueezed
library can still be squeezed files, so there is still a large
saving over normal ASCII encoded files.  The savings in time
and disk space which are inherent in the use of .LBR files also
helps to mitigate the slight size increase.

The files distributed with this package are:
LDIR.C		BDS C Source file.
LDIR.COM	BDS C Object code, compiled with V1.44 using
		the -E option, and CLINKed using the BDSNEW
		routines where possible.  NOBOOT has been run
		on this version.
LDIR.MSG	This file.

If there are any questions or problems, please feel free to
contact me at (201) 935-4087 voice, evenings (EST) and
weekends, or via CompuServe [70160,120] using EMAIL or CP-MIG.

Regards,
Gary P. Novosielski

	#		#		#
