;#dialect=RASM

ADDR_TPA		equ #0006
BDOS			equ 5
CONSOLEOUTPUT	equ 2
CONSOLEDIRECTIO equ 6
STACKSIZE		equ 128

				org #0100

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
				db "Loader for MSX DOS", 0	; description

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
				ld hl,(ADDR_TPA)
				ld sp,hl		; put stack at himem
				
				ld de,STACKSIZE	; calculate new himem to be below the stack
				and a
				sbc hl,de
				ld (MemBlock1End),hl
				ret				

PS_CanSave:		xor a			; can we save to the boot device?
				ret	

PS_CharIn:		ld c, CONSOLEDIRECTIO
				ld e, #FF		; #FF = input+status, #FE = status, #FD = input, other = char for output
				call BDOS
				ret	
		
PS_CharOut:		ld c, CONSOLEOUTPUT
				ld e, a
				call BDOS
				ret	
		
PS_CharWait:	ld c, CONSOLEDIRECTIO
				ld e, #FD		; #FF = input+status, #FE = status, #FD = input, other = char for output
				call BDOS
				ret	
		
PS_CommandLine:	ret				; get commandline parameters

PS_FileExists:	ret				; platform specific fileexists

PS_FileSize:	ret				; platform specific filesize

PS_FileDelete:	ret				; platform specific filedelete

PS_FileLoad:	ret				; platform specific fileload

PS_FileSave:	ret				; platform specific filesave

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
		
PS_Terminate:	ret				; terminate elegantly

END_OF_LOADER:
