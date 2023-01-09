.MODEL SMALL
	Space EQU " "					;Szóköz karakter
	CR    EQU 13
	LF    EQU 10

.STACK
.DATA
	disc_text   DB "Number of disc: ",0
	sector_text DB "Number of sector: ",0

.DATA?
	block  DB 512 DUP (?)			;1 blokknyi terület kijelölése
	disc   DB 1   DUP (?)			;1 byte terület lefoglalása a lemezmeghajtó számának
	sector DB 1   DUP (?)			;1 byte terület lefoglalása a kiolvasandó szektor számának
	
.CODE

main PROC
	MOV  AX, Dgroup					;DS beállítása
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

	LEA  BX, block					;DS:BX memóriacímre tölti a blokkot
	MOV  AL, disc					;Lemezmeghajtó száma (A:0, B:1, C:2, stb.)
	MOV  CX, 1						;Egyszerre beolvasott blokkok száma
	XOR  DX, DX
	MOV  DL, sector					;Lemezolvasás kezdõblokkja
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
	MOV  CX, 16						;Kiírandó sorok száma CX-be (ideiglenesen csökkentve)
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

write_string proc					;BX-ben címzett karaktersorozat kiírása 0 kódig.
	PUSH DX							;DX mentése a verembe
	PUSH BX							;BX mentése a verembe
write_string_new:
	MOV  DL, [BX]					;DL-be egy karakter betöltése
	OR   DL, DL						;DL vizsgálata
	JZ   write_string_end			;0 esetén kilépés
	CALL write_char					;Karakter kiírása
	INC  BX							;BX a következõ karakterre mutat
	JMP  write_string_new			;A következõ karakter betöltése
write_string_end:
	POP  BX							;BX visszaállítása
	POP  DX							;DX visszaállítása
	RET								;Visszatérés
write_string endp

read_decimal proc
	PUSH AX							;AX mentése a verembe
	PUSH BX							;BX mentése a verembe
	MOV  BL, 10						;BX-be a számrendszer alapszáma, ezzel szorzunk
	XOR  AX, AX						;AX törlése
read_decimal_new:
	CALL read_char					;Egy karakter beolvasása
	CMP  DL, CR						;ENTER ellenõrzése
	JE   read_decimal_end			;Vége, ha ENTER volt az utolsó karakter
	SUB  DL, "0"					;Karakterkód minusz ”0” kódja
	MUL  BL							;AX szorzása 10-zel
	ADD  AL, DL						;A következõ helyi érték hozzáadása
	JMP  read_decimal_new			;A következõ karakter beolvasása
read_decimal_end:
	MOV  DL, AL						;DL-be a beírt szám
	POP  BX							;AB visszaállítása
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
read_decimal endp

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

write_decimal proc
	PUSH AX							;AX mentése a verembe
	PUSH CX							;CX mentése a verembe
	PUSH DX							;DX mentése a verembe
	PUSH SI							;SI mentése a verembe
	XOR  DH, DH						;DH törlése
	MOV  AX, DX						;AX-be a szám
	MOV  SI, 10						;SI-be az osztó
	XOR  CX, CX						;CX-be kerül az osztások száma
decimal_non_zero:
	XOR  DX, DX						;DX törlése
	DIV  SI							;DX:AX 32 bites szám osztása SI-vel, az eredmény AX-be, a maradék DX-be kerül
	PUSH DX							;DX mentése a verembe
	INC  CX							;Számláló növelése
	OR   AX, AX						;Státuszbitek beállítása AX-nek megfelelõen
	JNE  decimal_non_zero			;Vissza, ha az eredmény még nem nulla
decimal_loop:
	POP  DX							;Az elmentett maradék visszahívása
	CALL write_hexa_digit			;Egy decimális digit kiírása
	LOOP decimal_loop
	POP  SI							;SI visszaállítása
	POP  DX							;DX visszaállítása
	POP  CX							;CX visszaállítása
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
write_decimal endp

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
	MOV  DL, CR
	CALL write_char					;kurzor a sor elejére
	MOV  DL, LF
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

read_char proc						;Karakter beolvasása. A beolvasott karakter DL-be kerül
	PUSH AX							;AX mentése a verembe
	MOV  AH, 1						;AH-ba a beolvasás funkciókód
	INT  21h						;Egy karakter beolvasása, a kód AL-be kerül
	MOV  DL, AL						;DL-be a karakter kódja
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
read_char endp

write_char proc						;A DL-ben lévõ karakter kiírása a képernyõre
	PUSH AX							;AX mentése a verembe
	MOV  AH, 2						; AH-ba a képernyõre írás funkciókódja
	INT  21h						; Karakter kiírása
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
write_char endp

END main