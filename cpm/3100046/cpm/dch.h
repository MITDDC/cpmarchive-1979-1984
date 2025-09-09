#define      DCHDP  128        /*D. C. HAYES DATA PORT*/
#define      DCHMASK  255      /*D. C. HAYES DATA MASK*/

#define      DCHSP  129        /*D. C. HAYES STATUS PORT*/
/*STATUS PORT BIT ASSIGNMENTS*/
#define      RRF         1   /*RECEIVE REGISTER FULL*/
#define      TRE         2   /*TRANSMIT REGISTER EMPTY*/
#define      PERR        4   /*PARITY ERROR*/
#define      FERR        8   /*FRAMING ERROR*/
#define      OERR        16  /*OVERFLOW ERROR*/
#define      CD          64  /*CARRIER DETECT*/
#define      NRI         128 /*NO RINGING INDICATOR*/

#define      DCHCP1      129 /*D. C. HAYES CONTROL PORT 1*/
/*CONTROL PORT 1 BIT ASSIGNMENTS*/
#define      EPE         1   /*EVEN PARITY ENABLE*/
#define      LS1         2   /*LENGTH SELECT 1*/
#define      LS2         4   /*LENGTH SELECT 2*/
#define      SBS         8   /*STOP BIT SELECT*/
#define      PI          16  /*PARITY INHIBIT*/

#define      DCHCP2  130       /*D. C. HAYES CONTROL PORT 2*/
/*CONTROL PORT 2 BIT ASSIGNMENTS*/
#define      BRS         1   /*BIT RATE SELECT*/
#define      TXE         2   /*TRANSMIT ENABLE*/
#define      MS          4   /*MODE SELECT*/
#define      ES          8   /*ECHO SUPPRESS*/
#define      ST          16  /*SELF TEST*/
#define      RID         32  /*RING INDICATOR DISABLE*/
#define      OH          128 /*OFF HOOK*/
