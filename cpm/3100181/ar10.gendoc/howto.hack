HOW2HACK.MSG	11/15/81	Tom McCormick

   I'd like to suggest some guidelines for making changes to
public domain programs on RCPM's.  I have spent a fair amount
of time on a couple dozen RCPM's around the country in the last
12 months.

   I'd like to see some of the leading contributors write a
.DOC file or two that could be permanently enlarged and refined
to become an outline of good practices for the RCPM scene.

   Ward and Ben and Kelly and others have been writing messages
and comments lately about the horrible job some hackers do to
good programs.	I'm suggesting that we list some of the good
practices and require (clearing house), or encourage them.

      1. The change should produce some benefit with BROAD
	 appeal. It should be TESTED for a few weeks prior
	 to submission. Dry running it on a friend or two
	 might also uncover something before hundreds of
	 people download it, only to have to download an
	 immediate "fix" or "improvement" a few days later!

      2. The source should indicate the author, version number,
	 as of date, and modifications since last version.
	 The purpose of the program should be immediately stated.
	 The comments should be in reverse chronological order,
	 and should be at the very front of the source so that
	 the 80 line typesq limit won't put 'em out of reach.

      3. The program should sign-on indicating the version #.

      4. If the program requires parameters passed to it, it
	 would be preferable to display a help menu or prompt
	 rather rather than abort, or exit the program. The 
	 reason for this is the growing use of menu programs;
	 they require a "second chance" to pass the parameters.

      5. A separate .DOC file is preferable. It should contain
	 the identical program name where possible, so that it
	 is clear what it belongs to.

      6. Program names of six characters or less will allow for
	 revision/version numbers to be appended later.

      7. If 2 or more programs are related, they should begin
	 with a common set of characters to force them to sort
	 together in directory listings.

	 RBBENT27.BAS and RBBMIN27.BAS
		is preferable to
	 FLS	SQ    USQ    and   CHANGES

      8. Give some thought (and effort) to avoiding use of words
	 or terms already used on non-CP/M systems. Programs have
	 been known to migrate, and the growing use of C and other
	 portable high level languages will only increase this.
	 Ask for help from SYSOPs or other users before setting
	 your pet name in concrete.

      9. DO NOT MAKE COSMETIC CHANGES to programs you send back
	 up to RCPMs.  The confusion far outweighs the "beauty".
	 Users do better with consistency than with constant change.

     10. Use DB's rather than equates for hardware dependant code
	 so that it can be readily patched with DDT, etc. MODEM7
	 is a nice example to follow, and all the bytes are in a
	 contiguous string right up front.  Nice.

     11. If you submit .BAS files to RCPMs, do that in ASCII so
	 they can be "TYPED". Nice to know if they're CBASIC or
	 MBASIC, or what.

     12. If a program is hardware dependant (Vector graphics), or
	 release dependant (ver 1.4 only?), or language dependant
	 (M80 but not MAC), this should be indicated in the filename,
	 or in the .DOC file right up front.


	-------------------------------------------------------------

	Well, I'll quit now. Give everybody else a chance to hack
	this up too.  Have at it.
	Tom McCormick	Houston

	-------------------------------------------------------------
