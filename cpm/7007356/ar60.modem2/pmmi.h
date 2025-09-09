
/* PMMI modem definitions */
#define	STATPORT	0xc0	/*uart status port*/
#define	DATAPORT	0xc1	/*modem data port*/
#define	MODEMCP2	0xc2	/*modem status port*/
#define	MODEMCP3	0xc3	/*modem control port*/
#define	TBMT		0x01	/*transmit buffer empty*/
#define	DAV		0x02	/*receive data available*/
#define	CTS		0x04	/*carrier detect*/
#define	ORIG		0x01	/*originate mode select*/
#define	ANS		0x02	/*answer mode select*/
#define	NP		0x10	/*no parity select*/
#define	EPS		0x20	/*even parity select*/
#define	TSB		0x40	/*number stop bits select*/
#define	NB1		0x04	/*number data bits select #1*/
#define	NB2		0x08	/*number data bits select #2*/
#define	BR110		0x8e	/*110 baud select byte*/
#define	BR300		0x32	/*300 baud select byte*/
#define	BR450		0x23	/*450 baud select byte*/
#define BR600		0x1a	/*600 baud select byte*/
#define	UND300		0x7f	/*filter select < 300 baud*/
#define	OVR300		0x5f	/*filter select > 300 baud*/
#define	MAHI		0x01	/*1 if status active high*/
#define	CTSHI		0x00	/*1 if cts active high*/
