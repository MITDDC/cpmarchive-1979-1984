BABYL OPTIONS:
Version:5
Append:1

1, recent,, filed,
*** EOOH ***
Date: 5 Jun 1982 21:18:56-PDT
From: ucivax!csuf!bytebug at Ucb-C70
To:   ucivax!ucbvax!INFO-CPM
Re:   WordStar Epson Patches
Via:  Mit-Mc; 6 Jun 82 0:22-EDT

The following was published in our computer club's newsletter.  As I don't
have an Epson MX-80, I can't make any claims to its accuracy, but would
appreciate hearing how it works out.

				Roger

----------
                         WordStar Epson Patches

The following patches will take advantage of some of the special
printing modes, available when using the Epson MX-80 printer with
GRAFTRAX-80 installed.

Using the INSTALL program area modification routine (after specifying
teletype-like printer), enter hex code at hex address shown below.

^A  Alternate pitch	Now selects alternate italics character set

	06B5 02
	06B6 1B
	06B7 34

^N  Normal pitch	Now selects normal character set

	06BA 02
	06BB 1B
	06BC 35

^Y  Ribbon Change	Now alternately sets, then resets, Epson's
			"Emphasized" mode.
	06DD 02
	06DE 1B
	06DF 45

	06E2 02
	06E3 1B
	06E4 46

^Q  User 1		Sets compressed (16.5 cpi) print mode

	06C9 02
	06CA 14
	06CB 0F

^W  User 2		Sets wider mode (8.25 cpi)
			Will revert to compressed mode after one line.
	06CE 02
	06CF 0F
	06D0 0E

^E  User 3		Sets expanded mode (5 cpi)
			Will reset next line.
	06D3 02
	06D4 12
	06D5 0E

^R  User 4		Resets pitch to standard (10 cpi)

	06D8 02
	06D9 12
	06DA 14
