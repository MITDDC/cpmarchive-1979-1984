/* Screen editor:  general utilities
 *		   BDS C version
 *
 * Source:  ed9.cc
 * Version: May 15, 1981.
 */

/* define global constants and variables */

#include ed.h
#include bdscio.h
#include ed1.ccc
#include edext.cc

/* return: is first token in args a number ? */
/* return value of number in *val            */

number(args,val) char *args; int *val;
{
char c;
	c=*args++;
	if ((c<'0')||(c>'9')) {
		return(NO);
	}
	*val=c-'0';
	while (c=*args++) {
		if ((c<'0')||(c>'9')) {
			break;
		}
		*val=(*val*10)+c-'0';
	}
	return(YES);
}

/* convert character buffer to numeric */

ctoi(buf,index) char *buf; int index;
{
int k;
	while ( (buf[index]==' ')||
		(buf[index]==TAB) ) {
		index++;
	}
	k=0;
	while ((buf[index]>='0')&&(buf[index]<='9')) {
		k=(k*10)+buf[index]-'0';
		index++;
	}
	return(k);
}


/* put decimal integer n in field width >= w.
 * left justify the number in the field.
 */

putdec(n,w) int n,w;
{
char chars[10];
int i,nd;
	nd=itoc(n,chars,10);
	i=0;
	while (i<nd) {
		syscout(chars[i++]);
	}
	i=nd;
	while (i++<w) {
		syscout(' ');
	}
}

/* convert integer n to character string in str */

itoc(n,str,size) int n; char *str; int size;
{
int absval;
int len;
int i,j,k;
	absval=abs(n);
	/* generate digits */
	str[0]=0;
	i=1;
	while (i<size) {
		str[i++]=(absval%10)+'0';
		absval=absval/10;
		if (absval==0) {
			break;
		}
	}
	/* generate sign */
	if ((i<size)&&(n<0)) {
		str[i++]='-';
	}
	len=i-1;
	/* reverse sign, digits */
	i--;
	j=0;
	while (j<i) {
		k=str[i];
		str[i]=str[j];
		str[j]=k;
		i--;
		j++;
	}
	return(len);
}

/* system error routine */

syserr(s) char *s;
{
	pmtmess("system error: ",s);
}

/* user error routine */

error(s) char *s;
{
	pmtmess("error: ",s);
}

/* disk error routine */

diskerr(s) char *s;
{
	pmtmess("disk error: ",s);
}

/* read the next line of the file into
 * the buffer of size n that p points to.
 * Successive calls to readline() read the file
 * from front to back.
 */

readline(file,p,n) int file; char *p; int n;
{
int c;
int k;
	k=0;
	while (1) {
		c=sysrdch(file);
		if (c==ERR) {
			return(ERR);
		}
		if (c==EOF) {
			/* ignore line without CR */
			return (EOF);
		}
		if (c==CR) {
			return(k);
		}
		if (k<n) {
			/* move char to buffer */
			*p++=c;
		}
		/* always bump count */
		k++;
	}
}

/* push (same as write) line to end of file.
 * line is in the buffer of size n that p points to.
 * lines written by this routine may be read by
 * either readline() or popline().
 */

pushline(file,p,n) int file; char *p; int n;
{
	/* write all but trailing CR */
	while ((n--)>0) {
		if (syspshch(*p++,file)==ERR) {
			return(ERR);
		}
	}
	/* write trailing CR */
	return(syspshch(CR,file));
}

/* pop a line from the back of the file.
 * the line should have been pushed using pushline().
 */

popline(file,p,n) int file; char *p; int n;
{
int c;
int k, kmax, t;
	/* first char must be CR */
	c=syspopch(file);
	if (c==EOF) {
		/* at START of file */
		return(EOF);
	}
	if (c==CR) {
		/* put into buffer */
		*p++=CR;
		k=1;
	}
	else {
		syserr("popline: missing CR");
		return(ERR);
	}
	/* pop line into buffer in reverse order */
	while (1) {
		c=syspopch(file);
		if (c==ERR) {
			return(ERR);
		}
		if (c==EOF) {
			break;
		}
		if (c==CR) {
			/* this ends ANOTHER line */
			/* push it back           */
			if (syspshch(CR,file)==ERR) {
				return(ERR);
			}
			break;
		}
		/* non-special case */
		if (k<n) {
			/* put into buffer */
			*p++=c;
		}
		/* always bump count */
		k++;
	}
	/* remember if we truncated the line */
	kmax=k;
	/* reverse the buffer */
	k=min(k,n-1);
	t=0;
	while (k>t) {
		/* swap p[t], p[k] */
		c=p[k];
		p[k]=p[t];
		p[t]=c;
		k--;
		t++;
	}
	return(kmax);
}
