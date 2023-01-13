.MODEL SMALL
	Space         EQU " "			;Sz�k�z karakter
	CR            EQU 13			;CR-be a kurzor a sor elej�re k�d
	LF            EQU 10			;LF-be a kurzor �j sorba k�d
	attr_text     EQU 00000111b		;Standard fekete alapon halv�ny feh�r sz�n
	attr_border   EQU 00011111b		;K�k alapon vil�gos feh�r sz�n
	Screen_width  EQU 80			;K�perny� sz�less�ge
	Screen_height EQU 25			;K�perny� magass�ga
	BorderHor     EQU "-"			;Horizont�lis szeg�ly
	BorderVer     EQU "|"			;Vertik�lis szeg�ly
	BorderCor     EQU "+"			;Sarok szeg�ly

.STACK
.DATA
	disc_text   DB "Number of disc: ",0
	sector_text DB "Number of sector: ",0
	lines       WORD 20				;Ki�rand� adatsorok darabsz�ma
	DataInLine  WORD 18				;Adatok 1 adatsoban

.DATA?
	block  DB 512 DUP (?)			;1 blokknyi ter�let kijel�l�se
	disc   DB 1   DUP (?)			;1 byte ter�let lefoglal�sa a lemezmeghajt� sz�m�nak
	sector DB 1   DUP (?)			;1 byte ter�let lefoglal�sa a kiolvasand� szektor sz�m�nak
	
.CODE

main PROC
	MOV  AX, Dgroup					;DS be�ll�t�sa
	MOV  DS, AX

	MOV  AX, 0B800h					;K�perny�-mem�ria szegmensc�me ES-be
	MOV  ES, AX

	LEA  BX, disc_text
	CALL write_string
	CALL read_decimal
	MOV  disc, DL

	LEA  BX, sector_text
	CALL write_string
	CALL read_decimal
	MOV  sector, DL

	CALL clear_screen

	LEA  BX, block					;DS:BX mem�riac�mre t�lti a blokkot
	MOV  AL, disc					;Lemezmeghajt� sz�ma (A:0, B:1, C:2, stb.)
	MOV  CX, 1						;Egyszerre beolvasott blokkok sz�ma
	XOR  DX, DX
	MOV  DL, sector					;Lemezolvas�s kezd�blokkja
	INT  25h						;Olvas�s
	POPF							;A veremben t�rolt jelz�bitek t�rl�se
	XOR  DX, DX						;Ki�rand� adatok kezd�c�me DS:DX
	CALL write_block				;Egy blokk ki�r�sa

	CALL draw_border				;Szeg�ly kirajzol�sa

	MOV  AH, 4Ch					;AH-ba a visszat�r�s funkci�k�dja
	INT  21h						;Visszat�r�s az oper�ci�s rendszerbe
main ENDP

write_block PROC
	PUSH BX							;BX ment�se
	PUSH CX							;CX ment�se
	PUSH DX							;DX ment�se
	MOV  BX, 0000001000000100b		;BX -be a k�perny� els� sor -�s oszlopindexe [ Oszlop=2 | Sor=4 ]
	MOV  CX, lines					;Ki�rand� sorok sz�ma CX-be
write_block_new:
	CALL out_line					;Egy sor ki�r�sa
	ADD  DX, DataInLine				;K�vetkez� sor adatainak kezd�c�me
	INC  BL							;K�vetkez� sor indexe
	LOOP write_block_new			;�j sor
	POP  DX							;DX vissza�ll�t�sa
	POP  CX							;CX vissza�ll�t�sa
	POP  BX							;BX vissza�ll�t�sa
	RET
write_block ENDP

out_line PROC
	PUSH BP							;BP ment�se
	PUSH AX							;AX ment�se
	PUSH BX							;BX ment�se
	PUSH CX							;CX ment�se
	PUSH DX							;DX ment�se
	MOV  BP,DX						;Sor adatainak kezd�c�me BP-be
	PUSH BP							;Ment�s a karakteres ki�r�shoz

	MOV  CX, DataInLine				;Egy sorban DataInLine darab hexadecim�lis karakter
out_line_hexa_out:

	MOV  DL, Block[BP]				;Egy b�jt bet�lt�se
	CALL cvt2hexa					;Hexadecim�lis form�tumm� alak�t�s azaz =>  AX = cvt2hexa( DL )

	INC  BH							;	X := K�vetkez� oszlop
	MOV  DL, AH						;	DL -be az 1. hexa karakter
	MOV  DH, attr_text				;	Standard st�lus� karakter
	CALL draw_char					;1. hexa karakter kirajzol�sa

	INC  BH							;	X := K�vetkez� oszlop
	MOV  DL, AL						;	DL -be a 2. hexa karakter
	MOV  DH, attr_text				;	Standard st�lus� karakter
	CALL draw_char					;2. hexa karakter kirajzol�sa

	INC  BH							;�res hely kihagy�sa a hexa k�dok k�z�tt
	INC  BP							;K�vetkez� adatb�jt c�me
	LOOP out_line_hexa_out			;K�vetkez� b�jt
	INC  BH							;�res hely kihagy�sa a k�tf�le m�d k�z�tt
	MOV  CX, DataInLine				;Egy sorban DataInLine darab karakter
	POP  BP							;Adatok kezd�c�m�nek be�ll�t�sa
out_line_ascii_out:
	INC  BH							;X := K�vetkez� oszlop
	MOV  DL, Block[BP]				;Egy b�jt bet�lt�se
	CMP  DL, Space					;Vez�rl�karakterek kisz�r�se
	JBE  out_line_invisible			;Ugr�s, ha NEM l�that� karakter

	MOV  DH, attr_text				;Standard st�lus� karakter
	CALL draw_char					;Karakter kirajzol�sa

out_line_invisible:
	INC  BP							;K�vetkez� adatb�jt c�me
	LOOP out_line_ascii_out			;K�vetkez� b�jt
	POP  DX							;DX vissza�ll�t�sa
	POP  CX							;CX vissza�ll�t�sa
	POP  BX							;BX vissza�ll�t�sa
	POP  AX							;AX vissza�ll�t�sa
	POP  BP							;BP vissza�ll�t�sa
	RET								;Vissza a h�v� programba
out_line ENDP

;DataInLine darab 2 jegy� hexa sz�m, k�z�tt�k t�rk�z, DataInLine darab karakter, 1db elv�laszt� t�rk�z
;1 + DataInLine * 2 + DataInLine + 1 + DataInLine + 1 = 4 DataInLine + 3
draw_border PROC USES AX BX CX DX SI
	MOV  BX, DataInLine				;BX -be az 1 sorban megjelen�tett adat mennyis�ge
	MOV  CL, 2						;CL -be a shiftel�s l�p�ssz�ma (CSAK a sz�ml�l�regiszterben elfogadott)
	SHL  BX, CL						;Shiftel�s 2 -vel (4 -gyel val� szorz�s)
	MOV  CX, BX						;CX -be a shiftel�s eredm�nye (a LOOP miatt ide kell)
	ADD  CX, 3						;+3
	MOV  DL, BorderHor				;DL -be a horizont�lis szeg�ly karakter
	MOV  DH, attr_border			;DH -ba a karakter st�lus
	PUSH CX							;CX ment�se. K�s�bb m�g kelleni fog egy m�sik regiszterben

	MOV  BX, 0000001000000010b		;BX = [ BH | BL ] = [ X=2 | Y=2 ]
	;(X=1 -n�l sarok van. Y=1 nem l�tszik a programv�gi 1 soros leg�rget�s miatt)
	CALL draw_horizontal_border		;Fels� szeg�ly kirajzol�sa

	MOV  AX, lines					;AX -be a ki�rt adatsorok darabsz�ma
	ADD  AL, 5						;egy-egy t�r�z alul, fel�l, �s egy a programv�gi g�rget�s miatt
	MOV  BL, AL						;Y := AL
	MOV  BH, 2						;X := 2 (X=1 -n�l sarok van)
	CALL draw_horizontal_border		;Als� szeg�ly kirajzol�sa

	MOV  CX, lines					;CX -be a ki�rt adatsorok darabsz�ma
	ADD  CX, 2						;1 karakternyi t�rk�z a szeg�lyt�l alul �s fel�l (+2)
	MOV  DL, BorderVer				;DL -be a vertik�lis szeg�ly karakter

	MOV  BX, 0000000100000011b		;BX = [ BH | BL ] = [ X=1 | Y=3 ] (X=1, Y=2 -n�l sarok van)
	CALL draw_vertical_border		;Bal oldali szeg�ly kirajzol�sa
	
	POP  AX							;Kor�bban CX -b�l mentett adat vissza�ll�t�sa AX -be
	PUSH AX							;Veremmutat� vissza a hely�re
	MOV  BH, AL						;BH -ba a horizont�lis szeg�ly hossza
	ADD  BH, 2						;BH -ba a vertik�lis szeg�ly kezd� X poz�ci�ja
	MOV  BL, 3						;Y := 3 (X=1, Y=2 -n�l sarok van)
	CALL draw_vertical_border		;Jobb oldali szeg�ly kirajzol�sa

	MOV  DL, BorderCor				;DL -be a sarok szeg�ly karakter
	MOV  BX, 0000000100000010b		;BX = [ BH | BL ] = [ X=1 | Y=2 ] (Bal fels� sarok)
	CALL draw_char

	POP  AX							;Kor�bban CX -b�l mentett adat vissza�ll�t�sa AX -be
	MOV  BH, AL						;BH -ba a horizont�lis szeg�ly hossza
	ADD  BH, 2						;BH -ba a jobb oldali szeg�ly X poz�ci�ja
	CALL draw_char					;Jobb fels� sarok

	MOV  AX, lines					;CX -be a ki�rt adatsorok darabsz�ma
	;2 karakter alul �s fel�l a t�rk�z �s a szeg�ly. Az 4. A K�VETKEZ�be kell rajzolni (+5)
	ADD  AX, 5
	MOV  BL, AL						;BL -be az als� szeg�ly Y poz�ci�ja
	CALL draw_char					;Jobb als� sarok

	MOV  BH, 1						;X := 1
	CALL draw_char					;Bal als� sarok
	RET
draw_border ENDP

;M�dos�tja BX -et.
draw_vertical_border PROC USES CX	;BX -et, �s DX -et tov�bbadja draw_char -nak
draw_vertical_border_start:
	CALL draw_char					;Karakterek kirajzol�sa
	INC  BL							;K�vetkez� poz�ci� (X := X+1)
	LOOP draw_vertical_border_start
	RET
draw_vertical_border ENDP

;M�dos�tja BX -et.
draw_horizontal_border PROC USES CX	;BX -et, �s DX -et tov�bbadja draw_char -nak
draw_horizontal_border_start:
	CALL draw_char					;Karakterek kirajzol�sa
	INC  BH							;K�vetkez� poz�ci� (Y := Y+1)
	LOOP draw_horizontal_border_start
	RET
draw_horizontal_border ENDP

write_string PROC					;BX-ben c�mzett karaktersorozat ki�r�sa 0 k�dig.
	PUSH DX							;DX ment�se a verembe
	PUSH BX							;BX ment�se a verembe
write_string_new:
	MOV  DL, [BX]					;DL-be egy karakter bet�lt�se
	OR   DL, DL						;DL vizsg�lata
	JZ   write_string_end			;0 eset�n kil�p�s
	CALL write_char					;Karakter ki�r�sa
	INC  BX							;BX a k�vetkez� karakterre mutat
	JMP  write_string_new			;A k�vetkez� karakter bet�lt�se
write_string_end:
	POP  BX							;BX vissza�ll�t�sa
	POP  DX							;DX vissza�ll�t�sa
	RET								;Visszat�r�s
write_string ENDP

read_decimal PROC
	PUSH AX							;AX ment�se a verembe
	PUSH BX							;BX ment�se a verembe
	MOV  BL, 10						;BL-be a sz�mrendszer alapsz�ma, ezzel szorzunk
	XOR  AX, AX						;AX t�rl�se
read_decimal_new:
	CALL read_char					;Egy karakter beolvas�sa
	CMP  DL, CR						;ENTER ellen�rz�se
	JE   read_decimal_end			;V�ge, ha ENTER volt az utols� karakter
	SUB  DL, "0"					;Karakterk�d minusz �0� k�dja
	MUL  BL							;AX szorz�sa 10-zel
	ADD  AL, DL						;A k�vetkez� helyi �rt�k hozz�ad�sa
	JMP  read_decimal_new			;A k�vetkez� karakter beolvas�sa
read_decimal_end:
	MOV  DL, AL						;DL-be a be�rt sz�m
	POP  BX							;BX vissza�ll�t�sa
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
read_decimal ENDP

;cvt = convert
cvt2hexa PROC						;write_hexa alprogram kicsit �talak�tva
	PUSH CX							;CX ment�se a verembe
	PUSH DX							;DX ment�se a verembe
	MOV  DH, DL						;DL ment�se
	MOV  CL, 4						;Shift-el�s sz�ma CX-be
	SHR  DL, CL						;DL shift-el�se 4 hellyel jobbra
	CALL get_hexa_digit				;AL = get_hexa_digit( DL )
	MOV  AH, AL						;AH -ba az els� hexa karakter
	MOV  DL, DH						;Az eredeti �rt�k visszat�lt�se DL-be
	AND  DL, 0Fh					;A fels� n�gy bit t�rl�se
	CALL get_hexa_digit				;AL = get_hexa_digit( DL )
	POP  DX							;DX vissza�ll�t�sa
	POP  CX							;CX vissza�ll�t�sa
	RET								;AX -szel visszat�r�s a h�v� rutinba
cvt2hexa ENDP

get_hexa_digit PROC USES DX			;#TODO: Visszaad egy hexa karaktert
	CMP  DL, 10						;DL �sszehasonl�t�sa 10-zel
	JB   get_hexa_digit_end			;Ugr�s, ha kisebb 10-n�l
	ADD  DL, "A"-"0"-10				;A � F bet�t kell menteni
get_hexa_digit_end:
	ADD  DL, "0"					;Az ASCII k�d megad�sa
	MOV  AL, DL						;A karakter ki�r�sa
	RET								;AL -lel Visszat�r�s a h�v� rutinba
get_hexa_digit ENDP

clear_screen PROC
	XOR  AL, AL						;AL t�rl�se
	XOR  CX, CX						;Bal fels� sarok (CL = 0, CH = 0)
	MOV  DH, Screen_height			;50 soros k�perny� als� sora (25 sorosn�l ide 24) kell
	DEC  DH							;K�perny� magass�ga -1
	MOV  DL, Screen_width			;Jobb oldali oszlop sorsz�ma kell
	DEC  DL							;K�perny� sz�less�ge -1
	MOV  BH, 7						;T�r�lt helyek attrib�tuma: fekete h�tt�r sz�rke karakter
	MOV  AH, 6						;Sorg�rget�s felfel� (Scroll-up) funkci�
	INT  10h						;K�perny� t�rl�se
	RET
clear_screen ENDP

read_char PROC						;Karakter beolvas�sa. A beolvasott karakter DL-be ker�l
	PUSH AX							;AX ment�se a verembe
	MOV  AH, 1						;AH-ba a beolvas�s funkci�k�d
	INT  21h						;Egy karakter beolvas�sa, a k�d AL-be ker�l
	MOV  DL, AL						;DL-be a karakter k�dja
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
read_char ENDP

;2 * ( (y-1) * <sorhossz=80> + x )
draw_char PROC USES AX CX DI		;BX = [ X:BYTE | Y:BYTE ] DX = Ki�rand� karakter attrib�tummal
	MOV  AL, BL						;AL -be az Y param�ter a veremb�l
	DEC  AL							;Y-1 a null�t�l indexel�s miatt
	MOV  CL, Screen_width			;CL -be a k�perny� sz�less�ge (oszlopok sz�ma)
	MUL  CL							;AX -be a k�v�nt magass�g
	XOR  CX, CX						;CX kinull�z�sa a fels� 8 bit miatt
	MOV  CL, BH						;CL -be az X param�ter a veremb�l
	ADD  AX, CX						;AX -be a k�v�nt offset karaktter poz�ci�
	SHL  AX, 1						;AX -be a k�v�nt offset mem�ria c�m
	
	MOV  DI, AX						;DI -be a k�v�nt offset mem�ria c�m, mert csak b�zis, vagy index regiszter elfogadott
	MOV  AX, DX						;AX -be a kirajzolni k�v�nt karakter

	MOV  ES:[DI], AX				;Karakter kirajzol�sa
	RET
draw_char ENDP

write_char PROC						;A DL-ben l�v� karakter ki�r�sa a k�perny�re
	PUSH AX							;AX ment�se a verembe
	MOV  AH, 2						;AH-ba a k�perny�re �r�s funkci�k�dja
	INT  21h						;Karakter ki�r�sa
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
write_char ENDP

END main