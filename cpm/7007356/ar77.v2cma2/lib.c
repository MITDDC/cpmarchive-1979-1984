

/*
** lib.c  -- function library
**
** Copyright 1982 J. E. Hendrix
*/

#define NOCCARGC  /* don't pass arg count to functions */
                  /* called by these functions */
#include stdio.h


/*
** dtoi -- convert signed decimal string to integer nbr
**         returns field length, else ERR on error
*/
dtoi(decstr, nbr)  char *decstr;  int *nbr;  {
  int len, s;
  if((*decstr)=='-') {s=1; ++decstr;} else s=0;
  if((len=utoi(decstr, nbr))<0) return ERR;
  if(*nbr<0) return ERR;
  if(s) {*nbr = -*nbr; return ++len;} else return len;
  }


/*
** itod -- convert nbr to signed decimal string of width sz
**         right adjusted, blank filled; returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itod(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  char sgn;
  if(nbr<0) {nbr = -nbr; sgn='-';}
  else sgn=' ';
  if(sz>0) str[--sz]=NULL;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=NULL) ++sz;
  while(sz) {
    str[--sz]=(nbr%10+'0');
    if((nbr=nbr/10)==0) break;
    }
  if(sz) str[--sz]=sgn;
  while(sz>0) str[--sz]=' ';
  return str;
  }



/*
** itou -- convert nbr to unsigned decimal string of width sz
**         right adjusted, blank filled; returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itou(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int lowbit;
  if(sz>0) str[--sz]=NULL;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=NULL) ++sz;
  while(sz) {
    lowbit=nbr&1;
    nbr=(nbr>>1)&32767;  /* divide by 2 */
    str[--sz]=((nbr%5)<<1)+lowbit+'0';
    if((nbr=nbr/5)==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }



/*
** itox -- converts nbr to hex string of length sz
**         right adjusted and blank filled, returns str
**
**        if sz > 0 terminate with null byte
**        if sz = 0 find end of string
**        if sz < 0 use last byte for data
*/
itox(nbr, str, sz)  int nbr;  char str[];  int sz;  {
  int digit, offset;
  if(sz>0) str[--sz]=NULL;
  else if(sz<0) sz = -sz;
  else while(str[sz]!=NULL) ++sz;
  while(sz) {
    digit=nbr&15; nbr=(nbr>>4)&4095;
    if(digit<10) offset=48; else offset=55;
    str[--sz]=digit+offset;
    if(nbr==0) break;
    }
  while(sz) str[--sz]=' ';
  return str;
  }



/*
** left -- left adjust and null terminate a string
*/
left(str) char *str; {
  char *str2;
  str2=str;
  while(*str2==' ') ++str2;
  while(*str++ = *str2++);
  }




cout(c, fd) char c; int fd; {
  if(fputc(c, fd)==EOF) xout();
  }

sout(string, fd) char *string; int fd; {
  if(fputs(string, fd)==EOF) xout();
  }

lout(line, fd) char *line; int fd; {
  sout(line, fd);
  cout('\n', fd);
  }

xout() {
  fputs("output error\n", stderr);
  abort(ERR);
  }




/*
** printf(controlstring, arg, arg, ...) -- formatted print
**        operates as described by Kernighan & Ritchie
**        only d, x, c, s, and u specs are supported.
*/
printf(argc) int argc; {
  int i, width, prec, preclen, len, *nxtarg;
  char *ctl, *cx, c, right, str[7], *sptr, pad;
  i = CCARGC();   /* fetch arg count from A reg first */
  nxtarg = &argc + i - 1;
  ctl = *nxtarg;
  while(c=*ctl++) {
    if(c!='%') {cout(c, stdout); continue;}
    if(*ctl=='%') {cout(*ctl++, stdout); continue;}
    cx=ctl;
    if(*cx=='-') {right=0; ++cx;} else right=1;
    if(*cx=='0') {pad='0'; ++cx;} else pad=' ';
    if((i=utoi(cx, &width)) >= 0) cx=cx+i; else continue;
    if(*cx=='.') {
      if((preclen=utoi(++cx, &prec)) >= 0) cx=cx+preclen;
      else continue;
      }
    else preclen=0;
    sptr=str; c=*cx++; i=*(--nxtarg);
    if(c=='d') itod(i, str, 7);
    else if(c=='x') itox(i, str, 7);
    else if(c=='c') {str[0]=i; str[1]=NULL;}
    else if(c=='s') sptr=i;
    else if(c=='u') itou(i, str, 7);
    else continue;
    ctl=cx; /* accept conversion spec */
    if(c!='s') while(*sptr==' ') ++sptr;
    len=-1; while(sptr[++len]); /* get length */
    if((c=='s')&(len>prec)&(preclen>0)) len=prec;
    if(right) while(((width--)-len)>0) cout(pad, stdout);
    while(len) {cout(*sptr++, stdout); --len; --width;}
    while(((width--)-len)>0) cout(pad, stdout);
    }
  }



/*
** sign -- return -1, 0, +1 depending on the sign of nbr
*/
sign(nbr)  int nbr;  {
  if(nbr>0) return 1;
  else if(nbr==0) return 0;
  else return -1;
  }




/*
** strcmp -- return -1, 0, +1 depending on str1 <, =, > str2
*/
strcmp(str1, str2)  char *str1, *str2;  {
  char c1, c2;
  while((c1=*str1++)==(c2=*str2++)) if(c1==NULL) return 0;
  return sign(c1-c2);
  }



/*
** utoi -- convert unsigned decimal string to integer nbr
**          returns field size, else ERR on error
*/
utoi(decstr, nbr)  char *decstr;  int *nbr;  {
  int d,t; d=0;
  *nbr=0;
  while((*decstr>='0')&(*decstr<='9')) {
    t=*nbr;t=(10*t) + (*decstr++ - '0');
    if ((t>=0)&(*nbr<0)) return ERR;
    d++; *nbr=t;
    }
  return d;
  }



/*



/*
** xtoi -- convert hex string to integer nbr
**         returns field size, else ERR on error
*/
xtoi(hexstr, nbr)  char *hexstr;  int *nbr;  {
  int d,t; d=0;
  *nbr=0;
  while(1)
    {
    if((*hexstr>='0')&(*hexstr<='9')) t=48;
    else if((*hexstr>='A')&(*hexstr<='F')) t=55;
    else if((*hexstr>='a')&(*hexstr<='f')) t=87;
    else break;
    if(d<4) ++d; else return ERR;
    *nbr=*nbr<<4;
    *nbr=*nbr+(*hexstr++)-t;
    }
  return d;
  }






/*
** abs -- returns absolute value of nbr
*/
abs(nbr)  int nbr;
  {if(nbr<0) return -nbr; else return nbr;}
