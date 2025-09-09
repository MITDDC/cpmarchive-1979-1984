/* Note: I'm sure that some of these may be improved
	and would appreciate any feedback */
/* A set of routines to allow a user to program in BDS C words and
   phrases using a VOTRAX SC-01 chip synthesizer. The main functions is
   "talk" which takes a character string argument that looks like phonemes.
   The subroutine "pronounce" does the port I/O and will need to be
   be individually modified, most likely. Read the comments above it */

/* written by Mark Zachmann Sept. 5 1981  Version 0.2 */

/* main talking functions... what a slow way to do things */

/* it reads a character string corresponding to the phoneme descriptions
	in the VOTRAX phoneme chart (page 3 of SC-01 data sheet)
	and decodes them into numbers (type char, though), then says them.
	Note that because it takes a while to talk I say each phoneme 
	seperately, and thus, while saying one phoneme, the next
	can be decoded from the character string input */

talk(line)
char *line;
{  while(0!=*line)
     {	pronounce(phoneme(line));	/* transmit to chip */
	while(','!=*line++);		/* increment counter to start
						of next phoneme */
     }
}

/* Subroutine to take a character string and return a number (type char)
	corresponding to the first phoneme found in the string. Returns
	0xFF if no match (although partial matches will have undefined
	results, e.g. O5 may be the same as O1)	*/

phoneme(line)
char *line;
{ switch(*line++) {
	case 'A': switch(*line) 
	      {   case '1': return(5);			/* A1 */
		  case '2': return(6);			/* A2 */
		  case 'Y': return(0x21);		/* AY */
		  case 'E': { if (','==*++line) return(0x2e); /* AE */
				return(0x2f);		      /* AE1 */
			    }
		  case 'H': { if (','==*++line) return(0x24); /* AH */
			      if('1'==*line) return(0x15);    /* AH1 */
			      return(8);		      /* AH2 */
			    }
		  case 'W': { if(','==*++line) return(0x3d);  /* AW */
			      if('1'==*line) return(0x13);    /* AW1 */
				return(0x30);		      /* AW2 */
			    }
		}
	case 'B': return(0xe);				/* B */
	case 'C': return(0x10);				/* CH */
	case 'D': { if(','==*line) return(0x1e);	/* D */
			return(0x4);			/* DT */
		  }
	case 'E': switch(*line)
		    {	case ',': return(0x2c);		/* E */
			case 'R': return(0x3a);		/* ER */
			case '1': return(0x3c);		/* E1 */
			case 'H': switch(*++line) {
					case ',': return(0x3b); /* EH */
					case '1': return(2);	/* EH1 */
					case '2': return(1);	/* EH2 */
					default: return(0);	/* EH3 */
						}
		    }
	case 'F': return(0x1d);				/* F */
	case 'G': return(0x1c);				/* G */
	case 'H': return(0x1b);				/* H */
	case 'I': switch(*line)
		   {	case ',': return(0x27);		/* I */
			case 'U': return(0x36); 	/* IU */
			case '1': return(0x0b); 	/* I1 */
			case '2': return(0x0a); 	/* I2 */
			default: return(9);		/* I3 */
		   }
	case 'J': return(0x1a);				/* J */
	case 'K': return(0x19);				/* K */
	case 'L': return(0x18);				/* L */
	case 'M': return(0x0c);				/* M */
	case 'N': if(','==*line)  return(0x0d);		/* N */
		       return(0x14);			/* NG */
	case 'O': switch(*line)
		   {	case ',': return(0x26);		/* O */
			case '1': return(0x35); 	/* O1 */
			case '2': return(0x34); 	/* O2 */
			case 'O': { if(','==*++line) return(0x17);  /* OO */
					return(0x16);	/* OO1 */
				  }
		   }
	case 'P': { if(','==*line) return(0x25);	/* P */
		    if('0'==*++line) return(3);		/* PA0 */
			return(0x3e);			/* PA1 */
		  }
	case 'R': return(0x2b);				/* R */
	case 'S': { if(','==*line) return(0x1f);	/* S */
		    if('H'==*line) return(0x11);	/* SH */
			return(0x3f);			/* STOP */
		  }
	case 'T': { if(','==*line) return(0x2a);	/* T */
		    if(','==*++line) return(0x39);	/* TH */
			return(0x38);			/* THV */
		  }
	case 'U': switch(*line)
		  {	case ',': return(0x28);		/* U */
			case '1': return(0x37);		/* U1 */
			default: switch(*++line)
			   {	case ',': return(0x33); /* UH */
				case '1': return(0x32); /* UH1 */
				case '2': return(0x31); /* UH2 */
				default: return(0x23);  /* UH3 */
			   }
		  }
	case 'V': return(0x0f);				/* V */
	case 'W': return(0x2d);				/* W */
	case 'Y': { if(','==*line) return(0x29);	/* Y */
			return(0x22);			/* Y1 */
		  }
	case 'Z': { if(','==*line) return(0x12);	/* Z */
			return(7);			/* ZH */
		  }
	default : return(0xff);		/* error !! */
	}
}

/* this is the pronunciation subroutine. It sends a single phoneme
	to the Votrax synthesis chip. I have implemented mine by way of
	the iobyte. When the list device is set to UC3: my BIOS sends
	output to the synthesizer. Thus all handshaking is external
	to  this program. !! You will need to modify either this or your BIOS.
	I suggest the BIOS as then BASIC and etc. stupid compilers can easily
	interface to the chip */

pronounce(c)
char(c);
{ char iobyt;
  iobyt=bdos(7);	/* read iobyte */
  bdos(8,0xc0);		/* set list to UC3: */
  bios(5,(c|0x80));	/* send character, I set my pitch to 80h always */
  bdos(8,iobyt);	/* reset IOBYTE to whatever it was */
}



/* program to say a number argument 
	assumes unsigned input, and calls itself recusively. Not terribly 
	fast */

saynum(numb)
unsigned numb;
{ char c,d,some;
  unsigned j;

  some=0;		/* nothing said yet */

/* first process the 1000's */
  if(0!=(j=numb/1000))
	{ saynum(j);	/* Recur to do thousands */
	  talk("TH,AH1,W,Z,I1,N,D,PA1,");     /* thousand */
	  numb%=1000;	/* continue with left over */
	  some=1 ;	/* flag it as having said something */
	}

/* now the 100's */
  if(0!=(j=numb/100))
	{ saynum(j);	/* recurring */
	  talk("H,H,UH,N,D,R,I3,D,PA1,");	/* hundred */
	  numb%=100;	/* continue again */
	  some=1 ;	/* flag it */
	}

/* now separate the 10's off (if > 20)  */
  if((numb>=20)&&0!=(j=numb%10))	/* recur again if not simple */
	{ saynum(numb-j);			/* first do the tens case */
	  numb=j;				/* now the remainder */
	  some=1;
	}

/* main non-recursive portion */
  c=numb;		/* turn into a char for speed */
  d=(c>=20)? c/10 : c%10 ;	/* the kernel is here */
  switch(d)
	    {	case 1 : { if(c==1)  talk("W,UH1,I3,N,");	/*  1 */
			     else    talk("E1,L,EH1,V,I1,N,");	/* 11 */
			   break;
			 }
		case 2 : { if(c==20) talk("T,PA0,W,EH2,N,");    /* 20 */
		      else if(c==12) talk("T,PA0,W,EH2,UH2,L,V,");  /* 12 */
		      else	     talk("T,PA0,U,W,");	/*  2 */
			   break;
			 }			   
		case 3 : { if(c==3)   talk("TH,R,E1,Y,");	/* 3 */
			      else    talk("TH,UH2,ER,");	/* 13,31 */
			   break ;
			 }
		case 4 : { if(c==4)   talk("F,O,ER,");		/* 4 */
			      else    talk("F,O1,R,");		/* 14,41 */
			   break;
			 }
		case 5 : { if(c==5)   talk("F,AH1,Y1,V,");	/* 5 */
			      else    talk("F,I1,F,");		/* 15,51 */
			   break;
			 } 
		case 6 : talk("S,I,K,S,");  break;		/* 6's */
		case 7 : talk("S,EH,V,I3,N,");   break;		/* 7's */
		case 8 : talk("A1,Y,T,");  break ;		/* 8's */
		case 9 : talk("N,AH2,Y,N,");  break ;		/* 9's */
		case 0 : {  if(c==10)  talk("T,EH,N,");		/* 10 */
		      else  if(!some) talk("Z,E1,R,O1,W,");	/* 0 */
			    break ;
			  }
	    }
	if(c>=20) talk("STOP,T,E1,PA0,");			/* ty */
	else if(c>12) talk("STOP,T,E1,E1,N,PA0,");		/* teen */
	else talk("PA1,");	/* done */
	}

/*   */
/* says the day of the week, 0 is sunday 6 is saturday */

sayday(dayow)
char dayow;
{ switch(dayow) {
	case 0: talk("S,UH,N,N,"); break;
	case 1: talk("M,UH,N,"); break;
	case 2: talk("T,PA0,U,EH3,Z,STOP,"); break;
	case 3: talk("W,EH,N,Z,"); break;
	case 4: talk("TH,U1,ER,Z,"); break;
	case 5: talk("F,R,AH1,Y,"); break;
	case 6: talk("S,AE1,EH3,T,ER,"); break;
	default: talk("H,W,UH,T,"); break;		/* what? */
		}
  talk("D,A1,AY,Y1,STOP,STOP,");				/* day */
}

/*  */
/* says the month desired */
saymonth(month)		/* month 0-January...11-December */
char(month);
{ switch(month) {
	case 0: talk("D,J,I3,AE1,UH2,N,Y,IU,U1,W,AE1,EH3,R,Y,"); break;
	case 1: talk("F,EH1,B,Y,IU,U1,W,AE1,EH3,R,Y,"); break;
	case 2: talk("M,AH2,ER,T,CH,"); break;
	case 3: talk("A1,AY,P,R,OO1,L,"); break;
	case 4: talk("M,A,Y,"); break;
	case 5: talk("D,J,U1,U,N,"); break;
	case 6: talk("D,J,U1,UH3,L,AR1,E1,"); break;
	case 7: talk("AW,G,UH3,S,T,"); break;
	case 8: talk("S,EH1,P,STOP,T,EH1,EH2,M,B,R,"); break;
	case 9: talk("AH1,K,STOP,T,O,W,B,R,"); break;
	case 10: talk("N,O1,W,PA0,V,EH,M,B,R,"); break;
	case 11: talk("D,I2,Y,S,EH,M,B,R,"); break;
	default: talk("H,W,UH,T,"); break;
		}
}
