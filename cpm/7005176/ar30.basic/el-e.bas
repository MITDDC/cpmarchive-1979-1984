   PRINT "          *** ELECTRICAL ENGENEERING & DESIGN ***"
   PRINT "                 J. Schrabal, April 1979"
   PRINT
   PRINT "File cleaned up of typos and put somewhat of a structure"
   PRINT "in it: 8/25/82 by S. Kluger"
   PRINT
   pi = 3.141592654      REM pi constant
10 PRINT "To select one of the programs just type it's number"
   PRINT "and hit 'RETURN' key. Enter all alphabetic answers in UPPER CASE!"
   PRINT
20 PRINT "Select from the following routines (0 to quit) :"
   PRINT "     1. Ohm's law (DC)"
   PRINT "     2. Zener stabilized DC supply"
   PRINT "     3. DC power supply design"
   PRINT "     4. Low pass 2-pole Butterworth filter"
   PRINT "     5. Series resonant frequency circuit"
   PRINT "     6. Passive band-pass filter"
   PRINT "     7. Small coil design & inductance calculations"
   PRINT "     8. Long wire antenna"
   PRINT "     9. Dipole or half wave antenna"
   PRINT "    10. Time constant calculation"
   PRINT "    11. Resistance of wire"
   PRINT "    12. Crystal (rec./tr.) frequency calculations"
   PRINT
   INPUT "What routine do you wish to select";SELECTION
     IF SELECTION>0 AND SELECTION<13 THEN 30
       IF SELECTION=0 THEN 9999
   PRINT "Please answer with number fom 0 to 12":GOTO 20
30 ON SELECTION GO TO 100,200,250,300,400,500,600,700,800,900,1000,1200

     REM PART 1 (100)

100 PRINT
    PRINT "          *** OHM's LAW (DC) ***"
110 PRINT
    PRINT " ENTER values for 2 (two) known"
    PRINT " ENTER 0 (zero) for unknown values to be calculated"
    PRINT
    INPUT "Potential in volts ";E
    INPUT "Current flow in amperes ";I
      IF E>0 AND I>0 THEN 111
    INPUT "Resistance in ohms";R
      IF I>0 AND R>0 AND E=0 THEN 120
      IF E>0 AND R>0 AND I=0 THEN 130
    INPUT "Power in watts ";P
      IF E>0 AND I=0 AND R=0 THEN 141
      IF I>0 AND E=0 AND R=0 THEN 142
      IF R>0 AND E=0 AND I=0 THEN 143
111 R=E/I
    GOTO 140
120 E=I*R
    GOTO 140
130 I=E/R
140 P=E*I
    GOTO 150
141 I=P/E
    R=(E^2)/P
    GOTO 150
142 E=P/I
    R=E/I
    GOTO 150
143 E=(P*R)^.5
    I=E/R
150 PRINT
    PRINT "Potential = ";E;" volts"
    PRINT "Current flow = ";I;" amperes"
    PRINT "Resistance = ";R;" ohms"
    PRINT "Power = ";P;" watts"
    PRINT
    INPUT "MORE CALCULATIONS? (YES/NO)";ANS$
      IF ANS$="YES" THEN GOTO 110 ELSE GOTO 20

              REM   Part 2   (200)

200 PRINT
    PRINT "      *** ZENER STABILIZED CIRCUIT DESIGN ***"
210  PRINT
    INPUT "Voltage rating of zener diode";A
    INPUT "Wattage rating of zener diode";W
    INPUT "Maximum DC voltage of power supply";B
    R=((B-A)^2)/W
    I=(W/R)^.5     REM in amperes
    PRINT "For an open circuit, or for load up to ";I*1000;" miliamperes"
    PRINT "Use ";R;"ohms ";W;" watt resistor"
    PRINT
    PRINT "Will the load (device) you use have larger than ";
    PRINT W;"watts consumption?"
    INPUT "(YES/NO)";A$
      IF A$="NO" THEN 220
    INPUT "What is the maximum wattage of the device you use:";C
    X=((B-A)^2)/((W/2)+C)
    PRINT "Use ";X; "ohms ";W+C;" watts resistor"
    PRINT "WARNING: Zener diode will probably burn out if the load"
    PRINT "         should be removed and circuit left open."
    PRINT
220 INPUT "More calculations? (YES/NO)";ANS$
      IF ANS$="YES" THEN GOTO 210 ELSE GOTO 20

250    REM Part 2.1

    PRINT "          *** POWER SUPPLY DESIGN ***"
    PRINT
    INPUT "What is LINE AC voltage supplied by utility";A
251 INPUT "What is transformer's primary rating (or tap)";B
252 INPUT "What is RMS voltage of secondary winding";C
    D=(C*A)/B        REM  D is max.RMS
    P=D*1.4          REM  P is peak voltage
    M=P+(P/4)      REM  M is maximum peak
256 INPUT "What is the needed (desired) DC voltage";O
      IF C>(2*O) THEN 267
      IF O>C THEN 268
    PRINT "What is the voltage rating of REGULATORS"
    INPUT "                  used with the power supply";Z
      IF ((Z+2.5)+(Z*.1))>O THEN 269
      IF ((Z+3.5)+(Z*.25))<O THEN 271
255 PRINT "Presuming that you use full wave, will the rectifying bridge"
    INPUT "consist of four (4) or two (2) diodes (as in centertap sec)";F
      IF F=4 OR F=2 THEN 260
    PRINT:PRINT "Answer whether 2 or 4 diodes will be used":PRINT:GOTO 255
260 IF F=2 THEN S=.75
      IF F=4 THEN S=1.5
    G=(D-S)*1.4        REM G is pulsating DC peak
    R=G-O              REM R is ripple
    INPUT "What is the load to be used in amperes? (if unknown type 0)";H
      IF H=0 THEN 280
261 I=(H*83)/R*100
    I=I+(I/10)
    PRINT
    PRINT "Line = ";A;" volts AC (max).Transformer primary (tap) = ";B;" volts AC"
    PRINT "Secondary = ";D;" volts RMS. Peak sec.voltage = ";P
    PRINT "For desired ";O;" volts DC use rectifying bridge of ";F
    PRINT "diodes rated at ";M;" volts (minimum) and ";4*H; "amps (min.)"
    PRINT "Filter capacitor should be rated ";I;" microfarads (minimum)"
    PRINT "and ";G; "volts DC (min).Permissible ripple = ";R;" volts"
    PRINT
    PRINT "NOTE:Use ohm-law to calculate bleeder-resistor."
    INPUT "More calculation for another secondary (YES/NO)";ANS$
      IF ANS$="YES" THEN 252
    INPUT "More calculation for another transformer (or tap)";ANS$
      IF ANS$="YES" THEN GOTO 251 ELSE GOTO 20
267 PRINT "Your secondary winding has overly high rating for this"
    PRINT "power requirement":PRINT:GOTO 252
268 PRINT "Your secondary winding has low voltage rating for this"
    PRINT "power requirement":PRINT:GOTO 252
269 PRINT "Power supply DC voltage must be more than 2.5 volts higher"
    PRINT "     than voltage of REGULATOR.":PRINT:GOTO 256
271 PRINT "Your supply voltage is overly high and will cause the regulator"
    PRINT "to overheat. Reduce your voltage to ";Z+4;" volts"
    PRINT "One way to do this is to insert series of diodes with rating"
    PRINT "which will be printed below, each such diode reducing the"
    PRINT "supply DC voltage by .7 volts (two diodes reduce 1.4 v)"
    PRINT "Then add this voltage to regulators when answering Q."
    PRINT:GOTO 256
280 INPUT "How many TAB-type regulators will be used";T
    INPUT "         K-type regulators";K
    INPUT "Any other load (in ampers)";Y
    H=T+(K*1.5)+Y:GOTO 261

       REM   Part 3  (300)

300 PRINT "         *** LOW PASS FILTER ***"
    PRINT "This program is based on OPERATIONAL AMPLIFIERS DESIGNS"
    PRINT "& APPLICATIONS by Graeme & Tobey, McGraw, 1971."
    PRINT
310 INPUT "Cut off frequency (in Hertz)";F
320 INPUT "Desired pass-band gain (H)";H
    PRINT "Peaking factor: 0(zero) for standard 2-pole Butterworth"
    INPUT "(alpha)         value for non-standard filter";A
    IF A=0 THEN A=2^.5
    IF (H/A)>100 THEN 330
    PRINT "Value of C2 in mF (microFarads)"
    INPUT "Note: 0.02 mF = 0.000 000 02 F     ";C
    R=A/(4*pi*F*C/1000000)
    PRINT
    PRINT "          .---------.                C1 = ";(4*(1+H)*C)/(A^2)
    PRINT "          X         :                C2 = ";C
    PRINT "          X R2      = C2             R1 = ";R/H
    PRINT "          X         :                R2 = ";R
    PRINT "    R1    :    R3   : - o            R3 = ";R/(H+1)
    PRINT "--XXXXXX--:--XXXXXX-:---o  o"
    PRINT "          :             o    o"
    PRINT " E-in     :             o      o---------------"
    PRINT "          = C1        + o    o"
    PRINT "          :          ---o  o" 
    PRINT "          :          :  o           E-out"
    PRINT "          :          :"
    PRINT "----------:----------:--------------------------"
    INPUT "Another gain/alpha ratio? (YES/NO)";ANS$
      IF ANS$="YES" THEN 320
    INPUT "Another filter configuration (YES/NO)";B$
      IF B$="YES" THEN GOTO 310 ELSE GOTO 20
330 PRINT"Because operational amplifiers are non-ideal, pass-"
    PRINT "band gain should be chosen to be less than 10 when peaking"
    PRINT "factor Alpha = 0-1"
    PRINT "Gain of 100 with peaking factor=1 is acceptable for "
    PRINT "for peaking gain 80 dB in 2-pole Batterworth config-"
    PRINT "uration."
    PRINT
    GOTO 320

      REM   Part 4 (400)

400 PRINT
    PRINT "          *** SERIES RESONANT FREQUENCY CIRCUITS ***"
410 PRINT
    INPUT "Inductance in MH (Milli-Henrys)";L
    INPUT "Capacitance in NF (Nano-Farads)";C
    PRINT
    PRINT "Series L/C resonant frequency is ";\
           1000/(6.283185307*((L*C)^0.5));" KHz (Kilo Hertz)"
    PRINT "Note: this frequency is not affected by resistance in the circuit"
    PRINT
    INPUT "More calculations? (YES/NO)";ANS$
      IF ANS$="YES" THEN 410
    GOTO 20

     REM Part 5 (500)

500 PRINT
    PRINT "      *** PASSIVE BANDPASS FILTER DESIGN ***"
    PRINT
    PRINT"   This program is based on ELECTRICAL ENGINEERING &"
    PRINT "CIRCUITS DESIGN by Skilling, Willey, 1961."
    PRINT "   It will calculate ideal component values for the"
    PRINT "T-section and PI-Section filters, given F1, F2,and R"
510 PRINT
    INPUT "What is F1, low cut-off frequency (in Hertz)";L
    INPUT "What is F2, high cut-off frequency (in Hertz)";H
      IF L>H THEN 560
    INPUT "What is R, image impedance in mid-frequency (in ohms)";R
      IF L<0 THEN 581
      IF H<0 THEN 581
      IF R<0 THEN 581
    X=H-L
    Y=12.56637061*L*H
    Z=pi
520 INPUT "If you want T-section type 'T'";T$
      IF T$<>"T" THEN 550
    PRINT
    PRINT "2Ca=";X/Y*R*2,"  Cb=";1/Z*R,"  R=";R
    PRINT "La/2=";R/Z/2,"  Lb=";R*X/Y
    PRINT
    PRINT "    2Ca     La/2                La/2     2Ca"
    PRINT "o----!!----mmmmmmm---:-----:---mmmmmmm---!!-....."
    PRINT "                     :     :                    :"
    PRINT "                     :     m                    X"
    PRINT "                  Cb =     m  Lb             R  X"
    PRINT "                     :     m                    X"
    PRINT "                     :     :                    :"
    PRINT "o--------------------:-----:----------------....:"
550 PRINT
    INPUT "If you want PI-section type 'P'";P$
      IF P$<>"P" THEN 582
    PRINT
    PRINT "La=";R/Z,"  2Lb=";2*R*X/Y,"  R=";R
    PRINT "Ca=";X/Y*R,"  Cb/2=";1/Z*R/2
    PRINT
    PRINT "                 La       Ca"
    PRINT "o-------:----:-mmmmmmm----!!-----:----:..........:"
    PRINT "        :    :                   :    :          :"
    PRINT "        m    :                   :    m          X"
    PRINT "    2Lb m    = Cb/2        Cb/2  =    m 2Lb    R X"
    PRINT "        m    :                   :    m          X"
    PRINT "        :    :                   :    :          :"
    PRINT "o-------:----:-------------------:----:..........:"
    PRINT
    INPUT "Another passive filter calculation (YES/NO)";A$
      IF A$="YES" THEN GOTO 510 ELSE GOTO 20
560 PRINT "High cut-off frequency must be higher than low-"
    PRINT "cut-off frequency":GOTO 510
581 PRINT "This value must be larger than 0 (zero)":GOTO 510  
582 PRINT "Answer 'P' or 'T' only":GOTO 510

     REM Part 6

600 PRINT "        *** SMALL COIL DESIGN ***"
    PRINT
    PRINT "Program limitations:"
    PRINT "        Inductance = 100 microhenries MAXIMUM"
    PRINT "        Wire size  =  12 size MAXIMUM"
    PRINT "                      40 gage MINIMUM"
    PRINT "        (resistors used as form must be of composite type)"
610 PRINT
    PRINT "PROGRAMS:"
    PRINT "     1. INDUCTANCE"
    PRINT "     2. INDUCTIVE REACTANCE"
    PRINT
    INPUT " WHICH ONE OF THE TWO PROGRAMS ABOVE YOU WANT COMPUTED";A
      IF A=1 THEN 650
      IF A>2 THEN 610
      IF A<0 THEN 610
620 INPUT "WHAT IS THE DESIRED INDUCTIVE REACTANCE IN OHMS";I
    INPUT "AT WHAT FREQUENCY IN MHZ";F
    H=I/(2*3.14159*F)
    PRINT "INDUCTANCE = ";H;" MICROHENRIES"
    IF H<100 THEN 660
640 PRINT "Program limitation is 100 microhenries MAXIMUM"
    GOTO 610
650 INPUT "What is the desired coil inductance in microhenries";H
      IF H>100 THEN 640
660 PRINT "Coil forms:"
    PRINT "   A = 1/4 WATT RESISTOR"
    PRINT "   B = 1/2 WATT RESISTOR"
    PRINT "   C = 1 WATT RESISTOR"
    PRINT "   D = 2 WATT RESISTOR"
    PRINT "   E = OTHER FORM"
    INPUT " SELECT COIL FORM FROM ABOVE (A,B,C,D,E)";FORM$
      IF FORM$="A" THEN D=.09
      IF FORM$="B" THEN D= .14
      IF FORM$="C" THEN D= .22
      IF FORM$="D" THEN D= .312
      IF FORM$="E" THEN GOTO 601 ELSE GOTO 602
601 INPUT "What is the diameter of the coil in inches";D
602 PRINT "What gage enameled wire will be used:"
    INPUT "                (gage 12 to 40)";G
      IF G=12 THEN W=.081
      IF G=13 THEN W=.072
      IF G=14 THEN W=.064
      IF G=15 THEN W=.057
      IF G=16 THEN W=.051
      IF G=17 THEN W=.045
      IF G=18 THEN W=.040
      IF G=19 THEN W=.036
      IF G=20 THEN W=.32
      IF G=21 THEN W=.0285
      IF G=22 THEN W=.0253
      IF G=23 THEN W=.0226
      IF G=24 THEN W=.0201
      IF G=25 THEN W=.0179
      IF G=26 THEN W=.0159
      IF G=27 THEN W=.0142
      IF G=28 THEN W=.0126
      IF G=29 THEN W=.0113
      IF G=30 THEN W=.01
      IF G=31 THEN W=.0089
      IF G=32 THEN W=.008
      IF G=33 THEN W=.0071
      IF G=34 THEN W=.0063
      IF G=35 THEN W=.0056
      IF G=36 THEN W=.005
      IF G=37 THEN W=.0045
      IF G=38 THEN W=.004
      IF G=39 THEN W=.0035
      IF G=40 THEN W=.0031
      IF G<12 OR G>40 THEN 602
    N=((40*H*W)+SQR (((4*H*W)*(4*H*W))+(4*D*D*D*18*H)))/(2*D*D)
    N1=((40*H*W)-SQR (((4*H*W)*(4*H*W))+(4*D*D*D*18*H)))/(2*D*D)
      IF N>N1 THEN N2=N ELSE N2=N1
    N2=(INT(N2*10))/10
    PRINT:PRINT "Wire size = ";G;" gage"
    PRINT "Coil diameter = ";D;" inches"
    PRINT "Number of turns = ";N2
    PRINT "Coil length = ";(INT(N2*W*100))/100;" inches"
    INPUT "More calculations? (YES/NO)";ANS$
      IF ANS$="YES" THEN GOTO 610 ELSE GOTO 20

     REM   Part 7 (700)

700 PRINT
    PRINT "          *** LONG WIRE ANTENNA ***"
    PRINT
    PRINT "    When an antenna is more than half wavelength long"
    PRINT "it is called 'long wire' or 'harmonic' antenna."
    PRINT
710 INPUT "What frequency in MHz (Mega Hertz)";F
    INPUT "How many half-waves long";N
    L=492*(N-0.05)/F
    PRINT "Length = ";L;" Feet"
    PRINT "Note: If this antenna is fed in exact center at ";L/2;" ft."
    PRINT "no unbalance will occur on any harmonic frequency."
    PRINT
    INPUT "More calculations? (YES/NO)";ANS$
      IF ANS$="YES" THEN 710
    GOTO 20

     REM    Part 8  (800)

800 PRINT
    PRINT "      *** DIPOLE OR HALF WAVE ANTENNA ***"
    PRINT
810 INPUT "Frequency in MHz (Mega Hertz)";F
    L=492/F
    PRINT:PRINT "Actual half-wave lenght is ";L;" feet"
      IF F<30 THEN L=L*.95
      IF F<150 THEN L=L*.97
      IF F>149.9 THEN L=L*.98
    PRINT "Lenght corrected to free space factor and to capacitance"
    PRINT "of insulators is ";L;" feet"
    PRINT
    C=118/F
    E=148/F
    PRINT "<----------";L;" ft-------->"
    PRINT "         <-";C;"ft->"
    PRINT "o----------o-------o----------o"
    PRINT "            o     o     ^"
    PRINT "             o   o      E = ";E;" ft"
    PRINT "              o=o  <- 600 ohms line 3.75 in spaced #16 wire"
    PRINT "              o o                   5 in spaced #14 wire"
    PRINT "              o o                   6 in spaced #12 wire"
    PRINT
    INPUT "More calculations (YES/NO)";ANS$
      IF ANS$="YES" THEN 810
    GOTO 20 

     REM       Part 9

900 PRINT
    PRINT "          *** TIME CONSTANT CALCULATIONS ***"
    PRINT
910 PRINT "NOTE: If you wish to substitute Farads by MICROfarads then you"
    PRINT "    must use resistance in MEGohms in order to get result"
    PRINT "    in seconds."
    INPUT "What is the resistance in ohms";R
    INPUT "What is the capacitance in farads";C
    PRINT "Time constant = ";R*C;"seconds"
    INPUT "More calculations? (YES/NO)";ANS$
      IF ANS$="YES" THEN GOTO 910 ELSE GOTO 20

     REM  Part 10

1000 PRINT
     PRINT "          *** RESISTANCE OF WIRE ***"
     PRINT
1010 INPUT "What is the desired resistance in ohms";R
     PRINT "What A.W.G.(B&S) size wire NO. is available?"
     INPUT "                     (if unknown, enter '0')";WN
       IF WN=0 THEN 1050
       IF WN=1 THEN RW=.1264
       IF WN=2 THEN RW=.1593
       IF WN=3 THEN RW=.2009
       IF WN=4 THEN RW=.2533
       IF WN=5 THEN RW=.3195
       IF WN=6 THEN RW=.4028
       IF WN=7 THEN RW=.5080
       IF WN=8 THEN RW=.6405
       IF WN=9 THEN RW=.8077
       IF WN=10 THEN RW=1.018
       IF WN=11 THEN RW=1.284
       IF WN=12 THEN RW=1.619
       IF WN=13 THEN RW=2.042
       IF WN=14 THEN RW=2.575
       IF WN=15 THEN RW=3.247
       IF WN=16 THEN RW=4.094
       IF WN=17 THEN RW=5.163
       IF WN=18 THEN RW=6.51
       IF WN=19 THEN RW=8.21
       IF WN=20 THEN RW=10.35
       IF WN=21 THEN RW=13.05
       IF WN=22 THEN RW=16.46
       IF WN=23 THEN RW=20.76
       IF WN=24 THEN RW=26.17
       IF WN=25 THEN RW=33
       IF WN=26 THEN RW=41.62
       IF WN=27 THEN RW=52.48
       IF WN=28 THEN RW=66.17
       IF WN=29 THEN RW=83.44
       IF WN=30 THEN RW=105.2
       IF WN=31 THEN RW=132.7
       IF WN=32 THEN RW=167.3
       IF WN=33 THEN RW=211
       IF WN=34 THEN RW=266
       IF WN=35 THEN RW=335
       IF WN=36 THEN RW=423
       IF WN=37 THEN RW=533
       IF WN=38 THEN RW=672.6
       IF WN=39 THEN RW=848.1
       IF WN=40 THEN RW=1069
1040 INPUT "Of what MATERIAL is the wire";MATERIAL$
     MAT$=LEFT$(MATERIAL$,3)
     TEST = RW  REM set up test for illegal entry
       IF MAT$="COP" THEN RW=RW*1
       IF MAT$="ALU" THEN RW=RW*1.6
       IF MAT$="BRA" THEN RW=RW*4
       IF MAT$="CAD" THEN RW=RW*4.4
       IF MAT$="CHR" THEN RW=RW*1.8
       IF MAT$="GOL" THEN RW=RW*1.4
       IF MAT$="IRO" THEN RW=RW*5.68
       IF MAT$="LEA" THEN RW=RW*12.8
       IF MAT$="NIC" THEN RW=RW*5.1
       IF MAT$="BRO" THEN RW=RW*4
       IF MAT$="SIL" THEN RW=RW*.94
       IF MAT$="STE" THEN RW=RW*11
       IF MAT$="TIN" THEN RW=RW*6.7
       IF MAT$="ZIN" THEN RW=RW*3.4
         IF (RW=TEST) AND (MAT$<>"COP") THEN 1040
     L=1000*R/RW
     PRINT "For ";R;"ohms use ";L;" feet of No.";WN;MATERIAL$;" wire"
     GOTO 1090
1050 INPUT "What is distance in feet";D
     RX=R*1000/D
       IF RX>.1264 THEN W=1
       IF RX>.1593 THEN W=2
       IF RX>.2009 THEN W=3
       IF RX>.2533 THEN W=4
       IF RX>.3195 THEN W=5
       IF RX>.4028 THEN W=6
       IF RX>.5080 THEN W=7
       IF RX>.6405 THEN W=8
       IF RX>.8077 THEN W=9
       IF RX>1.018 THEN W=10
       IF RX>1.284 THEN W=11
       IF RX>1.619 THEN W=12
       IF RX>2.042 THEN W=13
       IF RX>2.575 THEN W=14
       IF RX>3.247 THEN W=15
       IF RX>4.094 THEN W=16
       IF RX>5.163 THEN W=17
       IF RX>6.51 THEN W=18
       IF RX>8.21 THEN W=19
       IF RX>10.35 THEN W=20
       IF RX>13.05 THEN W=21
       IF RX>16.46 THEN W=22
       IF RX>20.76 THEN W=23
       IF RX>26.17 THEN W=24
       IF RX>33 THEN W=25
       IF RX>41.62 THEN W=26
       IF RX>52.48 THEN W=27
       IF RX>66.17 THEN W=28
       IF RX>83.44 THEN W=29
       IF RX>105.2 THEN W=30
       IF RX>132.7 THEN W=31
       IF RX>167.3 THEN W=32
       IF RX>211 THEN W=33
       IF RX>266 THEN W=34
       IF RX>335 THEN W=35
       IF RX>423 THEN W=36
       IF RX>533 THEN W=37
       IF RX>672.6 THEN W=38
       IF RX>848.1 THEN W=39
       IF RX>1069 THEN W=40
     PRINT "The smallest copper wire for ";R;" ohms at distance of ";D;" feet"
     PRINT "   that can be safely used is No.";W;" A.W.G.(B&S)"
1090 INPUT "More calculations? (YES/NO)";ANS$
     IF ANS$="YES" THEN GOTO 1010 ELSE GOTO 20

1200    REM  Part 12 tr/rec. crystals

     PRINT
     PRINT " ***RECEIVING & TRANSMITTING CRYSTAL CALCULATIONS***  "
     PRINT
1221 INPUT "What is the receiving frequency? (in MHz)";R
     INPUT "What is the transmitting frequency? (in MHz)";T
     GOTO 1250
1222 INPUT "What is 1st IF freq.(in MHz) of rec.";I
     INPUT "What is RECEIVING crystal divider";RD
     INPUT "What is TRANSMITTING crystal multiplier";TD
1230 PRINT
     PRINT "For receiving on ";R;" MHz (with ";I;" MHz IF) & ";RD;" divider"
     PRINT "	ORDER ";(R-I)/RD*1000;"KHz receiving crystal"
     PRINT "For transmitting on ";T;" MHz (tranmit multiplier=";TD;")"
     PRINT "ORDER ";T/TD*1000;" KHz transmitting crystal"
     PRINT
     INPUT "More crystal freq. calculations? (YES/NO)";ANS$
       IF ANS$="YES" THEN GOTO 1221 ELSE GOTO 20
1250 PRINT "What make and model transceiver?"
     PRINT "	STANDARD 146A - MOTOROLA 80D - VOICECOMMANDER";
     INPUT RADIO$
     RADIO$ = LEFT$(RADIO$,3)
       IF RADIO$="STA" THEN 1260
       IF RADIO$="MOT" THEN I=5.5:RD=5:TD=24:GOTO 1230
       IF RADIO$="VOI" THEN I=8.7:RD=3:TD=8:GOTO 1230
     GOTO 1222
1260 I=11.7:RD=9:TD=18:GOTO 1230

9999 END
