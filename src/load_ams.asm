;#dialect=RASM

ADDR_2KBUFFER	equ #c000
ADDR_RAMTOP		equ #a140		; 40k + #0040 + 256 (stack size)
CAS_IN_OPEN		equ #bc77
CAS_IN_CLOSE	equ #bc7a
CAS_IN_DIRECT	equ #bc83
CAS_OUT_OPEN	equ #bc8c
CAS_OUT_CLOSE	equ #bc8f
CAS_OUT_DIRECT	equ #bc98
KM_READ_KEY		equ #bb1b
KM_READ_CHAR	equ #bb09
KM_WAIT_CHAR	equ #bb06
SYSTEM_RESET	equ 0
TXT_OUT_CHAR	equ #bb5a

FILETYPE_BINARY	equ 2
STACKSIZE		equ 128

				org #0040

								; WARNING NO CODE FROM HERE IN THIS FILE

LOADER:			jp Main			; loader is a platform dependent program loader

								; header
ADDR_RELOCTABLE:dw 0			; this isn't being relocated, so always 0
ADDR_VERSION:	dw 1			; version
ADDR_APICOMPAT:	dw 1			; API compatability ID
ADDR_REQMEMTYPE:db 1			; required memory type
ADDR_PATCHTABLE:dw PatchTable
ADDR_JUMPBLOCK:	dw JumpBlock	; pointer to the jumpblock
ADDR_ISR:		dw 0			; pointer to the ISR
ADDR_LOADER:	dw 0			; always 0 for loader
MSG_PRIMAL:		db "PRIMAL", 0	; type must be after the jump to main
				db "Loader for Amstrad CPC", 0	; description

				include "load.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

								; Memory Table Record Summary
								; 0 = End of Table
								; 1 = Non-Pageable block of RAM
								; 2 = Pageable block of RAM
								; 252 = Video RAM
								; 253 = Reserved RAM
								; 254 = ROM
								; 255 = Extension Block (anything following an extension record is ignored)
MemTable:		
				db 1
				dw END_OF_LOADER
				dw #3fff

				db 1
				dw #8000
MemBlock1End:	dw 0

				db 2
				dw #4000, #7fff	

				db 0			; End of Block / can be patched to be an Extension Block
				dw 0, 0	

PS_RAMInit:						; initialise RAM
				ld hl,ADDR_RAMTOP
				ld sp,hl		; put stack at himem
				
				ld de,STACKSIZE	; calculate new himem to be below the stack
				and a
				sbc hl,de
				ld (MemBlock1End),hl
				ret		

PS_CanSave:		xor a			; can we save to the boot device?
				ret	

PS_CharIn:		call KM_READ_CHAR
				ret c
				xor a
				ret	
		
PS_CharOut:		call TXT_OUT_CHAR
				ret	
		
PS_CharWait:	call KM_WAIT_CHAR
				ret
		
PS_CommandLine:	ret				; get commandline parameters

					; ------------------------- FileExists
					; -- parameters:
					; -- HL = filename address
					; -- return:
					; -- Z if TRUE if the file exists, NZ if FALSE
					; -- corrupt:
					; -- AF, BC, DE, HL

PS_FileExists:	jp SysError		; platform specific fileexists
				ret				

					; ------------------------- FileSize
					; -- parameters:
					; -- HL = filename address
					; -- return:
					; -- BC = filesize
					; -- Z if TRUE, NZ if FALSE
					; -- corrupt:
					; -- AF, BC, DE, HL

PS_FileSize:	xor a			; platform specific filesize
				ret

PS_FileDelete:	ret				; platform specific filedelete

					; ------------------------- FileLoad
					; -- parameters:
					; -- HL = filename address
					; -- return:
					; -- Z if TRUE, NZ if FALSE
					; -- corrupt:
					; -- AF, BC, DE, HL

PS_FileLoad:	push hl
				push de
				push hl
				call SysStrLen
				ld b,c
				pop hl
				ld de,ADDR_2KBUFFER
				call CAS_IN_OPEN
				pop hl	; hl now is the load address
				pop de	; no need the filename anymore
				jp nc, SysError

				call CAS_IN_DIRECT
				jp nc, SysError

				call CAS_IN_CLOSE
				xor a
				ret

					; ------------------------- FileSave
					; -- parameters:
					; -- HL = filename address
					; -- DE = save from address
					; -- BC = save length
					; -- return:
					; -- Z if TRUE, NZ if FALSE
					; -- corrupt:
					; -- AF, BC, DE, HL

PS_FileSave:	push hl			; platform specific save
				push de
				push bc
				push hl
				call SysStrLen
				ld b,c
				pop hl
				ld de,ADDR_2KBUFFER
				call CAS_OUT_OPEN
				pop de	; now the save length
				pop hl	; now the save from address
				pop bc	; no need the filename anymore
				jp nc, SysError

				ld a, FILETYPE_BINARY
				call CAS_OUT_DIRECT
				jp nc, SysError

				call CAS_OUT_CLOSE
				xor a
				ret
				
PS_StrIn:						; gets a string input
				ret	

PS_StrOutHL:					; outputs a string pointed to by HL
StrOutHL_Loop1:	
				ld a,(hl)	
				or a	
				jr z,StrOutHL_Loop1end	
				push hl	
				call SysCharOut
				pop hl	
				inc hl	
				jr StrOutHL_Loop1	
StrOutHL_Loop1end:	
				ret	
		
PS_Terminate:					; terminate elegantly
				call SYSTEM_RESET
				ret	

END_OF_LOADER: