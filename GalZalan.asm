.MODEL SMALL
	Space EQU " "					;Szóköz karakter
.STACK
.DATA
.DATA?
	block DB 512 DUP (?)			;1 blokknyi terület kijelölése
	
.CODE

main PROC
	MOV  AX, Dgroup					;DS beállítása
	MOV  DS, AX
	LEA  BX, block					;DS:BX memóriacímre tölti a blokkot
	MOV  AL, 0						;Lemezmeghajtó száma (A:0, B:1, C:2, stb.)
	MOV  CX, 1						;Egyszerre beolvasott blokkok száma
	MOV  DX, 0						;Lemezolvasás kezdõblokkja
	INT  25h						;Olvasás
	POPF							;A veremben tárolt jelzõbitek törlése
	XOR  DX, DX						;Kiírandó adatok kezdõcíme DS:DX
	CALL write_block				;Egy blokk kiírása
	MOV  AH, 4Ch					;AH-ba a visszatérés funkciókódja
	INT  21h						;Visszatérés az operációs rendszerbe
main ENDP

write_block PROC
	PUSH CX							;CX mentése
	PUSH DX							;DX mentése
	MOV  CX, 32						;Kiírandó sorok száma CX-be
	write_block_new:
	CALL out_line					;Egy sor kiírása
	CALL cr_lf						;Soremelés
	ADD  DX, 16						;Következõ sor adatainak kezdõcíme;
	LOOP write_block_new			;Új sor
	POP  DX							;DX visszaállítása
	POP  CX							;CX visszaállítása
	RET
write_block ENDP

out_line PROC
	PUSH BX							;BX mentése
	PUSH CX							;CX mentése
	PUSH DX							;DX mentése
	MOV  BX,DX						;Sor adatainak kezdõcíme BX-be
	PUSH BX							;Mentés a karakteres kiíráshoz
	MOV  CX, 16						;Egy sorban 16 hexadecimális karakter
out_line_hexa_out:
	MOV  DL, Block[BX]				;Egy bájt betöltése
	CALL write_hexa					;Kiírás hexadecimális formában
	MOV  DL, Space					;Szóköz kiírása a hexa kódok között
	CALL write_char
	INC  BX							;Következõ adatbájt címe
	LOOP out_line_hexa_out			;Következõ bájt
	MOV  DL, Space					;Szóköz kiírása a kétféle mód között
	CALL write_char
	MOV  CX, 16						;Egy sorban 16 karakter
	POP  BX							;Adatok kezdõcímének beállítása
out_line_ascii_out:
	MOV  DL, Block[BX]				;Egy bájt betöltése
	CMP  DL, Space					;Vezérlõkarakterek kiszûrése
	JA   out_line_visible			;Ugrás, ha látható karakter
	MOV  DL, Space					;Nem látható karakterek cseréje szóközre
out_line_visible:
	CALL write_char					;Karakter kiírása
	INC  BX							;Következõ adatbájt címe
	LOOP out_line_ascii_out			;Következõ bájt
	POP  DX							;DX visszaállítása
	POP  CX							;CX visszaállítása
	POP  BX							;BX visszaállítása
	RET								;Vissza a hívó programba
out_line ENDP

write_hexa proc						;A DL-ben lévõ két hexa számjegy kiírása
	PUSH CX							;CX mentése a verembe
	PUSH DX							;DX mentése a verembe
	MOV  DH, DL						;DL mentése
	MOV  CL, 4						;Shift-elés száma CX-be
	SHR  DL, CL						;DL shift-elése 4 hellyel jobbra
	CALL write_hexa_digit			;Hexadecimális digit kiírása
	MOV  DL, DH						;Az eredeti érték visszatöltése DL-be
	AND  DL, 0Fh					;A felsõ négy bit törlése
	CALL write_hexa_digit			;Hexadecimális digit kiírása
	POP  DX							;DX visszaállítása
	POP  CX							;CX visszaállítása
	RET								;Visszatérés a hívó rutinba
write_hexa endp

write_hexa_digit PROC
	PUSH DX							;DX mentése a verembe
	CMP  DL, 10						;DL összehasonlítása 10-zel
	JB   non_hexa_letter			;Ugrás, ha kisebb 10-nél
	ADD  DL, "A"-"0"-10				;A – F betût kell kiírni
non_hexa_letter:
	ADD  DL, "0"					;Az ASCII kód megadása
	CALL write_char					;A karakter kiírása
	POP  DX							;DX visszaállítása
	RET								;Visszatérés a hívó rutinba
write_hexa_digit ENDP

cr_lf PROC
	PUSH DX							;DX mentése a verembe
	MOV  DL, 13
	CALL write_char					;kurzor a sor elejére
	MOV  DL, 10
	CALL write_char					;Kurzor egy sorral lejjebb
	POP  DX							;DX visszaállítása
	RET								;Visszatérés a hívó rutinba
cr_lf ENDP

clear_screen PROC
	XOR  AL, AL						;Ablak törlése
	XOR  CX, CX						;Bal felsõ sarok (CL = 0, CH = 0)
	MOV  DH, 49						;50 soros képernyõ alsó sora (25 sorosnál ide 24 kell)
	MOV  DL, 79						;Jobb oldali oszlop sorszáma
	MOV  BH, 7						;Törölt helyek attribútuma: fekete háttér szürke karakter
	MOV  AH, 6						;Sorgörgetés felfelé (Scroll-up) funkció
	INT  10h						;Képernyõ törlése
	RET
clear_screen ENDP

write_char proc						;A DL-ben lévõ karakter kiírása a képernyõre
	PUSH AX							;AX mentése a verembe
	MOV  AH, 2						; AH-ba a képernyõre írás funkciókódja
	INT  21h						; Karakter kiírása
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
write_char endp

END main