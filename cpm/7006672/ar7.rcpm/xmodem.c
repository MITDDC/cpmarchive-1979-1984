/*This program implements the Ward Christenson assembly language
  program in C.  All of the original modes are available, and a
  hide mode is added for restriction of file availability. A logger
  has been added, to keep a record of which files are most
  popular with BBS callers. Also, a local CRT display of errors
  and progress is implemented. This program as written is for the
  PMMI modem board, but may be changed for the D.C.Hayes via the
  proper equates. It requires CP/M Vers. 2.x to operate. Derived
  from CMODEM13.C

                                  original by Jack M. Wierda
                                  modified by Roderick W. Hart
				  modified by William D. Earnest
*/
#include     <bdscio.h>
#include     <pmmi.h>

#define      SOH 1
#define      EOT 4
#define      ACK 6
#define      TAB 9
#define      CPUCLK 4
#define      ERRORMAX 10
#define      RETRYMAX 10
#define      LF 10
#define      CR 13
#define      SPS 1500           /*loops per second */
#define      NAK 21
#define      CTRLZ 26
#define      DELETE 127
#define      TIMEOUT -1
#define      LRL 16      /* logger record lgth */
#define      RPB 8       /* logger rcrds per sector */
#define      SECSIZ 0x80
#define      TBFSIZ 0x2000	/*moderate size, 0x8000 will not work with
				  with BDS C, reduce buffer size as necessary
                                  for smaller systems*/
 
char option,buffer[TBFSIZ],fcb[36],crtm[24];
 
moready()
{ return (inp(STATPORT) & TBMT) == (MAHI ? TBMT : 0);
}

miready()
{ return (inp(STATPORT) & DAV) == (MAHI ? DAV : 0);
}

ctsready()
{ int lpc,seccnt;
    for(lpc=0; lpc < 25; lpc++)
        { seccnt = SPS * CPUCLK;
            while((inp(MODEMCP2) & CTS) == (CTSHI ? 0 : CTS) && seccnt--);
            if(seccnt >= 0)
                return;
        }
    exit();
}

crtmsg(msg)
char *msg;
{ while (*msg)
        { while((inp(CSTAT) & COMASK) == (CAHI ? 0 : COMASK));
            outp(CDATA,*msg);
            msg++;
        }
}

shocrt(sec,try,tot)
int sec,try,tot;
{ sprintf(crtm,"\015Blk %04d Try %1d Err %03d",sec,try,tot);
    crtmsg(crtm);
}

sendline(data)
char data;
{ ctsready();
    while(!MOREADY());
    outp(DATAPORT,data);
}

readline(seconds)
int seconds;
{ char data;
    int lpc,seccnt;
    for (lpc = 0; lpc < CPUCLK; lpc++)
        { seccnt = seconds * SPS;
          ctsready();
          while (!MIREADY() && seccnt--);
          if(seccnt >= 0)
              { data = inp(DATAPORT);
                return(data);
              }
        }
    return(TIMEOUT);
}

purgeline()
{ while (MIREADY())
      inp(DATAPORT);     /*PURGE THE RECEIVE REGISTER*/
  ctsready();
}

readfile(file)
char *file;
{ int j, firstchar, sectnum, sectcurr, sectcomp, errors;
  int toterr,checksum;
  int errorflag, fd;
  int bufctr;

  fd = creat(file);
  if(fd == -1)
      { printf("Cannot create %s\n",file);
        exit();
      }
  else
      printf("\nReady to receive %s\n",file);
  sectnum = 0;
  errors = 0;
  toterr = 0;
  bufctr = 0;
  purgeline();
  shocrt(0,0,0);
  do
      { errorflag = FALSE;
        do
            firstchar = readline(10);
        while(firstchar != SOH && firstchar != EOT && firstchar != TIMEOUT);

        if(firstchar == TIMEOUT)
            errorflag = TRUE;
        if(firstchar == SOH)
            { sectcurr = readline(1);
              sectcomp = readline(1);
              if((sectcurr + sectcomp) == 255)
                  { if(sectcurr == sectnum + 1)
                        { checksum = 0;
                          for(j = bufctr;j < (bufctr + SECSIZ);j++)
                              { buffer[j] = readline(1);
                                checksum = (checksum + buffer[j]) & 0xff;
                              }
                          if(checksum == readline(1))
                              { errors = 0;
                                sectnum = sectcurr;
                                bufctr = bufctr + SECSIZ;
                                if(bufctr == TBFSIZ)
                                    { bufctr = 0;
                                      write(fd,buffer,TBFSIZ/SECSIZ);
                                    }
                                shocrt(sectnum,errors,toterr);
                                sendline(ACK);
                              }
                          else
                              errorflag = TRUE;
                        }
                    else
                        if(sectcurr == sectnum)
                            { do;
                              while(readline(1) != TIMEOUT);
                              sendline(ACK);
                            }
                        else
                            errorflag = TRUE;
                  }
              else
                  errorflag = TRUE;
            }
        if(errorflag == TRUE)
            { errors++;
              if(sectnum)
                  toterr++;
              while(readline(1) != TIMEOUT);
              shocrt(sectnum,errors,toterr);
              sendline(NAK);
            }
      }
  while(firstchar != EOT && errors != ERRORMAX);

  if((firstchar == EOT) && (errors < ERRORMAX))
      { sendline(ACK);
        write(fd,buffer,(bufctr+SECSIZ-1)/SECSIZ);
        close(fd);
      }
  else
      printf("Aborting\n");
}

sendfile(file)
char *file;
{ char *npnt;
  int j, sectnum, sectors, attempts;
  int toterr,checksum;
  int bufctr, fd;

  fd = open(file,0);
  if(fd == -1)
      { printf("\n++File not found++\n");
        exit();
      }
  else
      { npnt = fcbaddr(fd);
        if(npnt[1] > 127 || npnt[2] > 127)
            { printf("\nFile %s not for distribution, Sorry.\n",file);
              exit();
            }
        else
            { attempts = rcfsiz(fd);
              printf("\nFile %s open, ",file);
              printf("size %d (%04xH) sectors.\n",attempts,attempts);
              printf("Ready to send, awaiting NAK.\n");
            }
      }
  purgeline();
  attempts=0;
  toterr = 0;
  shocrt(0,0,0);
  while((readline(10) != NAK) && (attempts != 8))
      { attempts++;
        shocrt(0,attempts,0);
      }
  if (attempts == 8)
      { printf("\nTimed out awaiting initial NAK\n");
        exit();
      }
  attempts = 0;
  sectnum = 1;
  while((sectors = read(fd,buffer,TBFSIZ/SECSIZ)) && (attempts != RETRYMAX))
      { if(sectors == -1)
            { printf("\nFile read error.\n");
              break;
            }
        else
            { bufctr = 0;
              do
                  { attempts = 0;
                    do
                        { shocrt(sectnum,attempts,toterr);
                          sendline(SOH);
                          sendline(sectnum);
                          sendline(-sectnum-1);
                          checksum = 0;
                          for(j = bufctr;j < (bufctr + SECSIZ);j++)
                              { sendline(buffer[j]);
                                checksum = (checksum + buffer[j]) & 0xff;
                              }
                          sendline(checksum);
                          purgeline();
                          attempts++;
                          toterr++;
                        }
                    while((readline(10) != ACK) && (attempts != RETRYMAX));
                    bufctr = bufctr + SECSIZ;
                    sectnum++;
                    sectors--;
                    toterr--;
                  }
              while((sectors != 0) && (attempts != RETRYMAX));
            }
      }
        if(attempts == RETRYMAX)
            printf("\nNo ACK on sector, aborting\n");
        else
            { attempts = 0;
              do
                  { sendline(EOT);
                    purgeline();
                    attempts++;
                  }
              while((readline(10) != ACK) && (attempts != RETRYMAX));
              if(attempts == RETRYMAX)
                  printf("\nNo ACK on EOT, aborting\n");
            } 
  close(fd);
}

docfile(file)
char *file;
{ int fd,rcsz,rch;
  fd = open(file,0);
  if(fd == -1)
      { printf("\n++File %s not found++\n,file");
        exit();
      }
  else
      { rcsz=rcfsiz(fd);
        rch = (rcsz * 14) / 3;
        printf("\nFile %s is ",file);
        printf("%d (%04xH) sectors long.\n",rcsz,rcsz);
        printf("At 300 baud, it would take about ");
        printf("%d minutes, %d seconds to send.\n",rch / 60,rch % 60);
      }
}

int filfnd(file)
char *file;
{ if(setfcb(fcb,file))
      return FALSE;
  if(bdos(17,fcb) != 255)
      return TRUE;
  else
      return FALSE;
}

char matchr(st,ch)
char *st,ch;
{ int i;
  for(i=0; st[i]; i++)
      { if(st[i] == ch)
            return(i);
      }
  return(0);
}

ckfile(argc,argv) int argc;
char **argv;
{ char *s,l;
  if(argc < 3)
      { printf("File name required\n");
        exit();
      }

  if(option == 'H')
      { l = matchr(*argv,'.');
        if(((l+3) > strlen(*argv)) || (!l))
            { printf("\nMust have full .typ to Hide\n");
              exit();
            }
      }

  for(s=*argv; *s; s++)
      { if((*s == '?') || (*s == '*'))
            { printf("\nNo 'Wild Card' characters allowed\n");
              exit();
            }
      }

  for(s=*argv; *s; s++)
      { if((*s == '.') && ((option == 'R') || (option == 'H')))
            { if(s[1] == 'C' && s[2] == 'O' && s[3] == 'M')
                  { printf("\nCan't accept a .COM file\n");
                    exit();
                  }
              if(option == 'H')
                  s[2] = s[2] | 0x80;
            }
      }
}

char bbcd(val)
char val;
{ return(((val / 10) << 4) + (val % 10));
}

logfil(file)
char *file;
{ int fd,rnum,bnum,savusr;
  char *i,*lrec,lbuf[128],*lnam;
  lnam = "A:\330\315ODEM.L\317G"; /* f1 & f2 flags, $sys */
  savusr = bdos(32,-1);
  bdos(32,0);
  fd = open(lnam,2);
  if(fd == -1)
      { fd = creat(lnam);
        if(fd == -1)
            return;
        else
            { setmem(lbuf,16,0x20);
              setmem(lbuf+16,112,CTRLZ);
              sprintf(lbuf,"%d",0);
            }
      }
  else
      read(fd,lbuf,1);
  rnum = atoi(lbuf)+1;
  sprintf(lbuf,"%d",rnum);
  seek(fd,0,0);
  write(fd,lbuf,1);
  bnum = rnum / RPB;
  rnum = (rnum % RPB) * LRL;
  seek(fd,bnum,0);
  if(rnum == 0)
      setmem(lbuf,128,CTRLZ);
  else
      read(fd,lbuf,1);
  if(peek(0xe802) == 0xc3)
      call(0xe802,0,0,0,0); /* r.t.c. put data in hi mem */
  lrec = lbuf+rnum;
  movmem(0xf406,lrec-4+LRL,4); /* time/date data from hi mem */
  for(i = lrec-4+LRL; i < lrec+LRL; i++)
      *i = bbcd(*i);
  movmem(0x6c,lrec,12);
  if(peek(0x6c) == 0)
      *lrec = peek(4) + 1;
  *lrec = *lrec | (peek(4) & 0xf0);
  if((option == 'R') || (option == 'H'))
      *lrec = *lrec | 0x80;
  seek(fd,bnum,0);
  write(fd,lbuf,1);
  close(fd);
  bdos(32,savusr); /* restore orig user nr */
}

main(argc,argv)
int argc;
char **argv;
{ char *s;
  printf("XMODEM (PMMI/BDS-C) ver 1.1    9-Jul-81\n");
  s=*++argv;
  ++argv;
  switch(s[0])
      { case 'R':
        case 'S':
        case 'H':
        case 'Q':
            option = s[0];
            break;

        default:
            printf("Command format: XMODEM option filename.typ\n");
            printf("Available options are:\n");
            printf("\tS: Send file     R: Receive file\n");
            printf("\tH: Hide file     Q: Query file size\n");
            exit();
            break;
      }

  switch(option)
      { case 'R': 
        case 'H':
            ckfile(argc,argv);
            if (filfnd(*argv))
                { printf("\nFile %s exists, pick another name.\n",*argv);
                  exit();
                }
            else
                { logfil(*argv);
                  readfile(*argv);
                }
            break;

        case 'S': 
            ckfile(argc,argv);
            if (filfnd(*argv))
                { logfil(*argv);
                  sendfile(*argv);
                }
            else
                { printf("\n++File %s not found++\n",*argv);
                  exit();
                }
            break;

        case 'Q':
            docfile(*argv);
            break;
      }
}
