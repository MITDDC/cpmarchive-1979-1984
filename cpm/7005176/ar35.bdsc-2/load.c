/*
	LOAD.C		written by Leo Kenen (I think --LZ)

	Works like the standard CP/M LOAD.COM utility, except it's
	written in C.
*/

#include "bdscio.h"

main(argc,argv)
int argc;
char **argv;
{
        char buf[BUFSIZ], obuf[BUFSIZ];
        int     lfd, ofd;
        char    name[20], oname[20];

        if (!(--argc))
        {
                printf("Useage:load <filename>");
                exit();
        }
        strcpy(name,argv[1]);
        lfd = fopen(name,buf);
        if (lfd == ERROR)
        {
                strcat(name,".HEX");
                lfd = fopen(name,buf);
                if (lfd == ERROR)
                {
                        printf("File not found.\n");
                        exit();
                }
        }
        /* Open the output file */
        strcpy(oname,argv[1]);
        strip(oname);
        strcat(oname,".OBJ");
        ofd = fcreat(oname,obuf);
        if (ofd == ERROR)
        {
                printf("Can not create output file");
                exit();
        }
        load(buf,obuf); /* DO the load operation to fname.obj */
        fflush(obuf);
        fclose(buf);
        fclose(obuf);
}

load(fb,ofb)
char fb[], ofb[];
{
        unsigned  address;
        int       bytes, chksum, count, foo;
        char      ch;

        while((ch=getc(fb)) != ':' );
        while((bytes=rdhex(fb)) != 0 )
        {
                address = rdword(fb);
                foo = rdhex(fb);
                for (count=1;count<=bytes;count++) putc(rdhex(fb),ofb);
                foo = rdhex(fb);
                while((ch=getc(fb)) != ':');
        }
}

rdhex(fbuf)
char fbuf[];
{
        char first, second;

        if (ishex(first=getc(fbuf)) && ishex(second=getc(fbuf)))
        return((tohex(first)*16)+tohex(second));
        else { printf("\nBad hex digit, error.\n");
               exit();
             }
}

rdword(fb)
char fb[];
{
        return((rdhex(fb)<<8)+rdhex(fb));
}

/* Remove anything after a . from a file name */


strip(s)
char *s;
{
        while ((*s != '.') && (*s))  *s++;
        *s = '\0';
}
