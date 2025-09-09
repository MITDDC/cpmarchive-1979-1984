      programratfor
      bytename(8),namer(11),namef(11)
      datanamer(9),namer(10),namer(11)/1hR,1hA,1hT/
      datanamef(9),namef(10),namef(11)/1hF,1hO,1hR/
9     format(51hAddison-Wesley Ratfor adapted for FORTRAN-80 August,59h1
     &979 by Tim Prince, 1 EastLakeView Apt 17, Cincinnati 45237)
      write(3,1,err=3)
1     format(1x,17hInput file name ?)
3     read(3,2,err=4)name
2     format(8a1)
4     do 23000i=1,8
      namer(i)=name(i)
      namef(i)=name(i)
23000 continue
23001 continue
      callopen(7,namer,0)
      callopen(6,namef,0)
      callparse
      endfile6
      stop
      end
      blockdatainitl
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      dataoutp/0/
      datalevel/1/,linect(1)/1/,infile(1)/7/
      databp/0/
      datafordep/0/
      datalastp/0/,lastt/0/
      datasdo/100,111,-2/,vdo/-66,-2/
      datasif/105,102,-2/,vif/-61,-2/
      dataselse/101,108,115,101,-2/
      datavelse/-62,-2/
      dataswhile/119,104,105,108,101,-2/
      datavwhile/-63,-2/
      datasbreak/98,114,101,97,107,-2/
      datavbreak/-64,-2/
      datasnext/110,101,120,116,-2/
      datavnext/-65,-2/
      datasfor/102,111,114,-2/,vfor/-68,-2/
      datasrept/114,101,112,101,97,116,-2/
      datavrept/-69,-2/
      datasuntil/117,110,116,105,108,-2/
      datavuntil/-70,-2/
      end
      logicalfunctionalldig(str)
      bytetype,str(100)
      alldig=.false.
      if(.not.(str(1).eq.-2))goto 23002
      return
23002 continue
      continue
      i=1
23004 if(.not.(str(i).ne.-2))goto 23006
      if(.not.(type(str(i)).ne.2))goto 23007
      return
23007 continue
23005 i=i+1
      goto 23004
23006 continue
      alldig=.true.
      return
      end
      subroutinebalpar
      bytegettok,t,token(200)
      integer*1nlpar
      if(.not.(gettok(token,200).ne.40))goto 23009
      callsynerr(19hmissing left paren.)
      return
23009 continue
      calloutstr(token)
      nlpar=1
      continue
23011 continue
      t=gettok(token,200)
      if(.not.(t.eq.59.or.t.eq.123.or.t.eq.125.or.t.eq.-3))goto 23014
      callpbstr(token)
      goto 23013
23014 continue
      if(.not.(t.eq.10))goto 23016
      token(1)=-2
      goto 23017
23016 continue
      if(.not.(t.eq.40))goto 23018
      nlpar=nlpar+1
      goto 23019
23018 continue
      if(.not.(t.eq.41))goto 23020
      nlpar=nlpar-1
23020 continue
23019 continue
23017 continue
      calloutstr(token)
23012 if(.not.(nlpar.le.0))goto 23011
23013 continue
      if(.not.(nlpar.ne.0))goto 23022
      callsynerr(33hmissing parenthesis in condition.)
23022 continue
      return
      end
      subroutinebrknxt(sp,lextyp,labval,token)
      integeri,labval(100),sp
      bytelextyp(100),token
      continue
      i=sp
23024 if(.not.(i.gt.0))goto 23026
      if(.not.(lextyp(i).eq.-63.or.lextyp(i).eq.-66.or.lextyp(i).eq.-68.
     &or.lextyp(i).eq.-69))goto 23027
      labout=labval(i)
      if(.not.(token.eq.-64))goto 23029
      labout=labout+1
23029 continue
      calloutgo(labout)
      return
23027 continue
23025 i=i-1
      goto 23024
23026 continue
      if(.not.(token.eq.-64))goto 23031
      callsynerr(14hillegal break.)
      goto 23032
23031 continue
      callsynerr(13hillegal next.)
23032 continue
      return
      end
      subroutineclosei(fd)
      integerfd
      endfilefd
      return
      end
      bytefunctiondeftok(token,toksiz,fd)
      integerfd,toksiz
      bytegtok,defn(200),t,token(toksiz)
      logicallookup
      continue
      t=gtok(token,toksiz,fd)
23033 if(.not.(t.ne.-3))goto 23035
      if(.not.(t.ne.-100))goto 23036
      goto 23035
23036 continue
      if(.not.(.not.lookup(token,defn)))goto 23038
      goto 23035
23038 continue
      if(.not.(defn(1).eq.-10))goto 23040
      callgetdef(token,toksiz,defn,200,fd)
      callinstal(token,defn)
      goto 23041
23040 continue
      callpbstr(defn)
23041 continue
23034 t=gtok(token,toksiz,fd)
      goto 23033
23035 continue
      deftok=t
      if(.not.(deftok.eq.-100))goto 23042
      callfold(token)
23042 continue
      return
      end
      subroutinefold(token)
      bytetoken(100)
      integer*1lwrmup
      lwrmup=97-65
      continue
      i=1
23044 if(.not.(token(i).ne.-2))goto 23046
      if(.not.(token(i).ge.65.and.token(i).le.90))goto 23047
      token(i)=token(i)+lwrmup
23047 continue
23045 i=i+1
      goto 23044
23046 continue
      return
      end
      subroutinedocode(lab)
      bytedostr(4)
      datadostr/100,111,32,-2/
      callouttab
      calloutstr(dostr)
      lab=labgen(2)
      calloutnum(lab)
      calleatup
      calloutdon
      return
      end
      subroutinedostat(lab)
      calloutcon(lab)
      calloutcon(lab+1)
      return
      end
      subroutineeatup
      bytegettok,ptoken(200),t,token(200)
      integer*1nlpar
      nlpar=0
      continue
23049 continue
      t=gettok(token,200)
      if(.not.(t.eq.59.or.t.eq.10))goto 23052
      goto 23051
23052 continue
      if(.not.(t.eq.125))goto 23054
      callpbstr(token)
      goto 23051
23054 continue
      if(.not.(t.eq.123.or.t.eq.-3))goto 23056
      callsynerr(24hunexpected brace or eof.)
      callpbstr(token)
      goto 23051
23056 continue
      if(.not.(t.eq.44.or.t.eq.95))goto 23058
      if(.not.(gettok(ptoken,200).ne.10))goto 23060
      callpbstr(ptoken)
23060 continue
      if(.not.(t.eq.95))goto 23062
      token(1)=-2
23062 continue
      goto 23059
23058 continue
      if(.not.(t.eq.40))goto 23064
      nlpar=nlpar+1
      goto 23065
23064 continue
      if(.not.(t.eq.41))goto 23066
      nlpar=nlpar-1
23066 continue
23065 continue
23059 continue
      calloutstr(token)
23050 if(.not.(nlpar.lt.0))goto 23049
23051 continue
      if(.not.(nlpar.ne.0))goto 23068
      callsynerr(23hunbalanced parentheses.)
23068 continue
      return
      end
      subroutineelseif(lab)
      calloutgo(lab+1)
      calloutcon(lab)
      return
      end
      logicalfunctionequal(str1,str2)
      bytestr1(100),str2(100)
      continue
      i=1
23070 if(.not.(str1(i).eq.str2(i)))goto 23072
      if(.not.(str1(i).eq.-2))goto 23073
      equal=.true.
      return
23073 continue
23071 i=i+1
      goto 23070
23072 continue
      equal=.false.
      return
      end
      subroutineerror(buf)
      bytebuf(100)
      callremark(buf)
      endfile6
      stop
      end
      subroutineforcod(lab)
      bytegettok,t,token(200),ifnot(9)
      integer*1i,nlpar
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      dataifnot/105,102,40,46,110,111,116,46,-2/
      lab=labgen(3)
      calloutcon(0)
      if(.not.(gettok(token,200).ne.40))goto 23075
      callsynerr(19hmissing left paren.)
      return
23075 continue
      if(.not.(gettok(token,200).ne.59))goto 23077
      callpbstr(token)
      callouttab
      calleatup
      calloutdon
23077 continue
      if(.not.(gettok(token,200).eq.59))goto 23079
      calloutcon(lab)
      goto 23080
23079 continue
      callpbstr(token)
      calloutnum(lab)
      callouttab
      calloutstr(ifnot)
      calloutch(40)
      nlpar=0
      continue
23081 if(.not.(nlpar.ge.0))goto 23082
      t=gettok(token,200)
      if(.not.(t.eq.59))goto 23083
      goto 23082
23083 continue
      if(.not.(t.eq.40))goto 23085
      nlpar=nlpar+1
      goto 23086
23085 continue
      if(.not.(t.eq.41))goto 23087
      nlpar=nlpar-1
23087 continue
23086 continue
      if(.not.(t.ne.10.and.t.ne.95))goto 23089
      calloutstr(token)
23089 continue
      goto 23081
23082 continue
      calloutch(41)
      calloutch(41)
      calloutgo(lab+2)
      if(.not.(nlpar.lt.0))goto 23091
      callsynerr(19hinvalid for clause.)
23091 continue
23080 continue
      fordep=fordep+1
      j=1
      continue
      i=1
23093 if(.not.(i.lt.fordep))goto 23095
      j=j+length(forstk(j))+1
23094 i=i+1
      goto 23093
23095 continue
      forstk(j)=-2
      nlpar=0
      continue
23096 if(.not.(nlpar.ge.0))goto 23097
      t=gettok(token,200)
      if(.not.(t.eq.40))goto 23098
      nlpar=nlpar+1
      goto 23099
23098 continue
      if(.not.(t.eq.41))goto 23100
      nlpar=nlpar-1
23100 continue
23099 continue
      if(.not.(nlpar.ge.0.and.t.ne.10.and.t.ne.95))goto 23102
      callscopy(token,1,forstk,j)
      j=j+length(token)
23102 continue
      goto 23096
23097 continue
      lab=lab+1
      return
      end
      subroutinefors(lab)
      integer*1i
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      calloutnum(lab)
      j=1
      continue
      i=1
23104 if(.not.(i.lt.fordep))goto 23106
      j=j+length(forstk(j))+1
23105 i=i+1
      goto 23104
23106 continue
      if(.not.(length(forstk(j)).gt.0))goto 23107
      callouttab
      calloutstr(forstk(j))
      calloutdon
23107 continue
      calloutgo(lab-1)
      calloutcon(lab+1)
      fordep=fordep-1
      return
      end
      bytefunctiongetch(c,f)
      bytebuf(81),c
      integerf
      datalastc/81/,buf(81)/10/
      if(.not.(buf(lastc).eq.10.or.lastc.ge.81))goto 23109
      read(f,1,err=5,end=10)(buf(i),i=1,80)
1     format(80a1)
      continue
      i=80
23111 if(.not.(i.gt.0))goto 23113
      if(.not.(buf(i).ne.32))goto 23114
      goto 23113
23114 continue
23112 i=i-1
      goto 23111
23113 continue
      buf(i+1)=10
      goto7
5     buf(1)=63
      buf(2)=10
7     if(.not.(buf(1).eq.10))goto 23116
      lastc=1
      goto 23117
23116 continue
      lastc=0
23117 continue
23109 continue
      lastc=lastc+1
      c=buf(lastc)
      getch=c
      return
10    c=-3
      getch=-3
      return
      end
      subroutinegetdef(token,toksiz,defn,defsiz,fd)
      integerdefsiz,fd,toksiz
      bytegtok,ngetch,c,defn(defsiz),token(toksiz)
      integer*1nlpar
      if(.not.(ngetch(c,fd).ne.40))goto 23118
      callremark(19hmissing left paren.)
23118 continue
      if(.not.(gtok(token,toksiz,fd).ne.-100))goto 23120
      callremark(22hnon-alphanumeric name.)
      goto 23121
23120 continue
      if(.not.(ngetch(c,fd).ne.44))goto 23122
      callremark(24hmissing comma in define.)
23122 continue
23121 continue
      nlpar=0
      continue
      i=1
23124 if(.not.(nlpar.ge.0))goto 23126
      if(.not.(i.gt.defsiz))goto 23127
      callerror(20hdefinition too long.)
      goto 23128
23127 continue
      if(.not.(ngetch(defn(i),fd).eq.-3))goto 23129
      callerror(20hmissing right paren.)
      goto 23130
23129 continue
      if(.not.(defn(i).eq.40))goto 23131
      nlpar=nlpar+1
      goto 23132
23131 continue
      if(.not.(defn(i).eq.41))goto 23133
      nlpar=nlpar-1
23133 continue
23132 continue
23130 continue
23128 continue
23125 i=i+1
      goto 23124
23126 continue
      defn(i-1)=-2
      return
      end
      bytefunctiongettok(token,toksiz)
      logicalequal
      integeropeni,toksiz
      bytejunk
      bytedeftok,name(30),token(toksiz),incl(8)
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      dataincl/105,110,99,108,117,100,101,-2/
      continue
23135 if(.not.(level.gt.0))goto 23137
      continue
      gettok=deftok(token,toksiz,infile(level))
23138 if(.not.(gettok.ne.-3))goto 23140
      if(.not.(.not.equal(token,incl)))goto 23141
      return
23141 continue
      junk=deftok(name,30,infile(level))
      if(.not.(level.ge.5))goto 23143
      callsynerr(27hincludes nested too deeply.)
      goto 23144
23143 continue
      infile(level+1)=openi(name,level+1)
      linect(level+1)=1
      level=level+1
23144 continue
23139 gettok=deftok(token,toksiz,infile(level))
      goto 23138
23140 continue
      if(.not.(level.gt.1))goto 23145
      callclosei(infile(level))
23145 continue
23136 level=level-1
      goto 23135
23137 continue
      gettok=-3
      return
      end
      bytefunctiongtok(lexstr,toksiz,fd)
      integertoksiz,fd
      bytengetch,type,c,lexstr(toksiz)
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      continue
23147 if(.not.(ngetch(c,fd).ne.-3))goto 23148
      if(.not.(c.ne.32.and.c.ne.9))goto 23149
      goto 23148
23149 continue
      goto 23147
23148 continue
      callputbak(c)
      continue
      i=1
23151 if(.not.(i.lt.toksiz-1))goto 23153
      gtok=type(ngetch(lexstr(i),fd))
      if(.not.(gtok.ne.1.and.gtok.ne.2))goto 23154
      goto 23153
23154 continue
23152 i=i+1
      goto 23151
23153 continue
      if(.not.(i.ge.toksiz-1))goto 23156
      callsynerr(15htoken too long.)
23156 continue
      if(.not.(i.gt.1))goto 23158
      callputbak(lexstr(i))
      lexstr(i)=-2
      gtok=-100
      goto 23159
23158 continue
      if(.not.(lexstr(1).eq.36))goto 23160
      if(.not.(ngetch(lexstr(2),fd).eq.40))goto 23162
      lexstr(1)=123
      gtok=123
      goto 23163
23162 continue
      if(.not.(lexstr(2).eq.41))goto 23164
      lexstr(1)=125
      gtok=125
      goto 23165
23164 continue
      callputbak(lexstr(2))
23165 continue
23163 continue
      goto 23161
23160 continue
      if(.not.(lexstr(1).eq.39.or.lexstr(1).eq.34))goto 23166
      continue
      i=2
23168 if(.not.(ngetch(lexstr(i),fd).ne.lexstr(1)))goto 23170
      if(.not.(lexstr(i).eq.10.or.i.ge.toksiz-1))goto 23171
      callsynerr(14hmissing quote.)
      lexstr(i)=lexstr(1)
      callputbak(10)
      goto 23170
23171 continue
23169 i=i+1
      goto 23168
23170 continue
      goto 23167
23166 continue
      if(.not.(lexstr(1).eq.35))goto 23173
      continue
23175 if(.not.(ngetch(lexstr(1),fd).ne.10))goto 23176
      goto 23175
23176 continue
      gtok=10
      goto 23174
23173 continue
      if(.not.(lexstr(1).eq.126.or.lexstr(1).eq.94))goto 23177
      lexstr(1)=33
23177 continue
      if(.not.(lexstr(1).eq.62.or.lexstr(1).eq.60.or.lexstr(1).eq.33.or.
     &lexstr(1).eq.61.or.lexstr(1).eq.38.or.lexstr(1).eq.124))goto 23179
      callrelate(lexstr,i,fd)
23179 continue
23174 continue
23167 continue
23161 continue
23159 continue
      lexstr(i+1)=-2
      if(.not.(lexstr(1).eq.10))goto 23181
      linect(level)=linect(level)+1
23181 continue
      return
      end
      subroutineifcode(lab)
      lab=labgen(2)
      callifgo(lab)
      return
      end
      subroutineifgo(lab)
      byteifnot(9)
      dataifnot/105,102,40,46,110,111,116,46,-2/
      callouttab
      calloutstr(ifnot)
      callbalpar
      calloutch(41)
      calloutgo(lab)
      return
      end
      subroutineinitkw
      bytedefnam(7),deftyp(2)
      datadefnam/100,101,102,105,110,101,-2/
      datadeftyp/-10,-2/
      callinstal(defnam,deftyp)
      return
      end
      subroutineinstal(name,defn)
      bytedefn(200),name(200)
      integerdlen
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      nlen=length(name)+1
      dlen=length(defn)+1
      if(.not.(lastt+nlen+dlen.gt.1500.or.lastp.ge.200))goto 23183
      callputlin(name,3)
      callremark(23h: too many definitions.)
23183 continue
      lastp=lastp+1
      namptr(lastp)=lastt+1
      callscopy(name,1,table,lastt+1)
      callscopy(defn,1,table,lastt+nlen+1)
      lastt=lastt+nlen+dlen
      return
      end
      functionitoc(int,str,size)
      integersize
      bytek,str(size)
      intval=iabs(int)
      str(1)=-2
      i=1
      continue
23185 continue
      i=i+1
      str(i)=mod(intval,10)+48
      intval=intval/10
23186 if(.not.(intval.eq.0.or.i.ge.size))goto 23185
23187 continue
      if(.not.(int.lt.0.and.i.lt.size))goto 23188
      i=i+1
      str(i)=45
23188 continue
      itoc=i-1
      continue
      j=1
23190 if(.not.(j.lt.i))goto 23192
      k=str(i)
      str(i)=str(j)
      str(j)=k
      i=i-1
23191 j=j+1
      goto 23190
23192 continue
      return
      end
      subroutinelabelc(lexstr)
      bytelexstr(100)
      if(.not.(length(lexstr).eq.5))goto 23193
      if(.not.(lexstr(1).eq.50.and.lexstr(2).eq.51))goto 23195
      callsynerr(34hwarning:  possible label conflict.)
23195 continue
23193 continue
      calloutstr(lexstr)
      callouttab
      return
      end
      functionlabgen(n)
      datalabel/23000/
      labgen=label
      label=label+n
      return
      end
      functionlength(str)
      bytestr(100)
      continue
      length=0
23197 if(.not.(str(length+1).ne.-2))goto 23199
23198 length=length+1
      goto 23197
23199 continue
      return
      end
      bytefunctionlex(lexstr)
      bytegettok,lexstr(200)
      logicalalldig,equal
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      continue
23200 if(.not.(gettok(lexstr,200).eq.10))goto 23201
      goto 23200
23201 continue
      lex=lexstr(1)
      if(.not.(lex.eq.-3.or.lex.eq.59.or.lex.eq.123.or.lex.eq.125))goto 
     &23202
      return
23202 continue
      if(.not.(alldig(lexstr)))goto 23204
      lex=-60
      goto 23205
23204 continue
      if(.not.(equal(lexstr,sif)))goto 23206
      lex=vif(1)
      goto 23207
23206 continue
      if(.not.(equal(lexstr,selse)))goto 23208
      lex=velse(1)
      goto 23209
23208 continue
      if(.not.(equal(lexstr,swhile)))goto 23210
      lex=vwhile(1)
      goto 23211
23210 continue
      if(.not.(equal(lexstr,sdo)))goto 23212
      lex=vdo(1)
      goto 23213
23212 continue
      if(.not.(equal(lexstr,sbreak)))goto 23214
      lex=vbreak(1)
      goto 23215
23214 continue
      if(.not.(equal(lexstr,snext)))goto 23216
      lex=vnext(1)
      goto 23217
23216 continue
      if(.not.(equal(lexstr,sfor)))goto 23218
      lex=vfor(1)
      goto 23219
23218 continue
      if(.not.(equal(lexstr,srept)))goto 23220
      lex=vrept(1)
      goto 23221
23220 continue
      if(.not.(equal(lexstr,suntil)))goto 23222
      lex=vuntil(1)
      goto 23223
23222 continue
      lex=-67
23223 continue
23221 continue
23219 continue
23217 continue
23215 continue
23213 continue
23211 continue
23209 continue
23207 continue
23205 continue
      return
      end
      logicalfunctionlookup(name,defn)
      bytedefn(200),name(200)
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      continue
      i=lastp
23224 if(.not.(i.gt.0))goto 23226
      j=namptr(i)
      continue
      k=1
23227 if(.not.(name(k).eq.table(j).and.name(k).ne.-2))goto 23229
      j=j+1
23228 k=k+1
      goto 23227
23229 continue
      if(.not.(name(k).eq.table(j)))goto 23230
      callscopy(table,j+1,defn,1)
      lookup=.true.
      return
23230 continue
23225 i=i-1
      goto 23224
23226 continue
      lookup=.false.
      return
      end
      bytefunctionngetch(c,fd)
      bytegetch,c
      integerfd
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      if(.not.(bp.gt.0))goto 23232
      c=buf(bp)
      goto 23233
23232 continue
      bp=1
      buf(1)=getch(c,fd)
23233 continue
      bp=bp-1
      ngetch=c
      return
      end
      integerfunctionopeni(name,level)
      bytename(30),namer(11)
      datanamer(9),namer(10),namer(11)/1hR,1hA,1hT/
      openi=level+6
      continue
      i=1
23234 if(.not.(i.le.8.and.name(i).ne.-2))goto 23236
      if(.not.(name(i).gt.95))goto 23237
      name(i)=name(i)-32
23237 continue
      namer(i)=name(i)
23235 i=i+1
      goto 23234
23236 continue
      if(.not.(name(i).ne.-2))goto 23239
      i=i+1
23239 continue
      continue
23241 if(.not.(i.le.8))goto 23242
  namer(i)=32
      i=i1:M2ee.-2))goto 23239
      i=i+1
23239 continue
      continue
23241 if(.not.(i.le.8))goto 23242
      namer(i)=32
      i=i+1
      goto 23241
23242 continue
      callopen(openi,namer,0)
      return
      end
      subroutineotherc(lexstr)
      bytelexstr(100)
      callouttab
      calloutstr(lexstr)
      calleatup
      calloutdon
      return
      end
      subroutineoutch(c)
      bytec
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      if(.not.(outp.ge.72))goto 23243
      calloutdon
      do 23245i=1,5
      outbuf(i)=32
23245 continue
23246 continue
      outbuf(6)=38
      outp=6
23243 continue
      outp=outp+1
      outbuf(outp)=c
      return
      end
      subroutineoutcon(n)
      bytecontin(9)
      datacontin/99,111,110,116,105,110,117,101,-2/
      if(.not.(n.gt.0))goto 23247
      calloutnum(n)
23247 continue
      callouttab
      calloutstr(contin)
      calloutdon
      return
      end
      subroutineoutdon
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      outbuf(outp+1)=10
      outbuf(outp+2)=-2
      callputlin(outbuf,6)
      outp=0
      return
      end
      subroutineoutgo(n)
      bytegoto(6)
      datagoto/103,111,116,111,32,-2/
      callouttab
      calloutstr(goto)
      calloutnum(n)
      calloutdon
      return
      end
      subroutineoutnum(n)
      bytechars(10)
      len=itoc(n,chars,10)
      do 23249i=1,len
      calloutch(chars(i))
23249 continue
23250 continue
      return
      end
      subroutineoutstr(str)
      bytec,str(100)
      continue
      i=1
23251 if(.not.(str(i).ne.-2))goto 23253
      c=str(i)
      if(.not.(c.ne.39.and.c.ne.34))goto 23254
      calloutch(c)
      goto 23255
23254 continue
      i=i+1
      continue
      j=i
23256 if(.not.(str(j).ne.c))goto 23258
23257 j=j+1
      goto 23256
23258 continue
      calloutnum(j-i)
      calloutch(104)
      continue
23259 if(.not.(i.lt.j))goto 23261
      calloutch(str(i))
23260 i=i+1
      goto 23259
23261 continue
23255 continue
23252 i=i+1
      goto 23251
23253 continue
      return
      end
      subroutineouttab
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      continue
23262 if(.not.(outp.lt.6))goto 23263
      calloutch(32)
      goto 23262
23263 continue
      return
      end
      subroutineparse
      bytelexstr(200),lex,lextyp(100),token
      integerlabval(100),sp
      callinitkw
      sp=1
      lextyp(1)=-3
      continue
      token=lex(lexstr)
23264 if(.not.(token.ne.-3))goto 23266
      if(.not.(token.eq.-61))goto 23267
      callifcode(lab)
      goto 23268
23267 continue
      if(.not.(token.eq.-66))goto 23269
      calldocode(lab)
      goto 23270
23269 continue
      if(.not.(token.eq.-63))goto 23271
      callwhilec(lab)
      goto 23272
23271 continue
      if(.not.(token.eq.-68))goto 23273
      callforcod(lab)
      goto 23274
23273 continue
      if(.not.(token.eq.-69))goto 23275
      callrepcod(lab)
      goto 23276
23275 continue
      if(.not.(token.eq.-60))goto 23277
      calllabelc(lexstr)
      goto 23278
23277 continue
      if(.not.(token.eq.-62))goto 23279
      if(.not.(lextyp(sp).eq.-61))goto 23281
      callelseif(labval(sp))
      goto 23282
23281 continue
      callsynerr(13hillegal else.)
23282 continue
23279 continue
23278 continue
23276 continue
23274 continue
23272 continue
23270 continue
23268 continue
      if(.not.(token.eq.-61.or.token.eq.-62.or.token.eq.-63.or.token.eq.
     &-68.or.token.eq.-69.or.token.eq.-66.or.token.eq.-60.or.token.eq.12
     &3))goto 23283
      sp=sp+1
      if(.not.(sp.gt.100))goto 23285
      callerror(25hstack overflow in parser.)
23285 continue
      lextyp(sp)=token
      labval(sp)=lab
      goto 23284
23283 continue
      if(.not.(token.eq.125))goto 23287
      if(.not.(lextyp(sp).eq.123))goto 23289
      sp=sp-1
      goto 23290
23289 continue
      callsynerr(20hillegal right brace.)
23290 continue
      goto 23288
23287 continue
      if(.not.(token.eq.-67))goto 23291
      callotherc(lexstr)
      goto 23292
23291 continue
      if(.not.(token.eq.-64.or.token.eq.-65))goto 23293
      callbrknxt(sp,lextyp,labval,token)
23293 continue
23292 continue
23288 continue
      token=lex(lexstr)
      callpbstr(lexstr)
      callunstak(sp,lextyp,labval,token)
23284 continue
23265 token=lex(lexstr)
      goto 23264
23266 continue
      if(.not.(sp.ne.1))goto 23295
      callsynerr(15hunexpected eof.)
23295 continue
      return
      end
      subroutinepbstr(in)
      bytein(100)
      continue
      i=length(in)
23297 if(.not.(i.gt.0))goto 23299
      callputbak(in(i))
23298 i=i-1
      goto 23297
23299 continue
      return
      end
      subroutineputbak(c)
      bytec
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      bp=bp+1
      if(.not.(bp.gt.300))goto 23300
      callerror(32htoo many characters pushed back.)
23300 continue
      buf(bp)=c
      return
      end
      subroutineputch(c,f)
      bytebuf(81),c,c1,q1
      integerf
      datac1/1hC/,q1/1h?/
      datalastc/0/
      if(.not.(lastc.ge.81.or.c.eq.10))goto 23302
      if(.not.(lastc.gt.0))goto 23304
      write(f,1,err=5)(buf(i),i=1,lastc)
      goto4
5     write(3,1)c1,q1
4     continue
1     format(1x,80a1)
23304 continue
      lastc=0
23302 continue
      if(.not.(c.ne.10))goto 23306
      lastc=lastc+1
      c=c.and.127
      if(.not.(c.lt.27))goto 23308
      c=c+33
23308 continue
      buf(lastc)=c
23306 continue
      return
      end
      subroutineputlin(b,f)
      byteb(100)
      integerf
      continue
      i=1
23310 if(.not.(b(i).ne.-2))goto 23312
      callputch(b(i),f)
23311 i=i+1
      goto 23310
23312 continue
      return
      end
      subroutinerelate(token,last,fd)
      bytengetch,token(100),dotge(5),dotgt(5),dotle(5),dotne(5),dotnot(6
     &),doteq(5),dotand(6),dotor(5),dotlt(5)
      integerfd
      datadotge/46,103,101,46,-2/,dotgt/46,103,116,46,-2/,dotle/46,108,1
     &01,46,-2/,dotlt/46,108,116,46,-2/,dotne/46,110,101,46,-2/,doteq/46
     &,101,113,46,-2/,dotor/46,111,114,46,-2/,dotand/46,97,110,100,46,-2
     &/,dotnot/46,110,111,116,46,-2/
      if(.not.(ngetch(token(2),fd).ne.61))goto 23313
      callputbak(token(2))
23313 continue
      if(.not.(token(1).eq.62))goto 23315
      if(.not.(token(2).eq.61))goto 23317
      callscopy(dotge,1,token,1)
      goto 23318
23317 continue
      callscopy(dotgt,1,token,1)
23318 continue
      goto 23316
23315 continue
      if(.not.(token(1).eq.60))goto 23319
      if(.not.(token(2).eq.61))goto 23321
      callscopy(dotle,1,token,1)
      goto 23322
23321 continue
      callscopy(dotlt,1,token,1)
23322 continue
      goto 23320
23319 continue
      if(.not.(token(1).eq.33))goto 23323
      if(.not.(token(2).eq.61))goto 23325
      callscopy(dotne,1,token,1)
      goto 23326
23325 continue
      callscopy(dotnot,1,token,1)
23326 continue
      goto 23324
23323 continue
      if(.not.(token(1).eq.61))goto 23327
      if(.not.(token(2).eq.61))goto 23329
      callscopy(doteq,1,token,1)
      goto 23330
23329 continue
      token(2)=-2
23330 continue
      goto 23328
23327 continue
      if(.not.(token(1).eq.38))goto 23331
      callscopy(dotand,1,token,1)
      goto 23332
23331 continue
      if(.not.(token(1).eq.124))goto 23333
      callscopy(dotor,1,token,1)
      goto 23334
23333 continue
      token(2)=-2
23334 continue
23332 continue
23328 continue
23324 continue
23320 continue
23316 continue
      last=length(token)
      return
      end
      subroutineremark(buf)
      bytebuf(100),pct
      datapct/1h%/
      continue
      j=1
23335 if(.not.(j.lt.63.and.buf(j).ne.46))goto 23337
      buf(j)=buf(j).and.127
      if(.not.(buf(j).lt.27))goto 23338
      buf(j)=buf(j)+33
23338 continue
23336 j=j+1
      goto 23335
23337 continue
      write(3,10,err=5)(buf(i),i=1,j)
10    format(1x,63a1)
      return
5     write(3,10)pct
      return
      end
      subroutinerepcod(lab)
      calloutcon(0)
      lab=labgen(3)
      calloutcon(lab)
      lab=lab+1
      return
      end
      subroutinescopy(from,i,to,j)
      bytefrom(100),to(100)
      k2=j
      continue
      k1=i
23340 if(.not.(from(k1).ne.-2))goto 23342
      to(k2)=from(k1)
      k2=k2+1
23341 k1=k1+1
      goto 23340
23342 continue
      to(k2)=-2
      return
      end
      subroutinesynerr(msg)
      bytelc(81),msg(81)
      integerbp
      bytebuf
      integer*1fordep
      byteforstk
      bytesdo(3),sif(3),selse(5),swhile(6),sbreak(6),snext(5),sfor(4),sr
     &ept(7),suntil(6),vdo(2),vif(2),velse(2),vwhile(2),vbreak(2),vnext(
     &2),vfor(2),vrept(2),vuntil(2)
      integerlevel
      integerlinect
      integerinfile
      integerlastp
      integerlastt
      integernamptr
      bytetable
      integeroutp
      byteoutbuf
      common/cdefio/bp,buf(300)
      common/cfor/fordep,forstk(200)
      common/ckeywd/sdo,sif,selse,swhile,sbreak,snext,sfor,srept,suntil,
     &vdo,vif,velse,vwhile,vbreak,vnext,vfor,vrept,vuntil
      common/cline/level,linect(5),infile(5)
      common/clook/lastp,lastt,namptr(200),table(1500)
      common/coutln/outp,outbuf(81)
      callremark(14herror at line.)
      do 23343i=1,level
      callputch(32,3)
      junk=itoc(linect(i),lc,81)
      callputlin(lc,3)
23343 continue
23344 continue
      callputch(58,3)
      callputch(10,3)
      callremark(msg)
      return
      end
      bytefunctiontype(c)
      bytec
      if(.not.(c.ge.48.and.c.le.57))goto 23345
      type=2
      goto 23346
23345 continue
      if(.not.((c.ge.97.and.c.le.122).or.(c.ge.65.and.c.le.90)))goto 233
     &47
      type=1
      goto 23348
23347 continue
      type=c
23348 continue
23346 continue
      return
      end
      subroutineunstak(sp,lextyp,labval,token)
      integerlabval(100),sp
      bytelextyp(100),token
      continue
23349 if(.not.(sp.gt.1))goto 23351
      if(.not.(lextyp(sp).eq.123.or.(lextyp(sp).eq.-61.and.token.eq.-62)
     &))goto 23352
      goto 23351
23352 continue
      if(.not.(lextyp(sp).eq.-61))goto 23354
      calloutcon(labval(sp))
      goto 23355
23354 continue
      if(.not.(lextyp(sp).eq.-62))goto 23356
      if(.not.(sp.gt.2))goto 23358
      sp=sp-1
23358 continue
      calloutcon(labval(sp)+1)
      goto 23357
23356 continue
      if(.not.(lextyp(sp).eq.-66))goto 23360
      calldostat(labval(sp))
      goto 23361
23360 continue
      if(.not.(lextyp(sp).eq.-63))goto 23362
      callwhiles(labval(sp))
      goto 23363
23362 continue
      if(.not.(lextyp(sp).eq.-68))goto 23364
      callfors(labval(sp))
      goto 23365
23364 continue
      if(.not.(lextyp(sp).eq.-69))goto 23366
      calluntils(labval(sp),token)
23366 continue
23365 continue
23363 continue
23361 continue
23357 continue
23355 continue
23350 sp=sp-1
      goto 23349
23351 continue
      return
      end
      subroutineuntils(lab,token)
      byteptoken(200),token,junk,lex
      calloutnum(lab)
      if(.not.(token.eq.-70))goto 23368
      junk=lex(ptoken)
      callifgo(lab-1)
      goto 23369
23368 continue
      calloutgo(lab-1)
23369 continue
      calloutcon(lab+1)
      return
      end
      subroutinewhilec(lab)
      calloutcon(0)
      lab=labgen(2)
      calloutnum(lab)
      callifgo(lab+1)
      return
      end
      subroutinewhiles(lab)
      calloutgo(lab)
      calloutcon(lab+1)
      return
      endî