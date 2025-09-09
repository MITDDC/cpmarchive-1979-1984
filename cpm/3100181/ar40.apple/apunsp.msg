
The unspool program by Gary P. Novosielski is a very useful routine,
particularly for those with slow printers. Apple owners will never 
get beyond the message "Error in system table" without a little added
massage.  Gary aimed me in the right direction, any errors are mine.

The big problem is that standard CP/M 2.2 has ( & unspool expects) 16
jump vectors st the start of BIOS, counting from the warm boot vector.
Microsoft ("in their infinite wisdom")only saw fit to provide standard
implementations for 14 of these.  Unspool uses number 15, LISTST:, which
checks list device ready status, returning 00 in a if not ready, 0ffh
in a if ready.  {Implementing vector 16 must wait for another day.}

First, Unspool must be modified to only expect 15 jumps.  At (about)
line 104, NVECTS equ 16 must be changed from 16 to 15, so that Unspool
will be happy with just 15 vectors.  

Next, you must add and implement vector No. 15.  This vector should be
found at address 242dh in cpm56.com (or 0da2dh in 56k CP/M BIOS, or,
according to my manual, at 0aa2dh in 44k CP/M BIOS; all future address
references will be to the image in cpm56.com). Occupying that location
now is [xor a, ret] af c9 00, which is a simulated and jumpless LISTST,
always returning 00 in a.  At this address you will have to place a jump
to where you will want to place LISTST; I would suggest 2483h as this
location, hence use DDT to install c3 83 da.  Naturally, the jump address
must be the actual CP/M address, not the address it occupies in 
cpm56.com, that is da not 24 high-order byte. Note that all these changes
in cpm56.com will be incorporated in CP/M by running cpm56.com, but 
remember after this to reestablish any special items you have used
CONFIGIO to install, such as printer drivers, keyboard redefinitions
or undefinitions, terminal configurations, etc., as cpm56.com returns
these all to their default values.

Finally you have to write your own LISTST code, and find a place to
put it. The batches of 00's starting at 2433h are a series of 16
byte disk parameter headers, 6 in all for disk drives a: through f:.
If, like me, you will never need drive f:, you can use that location
(16 bytes in length) for LISTST.  The location is 2483h through
2492h.  A LISTST (in z-80 code) for the CCS-7728 parallel printer
card in slot 1 is given below, it is only 10 bytes (11 if you con-
vert to 8080 code by changing the relative jump). Note that the 
status code of the 7728 is exactly the opposite of that expected by
LISTST, hence the xor a and cpl codes to get things right.

		;This is a is a simple implementation of LISTST for the
		;ccs-7728 printer card in slot 1

                        	.z80
  E090                  	status	equ	0e090h	;status port, ccs-7728 
							;in slot 1
  0000'                 	aseg
                        	org	0da83h		;loc. of DPH for 
							;drive f:
  DA83    3A E090       	ld	a,(status)	;printer status to a
  DA86    B7            	or	a		;set flags
  DA87    28 02         	jr	z,ready		;if zero, jump to 
							;next routine
  DA89    AF            	xor	a		;set a to 00h, meaning 
							;not ready
  DA8A    C9            	ret			;and return
  DA8B    2F            ready:	cpl			;since a was 0, 
							;complement = 0ffh
  DA8C    C9            	ret			;a=ff shows lst: ready 
							;for char.
                        	end	0da83h


That's all there is to it, folks, sit back and enjoy printing while you
compute!!

Bob Thompson
Reply messages via Hyde Park or Calamity Cliffs RCPM, Chicago, please.
