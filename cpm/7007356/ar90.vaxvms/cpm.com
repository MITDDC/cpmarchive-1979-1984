
$!	cpm.com
$!		defines commands useful for CP/M transfers
$!
$ x*modem:==$ulib:[cpm]xmodem.exe
$ toxmod:==$ulib:[cpm]toxmod.exe
$ fromxmod:==$ulib:[cpm]fromxmod.exe
$ modem7:==$sys$system:modem7.exe
