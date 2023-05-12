;#dialect=RASM

ADDR_MEMTOP		equ #d3ff
CONOUT			equ #fc39
READKEYBOARD	equ #fc6c
STARTREADKEYBOARD equ #fca8
ENDREADKEYBOARD	equ #fc4b
STACKSIZE		equ 128

				org #8000

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
				db "Loader for Coleco Adam EOS", 0	; description

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
				dw ADDR_MEMTOP

				db 2
				dw #0, #7fff

				db 0			; End of Block / can be patched to be an Extension Block
				dw 0, 0	

PS_RAMInit:		ret				; initialise RAM

PS_CanSave:		xor a			; can we save to the boot device?
				ret	

PS_CharIn:		call STARTREADKEYBOARD
				call ENDREADKEYBOARD
				ret c
				xor a
				ret	
		
PS_CharOut:		call CONOUT
				ret	
		
PS_CharWait:	call READKEYBOARD
				ret z
				xor a
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
