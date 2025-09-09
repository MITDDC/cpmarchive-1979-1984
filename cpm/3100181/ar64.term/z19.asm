; Z-19.ASM	Z-19 emulator for the SSM VB3 video card
; 
;		Version 1.0  Released 82.4.18
;		Copyleft (L) Scott W. Layson.  All rights reversed.
;		This code is in the public domain.
;
;	This code performs approximate (but usually adequate) emulation
;	of the Heath/Zenith Z-19 terminal on the SSM VB3 video card.  It
;	supports most of the Z-19 features required for normal text editing.
;	About the only useful thing missing is the special 25th line (49th?).
;
;	Things to note about this code:
;	-- The indentation in this file looks so strange because I edit with
;	   five-column instead of eight-column tabs.
;	-- Sections of this code, especially the relatively low-level routines,
;	   are not well commented.  Sorry 'bout that.
;	-- The code uses Intel mnemonics, but there are a couple of Z-80
;	   block moves inserted with `db's.  If you don't have a Z-80, you'll
;	   have to replace these with 8080 loops that do the same thing.
;	-- This file requires MAC for assembly as it stands, though it might
;	   not be very hard to make it ASM-compatible.
;	-- It assumes that the video controller has already been initialized
;	   (to 48 lines, but you can change this in the block of code below).
;	-- There's no keyboard I/O code in this file.
;	-- I have to turn the lower 48K of my main memory off, because my
;	   ExpandoRam II doesn't respond to PHANTOM* on write.  You will
;	   presumably have to change or remove this code; it's all right
;	   near the beginning.
;	-- This code uses a fair amount of stack space; I don't know exactly
;	   how much.  Because of this and because I'm turning most of main
;	   memory off, I use a private stack at the top of memory.  I recommend
;	   you do likewise if possible.
;	-- I normally use this code in "roll mode" rather than "scroll mode":
;	   after the last line on the screen is printed, the cursor is placed
;	   on the top line, which is then cleared.  The screen is never scrolled.
;	   I find this more comfortable on a P39 monitor, where scrolling leaves
;	   "trails".  The Z-19, of course, supports only "scroll mode".  The
;	   defaults for this and other modes are set in the `db's at the end
;	   of the file.
;	-- The behavior of this code when it gets an insert- or delete- line
;	   command is a little weird.  Instead of doing the insertion or
;	   deletion immediately, it counts the number of successive insertions
;	   or deletions and only executes them when it gets some other kind
;	   of command.  Sometimes this means that when you give an insert-line
;	   or delete-line command to your editor, nothing happens until you
;	   type another character.  The insert-n-lines and delete-n-lines
;	   commands, on the other hand, are executed immediately.
;	-- Consider: when you put a terminal into inverse video mode and give
;	   it a clear command of some sort (clear-to-end-of-line, home-and-clear-
;	   screen), should it clear to inverse or normal spaces?  The Z-19 clears
;	   to normal spaces; this code, like most other "smart" terminals these
;	   days, clears to inverse spaces.  Likewise for the other video
;	   attributes it supports.
;	-- The "graphics" mode accesses the user-definable font ROM.  Obviously,
;	   for emulation of Z-19 graphics mode, you must burn a ROM with that
;	   character set.
;
; Here is a list of control characters and escape sequences the code
; currently supports.  A `*' marks sequences the Z-19 doesn't have.
;
;  BS
;  TAB
;  CR
;  LF
;  Esc @			Enter insert-char mode
;  Esc A			Cursor up
;  Esc B			Cursor down
;  Esc C			Cursor forward
;  Esc D			Cursor backward
;  Esc E			Home and clear
;  Esc F			Enter graphics mode
;  Esc G			Exit graphics mode
;  Esc H			Home
;  Esc J			Clear to end of screen
;  Esc K			Clear to end of line
;  Esc L			Insert line
;  Esc M			Delete line
;  Esc N			Delete char
;  Esc O			Exit insert-char mode
;  Esc Y <r> <c>	Cursor pos
; *Esc l <n>		Insert n lines
; *Esc m <n>		Delete n lines
;  Esc p			Enter inverse video
;  Esc q			Exit inverse video
;  Esc x/y 5		Turn cursor off/on
; *Esc x/y *		Enter/exit scroll mode
; *Esc x/y A		Enter/exit inverse video
; *Esc x/y B		Enter/exit hide-char mode
; *Esc x/y C		Enter/exit underline mode
; *Esc x/y D		Enter/exit blink mode
; *Esc x/y E		Enter/exit strike-thru mode
; *Esc x/y F		Enter/exit dim mode
; *Esc x/y @		Set/clear all video modes
;  Esc v			Wrap mode on
;  Esc w			Wrap mode off
;

; And now the code itself.

vnormal	equ 3			; standard character attribute code
vinverse	equ 4			; inverse video bit
bs		equ 08h
tab		equ 09h
lf		equ 0ah
cr		equ 0dh
esc		equ 1Bh
vkbstat	equ 0e0h			; video keyboard status port
vkbdata	equ 0e1h			; video keyboard data port
vc		equ 0d0h			; video controller registers:
vhcount	equ vc + 0		;	char times per scan
vhsync	equ vc + 1		;	interlace(1), hsp(4), hbp(3)
vchars	equ vc + 2		;	0(1), scans/char(4), chars/line(3)
vlines	equ vc + 3		;	lines/frame
vscans	equ vc + 4		;	scans/frame
vvsync	equ vc + 5		;	vertical scan delay
vscrol	equ vc + 6		;	scroll register
vcolin	equ vc + 9		;	cursor column in
vcolout	equ vc + 12		;	cursor column out
vrowin	equ vc + 8		;	cursor row in
vrowout	equ vc + 13		;	cursor row out
vncols	equ 80			; number of cols
vnrows	equ 48			; number of rows
vvideo	equ 2000h			; address of video memory
voffset	equ 1000h			; offset to attributes
ramcard	equ 0FFh			; ExpandoRam bank-switch port
ramoff	equ 1			; to turn main memory off
ramon	equ 0			; to turn memory back on


		org 0F810h

; Main entry point.  The character is in C.

h19		push h			; save registers
		push d
		push b
		lxi h, 0
		dad sp			; get stack pointer
		lxi sp, 0			; move stack to high memory
		push h			; save old SP
		mvi a, ramoff		; turn main memory off
		out ramcard
		out vkbstat		; enable VB3
		call curoff		; turn cursor off
		call process		; process char
		call curon		; cursor back on
		out vkbdata		; disable VB3
		mvi a, ramon		; turn main memory back on
		out ramcard
		pop h			; recover old SP
		sphl				; and put the stack back where it was
		pop b			; restore registers
		pop d
		pop h
		ret				; and done!

process	lda escmode		; are we in an escape sequence?
		ora a
		jnz escseq		; yes: go interpret this char
		mov a, c
		cpi esc			; test for esc before checking insdelcnt
		jz doesc			; in case we're getting another ins or del
		
		lda insdelcnt		; any saved line insertions or deletions to do?
		ora a
		cnz doinsdel		; yes: do them first
		
		mov a, c			; check for the known control chars
		cpi cr			; (others are displayed)
		jz docr
		cpi lf
		jz dolf
		cpi bs
		jz dobs
		cpi tab
		jz dotab
		
; we have a displayable character.
display	lda insmode		; are we in insert-char mode?
		ora a
		cnz inschar		; yes: move rest of line over first
		lda attrib		; get current attribute byte
		mov b, a			; set up for putchar
		call putchar
		call right		; move cursor right
		rnz				; done if no wrap
		lda wrapp			; are we in wrap mode?
		ora a
		rz				; no: return
		jmp nextline		; wrap occurred

; write the char in c, attribute in b, to the video memory.
putchar	push h
		call addr			; get memory address of char
		mov m, c			; store char
		lxi d, voffset
		dad d			; address of attribute
		mov m, b			; store attribute
		pop h
		ret

nextline	mvi l, 0			; move to col. 0

; move the cursor down one line.  Clear the new line
; if the cursor was on the last logical line.  Scroll the screen
; if in scroll mode.

dolf		lda scrollp		; are we in scroll mode?
		ora a
		jnz dolfscr		; yes: go do the right thing
dolfnscr	lda lastlrow		; do lf in non-scroll mode:
		cmp h			; are we moving off the last logical row?
		push psw			; save the answer to that question
		call down			; move down
		jnz dolf3
		mvi h, 0			; wrap to top of screen
dolf3	pop psw			; are we moving off the last row?
		rnz				; no: done
		call nextlrow		; increment last-logical-row
		jmp dolf2

dolfscr	call down			; do lf in scroll mode
		rnz				; not moving off bottom: done
		call nextlrow		; increment last-logical-row
		out vscrol		; scroll screen
		sta lastprow		; set last-physical-row

dolf2	push h
		mvi l, 0
		call cleol		; clear the new line
		pop h
		ret

nextlrow	lda lastlrow		; increment last-logical-row
		inr a
		cpi vnrows		; modulo vnrows
		jnz nextl1
		xra a
nextl1	sta lastlrow		; store result
		ret

docr		mvi l, 0			; CR: set col to 0
		ret

dobs		jmp left			; BS: move cursor left

dotab	mov a, l			; TAB: move to current col...
		ani 0F8h			; ... modulo 8 ...
		adi 8			; ... plus 8
		cpi vncols
		jz right			; except near edge of screen
		mov l, a
		ret

; turn the cursor off.  Returns logical cursor address in HL.
curoff	lhld curaddr		; get logical cursor address
		mvi a, 0FFh
		out vcolout		; move cursor off screen
		ret

; turn the cursor on.  Called with logical cursor address in HL.
curon	shld curaddr		; save logical cursor address
		lda curoffp
		ora a
		rnz				; if cursor turned off, leave it off screen
		mov a, l			; set column
		out vcolout
		lda lastprow		; set row relative to last physical row
		inr a
		add h
		cpi vnrows
		jc curon1
		sui vnrows
curon1	out vrowout
		ret

; move the cursor left, if possible.  Returns Z iff at left edge.
left		mov a, l			; get col
		dcr l
		ora a
		rnz				; R(not at left edge)
		mov l, a			; force col. 0
		ret

; move the cursor right, if possible.  Returns Z iff at right edge.
right	inr l
		mvi a, vncols
		cmp l
		rnz				; R(not at right edge)
		mvi l, vncols - 1	; can't just dcr, cuz it clears Z!
		ret

; move the cursor down, if possible.  Returns Z iff at bottom.
down		inr h
		mvi a, vnrows
		cmp h
		rnz				; R(not at bottom)
		mvi h, vnrows - 1	; can't just dcr, cuz it clears Z!
		ret

; move the cursor up, if possible.  Returns Z iff at top.
up		mov a, h
		dcr h
		ora a
		rnz
		mov h, a
		ret

; clear to end of line.
cleol	mov d, h			; set de to end of line
		mvi e, vncols - 1
		mvi c, ' '		; space character in c
		lda attrib		; current attribute in b
		mov b, a
		jmp fills			; and do it!

; home and clear.
hcl		call home
		jmp cleow


; cursor home.
home		lxi h, 0
		ret

; clear to end of window (screen).
cleow	lda lastprow
		sta lastlrow		; set lastlrow to bottom of screen
		mvi d, vnrows - 1	; set de to end of screen
		mvi e, vncols - 1
		mvi c, ' '		; space char in c
		lda attrib		; current attribute in b
		mov b, a
		jmp fills			; and do it!

; insert a character at the cursor.
inschar	push b
		push h
		mvi a, vncols - 1	; how many chars to move?
		sub l
		jz insch1			; none: skip
		mov c, a
		mvi b, 0			; # chars in bc
		push b			; and save it
		mvi l, vncols - 1	; set hl to end of line
		call addr			; get starting address of move
		push h
		mov d, h			; dest in de
		mov e, l
		dcx h			; source in hl
;		lddr				; and move!
		db 0EDh, 0B8h		; Z80 instruction
		pop h			; address
		pop b			; byte count
		lxi d, voffset		; now do attributes
		dad d
		mov d, h			; just like before
		mov e, l
		dcx h
;		lddr
		db 0EDh, 0B8h		; another Z80 instruction
insch1	pop h
		pop b
		ret

; delete a character at the cursor.
delchar	push b
		push h
		mvi a, vncols - 1	; get # of chars to move
		sub l
		jz delch1			; none: skip
		mov c, a
		mvi b, 0			; # chars in bc
		push b
		call addr			; get starting address
		push h
		mov d, h			; de = dest
		mov e, l
		inx h			; hl = source
;		ldir				; and move!
		db 0EDh, 0B0h		; Z80 instruction
		pop h			; address
		pop b			; byte count
		lxi d, voffset		; now do attributes
		dad d
		mov d, h			; just like before
		mov e, l
		inx h
;		ldir				; and move!
		db 0EDh, 0B0h		; Z80 instruction
delch1	pop h			; get current row, col back
		push h
		mvi l, vncols - 1	; set up to clear last char in line
		mvi c, ' '
		lda attrib
		mov b, a
		call putchar		; do it
		pop h
		pop b
		ret

; delete the line containing the cursor.
delline	mvi c, 1			; and fall through

; delete <n> lines, starting with the one containing the cursor.
; <n> is in C.
delnlines	push h
		mov a, h
		add c			; other end of region to be deleted
		cpi vnrows
		jm deln1
		mvi a, vnrows
deln1	mov l, a			; h = first dest, l = first source
		mvi a, vnrows
		sub l
		mov b, a			; b = no. of lines to move
		call moveblk
		mvi a, vnrows
		sub c			; c = no. of lines to clear
		mov h, a			; h = first row to clear
		call clrblk
		pop h
		mvi l, 0			; move to beginning of line
		ret

; insert a line where the cursor is.
insline	mvi c, 1			; and fall through

; insert <n> lines before the line containing the cursor.
; <n> is in C.
insnlines	push h
		mov a, h
		mov l, h
		add c			; other end of region to be inserted
		cpi vnrows
		jm insn1
		mvi a, vnrows
insn1	mov h, a			; h = first dest, l = first source
		mvi a, vnrows
		sub h
		mov b, a			; b = no. of lines to move
		call moveblk
		mov h, l			; h = first row to clear
		call clrblk		; c = no. of lines to clear
		pop h
		mvi l, 0			; move to beginning of line
		ret

; move a block of B lines from row L to row H.
moveblk	push h
		push d
		push b
		mov a, l
		cmp h
		jm movbrev
movbfwd	mov d, h
		mov h, l
movbfwd1	mov a, b
		ora a
		jz movbret
		dcr b
		call movelin
		inr h
		inr d
		jmp movbfwd1

movbrev	mov a, h
		add b
		mov d, a			; d = h + b
		mov a, l
		add b
		mov h, a			; h = l + b
movbrev1	mov a, b
		ora a
		jz movbret
		dcr b
		dcr h
		dcr d
		call movelin
		jmp movbrev1

movbret	pop b
		pop d
		pop h
		ret


; clear C lines starting at H.
clrblk	push h
		push d
		push b
		mvi l, 0
clrblk1	mov a, c
		ora a
		jz clrblk2
		push b
		call cleol
		pop b
		inr h
		dcr c
		jmp clrblk1
clrblk2	pop b
		pop d
		pop h
		ret

; move a line from row H to row D.
movelin	push h
		push d
		push b
		mvi l, 0
		mov e, l
		lxi b, voffset
		call addr
		push h
		dad b
		xchg
		call addr
		push h
		dad b
		xchg
		lxi b, vncols
;		ldir
		db 0EDh, 0B0h		; Z80 instruction
		pop d
		pop h
		lxi b, vncols
;		ldir
		db 0EDh, 0B0h		; Z80 instruction
		pop b
		pop d
		pop h
		ret


; get physical address from logical address.

addr		push b
		lda lastprow
		inr a
		add h
		cpi vnrows
		jc addr1
		sui vnrows
addr1	mov c, a
		mvi b, 0
		mov a, l			; save col
		lxi h, rowtab
		dad b
		dad b
		mov c, a			; get col back
		mov a, m			; look row up in table
		inx h
		mov h, m
		mov l, a
		dad b			; add col
		pop b
		ret

rowtab
j		set vncols
i		set 0
		rept vnrows
		dw vvideo + j * i
i		set i + 1
		endm


; fill the screen with the data in C, the attribute in B
; from x, y location HL through DE.
fills	push h
		call addr
		xchg
		call addr
		mov a, h
		cmp d
		jnz fills1a
		mov a, l
		cmp e
fills1a	xchg
		jnc fills1		; J(area to fill doesn't wrap)
		push d
		push b
		lxi d, vvideo + vnrows * vncols - 1
		call fills2
		pop b
		pop d
		lxi h, vvideo
fills1	call fills2
		pop h
		ret

fills2	push b
		push h
		push d
		call fill			; fill in the data
		pop h
		pop d
		lxi b, voffset
		dad b
		xchg
		dad b
		pop b
		mov c, b
		call fill			; fill in the attributes
		ret

fill		mov m, c			; put down first copy
		mov a, e
		sub l
		mov c, a
		mov a, d
		sbb h
		mov b, a			; bc = de - hl = no. bytes to move
		ora c
		rz				; R(nothing to do -- only one byte to fill)
		mov d, h			; hl = source
		mov e, l
		inx d			; de = dest
;		ldir
		db 0EDh, 0B0h		; Z80 instruction
		ret


; turn on escape mode.
doesc	mvi a, stesc
		sta escmode
		ret


;
; These are the various escape-states we can be in.  They indicate
; what part of an escape sequence we've seen already.
stesc	equ 1			; Esc
stcprow	equ 2			; Esc Y
stcpcol	equ 3			; Esc Y <row>
stsetmode	equ 4			; Esc x
stclrmode equ 5			; Esc y
stinsn	equ 6			; Esc l
stdeln	equ 7			; Esc m

; We get here if we're in the middle of an escape sequence.
; escmode is in A.

escseq	push psw
		xra a
		sta escmode		; clear escape mode here, for convenience
		pop psw
		
		cpi stcprow		; row byte?
		jz docprow
		cpi stcpcol		; col byte?
		jz docpcol
		cpi stsetmode		; set-mode byte?
		jz dosetmode
		cpi stclrmode		; clear-mode byte?
		jz doclrmode
		cpi stinsn		; insert-n-lines byte?
		jz doinsn
		cpi stdeln		; delete-n-lines byte?
		jz dodeln
		
		mov a, c
		cpi 'L'			; insert (1) line?
		jz doinslin
		cpi 'M'			; delete (1) line?
		jz dodellin
		
		lda insdelcnt		; for anything else: do any saved
		ora a			; insertions/deletions first
		cnz doinsdel
		
		mov a, c
		cpi 'Y'			; cursor pos?
		jz docp
		cpi 'K'			; clear to end of line?
		jz docleol
		cpi 'E'			; home and clear screen?
		jz dohcl
		cpi 'H'			; home?
		jz dohome
		cpi 'J'			; clear to end of screen?
		jz docleow
		cpi 'A'			; cursor up?
		jz doup
		cpi 'B'			; cursor down?
		jz dodown
		cpi 'C'			; cursor right?
		jz doright
		cpi 'D'			; cursor left?
		jz doleft
		cpi '@'			; set char-insert mode?
		jz inschon
		cpi 'O'			; clear char-insert mode?
		jz inschoff
		cpi 'N'			; delete char?
		jz dodelchar
		cpi 'l'			; insert n lines?
		jz doinsnlins
		cpi 'm'			; delete n lines?
		jz dodelnlins
		cpi 'p'			; set inverse video?
		jz doinvon
		cpi 'q'			; clear inverse video?
		jz doinvoff
		cpi 'x'			; set mode?
		jz setmode
		cpi 'y'			; clear mode?
		jz clrmode
		cpi 'v'			; set wrap mode?
		jz dowrapon
		cpi 'w'			; clear wrap mode?
		jz dowrapoff
		cpi 'F'			; set graphics mode?
		jz dografon
		cpi 'G'			; clear graphics mode?
		jz dografoff

escfail	push b			; not any recognized command.  display
		mvi c, esc		; sequence literally so user can see what
		call display		; happened
		pop b
		call display
		ret

docp		mvi a, stcprow		; cursor pos command: set esc mode
		sta escmode
		ret

docprow	mov a, c			; get row byte
		sui 32			; subtract bias
		mov h, a
		mvi a, stcpcol		; set new esc mode
		sta escmode
		lda curoffp
		inr a			; cursor off during CP
		sta curoffp
		ret

docpcol	mov a, c			; get col byte
		sui 32			; subtract bias
		mov l, a
		lda curoffp
		dcr a			; cursor back on (unless it was already off)
		sta curoffp
		ret

docleol	equ cleol

dohcl	equ hcl

dohome	equ home

docleow	equ cleow

doup		equ up

dodown	equ down

doright	equ right

doleft	equ left

inschon	mvi a, 1			; set insert-char mode
		sta insmode
		ret

inschoff	xra a			; clear insert-char mode
		sta insmode
		ret

dodelchar	equ delchar

doinslin	lda insdelcnt		; accumulate insertions
		ora a
		push psw
		cm doinsdel		; do any saved deletions first
		pop psw
		inr a			; then increment insdelcnt
		sta insdelcnt
		ret

dodellin	lda insdelcnt		; accumulate deletions
		dcr a
		push psw
		cp doinsdel		; do any saved insertions first
		pop psw
		sta insdelcnt
		ret

doinsnlins mvi a, stinsn		; set escmode to expect no. of insertions
		sta escmode
		ret

dodelnlins mvi a, stdeln		; set escmode to expect no. of deletions
		sta escmode
		ret

doinsn	equ insnlines

dodeln	equ delnlines

doinsdel	lda insdelcnt		; do saved insertions/deletions
		ora a			; any to do?
		rz				; no: done
		push b
		jm doinsdel1		; pos: insertions; neg: deletions
		mov c, a			; insertion was saved
		call insnlines		; do it
		jmp doinsdel2
doinsdel1	cma
		inr a
		mov c, a			; deletion was saved
		call delnlines		; do it
doinsdel2	pop b
		xra a
		sta insdelcnt		; clear saved count
		ret

doinvon	lda attrib		; inverse video on
		ori vinverse
		sta attrib
		ret

doinvoff	lda attrib		; inverse video off
		cma
		ori vinverse
		cma
		sta attrib
		ret

setmode	mvi a, stsetmode	; set escmode to expect mode to set
		sta escmode
		ret

clrmode	mvi a, stclrmode	; set escmode to expect mode to clear
		sta escmode
		ret

; come here with a mode to set in C
dosetmode	mov a, c
		cpi '5'
		jz setcuroff		; turn cursor off
		cpi '@'
		jnc setattr		; set display attributes
		cpi '*'
		jz setscrol		; set scroll mode
		push b
		mvi c, esc		; display unimplemented sequence, so
		call display		; user can see what happened
		mvi c, 'x'
		call display
		pop b
		call display
		ret

setcuroff	mvi a, 1			; turn cursor off
		sta curoffp
		ret

setattr	call attrbit		; get bit for this attribute
		lda attrib		; or it into current attribute byte
		ora e
		sta attrib
		ret

setscrol	lda scrollp		; set scroll (Z-19 normal) mode
		ora a
		rnz				; already on
		mvi a, 1
		sta scrollp
		mvi h, vnrows - 1
		lda lastlrow		; get last logical row
		out vscrol		; make it last physical row
		sta lastprow
		ret

; come here with a mode to clear in C
doclrmode	mov a, c
		cpi '5'
		jz clrcuroff		; turn cursor back on
		cpi '@'
		jnc clrattr		; clear an attribute
		cpi '*'
		jz clrscrol		; turn roll mode back on
		push b
		mvi c, esc		; display unimplemented sequence
		call display		; so the user can see what happened
		mvi c, 'y'
		call display
		pop b
		call display
		ret

clrcuroff	xra a			; turn cursor back on
		sta curoffp
		ret

clrattr	call attrbit		; get bit for attribute
		lda attrib
		cma
		ora e			; clear it in current attr. byte
		cma
		sta attrib
		ret

clrscrol	lda scrollp		; set "roll" mode: no scrolling
		ora a
		rz 				; scroll mode already off
		xra a
		sta scrollp
		lda lastlrow
		mov h, a
		mvi a, vnrows - 1	; return screen to 0-origin
		out vscrol
		sta lastprow
		ret

; given command char in A, leaves attribute bit set in E
attrbit	sbi '@'
		jz attrbit1
		mov e, a
		mvi a, 2			; start with 2
attrbit2	rlc				; rotate left
		dcr e			; the right number of times
		jnz attrbit2
		mov e, a
		ret
attrbit1	mvi e, 0FCh		; '@': all attributes
		ret

dowrapon	mvi a, 1			; turn wrap mode (end-of-line wrapping) on
		sta wrapp
		ret

dowrapoff	xra a			; turn wrap mode (end-of-line wrapping) off
		sta wrapp
		ret

dografon	lda attrib		; turn graphics mode on (enable ROM)
		ani 0FDh
		sta attrib
		ret

dografoff	lda attrib		; turn graphics mode off (disable ROM)
		ori 2
		sta attrib
		ret



;
; Data section.  If you want to change the default modes (e.g., to
; wrapping and scrolling), this is the place to do it.  (Just change
; wrapp and scrollp.)
;

curaddr	dw 0				; logical address of cursor
lastprow	db vnrows - 1		; physical last row
lastlrow	db vnrows - 1		; logical last row
attrib	db 3				; character attribute byte
escmode	db 0				; escape-sequence mode
wrapp	db 0				; wrap at end of line?
insmode	db 0				; insert-character mode
scrollp	db 0				; scroll mode
curoffp	db 0				; cursor-off mode
insdelcnt	db 0				; insert/delete line count

; End of Z-19.ASM -- Z-19 Emulator for SSM VB3
  