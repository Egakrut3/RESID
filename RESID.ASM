.model tiny

.code
locals @@
org 100h

Start:
		jmp Init

;-------------------------------------------------------
ScnCode		equ 36h				;RShift
ScrW		equ 80d
FLn		equ 5
Color		equ 00001010b			;Light green

NewInt		proc
		cli
		push BP
		mov BP, SP

		push AX
		push BX
		push CX
		push DX
		push SI
		push DI
		push DS
		push ES

		mov AX, CS
		mov DS, AX
		mov ES, AX

		in AL, 60h
		cmp AL, ScnCode
		;cmp [BP - 2], 1111h
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
		add DX, 2 * 12d				;SP differs by 12
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

		mov AL, 0FFh
		mov AH, Color
		mov CX, 8 * 13d - 1
		mov SI, offset TableAXFrmt
		mov DI, 2 * (FLn * ScrW)
		mov BX, 0B800h
		mov ES, BX
		cld
		call FrmtdPrint

	@@Exit:	pop ES
		pop DS
		pop DI
		pop SI
		pop DX
		pop CX
		pop BX
		pop AX

		pop BP
		sti
		jmp dword ptr CS:[PrvInt]
		endp

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

;-------------------------------------------------------
;Stores hexadecimal representation of a word into the string of length 4
;Enters:  DX - The word to be represented
;Expects: DF set to 1
;	  The lowest digit of representation must be stored from ES:[DI]
;Returns: None
;Destroys: AL, CL, DX, DI

StoreHex	proc
		mov CL, 4
		mov AL, DL
		and AL, 0Fh
		cmp AL, 9
		jbe @@Dec0
		add AL, 'A' - 0Ah
		jmp @@Beg1

	@@Dec0:	add AL, '0'

	@@Beg1:	stosb
		shr DX, CL
		mov AL, DL
		and AL, 0Fh
		cmp AL, 9
		jbe @@Dec1
		add AL, 'A' - 0Ah
		jmp @@Beg2

	@@Dec1:	add AL, '0'

	@@Beg2:	stosb
		shr DX, CL
		mov AL, DL
		and AL, 0Fh
		cmp AL, 9
		jbe @@Dec2
		add AL, 'A' - 0Ah
		jmp @@Beg3

	@@Dec2:	add AL, '0'

	@@Beg3:	stosb
		shr DX, CL
		mov AL, DL
		and AL, 0Fh
		cmp AL, 9
		jbe @@Dec3
		add AL, 'A' - 0Ah
		jmp @@Exit

	@@Dec3:	add AL, '0'

	@@Exit:	stosb
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
;	  [SP + 4] - Middle frame symbol
;	  [SP + 6] - Right frame symbol
;Expects: DF set to 0
;	  Line must be stored from ES:[DI]
;Destroys: AL, CX, DI

PrintFrmLn	proc
		push BP
		mov BP, SP

		mov AL, [BP + 4]
		stosw

		mov AL, [BP + 6]
		rep stosw

		mov AL, [BP + 8]
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
;	 [SP + 4] - Right frame symbol
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
		mov AL, [BP + 6]
		stosw

		pop BP
		ret
		endp

;-------------------------------------------------------
;Prints a formated string to VMemory with a frame
;Enters:  AL - Equals 0 if no frame must be provided, FFh if default frame
;	  must be provided, else contains ASCII-code of the frame symbol
;	  AH - Color of the frame
;	  CX - Length of the string
;Expects: DF set to 0
;	  The string begins at DS:[SI]
;	  Line with top corner begins at ES:[DI]
;Returns: None
;Destroys: BX

HFrm		equ 0CDh
VFrm		equ 0BAh
LTFrm		equ 0C9h
RTFrm		equ 0BBh
LBFrm		equ 0C8h
RBFrm		equ 0BCh

FrmtdPrint	proc
		push BP
		mov BP, SP
		push AX
		push CX
		push DI
		push ES

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
		add word ptr [BP - 6], BX

		mov DI, [BP - 6]
		mov ES, [BP - 8]
		mov CX, DX
		push RTFrm
		push HFrm
		push LTFrm
		call PrintFrmLn
		add SP, 3 * 2
		add word ptr [BP - 6], 2 * ScrW

		mov AL, '$'
		mov DI, SI
		push DS
		pop ES
		mov CX, [BP - 4]
	@@L4:	mov BX, CX
		repne scasb
		sub BX, CX
		cmp CX, 0
		je @@L5
		dec BX
	@@L5:	push DI
		push ES
		mov DI, [BP - 6]
		mov ES, [BP - 8]
		push AX
		push CX
		push DX
		mov CX, BX
		push VFrm
		push VFrm
		call PrintFrmTxt
		add SP, 2 * 2
		pop DX
		pop CX
		pop AX
		pop ES
		pop DI
		add word ptr [BP - 6], 2 * ScrW
		inc SI
		cmp CX, 0
		jne @@L4

		mov DI, [BP - 6]
		mov ES, [BP - 8]
		mov CX, DX
		push RBFrm
		push HFrm
		push LBFrm
		call PrintFrmLn
		add SP, 3 * 2

		add SP, 4 * 2
		pop BP
		ret
		endp

;-------------------------------------------------------
Init:		cld

		mov AX, 3509h
		int 21h
		mov word ptr CS:[PrvInt + 0], BX
		mov word ptr CS:[PrvInt + 2], ES

		mov DX, offset NewInt
		mov AX, 2509h
		int 21h

		mov DX, offset Init + 15
		mov CL, 4
		shr DX, CL
		mov AX, 3100h
		int 21h

end Start
