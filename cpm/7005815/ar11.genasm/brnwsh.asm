;BBBB    RRRR     AAA     III    N   N   W   W    AAA     SSS    H   H
;B   B   R   R   A   A     I     NN  N   W   W   A   A   S   S   H   H
;B   B   R   R   A   A     I     N N N   W   W   A   A    S      H   H
;BBBB    RRRR    A   A     I     N  NN   W W W   A   A     S     HHHHH
;B   B   R R     AAAAA     I     N   N   W W W   AAAAA      S    H   H
;B   B   R  R    A   A     I     N   N   W W W   A   A   S   S   H   H
;BBBB    R   R   A   A    III    N   N    WWW    A   A    SSS    H   H
;
;
        ;A Z80 PROGRAM TO TEST MEMORY RIGOROUSLY AND QUICKLY
        ;RUN WITH NO M1 WAIT STATES TO FIND SLOW CHIPS
;
;last modified 8 jun 1981 at nosc hawaii to configure for that system

;
;A SERIALIZED CIPHER IS HIDDEN IN THIS PROGRAM BY WHICH IT MAY BE
;TRACED TO THE SOURCE OF ITS RELEASE.
;
;
        ORG     0100H
CR      EQU     0DH
LF      EQU     0AH
TCR     EQU     8DH             ;WITH BIT 7 SET FOR TERMINATING STRINGS
TLF     EQU     8AH
TSP     EQU     0A0H
MAXADR  EQU     0FFFFH          ;64K IF NO MEMORY MAPPED IO
START   JR      ST1             ;JUMP AROUND DATA AREA

GIL     equ     1               ;home system configuration
ZOBEX   equ     0               ;nosc configuration

;USER'S JUMP TABLE GOES HERE

        ORG     106H

INIT:   JP      INITX
CHKIN:  JP      CHKINX
CRTO:   JP      CRTOX
PRTO:   JP      PRTOX
FREEMEM:DEFW    ENDOFIT

PBYTE:  JP      CRTOX           ;SWITCH FOR PRINTER OR CRT

FIRST   DEFW    0               ;FIRST ADDR TO TEST
LAST    DEFW    0               ;LAST ADR TO TEST
NEX1K   DEFW    0               ;NEXT 1K CHUNK FOR XTALK
END1K   DEFW    0               ;END OF 1K CHUNK
NBYTES  DEFW    0               ;LAST - FIRST +1
ITER    DEFB    0               ;NO OF TIMES TO DO TEST
CTR     DEFB    0               ;COUNTER FOR ITERATIONS
ERCTR   DEFW    0               ;ERROR COUNTER
TYCTR   DEFB    0               ;COUNTS ADDRESS TYPEOUTS IN XTALK
TESTAD  DEFW    0               ;CURRENT ADR FOR IBUS TEST
BYTCNT  DEFW    0               ;# BYTES LEFT TO TEST
LONGI:  DEFB    0FFH            ;FF IF LONG TEST NOT WANTED, 0 IF IT IS
XTLK:   DEFB    0FFH            ;FF IF XTALK TESTS NOT WANTED
CONTMD: DEFB    0FFH            ;FF IF CONTINUOUS MODE NOT WANTED

ST1     LD      SP,STACK        ;GIVE STACK 64 BYTES OF ROOM
        XOR     A               ;CLEAR A
        LD      DE,STAKBAK
        LD      HL,STACK-3      ;LEAVE ROOM FOR THE CALL
        CALL    SADEHL          ;ZERO STACK AREA
        CALL    INIT            ;DO WHATEVER HOUSEKEEPING IS NEEDED
        LD      HL,HITHERE
        CALL    GETANS
        JP      NZ,ST2
        LD      HL,(PRTO+1)     ;GET PRINTER ADDRESS
        JP      ST3
ST2:    LD      HL,(CRTO+1)     ;GET CRT ADDRESS
ST3:    LD      (PBYTE+1),HL    ;PUT CRT OR PRT ADR IN VECTOR
        LD      HL,NOTMSG
        CALL    TYPMSG
        LD      HL,START
        CALL    TYPSHL           ;TYPE BEGIN OF PROGRAM
        LD      HL,(FREEMEM)    ;DON'T TEST BELOW END PROGRAM
        CALL    TYPSHL
        LD      HL,ENTMSG
        CALL    TYPMSG            ;TYPE ENTRY MESSAGE
        CALL    GETHEX           ;GET FIRST ADDRESS
        LD      (FIRST),HL      ;STORE FIRST ADDRESS
        CALL    GETHEX           ;GET LAST ADDRESS
        LD      (LAST),HL       ;STORE LAST ADDRESS
        LD      HL,(LAST)       ;COMPUTE NBYTES
        LD      BC,(FIRST)
        AND     A               ;CLEAR CARRY FLAG
        SBC     HL,BC           ;DO SUBTRACT
        INC     HL              ;ADD ONE
        LD      (NBYTES),HL     ;STORE NBYTES TO TEST
;
        LD      HL,ITMSG
        CALL    TYPMSG            ;TYPE ITERATIONS MESSAGE
        CALL    GETHEX           ;GET FROM TERMINAL
        LD      A,L
        LD      (ITER),A        ;MAX IS FF
        LD      HL,LNGMSG
        CALL    GETANS          ;ASK IF WANT LONG IBUS TEST
        LD      (LONGI),A       ;STORE 0 IF YES, FF IF NO
        LD      HL,XTKMSG
        CALL    GETANS          ;ASK IF WANT CROSSTALK TESTS
        LD      (XTLK),A
        LD      HL,CONMSG
        CALL    GETANS          ;ASK IF WANT TO TEST FOREVER
        LD      (CONTMD),A
        LD      HL,0
        LD      (ERCTR),HL      ;CLEAR ERROR COUNTER
;NOW BEGIN TESTING
;
;                      ZEROES AND ONES TEST
;
;
;             STORE ALL ZEROES THRU AREA
;
;             READ BACK AND TEST
;
;
;             STORE ALL ONES THRU AREA
;
;             READ BACK AND TEST
;
;
;             RECYCLE N ITERATIONS
;
;
;DO ZEROES AND ONES TEST FIRST
BIGLP:  CALL    SETCNT          ;SET CTR TO ITERATIONS
        LD      HL,ZMSG
        CALL    TYPMSG
T1      LD      A,0             ;START WITH ZEROES
        CALL    STR             ;STORE IN WHOLE AREA
        CALL    RD              ;CHECK FOR ERRORS
        LD      A,0FFH          ;NOW DO ALL ONES
        CALL    STR
        CALL    RD
        CALL    NTERUP          ;SEE IF ANYTHING TYPED
        CALL    CKCNT           ;SEE IF CTR IS ZERO YET
        JR      NZ,T1           ;GO BACK AND DO IT AGAIN
;
;                      INCREMENTING BYTE TEST
;
;
;             STORE 1 TO FF (NEVER 00) IN CONSECUTIVE BYTES
;
;               (USE CPI TO VERIFY STORED CORRECTLY)
;
;             REPEAT TIL END OF AREA
;
;
;             READ BACK AND TEST FOR KNOWN VALUES
;
;             RECYCLE N ITERATIONS
;
;
;DO ROTATING PATTERN TEST
        CALL    SETCNT          ;SET CTR FOR INCREMENTING PATTERN TEST
        LD      HL,INCMSG       ;NOW DO INCREMENTING PATTERN
        CALL    TYPMSG            ;TYPE INCREMENTING PATTERN TEST
T2      CALL    STRROT          ;STORE PATTERNS
        CALL    RDROT           ;TEST THEM
        CALL    NTERUP          ;SEE IF BOSS WANTS TO STOP
        CALL    CKCNT           ;SEE IF ITERATIONS DONE
        JR      NZ,T2           ;NOT YET
;
;
;             PART A: (NOP TEST)
;
;             STORE FF EVERYWHERE EXCEPT PROGRAM
;
;             SET UP 38H TO JP XYZ
;
;             STORE NO-OP (00 BYTE)
;
;             STORE RST 38H (FF BYTE) IN NEXT BYTE
;
;             LOAD REGISTERS WITH KNOWN PATTERN
;
;             JP NO-OP
;
;
; XYZ:        TEST TO SEE IF CAME FROM RIGHT PLACE
;
;             TEST TO SEE IF REGISTERS CHANGED
;
;             SET 00 BYTE TO FF (UNLESS DOING LONG MODE)
;
;             INDEX UP ONE BYTE AND REPEAT
;
;
;
;             PART B: (INSTRUCTION TEST)
;
;             SET UP AS FOR PART A
;
;
;             STORE SHORT PROGRAM THAT TRANSFERS DATA AND SHIFTS
;
;             SET UP REGISTERS WITH KNOWN PATTERNS
;
;             CALL PROGRAM
;
;
;             SEE IF CAME BACK PROPERLY
;
;             TEST REGISTERS FOR PROPER VALUES
;
;             INDEX TO NEXT BYTE AND REPEAT TO END OF AREA
;
;             RECYCLE N ITERATIONS
;
;
;DO INSTRUCTION READUP TESTS
;THIS TEST IS DEATH ON SLOW MEMORY CHIPS BECAUSE THE Z80 WITH
;NO M1 WAIT STATES NEEDS MEMORY ACCESS TIME UP TO 130 NS FASTER
;ON INSTRUCTION READUP THAN IT DOES FOR OPERAND READ/WRITE.
;THIS TEST WRITES IN ALL RAM MEMORY EXCEPT THE PROGRAM AREA
;IN ORDER TO DEFEND AGAINST WHAT BAD INSTRUCTION READUP CAN
;DO TO A PROGRAM.  VERY VERY BAD CHIPS CAN STILL WIPE OUT
;THE PROGRAM THEORETICALLY, ALTHOUGH IT HAS NOT BEEN OBSERVED
;SINCE THE LATEST BULLETPROOF STACK CODE HAS BEEN ADDED.
;
SLOCHIP XOR     A               ;CLEAR TYPEOUT COUNTER
        LD      (TYCTR),A
        CALL    SETCNT          ;PRESET COUNT OF ITERATIONS
        LD      HL,IBUSMS       ;TYPE TEST WE'RE DOING
        CALL    TYPMSG
        LD      A,0FFH          ;STORE FF EVERYWHERE
        LD      DE,0
        LD      HL,START-1
        CALL    SADEHL          ;STORES FF FROM ZERO TO BASE
        LD      DE,(FREEMEM)    ;FIRST BYTE OF FREE MEMORY
        LD      HL,MAXADR       ;END OF ALLOWED RAM SPACE
        CALL    SADEHL          ;FROM END OF PROGRAM TO END OF MEMORY
IBUS:   LD      DE,(FIRST)
        LD      HL,(LAST)
        LD      A,0FFH
        CALL    SADEHL          ;STORE FF IN TEST MEMORY
        LD      HL,(NBYTES)
        LD      BC,LNGTH
        AND     A               ;CLEAR CARRY
        SBC     HL,BC           ;LEAVE ROOM FOR TEST PROGRAM
        LD      (BYTCNT),HL     ;SAVE BYTES LEFT TO TEST
        LD      HL,(FIRST)
        LD      (TESTAD),HL     ;SAVE CURRENT TEST ADDRESS
        LD      (GOTHAR+1),HL   ;IN CASE DO LONG TEST ALWAYS JUMP TO BEGIN
NOPFF:  LD      (HL),00H        ;NO OP
        INC     HL
        LD      (HL),0FFH       ;RESTART 38H
        DEC     HL
        LD      A,(LONGI)       ;GET LONG TEST FLAG
        OR      A               ;IF 0 WE'LL DO IT
        JR      Z,YLI           ;JUMP AROUND STORE OF PLACE TO JUMP
        LD      (GOTHAR+1),HL   ;PRESET JSR
YLI:    LD      A,0C3H          ;JP INST
        LD      (38H),A         ;STORE AT RESTART 38H LOCATION
        LD      HL,TESTO        ;PLACE TO GO
        LD      (39H),HL        ;STORE IT
        CALL    LDEM            ;LOAD UP REGS WITH KNOWN PATTERN
GOTHAR: JP      0               ;PLACE TO GO GETS STORED HERE
;
;
TESTO:  LD      IX,NOPMSG       ;MESSAGE OF WHICH TEST FAILED
        CALL    ICHECK          ;SEE IF REGS ARE OK
        POP     HL              ;GET RETURN ADR FROM STACK
        DEC     HL
        DEC     HL
        PUSH    HL              ;SAVE WHERE CAME FROM
        LD      DE,(TESTAD)     ;WHERE WE SHOULD HAVE COME FROM
        AND     A
        SBC     HL,DE
        JR      Z,REAL          ;IF CAME FROM RIGHT PLACE
        LD      HL,LOSTMSG
        CALL    LOSTIT          ;OOPS
;
;NOW TRY A FEW REAL INSTRUCTIONS
;
REAL:
        LD      SP,STACK
        LD      DE,(TESTAD)
        LD      HL,TESTCOD
        LD      BC,LNGTH
        LDIR                    ;BLOCK MOVE PROGRAM TO TEST AREA
        LD      HL,(TESTAD)
        LD      (CALLIT+1),HL   ;THIS TIME WE'LL DO A CALL
        LD      A,0C3H          ;JP
        LD      (38H),A
        LD      HL,WILDBLUE
        LD      (39H),HL        ;IN CASE FLY OFF THE HANDLE SOMEWHERE
        CALL    LDEM            ;LOAD UP REGISTERS
CALLIT  CALL    0               ;HERE WE GO - I HOPE

;SHOULD COME BACK HERE IF CODE IS EXECUTED ANYTHING LIKE RIGHT

CUMBAK: LD      SP,STACK        ;IN CASE STACK GOT CLOBBERED BY BAD MEM
        LD      IX,EXMSG        ;TEST THAT FAILED MESSAGE
        CALL    ICHECK          ;SEE IF REGS ARE WHAT THEY SHOULD BE
        LD      HL,(TESTAD)
        LD      A,(HL)
        CP      0AAH            ;SEE IF SWAP GOT DONE RIGHT
        CALL    NZ,ERR9
        INC     HL              ;POINT TO NEXT BYTE
        LD      A,(HL)
        CP      0AAH
        CALL    NZ,ERR9

DUNONE: CALL    NTERUP          ;SEE IF OP WANTS ANYTHING
        LD      HL,(TESTAD)     ;GET HL BACK
        LD      BC,(BYTCNT)     ;GET BC BACK
        LD      A,(LONGI)       ;0 IF LONG TEST WANTED
        LD      (HL),A          ;SET 00 OR FF WHERE INST WAS
        CPI                     ;HL UP, BC DOWN
        LD      (TESTAD),HL     ;UPDATE TEST ADDRESS
        LD      (BYTCNT),BC     ;UPDATE # BYTES LEFT TO TEST
        JP      PE,NOPFF        ;GO BACK FOR MORE
THRU1:  CALL    NTERUP
        LD      A,(TYCTR)       ;UPDATE TIMES TYPED
        INC     A
        LD      (TYCTR),A
        AND     1FH             ;USE 5 BITS TO COUNT TO 32
        CALL    Z,CRLF          ;THAT'S ENOUGH
        LD      HL,SPIMSG       ;TYPE SPACE I TO INDICATE ONE PASS
        CALL    TYPMSG
        CALL    CKCNT
        JP      NZ,IBUS        ;GO BACK FOR ANOTHER PASS
        JP      GWRT            ;GO TO CROSSTALK TESTS

RDYGO:  DEFM    'READY TO LEAP?',CR,LF

TESTCOD:NOP
        NOP
        LD      A,E
        RLA
        LD      IX,5555H
        LD      HL,0AAAAH
        LD      SP,(TESTAD)
        INC     SP
        INC     SP              ;SO WILL PUSH TO FIRST TWO BYTES
        PUSH    IX
        EX      (SP),HL         ;HL_5555, (TESTAD)_AAAA
        LD      SP,STACK-2
TESTND: RET                     ;RETURN TO CALLER

LNGTH:  EQU     TESTND-TESTCOD+1

;
;STORES A FROM ADR IN DE THRU ADR IN HL
SADEHL: AND     A       ;CLEAR CARRY
        SBC     HL,DE
        INC     HL      ;#BYTES TO STORE
        LD      B,H
        LD      C,L     ;TO BYTE COUNTER
        EX      DE,HL   ;GET WHAT WAS IN DE
PUTIT:  LD      (HL),A
        CPI
        JP      PE,PUTIT        ;LOOP BACK TIL DONE
        RET
;
;LOADS REGISTERS WITH KNOWN PATTERN
;
LDEM    LD      A,0B4H          ;AS GOOD A NUMBER AS ANY
        LD      BC,0BBCCH
        LD      DE,0DD5AH
        LD      HL,5555H
        OR      A               ;CLEAR CARRY BIT
        RET
;
;CHECKS CONTENTS OF REGISTERS TO SEE THEY ARE WHAT SHOULD BE
;
ICHECK: JR      C,ERR1          ;CARRY SHOULD NOT BE SET
        CP      0B4H
        JR      NZ,ERR2         ;A SHOULD BE B4
        LD      A,B
        CP      0BBH
        JR      NZ,ERR3
        LD      A,C
        CP      0CCH
        JR      NZ,ERR4
        LD      A,D
        CP      0DDH
        JR      NZ,ERR5
        LD      A,E
        CP      5AH
        JR      NZ,ERR6
        LD      A,H
        CP      55H
        JR      NZ,ERR7
        LD      A,L
        CP      55H
        JR      NZ,ERR8
        RET                     ;NO ERRORS IF GOT THIS FAR

ERR1    LD      HL,CBIT
        JR      TYERR
ERR2    LD      HL,ACHNG
        JR      TYERR
ERR3    LD      HL,BCHNG
        JR      TYERR
ERR4    LD      HL,CCHNG
        JR      TYERR
ERR5    LD      HL,DCHNG
        JR      TYERR
ERR6    LD      HL,ECHNG
        JR      TYERR
ERR7    LD      HL,HCHNG
        JR      TYERR
ERR8    LD      HL,LCHNG
        JR      TYERR
ERR9:   LD      HL,EXSP

;ENTERED WITH IX POINTING AT MESSAGE ABOUT WHICH TEST FAILED
;HL POINTS TO ERROR MESSAGE
;
TYERR:  CALL    CRLF
        PUSH    HL
        PUSH    IX
        POP     HL              ;GET WHICH TEST FAILED IN HL
        CALL    TYPMSG            ;TYPE IT
        LD      HL,(ERCTR)      ;GET NO OF ERRORS SO FAR
        INC     HL
        LD      (ERCTR),HL      ;UPDATE IT
        CALL    TYPSHL           ;TYPE NO OF ERRORS
        CALL    SPACE
        POP     HL
        CALL    TYPMSG            ;HL POINTS TO MESSAGE
        CALL    SPACE
        LD      A,'@'
        CALL    PBYTE
        LD      HL,(TESTAD)     ;WHERE WE WERE TESTING WHEN THINGS GOT BAD
        CALL    TYPSHL           ;TYPE THIS ADDRESS
        CALL    NTERUP          ;SEE IF STOP AFTER THIS ERROR
        RET
;
;TYPES WHERE WE WERE WHEN WE GOT LOST, AND MAYBE
;WHERE WE GOT TO MORE OR LESS
LOSTIT: CALL    TYERR
        LD      HL,TOMSG        ;TYPE "TO"
        CALL    TYPMSG
        POP     HL              ;PASS BY RETURN ADR ON STACK
        POP     HL              ;GET FROM WHENCE WE WENT TO 38H
        DEC     SP
        DEC     SP
        DEC     SP
        DEC     SP              ;GET STACK BACK IN SHAPE
        CALL    TYPSHL           ;TYPE IT
        CALL    NTERUP
        RET
;
;COME HERE FROM INSTRUCTION TEST IF DIDN'T DO NORMAL RETURN
WILDBLUE:       LD      IX,EXMSG        ;TEST WHICH FAILED
        CALL    ICHECK
        LD      HL,LOSTMSG
        CALL    LOSTIT          ;TYPE WHAT LITTLE WE KNOW ABOUT IT
        POP     HL              ;STACK CLEANUP
        POP     HL              ;STACK CLEANUP
        JP      DUNONE          ;GIVE UP ON THIS ADDRESS, GO TO NEXT
;
;BEGIN CROSSTALK TESTS (RUNNING TIME GOES UP EXPONENTIALLY)
;
;ONLY EXECUTES THESE TWO TESTS ONCE, REGARDLESS OF INTERATION COUNTER
;BECAUSE THEY ARE SO LONG RUNNING.  WILL NOT DO TEST AT ALL UNLESS AREA
;IS AT LEAST 400H (1024) IN SIZE.
;
;                      EXPONENTIAL WRITE TEST
;
;
;             ZERO THE AREA
;
;             CLEAR INDEX 1
;
;
; LOOP1:      STORE FF BYTE (INDEX 1)
;
;             CLEAR INDEX 2
;
;
; LOOP2:      STORE 00 (INDEX 2)
;
;             SEE IF FF STILL OK
;
;             BUMP INDEX 2
;
;             LOOP2 TIL END OF AREA
;
;
;             BUMP INDEX 1
;
;             LOOP1 TIL END OF AREA
;
;             EXIT TO EXPONENTIAL READ TEST
;
;
GWRT:   XOR     A               ;CLEAR TYPEOUT COUNTER
        LD      (TYCTR),A
        LD      A,(XTLK)        ;SEE IF WANT TO DO THESE TESTS AT ALL
        OR      A               ;SET FLAGS
        JP      NZ,DONE         ;NOT WANTED
T3      LD      HL,GWRMSG
        CALL    SETUP           ;GET AREA DEFINED, ETC
WLP0:   CALL    COMCOD          ;LOOP HOUSEKEEPING SUBR
        JP      C,STRD          ;DONE IF MINUS
        LD      DE,(NEX1K)      ;DE KEEPS TRACK OF WHERE THE FF IS
WLP2:   CALL    TYPEAD          ;TYPE ADDRESS IF MULTIPLE OF 100H
        LD      HL,(NEX1K)      ;STARTING ADR OF 1K CHUNK
        LD      BC,03FFH        ;ALWAYS 1 K CHUNKS
        LD      A,0FFH
        LD      (DE),A          ;STORE THE FF BYTE
WMLP    XOR     A               ;CLEAR A
        LD      (HL),A          ;STORE A ZERO BYTE WHERE HL IS
        LD      A,(DE)          ;GET SUPPOSED FF BYTE
        CP      0FFH            ;SEE IF IT STILL IS FF
        JR      NZ,WOOPS        ;MAYBE OK, MAYBE NOT
        XOR     A               ;CLEAR A AGAIN
WLP1    CPI                     ;COMPARE A & (HL), DEC BC
        JP      PO,WEND1        ;THRU AREA?
        JR      Z,WMLP          ;CHECK NEXT ADDRESS
        CALL    ERR             ;BYTE WASN'T ZERO
        JR      WMLP
;
WOOPS   AND     A               ;CLEAR CARRY FLAG
        PUSH    HL              ;SAVE ADDRESS POINTER
        SBC     HL,DE           ;COMPARE TO WHERE FF SUPPOSED TO BE
        POP     HL              ;GET POINTER BACK
        JR      NZ,WERR         ;REAL ERROR, IT WASN'T HERE
        LD      A,0FFH          ;NOW RESTORE THE CLOBBERED FF
        LD      (DE),A
        JR      WLP1            ;KEEP GOING
;
WERR    INC     HL              ;SIMULATE ACTION OF CPI ON HL
        CALL    ERR             ;TYPE OUT THE ERROR
        JR      WMLP
;
WEND1   LD      HL,(END1K)      ;SEE IF WE'RE THRU THE AREA YET
        AND     A               ;CLEAR CARRY
        SBC     HL,DE           ;COMPARE
        JR      NZ,KG1          ;NOT DONE YET
        CALL    UPDATE          ;SET NEXT 1K CHUNK
        JR      WLP0            ;CONTINUE TESTING WITH NEXT CHUNK
KG1:    INC     DE              ;UP POINTER TO FF BYTE
        JR      WLP2
;
;
;                     EXPONENTIAL READ TEST
;
;
;             ZERO THE AREA
;
;
; LOOP1:      STORE FF (INDEX 1)
;
;             CLEAR INDEX 2
;
;
; LOOP2:      READ BYTE (INDEX 2)
;
;             TEST FOR CORRECTNESS
;
;             SEE IF FF STILL OK
;
;             BUMP INDEX 2
;
;             LOOP2 TIL END OF AREA
;
;
;             BUMP INDEX 1
;
;             LOOP1 TIL END OF AREA
;
;             EXIT
;
;
;EXPONENTIAL READ CROSSTALK TEST
;
STRD    LD      HL,GRDMSG
        CALL    SETUP
RDLP0:  CALL    COMCOD
        JR      C,DONE          ;YES
        LD      DE,(NEX1K)      ;DE KEEPS TRACK OF FF BYTE
STLP:   CALL    TYPEAD          ;TYPE ADDRESS EVERY 100H
        LD      HL,(NEX1K)      ;BEGIN PASS AT FIRST BYTE
        LD      BC,03FFH        ;ALWAYS TEST 1K
        LD      A,0FFH          ;ALL ONES
        LD      (DE),A          ;STORE FF IN (DE)
        XOR     A               ;CLEAR A
MLP     CPI                     ;SEE IF THIS BYTE IS ZERO
        JP      PO,END1         ;AT END OF AREA IF PO
        JR      Z,MLP           ;KEEP LOOKING FOR FF OR END OF AREA
MAYBE   PUSH    HL              ;SAVE NEXT BYTE TO TEST
        DEC     HL              ;TO GET BACK TO BYTE JUST TESTED
        AND     A               ;CLEAR CARRY FLAG
        SBC     HL,DE           ;SEE IF WHERE FF WAS SUPPOSED TO BE
        JR      NZ,ERROR        ;NO, THIS IS AN ERROR FOR SURE!
        POP     HL
        JR      MLP             ;FF WAS SUPPOSED TO BE HERE
END1:   LD      HL,(END1K)
        AND     A               ;CLEAR CARRY FLAG
        SBC     HL,DE
        JR      NZ,KG2          ;IF NOT DONE WITH 1K CHUNK YET
        CALL    UPDATE
        JR      RDLP0
KG2:    LD      A,(DE)          ;GET THE SUPPOSED FF BYTE
        CP      0FFH            ;SEE IF IT STILL IS FF
        JR      NZ,ERROR        ;LOST THE FF
        XOR     A               ;CLEAR A
        LD      (DE),A          ;CLEAR THE FORMER FF BYTE
        INC     DE
        JR      STLP            ;END OF ONE LOOK, GO STORE FF IN NEXT BYTE
;
;
;END OF ONE PASS OF SAND DUNE TESTS
DONE    LD      HL,DUNMSG
        CALL    TYPMSG
        LD      HL,ERCTR
        LD      A,(ERCTR+1)
        ADD     A,(HL)
        OR      A
        JR      Z,MEMOK         ;ERROR COUNTER WAS ZERO
        LD      HL,BADMSG
D1:     CALL    TYPMSG
        LD      HL,(ERCTR)
        CALL    TYPSHL
        LD      HL,ERSMSG
        CALL    TYPMSG            ;TYPE TOTAL NO OF ERRORS
        LD      A,(CONTMD)      ;SEE IF WANT TO TEST FOREVER
        OR      A
        JP      Z,BIGLP         ;YES, GO ANOTHER ROUND OF INTERATIONS
        JP      START           ;GO BACK AND ASK FOR MORE
MEMOK:  LD      HL,OKMSG
        JR      D1              ;TYPE GOOD MESSAGE
ERROR   POP     HL
        CALL    ERR
        JP      MLP
; TYPES TEST NAME, CLEARS AREA, SETS FIRST 1K CHUNK ADDRESS
SETUP:  CALL    TYPMSG            ;TYPE TEST NAME
        CALL    CLAREA          ;ZERO THE TEST AREA
        LD      HL,(FIRST)      ;STARTING ADDRESS
        LD      (NEX1K),HL      ;PRESET
        RET
;CONTROLS TEST AREA IN 1K CHUNKS AT A TIME TO KEEP
;RUNNING TIME REASONABLE SINCE IT GOES UP AS THE SQUARE
;OF THE NUMBER OF BYTES TESTED.  RETURNS NEGATIVE FLAG
;WHEN TOTAL AREA FINISHED.
COMCOD: LD      HL,(NEX1K)      ;GET START OF 1K CHUNK TO TEST
        LD      DE,03FFH
        ADD     HL,DE           ;COMPUTE LAST ADR OF 1K CHUNK
        LD      (END1K),HL      ;SAVE IT
        EX      DE,HL           ;END1K TO DE
        LD      HL,(LAST)
        AND     A               ;CLEAR CARRY
        SBC     HL,DE           ;SEE IF THROUGH TOTAL AREA YET
        RET                     ;RETURN C IF DONE
CLAREA  LD      A,0             ;CLEARS THE TEST AREA TO ZEROES
        CALL    STR
        RET
SETCNT  LD      A,(ITER)        ;GET ITERATIONS DESIRED
        LD      (CTR),A         ;STORE IN CTR
        RET
;
CKCNT   LD      HL,CTR          ;POINT AT CTR
        DEC     (HL)            ;DECREMENT THE COUNT
        RET                     ;WITH THE FLAGS SET
;STORE A PATTERN ROUTINE
STR     LD      DE,(FIRST)      ;GET BEGINNING
        LD      HL,(LAST)
        CALL    SADEHL
        RET
;READ AND TEST PATTERN
RD      LD      HL,(FIRST)
        LD      BC,(NBYTES)
RD1     CPI                     ;SEE IF SAME AS A
        CALL    NZ,ERR
        JP      PE,RD1
        RET
;TYPE OUT ERROR
;HL HAS ADDRESS OF FAILURE
;A HAS GOOD BYTE
ERR     PUSH    HL              ;SAVE WHERE WE'RE AT
        PUSH    AF              ;SAVE A AND FLAGS
        DEC     HL              ;GET ACTUAL ADR WHERE FAILED
        PUSH    HL
        CALL    CRLF
        LD      HL,(ERCTR)     ;# SO FAR
        INC     HL             ;ADD THIS ONE
        LD      (ERCTR),HL     ;STORE IT BACK
        CALL    TYPSHL           ;TYPE # OF ERRORS SO FAR
        POP     HL              ;GET ADDRESS OF FAILURE
        CALL    TYPSHL
        CALL    SPACE
        LD      A,(HL)          ;GET BAD BYTE
        CALL    P2HEX
        LD      HL,SHDBE
        CALL    TYPMSG           ;TYPE SHOULD BE
        POP     AF              ;GET A BACK
        PUSH    AF
        CALL    P2HEX           ;TYPE GOOD BYTE
        CALL    NTERUP          ;SEE IF WANT TO STOP A WHILE
        POP     AF
        POP     HL
        RET
;STORE INCREMENTING PATTERN
STRROT  LD      A,0
        LD      HL,(FIRST)
        LD      BC,(NBYTES)
ROT1    INC     A
        JR      Z,ROT1          ;NEVER USE ZERO
        LD      (HL),A          ;STORE BYTE
        CPI                     ;CK IT ALREADY
        CALL    NZ,ERR          ;WOOPS
        JP      PE,ROT1
        RET
;CHECK INCREMENTING PATTERNS
RDROT   LD      A,0
        LD      HL,(FIRST)
        LD      BC,(NBYTES)
RDROT1  INC     A               ;NEXT PATTERN
        JR      Z,RDROT1        ;NEVER ALLOWED ZERO
        CPI
        CALL    NZ,ERR
        JP      PE,RDROT1
        RET
;UPDATE POINTER TO NEXT 1K CHUNK OF MEMORY TO TEST
;
UPDATE: LD      HL,(END1K)      ;UPDATE FOR NEXT 1K CHUNK
        INC     HL
        LD      (NEX1K),HL
        RET
;
;ROUTINE TO TYPE ADDRESS EVERY 100H (FROM DE)
TYPEAD: LD      A,E
        CP      0               ;SEE IF A MULTIPLE OF 100H
        RET     NZ              ;NO, DON'T BOTHER TO TYPE ADDRESS YET
        CALL    NTERUP          ;SEE IF WANT TO WAIT A BIT
        LD      H,D             ;GET NEXT ADDRESS IN HL
        LD      L,E
        CALL    TYPSHL
        LD      A,(TYCTR)       ;GET NUMBER OF TIMES THIS LINE
        INC     A
        LD      (TYCTR),A       ;UPDATE IT
        AND     0FH             ;ONLY USE LOWER 4 BITS
        RET     NZ              ;LESS THAN 16 TIMES
        CALL    CRLF            ;16 X 5 = 80 AND THAT'S ENUF PER LINE
        RET
;
;ROUTINE TO SEE IF ANYTHING BEEN TYPED FROM KEYBOARD.
;RETURNS IMMEDIATELY IF NOT.  IF C/R, RESTART PROGRAM
;FROM SQUARE ONE. IF ?, TYPE LOCATION CURRENTLY TESTING,
;IF ANYTHING ELSE, JUST DELAY TIL
;ANOTHER KEY STRUCK.
NTERUP: CALL    CHKIN           ;SEE IF ANYTHING BEEN TYPED?
        RET     Z               ;NO
        AND     7FH             ;GET RID OF PARITY BIT IF ANY
        CP      '?'             ;SEE IF WANT TO FIND OUT WHERE
        JP      Z,WHRWE
        CP      0DH             ;SEE IF C/R
        JP      Z,START         ;START ALLL OVER
        LD      HL,INTMSG       ;TYPE "INTERRUPTED"
        CALL    TYPMSG
NTW     CALL    CHKIN           ;WAIT FOR ANOTHER CHARACTER
        RET     NZ              ;GOT ONE
        JR      NTW             ;UNTIL WE GET ANY CHARACTER TO RESTART
WHRWE:  LD      HL,WHRMSG
        CALL    TYPMSG
        LD      HL,(TESTAD)     ;GET ADDRESS CURRENTLY TESTING
        CALL    TYPSHL
        RET

;TYPES MESSAGE POINTED BY HL, GETS A CHARACTER FROM KBD,
; AND RETURNS WITH A REG =0 IF CHAR WAS A Y, ELSE A=FF
; Z FLAG WILL BE SET IF YES, NZ SET IF NOT YES

GETANS: CALL    TYPMSG            ;TYPE MESSAGE
        CALL    GCHR            ;GET ANSWER FROM KBD
        PUSH    AF              ;SAVE IT
        CALL    CRLF            ;FOR NEATNESS
        POP     AF
        CP      'Y'             ;DID OP TYPE A Y
        JR      Z,GOTYES
        CP      'y'             ;CK FOR LOWER CASE TOO
GOTYES: LD      A,0
        RET     Z               ;ANSWER WAS Y
        LD      A,0FFH
        RET                     ;ANSWER WAS NOT Y

;
; GET CHARACTER FROM INPUT.
;
GBYTE:  CALL    CHKIN
        JR      Z,GBYTE         ;NOT READY YET
        AND     7FH             ;STRIP OFF BIT 7?????
        RET
;
SPACE:  LD      A,20H           ;FALLS THRU TO PCHR
;
;PRINTS CHARACTER IN A, PLUS LINEFEED AND 2 NULLS IF
;CHAR IS A CARRIAGE RETURN.  PRESERVES ALL REGISTERS
;
PCHR:   PUSH    AF
        PUSH    HL
        AND     7FH
        CALL    PBYTE           ;PRINT THE CHAR
        LD      HL,LFNN
        CP      CR              ;WAS IT A C/R?
        CALL    Z,TYPMSG          ;PRINT LINE FEED AND 2 NULLS
        POP     HL
        POP     AF
        RET
;
LFNN:   DEFB    8AH
;
; GET CHARACTER. RETURNS IT IN A.
; ALTERS F.
;
GCHR:   CALL    GBYTE
        CALL    PCHR
        JR      Z,GCHR          ;IF NULL DON'T RETURN
        CP      61H             ;SEE IF LOWER CASE
        JR      C,SK2           ;LESS THAN LC A
        CP      7BH             ;SEE IF MORE THAN Z
        JR      NC,SK2          ;NOT A LOWER CASE
        SUB     20H             ;CONVERT TO UPPER CASE
SK2     RET
;
;
; CRLF. ALTERS A ONLY.
;
CRLF:   LD      A,CR
        JR      PCHR
;
;
; GETS A 4 DIGIT (OR LESS) HEX NUMBER FROM
; KEYBOARD INTO HL.  IGNORES LEADING SPACES
; CONTINUES UNTIL A NON-HEX CHARACTER IS TYPED.
; RETURNS WITH THE LATTER IN A, AND HL SET TO
; THE LAST 4 HEX DIGITS (OR LESS) TYPED.
; LOSES AF AND HL
;
;
GETHEX: SUB     A
;
GNHL:   PUSH    BC              ;SAVE
        LD      HL,0            ;CLR BUFFER
; STRIP LEADING SPACES & GET CHAR
        CALL    SKSG
; FIRST CHAR MUST BE HEX
        CALL    HEXSH           ;IF HEX, SHIFT INTO HL
        JP      C,HEXERR         ;O/W, HEXERR
GN1:    CALL    GCHR
        CALL    HEXSH           ;IF HEX SHIFT INTO HL
        LD      A,B             ;RESTORE CHAR
        JR      NC,GN1   ;IF HEX, CONTINUE
        POP     BC              ;IF NON-HEX, DONE
        RET
HEXERR  LD      A,'?'
        CALL    PBYTE
        CALL    CRLF
        JR      GETHEX           ;RESTART
;
;
; IF A CONTAINS HEX CHAR, SHIFTS BINARY EQUIVALENT
; INTO HL. IF NOT HEX, RET WITH CY SET. SAVES
; ORIGINAL CHAR IN B
;
HEXSH:  LD      B,A
        SUB     '0'             ; < '0'?
        RET     C
        ADD     A,'0'-'G'
        RET     C
        SUB     'A'-'G'
        JR      NC,HX1          ;OK IF >= 'A'
        ADD     A,07H; 'A'-'9'+1
        RET     C
HX1:    ADD     A,'9'+1-'0'
; THE A-REG NOW CONTAINS THE HEX DIGIT IN BINARY.
; (THE HIGH-ORDER NIBBLE OF A IS 0.)
HXSH4:  ADD     HL,HL           ;SHIFT 4 BITS INTO HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        OR      L
        LD      L,A
        RET
;
;
; RETURNS WITH A NON-SPACE IN THE A-REG.
; IF ENTERED WITH A-REG CONTAINING A NULL
; OR A SPACE, GETS NEW CHARS UNTIL FIRST
; NON-SPACE OCCURS. ALTERS AF.
;
SKSG0:  SUB     A
;
SKSG:   OR      A               ;DOES A CONTAIN NULL?
SK1:    CALL    Z,GCHR          ;YES
        CP      20H             ;SPACE?
        JR      Z,SK1           ;YES, KEEP LOOKING
        CP      ','             ;PASS BY COMMAS TOO
        JR      Z,SK1
        CP      CR              ;RETURNS ZFLAG IF CR
        RET
;
;
; PRINT THE NUMBER IN HL.
; PRESERVES ALL BUT A.
;
TYPSHL: CALL    SPACE
;
PNHL:   LD      A,H
        CALL    P2HEX
        LD      A,L
;                               ;(CONTINUE BELOW)
;
; PRINT THE NUMBER IN THE A-REGISTER.
; PRESERVES ALL REGISTERS.
;
P2HEX:  CALL    P1HEX
        RRA
P1HEX:  RRA
        RRA
        RRA
        RRA
        PUSH    AF
        AND     0FH             ;MASK
        CP      10D             ; <= 9?
        JR      C,PH1
        ADD     A,7             ;A THRU F
PH1:    ADD     A,30H           ;ASCII BIAS
        CALL    PCHR             ;PRINT IT
        POP     AF
        RET
;
;
; PRINT MESSAGE. ENTER WITH ADDR OF MSG
; IN HL.  THE MESSAGE IS TERMINATED
; AFTER PRINTING A NULL (00) CHARACTER OR ONE WHOSE
; BIT 7 WAS SET.
; PRESERVES FLAGS, INCREMENTS HL.
;
;
;
TYPMSG:   PUSH    AF              ;SAVE
PS1:    LD      A,(HL)
        INC     HL
        CALL    PCHR
        OR      A               ;SET FLAGS
        JR      Z,PS2           ;NULL CHARACTER, EXIT
        RLA                     ;LAST CHARACTER?
        JR      NC,PS1          ;IF NOT, LOOP
PS2:    POP     AF
        RET
;
DUNMSG  DEFB    LF
        DEFB    CR
        DEFB    ' FINISHED'
        DEFB    CR
        DEFB    TLF
ERSMSG: DEFB    ' TOTAL ERRORS'
        DEFB    CR
        DEFB    TLF
SHDBE   DEFB    ' SHOULD BE'
        DEFB    TSP
ENTMSG  DEFB    LF
        DEFB    CR
        DEFB    '"FIRST LAST" ? ?'
        DEFB    TSP
ZMSG    DEFB    'TESTING ZEROES, THEN ONES'
        DEFB    LF
        DEFB    TCR
INCMSG  DEFB    'INCREMENTING BYTE TEST'
        DEFB    LF
        DEFB    TCR
IBUSMS: DEFB    LF
        DEFB    CR
        DEFB    'IBUS TEST'
        DEFB    CR
        DEFB    TLF
NOPMSG: DEFB    'FAILED NOP TEST'
        DEFB    TSP
EXMSG:  DEFB    'FAILED INST TEST'
        DEFB    TSP
GRDMSG  DEFB    LF
        DEFB    CR
        DEFB    'CROSSTALK READ TEST'
        DEFB    LF
        DEFB    TCR
GWRMSG  DEFB    LF
        DEFB    CR
        DEFB    'CROSSTALK WRITE TEST'
        DEFB    LF
        DEFB    TCR
ITMSG   DEFB    'ITERATIONS? (1 TO FF)'
        DEFB    TSP
HITHERE:DEFB    CR
        DEFB    LF
        DEFB    'BRAINWASH 2.3 - Copyright 1979 by Jim Gilbreath'
        DEFB    CR
        DEFB    LF
        DEFM    'OUTPUT TO PRINTER?',CR,LF
NOTMSG: DEFB    'DONT TEST 38-3A OR FRO'
        DEFB    0CDH
INTMSG: DEFB    LF
        DEFB    CR
        DEFB    'INTERRUPTED'
        DEFB    CR
        DEFB    TLF
LOSTMSG DEFB    ' FLEW AWA'
        DEFB    0D9H
CBIT:   DEFB    'CARRY GOT SE'
        DEFB    0D4H
ACHNG:  DEFB    'A CHANGE'
        DEFB    0C4H
BCHNG:  DEFB    'B CHANGE'
        DEFB    0C4H
CCHNG:  DEFB    'C CHANGE'
        DEFB    0C4H
DCHNG:  DEFB    'D CHANGE'
        DEFB    0C4H
ECHNG:  DEFB    'E CHANGE'
        DEFB    0C4H
HCHNG:  DEFB    'H CHANGE'
        DEFB    0C4H
LCHNG:  DEFB    'L CHANGE'
        DEFB    0C4H
EXSP:   DEFM    'EX (SP),HL failed'
TOMSG:  DEFB    ' T'
        DEFB    0CFH
LNGMSG: DEFB    'LONG INST TEST? (Y/N)'
        DEFB    TSP
XTKMSG: DEFB    'DO CROSSTALK TESTS? (Y/N)'
        DEFB    TSP
CONMSG: DEFB    'TEST FOREVER? (Y/N)'
        DEFB    TSP
BADMSG  DEFB    'POOR MEMORY!'
        DEFB    0ACH            ;COMMA
OKMSG   DEFB    'GOOD MEMORY'
        DEFB    0ACH            ;COMMA
SPIMSG: DEFB    ' '
        DEFB    0C9H            ;I+80H
WHRMSG: DEFM    CR,LF,'Testing'
STAKBAK DEFS    64     ;STACK BETTER NOT GET ANY LOWER THAN THIS
STACK:  DEFB    0


; I/O PACKAGE


 IF     GIL             ;home configuration
STAT    EQU     1       ;STATUS PORT
DATA    EQU     0
DAV     EQU     2
TBE     EQU     1
PRSTAT  EQU     3
PRDAT   EQU     2
PRTBE   EQU     1

INITX:                          ;DO HOUSEKEEPING
        DI                      ;TURN OFF INTERRUPTS
        LD      A,1             ;TO DISABLE ROM SO ALL RAM CAN BE TESTED
        OUT     (1FH),A         ;FOR GILBREATH CPU
        OUT     (7FH),A         ;FOR SSM ROM BOARD
        RET
 ENDIF          ;gil

 IF     ZOBEX                   ;nosc system
stat    equ     1               ;crt status port
data    equ     0               ;crt data port
dav     equ     1               ;bit mask for kbd input active
tbe     equ     4               ;bit mask for tx buffer empty
prstat  equ     3               ;printer status port
prdat   equ     2               ;printer data port
prdav   equ     1               ;printer input mask
prtbe   equ     4               ;printer tx buffer empty bit mask

initx:                          ;do housekeeping
        ld      a,1             ;to disable rom so all ram can be tested
        out     (0ch),a         ;for zobex cpu board
        ret
 ENDIF          ;zobex

; CHECK INPUT & RETURN WITH DATA IF READY. ONLY REG CHANGE IS A.
;
CHKINX:  IN      A,(STAT)
        AND     DAV
        RET     Z               ;DATA NOT READY, RETURN WITH Z FLAG SET
        IN      A,(DATA)        ;RETURN WITH DATA AND Z FLAG CLEARED
        RET
;

; TYPE CHARACTER.  CHANGE NO REGISTERS.
;
CRTOX:  PUSH    AF
PBY1:   IN      A,(STAT)
        AND     TBE
        JR      Z,PBY1
        POP     AF
        OUT     (DATA),A
        RET


PRTOX:                          ;PRINT CHARACTER, CHANGE NO REGISTERS

 IF ZOBEX

        push    af              ;save char
        in      a,(prstat)      ;get printer port status
        and     prdav           ;see if got char
        jr      z,list1         ;no
        in      a,(prdat)
        and     7fh
        cp      'S'-40h         ;see if stop code
        jr      nz,list1
plist2: in      a,(prstat)      ;got a stop, wait til next one
        and     prdav
        jr      z,plist2                ;loop til get char
        in      a,(prdat)
        and     7fh
        cp      'Q'-40h         ;see if go code
        jr      nz,plist2       ;loop til get it right
list1:  in      a,(prstat)
        and     prtbe           ;ck busy bit
        jr      z,list1         ;loop til bit goes hi meaning ready
        pop     af              ;get char to print
        out     (prdat),a       ;send character
        ret
 ENDIF  ;zobex

 IF GIL
        ret     ;no printer in here as yet
 ENDIF; gil


ENDOFIT:DEFB    0               ;FIRST MEMORY AVAILABLE TO TEST

SIZE    EQU     ENDOFIT-START   ;NUMBER OF TOTAL BYTE IN PROGRAM

        END
