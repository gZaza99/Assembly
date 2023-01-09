.MODEL SMALL
	Space EQU " "					;Sz�k�z karakter
.STACK
.DATA
.DATA?
	block DB 512 DUP (?)			;1 blokknyi ter�let kijel�l�se
	
.CODE

main PROC
	MOV  AX, Dgroup					;DS be�ll�t�sa
	MOV  DS, AX
	LEA  BX, block					;DS:BX mem�riac�mre t�lti a blokkot
	MOV  AL, 0						;Lemezmeghajt� sz�ma (A:0, B:1, C:2, stb.)
	MOV  CX, 1						;Egyszerre beolvasott blokkok sz�ma
	MOV  DX, 0						;Lemezolvas�s kezd�blokkja
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
	MOV  CX, 32						;Ki�rand� sorok sz�ma CX-be
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
	MOV  DL, 13
	CALL write_char					;kurzor a sor elej�re
	MOV  DL, 10
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

write_char proc						;A DL-ben l�v� karakter ki�r�sa a k�perny�re
	PUSH AX							;AX ment�se a verembe
	MOV  AH, 2						; AH-ba a k�perny�re �r�s funkci�k�dja
	INT  21h						; Karakter ki�r�sa
	POP  AX							;AX vissza�ll�t�sa
	RET								;Visszat�r�s a h�v� rutinba
write_char endp

END main