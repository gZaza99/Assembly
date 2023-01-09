.MODEL SMALL
	Space EQU " "					;Sz�k�z karakter
	CR    EQU 13
	LF    EQU 10

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

	LEA  BX, disc_text
	CALL write_string
	CALL read_decimal
	MOV  disc, DL

	;MOV  DL, disc
	;CALL write_decimal
	;CALL cr_lf

	LEA  BX, sector_text
	CALL write_string
	CALL read_decimal
	MOV  sector, DL

	;MOV  DL, sector
	;CALL write_decimal
	;CALL cr_lf

	LEA  BX, block					;DS:BX mem�riac�mre t�lti a blokkot
	MOV  AL, disc					;Lemezmeghajt� sz�ma (A:0, B:1, C:2, stb.)
	MOV  CX, 1						;Egyszerre beolvasott blokkok sz�ma
	XOR  DX, DX
	MOV  DL, sector					;Lemezolvas�s kezd�blokkja
	INT  25h						;Olvas�s
	POPF							;A veremben t�rolt jelz�bitek t�rl�se
	XOR  DX, DX						;Ki�rand� adatok kezd�c�me DS:DX
	CALL write_block				;Egy blokk ki�r�sa

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

write_string proc					;BX-ben c�mzett karaktersorozat ki�r�sa 0 k�dig.
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
write_string endp

read_decimal proc
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
read_decimal endp

write_hexa proc						;A DL-ben l�v� k�t hexa sz�mjegy ki�r�sa
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
write_hexa endp

write_decimal proc
	PUSH AX							;AX ment�se a verembe
	PUSH CX							;CX ment�se a verembe
	PUSH DX							;DX ment�se a verembe
	PUSH SI							;SI ment�se a verembe
	XOR  DH, DH						;DH t�rl�se
	MOV  AX, DX						;AX-be a sz�m
	MOV  SI, 10						;SI-be az oszt�
	XOR  CX, CX						;CX-be ker�l az oszt�sok sz�ma
decimal_non_zero:
	XOR  DX, DX						;DX t�rl�se
	DIV  SI							;DX:AX 32 bites sz�m oszt�sa SI-vel, az eredm�ny AX-be, a marad�k DX-be ker�l
	PUSH DX							;DX ment�se a verembe
	INC  CX							;Sz�ml�l� n�vel�se
	OR   AX, AX						;St�tuszbitek be�ll�t�sa AX-nek megfelel�en
	JNE  decimal_non_zero			;Vissza, ha az eredm�ny m�g nem nulla
decimal_loop:
	POP  DX							;Az elmentett marad�k visszah�v�sa
	CALL write_hexa_digit			;Egy decim�lis digit ki�r�sa
	LOOP decimal_loop
	POP  SI							;SI vissza�ll�t�sa
	POP  DX							;DX vissza�ll�t�sa
	POP  CX							;CX vissza�ll�t�sa
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
write_decimal endp

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
	MOV  DH, 49						;50 soros k�perny� als� sora (25 sorosn�l ide 24 kell)
	MOV  DL, 79						;Jobb oldali oszlop sorsz�ma
	MOV  BH, 7						;T�r�lt helyek attrib�tuma: fekete h�tt�r sz�rke karakter
	MOV  AH, 6						;Sorg�rget�s felfel� (Scroll-up) funkci�
	INT  10h						;K�perny� t�rl�se
	RET
clear_screen ENDP

read_char proc						;Karakter beolvas�sa. A beolvasott karakter DL-be ker�l
	PUSH AX							;AX ment�se a verembe
	MOV  AH, 1						;AH-ba a beolvas�s funkci�k�d
	INT  21h						;Egy karakter beolvas�sa, a k�d AL-be ker�l
	MOV  DL, AL						;DL-be a karakter k�dja
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
read_char endp

write_char proc						;A DL-ben l�v� karakter ki�r�sa a k�perny�re
	PUSH AX							;AX ment�se a verembe
	MOV  AH, 2						; AH-ba a k�perny�re �r�s funkci�k�dja
	INT  21h						; Karakter ki�r�sa
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
write_char endp

END main