.model tiny

.code
locals @@
org 100h

CRLF		equ 0Dh, 0Ah
ScnCode		equ 01h

Start:
		jmp Init

;-------------------------------------------------------
NewInt:		push AX
		push DI
		push ES

		in AL, 60h
		cmp AL, ScnCode
		jne @@Exit

		mov DI, 2 * (5 * 80 + 10)
		mov AX, 0B800h
		mov ES, AX
		mov AH, 10001010b
		mov AL, 49
		stosw

	@@Exit:	pop ES
		pop DI
		pop AX

		jmp dword ptr CS:[PrvInt]

PrvInt		dd 0

;-------------------------------------------------------
Init:		cld
		mov AX, CS
		mov DS, AX

		mov AX, 3509h
		int 21h
		mov word ptr CS:[PrvInt], BX
		mov word ptr CS:[PrvInt + 2], ES

		mov DX, offset NewInt
		mov AX, 2509h
		int 21h

		mov DX, offset InitMsg
		mov AH, 09h
		int 21h

		mov DX, offset Init
		add DX, 15
		mov CL, 4
		shr DX, CL
		mov AX, 3100h
		int 21h

InitMsg		db 'Installed', CRLF, '$'

end Start
