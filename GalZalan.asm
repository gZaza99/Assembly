.MODEL SMALL, C						;Paraméter vermen keresztüli átadásához kell a híváskonvenció
	Space         EQU " "			;Szóköz karakter
	CR            EQU 13			;CR-be a kurzor a sor elejére kód
	LF            EQU 10			;LF-be a kurzor új sorba kód
	attr_text     EQU 00000111b		;Standard fekete alapon halvány fehér szín
	attr_border   EQU 01110000b		;Fehér alapon fekete szín
	Screen_width  EQU 80			;Képernyõ szélessége
	Screen_height EQU 25			;Képernyõ magassága

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

	MOV  AX, 0B800h					;Képernyõ-memória szegmenscíme ES-be
	MOV  ES, AX

	MOV  AL, Screen_height			;Y = 25 - 1
	DEC  AL
	MOV  AH, 60						;X = 60
	PUSH AX							;XY = [ 10 | 1 ]
	MOV  AL, "P"					;Karakter: "P"
	MOV  AH, attr_text				;Attribútum: Standard megjelenítés
	PUSH AX
	CALL draw_char					;Kiírás

	;LEA  BX, disc_text
	;CALL write_string
	;CALL read_decimal
	;MOV  disc, DL

	;LEA  BX, sector_text
	;CALL write_string
	;CALL read_decimal
	;MOV  sector, DL

	;CALL clear_screen

	;LEA  BX, block					;DS:BX memóriacímre tölti a blokkot
	;MOV  AL, disc					;Lemezmeghajtó száma (A:0, B:1, C:2, stb.)
	;MOV  CX, 1						;Egyszerre beolvasott blokkok száma
	;XOR  DX, DX
	;MOV  DL, sector					;Lemezolvasás kezdõblokkja
	;INT  25h						;Olvasás
	;POPF							;A veremben tárolt jelzõbitek törlése
	;XOR  DX, DX						;Kiírandó adatok kezdõcíme DS:DX
	;CALL write_block				;Egy blokk kiírása

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

write_string PROC					;BX-ben címzett karaktersorozat kiírása 0 kódig.
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
write_string ENDP

read_decimal PROC
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
read_decimal ENDP

write_hexa PROC						;A DL-ben lévõ két hexa számjegy kiírása
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
write_hexa ENDP

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
	MOV  DH, Screen_height			;50 soros képernyõ alsó sora (25 sorosnál ide 24) kell
	DEC  DH							;Képernyõ magassága -1
	MOV  DL, Screen_width			;Jobb oldali oszlop sorszáma kell
	DEC  DL							;Képernyõ szélessége -1
	MOV  BH, 7						;Törölt helyek attribútuma: fekete háttér szürke karakter
	MOV  AH, 6						;Sorgörgetés felfelé (Scroll-up) funkció
	INT  10h						;Képernyõ törlése
	RET
clear_screen ENDP

read_char PROC						;Karakter beolvasása. A beolvasott karakter DL-be kerül
	PUSH AX							;AX mentése a verembe
	MOV  AH, 1						;AH-ba a beolvasás funkciókód
	INT  21h						;Egy karakter beolvasása, a kód AL-be kerül
	MOV  DL, AL						;DL-be a karakter kódja
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
read_char ENDP

;2 * ( (y-1) * <sorhossz=80> + x )
draw_char PROC USES AX BX DX, MemoryItem: WORD, XY: WORD			;XY = [ X:BYTE | Y:BYTE ]
	MOV  DX, XY
	MOV  AL, DL						;AL -be az Y paraméter a verembõl
	DEC  AL							;Y-1 a nullától indexelés miatt
	MOV  BL, Screen_width			;BL -be a képernyõ szélessége (oszlopok száma)
	MUL  BL							;AX -be a kívánt magasság
	XOR  BX, BX						;BX kinullázása a felsõ 8 bit miatt
	MOV  BL, DH						;BL -be az X paraméter a verembõl
	ADD  AX, BX						;AX -be a kívánt offset karaktter pozíció
	SHL  AX, 1						;AX -be a kívánt offset memória cím
	
	MOV  BX, AX						;BX -be a kívánt offset memória cím, mert csak bázis, vagy index regiszter elfogadott
	MOV  AX, MemoryItem				;AX -be a kirajzolni kívánt karakter

	MOV  ES:[BX], AX				;Karakter kirajzolása
	RET
draw_char ENDP

write_char PROC						;A DL-ben lévõ karakter kiírása a képernyõre
	PUSH AX							;AX mentése a verembe
	MOV  AH, 2						; AH-ba a képernyõre írás funkciókódja
	INT  21h						; Karakter kiírása
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
write_char ENDP

END main