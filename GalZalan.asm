.MODEL SMALL, C						;Param�ter vermen kereszt�li �tad�s�hoz kell a h�v�skonvenci�
	Space         EQU " "			;Sz�k�z karakter
	CR            EQU 13			;CR-be a kurzor a sor elej�re k�d
	LF            EQU 10			;LF-be a kurzor �j sorba k�d
	attr_text     EQU 00000111b		;Standard fekete alapon halv�ny feh�r sz�n
	attr_border   EQU 01110000b		;Feh�r alapon fekete sz�n
	Screen_width  EQU 80			;K�perny� sz�less�ge
	Screen_height EQU 25			;K�perny� magass�ga

.STACK
.DATA
	disc_text   DB "Number of disc: ",0
	sector_text DB "Number of sector: ",0

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

	MOV  AL, Screen_height			;Y = 25 - 1
	DEC  AL
	MOV  AH, 60						;X = 60
	PUSH AX							;XY = [ 10 | 1 ]
	MOV  AL, "P"					;Karakter: "P"
	MOV  AH, attr_text				;Attrib�tum: Standard megjelen�t�s
	PUSH AX
	CALL draw_char					;Ki�r�s

	;LEA  BX, disc_text
	;CALL write_string
	;CALL read_decimal
	;MOV  disc, DL

	;LEA  BX, sector_text
	;CALL write_string
	;CALL read_decimal
	;MOV  sector, DL

	;CALL clear_screen

	;LEA  BX, block					;DS:BX mem�riac�mre t�lti a blokkot
	;MOV  AL, disc					;Lemezmeghajt� sz�ma (A:0, B:1, C:2, stb.)
	;MOV  CX, 1						;Egyszerre beolvasott blokkok sz�ma
	;XOR  DX, DX
	;MOV  DL, sector					;Lemezolvas�s kezd�blokkja
	;INT  25h						;Olvas�s
	;POPF							;A veremben t�rolt jelz�bitek t�rl�se
	;XOR  DX, DX						;Ki�rand� adatok kezd�c�me DS:DX
	;CALL write_block				;Egy blokk ki�r�sa

	MOV  AH, 4Ch					;AH-ba a visszat�r�s funkci�k�dja
	INT  21h						;Visszat�r�s az oper�ci�s rendszerbe
main ENDP

write_block PROC
	PUSH CX							;CX ment�se
	PUSH DX							;DX ment�se
	MOV  CX, 16						;Ki�rand� sorok sz�ma CX-be (ideiglenesen cs�kkentve)
write_block_new:
	CALL out_line					;Egy sor ki�r�sa
	CALL cr_lf						;Soremel�s
	ADD  DX, 16						;K�vetkez� sor adatainak kezd�c�me;
	LOOP write_block_new			;�j sor
	POP  DX							;DX vissza�ll�t�sa
	POP  CX							;CX vissza�ll�t�sa
	RET
write_block ENDP

out_line PROC
	PUSH BX							;BX ment�se
	PUSH CX							;CX ment�se
	PUSH DX							;DX ment�se
	MOV  BX,DX						;Sor adatainak kezd�c�me BX-be
	PUSH BX							;Ment�s a karakteres ki�r�shoz
	MOV  CX, 16						;Egy sorban 16 hexadecim�lis karakter
out_line_hexa_out:
	MOV  DL, Block[BX]				;Egy b�jt bet�lt�se
	CALL write_hexa					;Ki�r�s hexadecim�lis form�ban
	MOV  DL, Space					;Sz�k�z ki�r�sa a hexa k�dok k�z�tt
	CALL write_char
	INC  BX							;K�vetkez� adatb�jt c�me
	LOOP out_line_hexa_out			;K�vetkez� b�jt
	MOV  DL, Space					;Sz�k�z ki�r�sa a k�tf�le m�d k�z�tt
	CALL write_char
	MOV  CX, 16						;Egy sorban 16 karakter
	POP  BX							;Adatok kezd�c�m�nek be�ll�t�sa
out_line_ascii_out:
	MOV  DL, Block[BX]				;Egy b�jt bet�lt�se
	CMP  DL, Space					;Vez�rl�karakterek kisz�r�se
	JA   out_line_visible			;Ugr�s, ha l�that� karakter
	MOV  DL, Space					;Nem l�that� karakterek cser�je sz�k�zre
out_line_visible:
	CALL write_char					;Karakter ki�r�sa
	INC  BX							;K�vetkez� adatb�jt c�me
	LOOP out_line_ascii_out			;K�vetkez� b�jt
	POP  DX							;DX vissza�ll�t�sa
	POP  CX							;CX vissza�ll�t�sa
	POP  BX							;BX vissza�ll�t�sa
	RET								;Vissza a h�v� programba
out_line ENDP

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
	MOV  BL, 10						;BX-be a sz�mrendszer alapsz�ma, ezzel szorzunk
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
	POP  BX							;AB vissza�ll�t�sa
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
read_decimal ENDP

write_hexa PROC						;A DL-ben l�v� k�t hexa sz�mjegy ki�r�sa
	PUSH CX							;CX ment�se a verembe
	PUSH DX							;DX ment�se a verembe
	MOV  DH, DL						;DL ment�se
	MOV  CL, 4						;Shift-el�s sz�ma CX-be
	SHR  DL, CL						;DL shift-el�se 4 hellyel jobbra
	CALL write_hexa_digit			;Hexadecim�lis digit ki�r�sa
	MOV  DL, DH						;Az eredeti �rt�k visszat�lt�se DL-be
	AND  DL, 0Fh					;A fels� n�gy bit t�rl�se
	CALL write_hexa_digit			;Hexadecim�lis digit ki�r�sa
	POP  DX							;DX vissza�ll�t�sa
	POP  CX							;CX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
write_hexa ENDP

write_hexa_digit PROC
	PUSH DX							;DX ment�se a verembe
	CMP  DL, 10						;DL �sszehasonl�t�sa 10-zel
	JB   non_hexa_letter			;Ugr�s, ha kisebb 10-n�l
	ADD  DL, "A"-"0"-10				;A � F bet�t kell ki�rni
non_hexa_letter:
	ADD  DL, "0"					;Az ASCII k�d megad�sa
	CALL write_char					;A karakter ki�r�sa
	POP  DX							;DX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
write_hexa_digit ENDP

cr_lf PROC
	PUSH DX							;DX ment�se a verembe
	MOV  DL, CR
	CALL write_char					;kurzor a sor elej�re
	MOV  DL, LF
	CALL write_char					;Kurzor egy sorral lejjebb
	POP  DX							;DX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
cr_lf ENDP

clear_screen PROC
	XOR  AL, AL						;Ablak t�rl�se
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
draw_char PROC USES AX BX DX, MemoryItem: WORD, XY: WORD			;XY = [ X:BYTE | Y:BYTE ]
	MOV  DX, XY
	MOV  AL, DL						;AL -be az Y param�ter a veremb�l
	DEC  AL							;Y-1 a null�t�l indexel�s miatt
	MOV  BL, Screen_width			;BL -be a k�perny� sz�less�ge (oszlopok sz�ma)
	MUL  BL							;AX -be a k�v�nt magass�g
	XOR  BX, BX						;BX kinull�z�sa a fels� 8 bit miatt
	MOV  BL, DH						;BL -be az X param�ter a veremb�l
	ADD  AX, BX						;AX -be a k�v�nt offset karaktter poz�ci�
	SHL  AX, 1						;AX -be a k�v�nt offset mem�ria c�m
	
	MOV  BX, AX						;BX -be a k�v�nt offset mem�ria c�m, mert csak b�zis, vagy index regiszter elfogadott
	MOV  AX, MemoryItem				;AX -be a kirajzolni k�v�nt karakter

	MOV  ES:[BX], AX				;Karakter kirajzol�sa
	RET
draw_char ENDP

write_char PROC						;A DL-ben l�v� karakter ki�r�sa a k�perny�re
	PUSH AX							;AX ment�se a verembe
	MOV  AH, 2						; AH-ba a k�perny�re �r�s funkci�k�dja
	INT  21h						; Karakter ki�r�sa
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
write_char ENDP

END main