.model tiny

.code
locals @@
org 100h

CRLF		equ 0Dh, 0Ah

Start:		mov AX, 1136h
		mov BX, 2222h
		mov CX, 3333h
		mov DX, 4444h
		mov SI, 5555h
		mov DI, 6666h
		mov BP, 7777h
		mov DS, AX
		mov ES, BX
		int 09h

		call $ + 3
		pop DX
		sub DX, 3
		std
		mov AX, CS
		mov DS, AX
		mov ES, AX
		mov DI, offset TestMsg + 6d
		call StoreHex

		mov DX, CS
		mov DI, offset TestMsg + 15d
		call StoreHex

		mov DX, SP
		mov DI, offset TestMsg + 24d
		call StoreHex

		mov DX, SS
		mov DI, offset TestMsg + 33d
		call StoreHex

		mov AH, 09h
		mov DX, offset TestMsg
		int 21h

	@@Exit:	mov AX, 4C00h
		int 21h

TestMsg		db 'IP=0000', CRLF, 'CS=0000', CRLF, 'SP=0000', CRLF, 'SS=0000', CRLF, '$'

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

end Start	