	REAL A(3)
	DATA A/'AWRU','FVBY','TGKM'/
	I=INDEX(A,'UFVB',4,12)
	WRITE(3,10)I
10	FORMAT(1X,'Index =',I4)
	I=INDEX('Abfrg','rg',2,5)
	WRITE(3,10)I
	I=INDEX('SXCt','x',1,4)
	WRITE(3,10)I
	I=INDEX('Helpme','Helpme',6,6)
	WRITE(3,10)I
	STOP
	END
