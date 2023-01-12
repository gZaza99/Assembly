.MODEL SMALL
	Space         EQU " "			;Szóköz karakter
	CR            EQU 13			;CR-be a kurzor a sor elejére kód
	LF            EQU 10			;LF-be a kurzor új sorba kód
	attr_text     EQU 00000111b		;Standard fekete alapon halvány fehér szín
	attr_border   EQU 11010000b		;Ibolya (lila) alapon fekete szín és villog
	Screen_width  EQU 80			;Képernyõ szélessége
	Screen_height EQU 25			;Képernyõ magassága

.STACK
.DATA
	disc_text   DB "Number of disc: ",0
	sector_text DB "Number of sector: ",0
	lines       WORD 20

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

	LEA  BX, disc_text
	CALL write_string
	CALL read_decimal
	MOV  disc, DL

	LEA  BX, sector_text
	CALL write_string
	CALL read_decimal
	MOV  sector, DL

	CALL clear_screen

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
	PUSH BX							;BX mentése
	PUSH CX							;CX mentése
	PUSH DX							;DX mentése
	MOV  BX, 0000001000000100b		;BX -be a képernyõ elsõ sor -és oszlopindexe [ Oszlop=2 | Sor=4 ]
	MOV  CX, lines					;Kiírandó sorok száma CX-be (ideiglenesen csökkentve)
write_block_new:
	CALL out_line					;Egy sor kiírása
	ADD  DX, 16						;Következõ sor adatainak kezdõcíme
	INC  BL							;Következõ sor indexe
	LOOP write_block_new			;Új sor
	POP  DX							;DX visszaállítása
	POP  CX							;CX visszaállítása
	POP  BX							;BX visszaállítása
	RET
write_block ENDP

out_line PROC
	PUSH BP							;BP mentése
	PUSH AX							;AX mentése
	PUSH BX							;BX mentése
	PUSH CX							;CX mentése
	PUSH DX							;DX mentése
	MOV  BP,DX						;Sor adatainak kezdõcíme BP-be
	PUSH BP							;Mentés a karakteres kiíráshoz

	MOV  CX, 16						;Egy sorban 16 hexadecimális karakter
out_line_hexa_out:

	MOV  DL, Block[BP]				;Egy bájt betöltése
	CALL cvt2hexa					;Hexadecimális formátummá alakítás azaz =>  AX = cvt2hexa( DL )

	INC  BH							;	X := Következõ oszlop
	MOV  DL, AH						;	DL -be az 1. hexa karakter
	MOV  DH, attr_text				;	Standard stílusú karakter
	CALL draw_char					;1. hexa karakter kirajzolása

	INC  BH							;	X := Következõ oszlop
	MOV  DL, AL						;	DL -be a 2. hexa karakter
	MOV  DH, attr_text				;	Standard stílusú karakter
	CALL draw_char					;2. hexa karakter kirajzolása

	INC  BH							;Üres hely kihagyása a hexa kódok között
	INC  BP							;Következõ adatbájt címe
	LOOP out_line_hexa_out			;Következõ bájt
	INC  BH							;Üres hely kihagyása a kétféle mód között
	MOV  CX, 16						;Egy sorban 16 karakter
	POP  BP							;Adatok kezdõcímének beállítása
out_line_ascii_out:
	INC  BH							;X := Következõ oszlop
	MOV  DL, Block[BP]				;Egy bájt betöltése
	CMP  DL, Space					;Vezérlõkarakterek kiszûrése
	JBE  out_line_invisible			;Ugrás, ha NEM látható karakter

	MOV  DH, attr_text				;Standard stílusú karakter
	CALL draw_char					;Karakter kirajzolása

out_line_invisible:
	INC  BP							;Következõ adatbájt címe
	LOOP out_line_ascii_out			;Következõ bájt
	POP  DX							;DX visszaállítása
	POP  CX							;CX visszaállítása
	POP  BX							;BX visszaállítása
	POP  AX							;AX visszaállítása
	POP  BP							;BP visszaállítása
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
	MOV  BL, 10						;BL-be a számrendszer alapszáma, ezzel szorzunk
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
	POP  BX							;BX visszaállítása
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
read_decimal ENDP

;cvt = convert
cvt2hexa PROC						;write_hexa alprogram kicsit átalakítva
	PUSH CX							;CX mentése a verembe
	PUSH DX							;DX mentése a verembe
	MOV  DH, DL						;DL mentése
	MOV  CL, 4						;Shift-elés száma CX-be
	SHR  DL, CL						;DL shift-elése 4 hellyel jobbra
	CALL get_hexa_digit				;AL = get_hexa_digit( DL )
	MOV  AH, AL						;AH -ba az elsõ hexa karakter
	MOV  DL, DH						;Az eredeti érték visszatöltése DL-be
	AND  DL, 0Fh					;A felsõ négy bit törlése
	CALL get_hexa_digit				;AL = get_hexa_digit( DL )
	POP  DX							;DX visszaállítása
	POP  CX							;CX visszaállítása
	RET								;AX -szel visszatérés a hívó rutinba
cvt2hexa ENDP

get_hexa_digit PROC USES DX			;#TODO: Visszaad egy hexa karaktert
	CMP  DL, 10						;DL összehasonlítása 10-zel
	JB   get_hexa_digit_end			;Ugrás, ha kisebb 10-nél
	ADD  DL, "A"-"0"-10				;A – F betût kell menteni
get_hexa_digit_end:
	ADD  DL, "0"					;Az ASCII kód megadása
	MOV  AL, DL						;A karakter kiírása
	RET								;AL -lel Visszatérés a hívó rutinba
get_hexa_digit ENDP

clear_screen PROC
	XOR  AL, AL						;AL törlése
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
draw_char PROC USES AX CX DI		;BX = [ X:BYTE | Y:BYTE ] DX = Kiírandó karakter attribútummal
	MOV  AL, BL						;AL -be az Y paraméter a verembõl
	DEC  AL							;Y-1 a nullától indexelés miatt
	MOV  CL, Screen_width			;CL -be a képernyõ szélessége (oszlopok száma)
	MUL  CL							;AX -be a kívánt magasság
	XOR  CX, CX						;CX kinullázása a felsõ 8 bit miatt
	MOV  CL, BH						;CL -be az X paraméter a verembõl
	ADD  AX, CX						;AX -be a kívánt offset karaktter pozíció
	SHL  AX, 1						;AX -be a kívánt offset memória cím
	
	MOV  DI, AX						;DI -be a kívánt offset memória cím, mert csak bázis, vagy index regiszter elfogadott
	MOV  AX, DX						;AX -be a kirajzolni kívánt karakter

	MOV  ES:[DI], AX				;Karakter kirajzolása
	RET
draw_char ENDP

write_char PROC						;A DL-ben lévõ karakter kiírása a képernyõre
	PUSH AX							;AX mentése a verembe
	MOV  AH, 2						;AH-ba a képernyõre írás funkciókódja
	INT  21h						;Karakter kiírása
	POP  AX							;AX visszaállítása
	RET								;Visszatérés a hívó rutinba
write_char ENDP

END main