.model tiny

.code
locals @@
org 100h

Start:
		jmp Init

;-------------------------------------------------------
ScrW		equ 80d

ScnCode		equ 36h
FLn		equ 5
Color		equ 00001010b			;Light green
HFrm		equ 0CDh			;Õ
VFrm		equ 0BAh			;∫	…Õª
LTFrm		equ 0C9h			;…	∫ ∫
RTFrm		equ 0BBh			;ª	»Õº
LBFrm		equ 0C8h			;»
RBFrm		equ 0BCh			;º

NewInt		proc
		cli
		push BP
		mov BP, SP

		push AX BX CX DX SI DI DS ES

		mov AX, CS
		mov DS, AX
		mov ES, AX

		in AL, 60h
		cmp AL, ScnCode
		je @@Skip
		jmp @@Exit

	@@Skip:	std

		mov DX, [BP - 2]			;AX
		mov DI, offset TableAXFrmt + 6
		call StoreHex

		mov DX, [BP - 4]			;BX
		mov DI, offset TableBXFrmt + 6
		call StoreHex

		mov DX, [BP - 6]			;CX
		mov DI, offset TableCXFrmt + 6
		call StoreHex

		mov DX, [BP - 8]			;DX
		mov DI, offset TableDXFrmt + 6
		call StoreHex

		mov DX, [BP - 10d]			;SI
		mov DI, offset TableSIFrmt + 6
		call StoreHex

		mov DX, [BP - 12d]			;DI
		mov DI, offset TableDIFrmt + 6
		call StoreHex

		mov DX, SP
		add DX, 2 * 12d				;SP differs by 12 words
		mov DI, offset TableSPFrmt + 6		;from the correct one now
		call StoreHex

		mov DX, [BP]				;BP
		mov DI, offset TableBPFrmt + 6
		call StoreHex

		mov DX, [BP + 4]			;Initial CS located there
		mov DI, offset TableCSFrmt + 6
		call StoreHex

		mov DX, SS
		mov DI, offset TableSSFrmt + 6
		call StoreHex

		mov DX, [BP - 14d]			;DS
		mov DI, offset TableDSFrmt + 6
		call StoreHex

		mov DX, [BP - 16d]			;ES
		mov DI, offset TableESFrmt + 6
		call StoreHex

		mov DX, [BP + 2]			;Initial IP located there
		mov DI, offset TableIPFrmt + 6
		call StoreHex

		mov AH, Color
		mov CX, 8 * 13d - 1
		mov SI, offset TableAXFrmt
		mov DI, 2 * (FLn * ScrW)
		mov BX, 0B800h
		mov ES, BX
		cld
		cmp CS:[FrmMode], 0FFh
		je @@Dflt
		mov DL, CS:[FrmMode]
		mov DH, CS:[FrmMode]
		push DX DX DX DX
		jmp @@Prnt
	@@Dflt:	mov DH, RBFrm
		mov DL, HFrm
		push DX
		mov DH, LBFrm
		mov DL, VFrm
		push DX
		mov DH, VFrm
		mov DL, RTFrm
		push DX
		mov DH, HFrm
		mov DL, LTFrm
		push DX
	@@Prnt:	call FrmtdPrint
		add SP, 4 * 2

	@@Exit:	pop ES DS DI SI DX CX BX AX

		pop BP
		sti
		jmp 	CS:[PrvInt]
		endp

InstFl		dw 0FACEh
PrvInt		dd 0
TableAXFrmt	db 'AX=0000$'
TableBXFrmt	db 'BX=0000$'
TableCXFrmt	db 'CX=0000$'
TableDXFrmt	db 'DX=0000$'
TableSIFrmt	db 'SI=0000$'
TableDIFrmt	db 'DI=0000$'
TableSPFrmt	db 'SP=0000$'
TableBPFrmt	db 'BP=0000$'
TableCSFrmt	db 'CS=0000$'
TableSSFrmt	db 'SS=0000$'
TableDSFrmt	db 'DS=0000$'
TableESFrmt	db 'ES=0000$'
TableIPFrmt	db 'IP=0000'
FrmMode		db 0FFh

;-------------------------------------------------------
;Stores hexadecimal representation of a word into the string of length 4
;Enters:  DX - The word to be represented
;Expects: DF set to 1
;	  The lowest digit of representation must be stored from ES:[DI]
;Returns: None
;Destroys: AL, CL, DX, DI

StoreDig	macro
		mov SI, DX
		and SI, 0Fh
		mov AL, CS:[HexDigits + SI]
		stosb
		shr DX, CL
		endm

HexDigits	db '0123456789ABCDEF'

StoreHex	proc
		mov CL, 4

		StoreDig
		StoreDig
		StoreDig
		StoreDig
		
		ret
		endp
		
;-------------------------------------------------------
;Calculates the offset from the beginning of a line to centering a string
;Enters:  CX - Length of the string
;	  DX - Length of the line
;Expects: None
;Returns: BX - Offset
;Destroys: None

LnOffset	proc
		mov BX, DX
		cmp CX, BX
		jbe @@L1
		xor BX, BX
		jmp @@L2
	@@L1:	sub BX, CX
	@@L2:	shr BX, 1
		ret
		endp

;-------------------------------------------------------
;Prints line of frame symbols, multiplying the middle symbol several times
;Enters:  AH - Color of the frame
;	  CX - Length of the middle part
;	  [SP + 2] - Left frame symbol
;	  [SP + 3] - Middle frame symbol
;	  [SP + 4] - Right frame symbol
;Expects: DF set to 0
;	  Line must be stored from ES:[DI]
;Destroys: AL, CX, DI

PrintFrmLn	proc
		push BP
		mov BP, SP

		mov AL, [BP + 4]
		stosw

		mov AL, [BP + 5]
		rep stosw

		mov AL, [BP + 6]
		stosw

		pop BP
		ret
		endp

;-------------------------------------------------------
;Prints text line with frame symbols on the edges
;Enters  AH - Color of the frame and the text
;	 CX - Text length
;	 DX - Frame line length
;	 [SP + 2] - Left frame symbol
;	 [SP + 3] - Right frame symbol
;Expects: DF set to 0
;	  Text begins from DS:[SI]
;	  Line must be stored from ES:[DI]
;Returns: None
;Destroys: AL, BX, CX, DX, SI, DI

PrintFrmTxt	proc
		push BP
		mov BP, SP

		cmp CX, DX
		jbe @@L1
		mov CX, DX

	@@L1:	mov AL, [BP + 4]
		stosw

		call LnOffset
		push DI
		shl BX, 1
		add DI, BX
	@@L2:	lodsb
		stosw
		loop @@L2
		pop DI

		shl DX, 1
		add DI, DX
		mov AL, [BP + 5]
		stosw

		pop BP
		ret
		endp

;-------------------------------------------------------
;Prints a formated string to VMemory with a frame
;Enters:  AH - Color of the frame
;	  CX - Length of the string
;	  [SP + 2] - Left-top frame symbol
;	  [SP + 3] - Middle-top frame symbol
;	  [SP + 4] - Right-top frame symbol
;	  [SP + 5] - Middle-left frame symbol
;	  [SP + 6] - Middle-right frame symbol
;	  [SP + 7] - Left-bottom frame symbol
;	  [SP + 8] - Middle-left frame symbol
;	  [SP + 9] - Right-bottom frame symbol
;Expects: DF set to 0
;	  The string begins at DS:[SI]
;	  Line with top corner begins at ES:[DI]
;Returns: None
;Destroys: AL, BX, DX

FrmtdPrint	proc
		push BP
		mov BP, SP

		push CX DI ES

		mov AL, '$'
		mov DI, SI
		push DS
		pop ES
		xor DX, DX
	@@L1:	mov BX, CX
		repne scasb
		sub BX, CX
		cmp CX, 0
		je @@L2
		dec BX
	@@L2:	cmp DX, BX
		jae @@L3
		mov DX, BX
	@@L3:	cmp CX, 0
		jne @@L1

		mov CX, DX
		add CX, 2
		push DX
		mov DX, ScrW
		call LnOffset
		pop DX
		shl BX, 1
		add word ptr [BP - 4], BX

		mov DI, [BP - 4]
		mov ES, [BP - 6]
		mov CX, DX
		push [BP + 6]
		push [BP + 4]
		call PrintFrmLn
		add SP, 2 * 2
		add word ptr [BP - 4], 2 * ScrW

		mov AL, '$'
		mov DI, SI
		push DS
		pop ES
		mov CX, [BP - 2]
	@@L4:	mov BX, CX
		repne scasb
		sub BX, CX
		cmp CX, 0
		je @@L5
		dec BX
	@@L5:	push AX CX DX DI ES
		mov CX, BX
		mov DI, [BP - 4]
		mov ES, [BP - 6]
		push [BP + 7]
		call PrintFrmTxt
		add SP, 1 * 2
		pop ES DI DX CX AX
		add word ptr [BP - 4], 2 * ScrW
		inc SI
		cmp CX, 0
		jne @@L4

		mov DI, [BP - 4]
		mov ES, [BP - 6]
		mov CX, DX
		push [BP + 11d]
		push [BP + 9]
		call PrintFrmLn
		add SP, 2 * 2

		add SP, 3 * 2
		pop BP
		ret
		endp

;-------------------------------------------------------
Canary		equ 0FACEh

Init		proc
		mov AX, 3509h
		int 21h
		mov word ptr CS:[PrvInt + 0], BX
		mov word ptr CS:[PrvInt + 2], ES

		cmp word ptr ES:[InstFl], Canary
		je @@Exit


		mov SI, 80h
		push CS
		pop DS
		lodsb
		xor AH, AH
		mov CX, AX
		cld
		call ParseCmd
		mov [FrmMode], AL

		mov DX, offset NewInt
		mov AX, 2509h
		int 21h

		mov [InstFl], Canary
		mov DX, offset Init + 15
		mov CL, 4
		shr DX, CL
		mov AX, 3100h
		int 21h

	@@Exit:	mov AX, 4C00h
		int 21h
		endp

;-------------------------------------------------------
;Parses a string as command-line arguments
;Enters:  CX - Length of the string
;Expects: The beginning	of the string at DS:[SI]
;Returns: AL - Equals FFh if default frame must be provided,
;	  else contains frame symbol (0 if no frame)
;	  CX - Number of unparsed symbols
;	  DS:[SI] - The first unparsed symbol
;Destroys: BX

ChkInd		macro
		cmp CX, 0
		je @@End
		endm
MovInd		macro
		dec CX
		inc SI
		endm

ParseCmd	proc
		mov AL, 0FFh
		mov BX, SI

		ChkInd
		cmp byte ptr [SI], ' '
		jne @@End
		MovInd
		mov BX, SI

	@@Opt:	ChkInd
		cmp byte ptr [SI], '/'
		jne @@End
		MovInd

		ChkInd
		cmp byte ptr [SI], 'f'
		jne @@L1
		MovInd
		ChkInd
		cmp byte ptr [SI], '='
		jne @@End
		MovInd
		ChkInd
		mov AL, [SI]
		jmp @@Nxt

	@@L1:	cmp byte ptr [SI], 'n'
		jne @@End
		MovInd
		ChkInd
		cmp byte ptr [SI], 'o'
		jne @@End
		mov AL, 0

	@@Nxt:	MovInd
		mov BX, SI
		jmp @@Opt

	@@End:	sub SI, BX
		add CX, SI
		mov SI, BX
		ret
		endp

end Start
