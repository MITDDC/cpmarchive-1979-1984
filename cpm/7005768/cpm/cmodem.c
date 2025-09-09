/*This program implements the Ward Christenson assembly language
  program in C.  All of the original modes are available, and a
  capture buffer was added to the terminal and computer modes.
  The UNIX and PDP10 modes were added to facilitate sending files
  to those systems.,  Note that this program as written is for the
  original version of the D. C. Hayes modem board. However, it will
  execute correctly on the newer Modem-100 board.

                                      Jack M. Wierda
*/
#include     <b:dch.h>

#define      FALSE  0
#define      TRUE  1
#define      NUL  0
#define      SOH  1
#define      CTRLB 2
#define      CTRLC  3
#define      EOT  4
#define      ERRORMAX  5
#define      RETRYMAX  5
#define      CTRLE  5
#define      ACK  6
#define      TAB  9
#define      LF  10
#define      CR  13
#define      CTRLQ  17
#define      SPS 2750           /*loops per second*/
#define      CTRLS  19
#define      NAK  21
#define      CTRLZ  26
#define      SPACE  32
#define      DELETE  127
#define      TIMEOUT  -1
#define      SECSIZ  0x80
#define      BUFSIZ  0x7f80	/*maximum size, 0x8000 will not work with
				  with BDS C, reduce buffer size as necessary
                                  for smaller systems*/
 
char dchcw1, dchcw2;
char hangup, option, option2, mode, baudrate, display, system;
char asciiflg, showtrans, showrecv, view;
char buffer[BUFSIZ];
 
sendline(data)
char data;
{
  while(!statp(DCHSP,TRE,TRE));
  outp(DCHDP,data);
  if(showtrans)
    { if(asciiflg)
        if(((data >= ' ') && (data <= 0x7f)) || data == LF || data == CR 
            || data == TAB)
          putchar(data);
        else
          printf("[%0x]",data);
      if(option2 == 'H')
        printf("[%0x]",data);
    }
}
 
readline(seconds)
int seconds;
{
  char data;
  seconds = seconds * SPS;
  while (!statp(DCHSP,RRF,RRF) && seconds--);
  if(seconds < 0)
    return(TIMEOUT);
  data = input(DCHDP,DCHMASK);
  if(showrecv)
    { if(asciiflg)
        if(((data >= ' ') && (data <= 0x7f)) || data == LF || data == CR 
            || data == TAB)
          putchar(data);
        else
          printf("[%0x]",data);
      if(option2 == 'H')
        printf("<%0x>",data);
    }
  return(data);
}

purgeline()
{
  while(statp(DCHSP,RRF,RRF))
    input(DCHDP,DCHMASK);   /*PURGE THE RECEIVE REGISTER*/
}

dchinitialize()
{
  char cdflg;
  cdflg = TRUE;
  if((option == 'R') || (option == 'S'))
    { dchcw1 = PI+LS2+LS1;
      dchcw2 = OH+RID+TXE+dchcw2;
    }
  else
    { dchcw1 = LS2+EPE;
      dchcw2 = OH+RID+TXE+dchcw2;
    }
  if(!statp(DCHSP,CD,CD))
    { printf("Waiting for carrier\n");
      cdflg = FALSE;
    }
  while(!statp(DCHSP,CD,CD) && !bios(2))
    { outp(DCHCP2,dchcw2);
      outp(DCHCP1,dchcw1);
    }
  if(statp(DCHSP,CD,CD) && !cdflg)
    printf("Carrier detected\n");
  purgeline();
}

sendstr(str)
char *str;
{
  while(*str)
    if(option == 'U')
      sendline(tolower(*str++));
    else
      sendline(*str++);
}

termcomp()
{
  char bflag, kbdata, dchdata;
  int fd;
  int bufctr;
  bflag = FALSE;
  bufctr = 0;
  dchinitialize();
  while((statp(DCHSP,CD,CD)) && (kbdata != CTRLE))
    { if(bios(2))
        switch(kbdata = bios(3))
          { case CTRLB:
              bflag = ~bflag;
              if(bflag)
                printf("Capture initiated");
              else
                printf("Capture terminated");
              printf(", %u bytes free\n",BUFSIZ - bufctr);
              break;
            case CTRLE:
              break;
            default:
              if(option == 'C')
                { putchar(kbdata);
                  if(bflag && (bufctr < BUFSIZ))
                    buffer[bufctr++] = kbdata;
                }
              outp(DCHDP,kbdata);
              break;
          }
      if(statp(DCHSP,RRF,RRF))
        { dchdata = input(DCHDP,DCHMASK);
          if(option == 'C')
            outp(DCHDP,dchdata);
          if(bflag && (bufctr < BUFSIZ))
            buffer[bufctr++] = dchdata;
          else if(bflag)
            printf("Buffer overflow\n");
          putchar(dchdata);
        }
    }
  if(bufctr)
    { buffer[bufctr] = CTRLZ;
      fd = creat("cmodem.tmp");
      if(fd == -1)
        { printf("Cannot create cmodem.tmp\n");
          exit();
        }
      write(fd,buffer,1 + (bufctr/SECSIZ));
      close(fd);
    }
}
 
putbuffer(buffer,sectors)
char *buffer;
int sectors;
{
  char ch, dchdata; 
  unsigned  k;
  ch = 0;
  k = 0;
  while((ch != CTRLZ) && (k < sectors * SECSIZ) && (statp(DCHSP,CD,CD)))
        { k = k+1;
          if((ch = *buffer++) == LF)        /*don't send LF's*/
            putchar(LF);
          else
            if(ch != CTRLZ || option != 'U') /*don't send CTRLZ to UNIX*/
              sendline(ch);
          if(!(k & 0xff))                   /*let other end catch-up*/ 
             while(readline(1) != TIMEOUT);
        }
}

pdp10(file)
char *file;
{
  char sectors;
  int fd;
  showrecv = FALSE;
  asciiflg = showtrans = TRUE;
  fd = open(file,0);
  if(fd == -1)
    { printf("Cannot open %s\n",file);
      exit();
    }
  dchinitialize();
  if(option == 'P')
    { sendstr("\nR PIP\n");
      while((readline(1) != '*') && !bios(2));
      if(*(++file) != ':')
        sendstr(--file);
      else
        sendstr(++file);
      sendstr("=TTY:\n");
    }
  else
    { sendstr("\ncat > ");
      if(*(++file) != ':')
        sendstr(--file);
      else
        sendstr(++file);
      sendstr("\n");
    }
  while((sectors = read(fd,buffer,BUFSIZ/SECSIZ)) == BUFSIZ/SECSIZ)
    putbuffer(buffer,sectors);
  if(sectors)
    putbuffer(buffer,sectors);
  close(fd);
  while(readline(1) != TIMEOUT);
  if(option == 'P')
    sendline(CTRLC);
  else
    { sendline(CR);
      sendline(LF);
      sendline(EOT);
    }
  while(readline(10) != TIMEOUT);
  sendline(CR);
  sendline(LF);
}
 
readfile(file)
char *file;
{ int j, firstchar, sectnum, sectcurr, sectcomp, errors;
  int checksum;
  int errorflag, fd;
  int bufctr;

  if(view)
    { showrecv = TRUE;
      showtrans = FALSE;
    }
  option2 = 'A';
  fd = creat(file);
  if(fd == -1)
    { printf("Cannot create %s\n",file);
      exit();
    }
  sectnum = 0;
  errors = 0;
  bufctr = 0;
  dchinitialize();
  sendline(NAK);
  do
    { errorflag = FALSE;
      do
        firstchar = readline(6);
      while(firstchar != SOH && firstchar != EOT && firstchar != TIMEOUT);
      if(firstchar == TIMEOUT)
        { errorflag = TRUE;
          printf("SOH timeout\n");
        }
      if(firstchar == SOH)
        { sectcurr = readline(1);
          sectcomp = readline(1);
          if((sectcurr + sectcomp) == 255)
            { if(sectcurr == sectnum + 1)
                { checksum = 0;
                  if(option2 == 'A')
                    asciiflg = TRUE;
                  for(j = bufctr;j < (bufctr + SECSIZ);j++)
                    { buffer[j] = readline(1);
                      checksum = (checksum + buffer[j]) & 0xff;
                    }
                  asciiflg = FALSE;
                  if(checksum == readline(1))
                    { errors = 0;
                      sectnum = sectcurr;
                      bufctr = bufctr + SECSIZ;
                      if(bufctr == BUFSIZ)
                        { bufctr = 0;
                          write(fd,buffer,BUFSIZ/SECSIZ);
                        }
                      if(!showrecv)
                        printf("Received sector %d\n",sectcurr);
                      sendline(ACK);
                    }
                  else
                    { printf("Checksum error, expected <%0x>\n",checksum);
                      errorflag = TRUE;
                    }
                }
              else
                if(sectcurr == sectnum)
                  { do;
                    while(readline(1) != TIMEOUT);
                    printf("Received duplicate sector %d\n", sectcurr);
                    sendline(ACK);
                  }
                else
                  { printf("Synchronization error\n");
                    errorflag = TRUE;
                  }
              }
            else
              { printf("Sector number error\n");
                errorflag = TRUE;
              }
          }
       if(errorflag == TRUE)
         { errors++;
           printf("Error %d\n",errors);
           while(readline(1) != TIMEOUT);
           sendline(NAK);
         }
     }
  while(firstchar != EOT && errors != ERRORMAX);
  if((firstchar == EOT) && (errors < ERRORMAX))
    { sendline(ACK);
      write(fd,buffer,1 + (bufctr/SECSIZ));
      close(fd);
      printf("Transfer complete\n");
    }
  else
    printf("Aborting\n");
}

sendfile(file)
char *file;
{
  int j, sectnum, sectors, attempts;
  int checksum;
  int bufctr, fd;

  if(view)
    { showrecv = FALSE;
      showtrans = TRUE;
    }
  option2 = 'A';
  fd = open(file,0);
  if(fd == -1)
    { printf("Cannot open %s\n",file);
      exit();
    }
  dchinitialize();
  attempts = 0;
  sectnum = 1;
  while((sectors = read(fd,buffer,BUFSIZ/SECSIZ)) && (attempts != RETRYMAX))
    { if(sectors == -1)
        printf("\nFile read error\n");
      else
        { bufctr = 0;
          do
            { attempts = 0;
              do
                { if(!showtrans)
                    printf("\nSending sector %d\n",sectnum);
                  sendline(SOH);
                  sendline(sectnum);
                  sendline(-sectnum-1);
                  checksum = 0;
                  if(option2 == 'A')
                    asciiflg = TRUE;
                  for(j = bufctr;j < (bufctr + SECSIZ);j++)
                    { sendline(buffer[j]);
                      checksum = (checksum + buffer[j]) & 0xff;
                    }
                  asciiflg = FALSE;
                  sendline(checksum);
                  purgeline();
                  attempts++;
                }
              while((readline(10) != ACK) && (attempts != RETRYMAX));
              bufctr = bufctr + SECSIZ;
              sectnum++;
              sectors--;
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
          else
            printf("\nTransfer complete\n");
        } 
  close(fd);
}

ckfile(argc) int argc;
{ if(!argc)
    { printf("File required\n");
      exit();
    }
}

main(argc,argv)
int argc;
char **argv;
{ char *s;
  printf("Cmodem, 9-July-80\n");
  dchcw2 = 0;
  asciiflg = hangup = showrecv = showtrans = view = FALSE;
  if(**++argv != '-')
    { printf("Command line format: cmodem -options file1 file2 ... file14\n");
      printf("Available options are:\n");
      printf("\ta: answer\n");
      printf("\tc: computer\n");
      printf("\th: auto-hangup\n");
      printf("\to: originate\n");
      printf("\tp: PDP10\n");
      printf("\tr: receive file\n");
      printf("\ts: send file\n");
      printf("\tt: terminal\n");
      printf("\tu: UNIX\n");
      printf("\tv: view data\n");
      printf("\t1: 110 baud\n");
      printf("\t3: 300 baud\n");
      printf("The p, r, s, and u options require one or more files.\n");
      printf("Ctrl-B initiates and terminates data capture in file\n");
      printf("cmodem.tmp in the terminal and computer modes.\n");
      printf("Ctrl-E is used to initiate file transfers in the UNIX and\n");
      printf("PDP10 modes. In the terminal mode Ctrl-E escapes to the\n");
      printf("hangup question or CP/M.\n");
      printf("Any character escapes the no carrier condition.\n");
      exit();
    }
  --argv;
  while(--argc && **++argv == '-')
    for(s = *argv+1;*s;s++)
      switch(*s)
        { case 'C':
          case 'P':
          case 'R':
          case 'S':
          case 'T':
          case 'U':
            option = *s;
            break;
          case 'A':
          case '1':
            break;
          case 'H':
            hangup = TRUE;
            break;
          case 'V':
            view = TRUE;
            break;
          case 'O':
            dchcw2 = dchcw2 + MS;
            break;
          case '3':
            dchcw2 = dchcw2 + BRS;
            break;
          default:
            printf("Unimplemented option %c\n\n",*s);
            exit();
            break;
        }
      switch(option)
        { case 'C':
          case 'T': 
            termcomp();
            break;
          case 'P': 
          case 'U':
            ckfile(argc);
            termcomp();
            while(argc--)
              { printf("\nSending %s\n",*argv);
                pdp10(*argv++);
              }
            termcomp();
            break;
          case 'R': 
            ckfile(argc);
            while(argc--)
              { printf("\nReceiving %s\n",*argv);
                readfile(*argv++);
              }
            break;
          case 'S': 
            ckfile(argc);
            while(argc--)
              { printf("\nSending %s\n",*argv);
                sendfile(*argv++);
              }
            break;
        }
      if(hangup)
        outp(DCHCP2,0);
      else
        { do
            { printf("\nHangup : Y(es), N(o) ? ");
              hangup = tolower(getchar());
              printf("\n");
            }
          while((hangup != 'y') && (hangup != 'n'));
          if(hangup == 'y')
            outp(DCHCP2,0);
        }
}











