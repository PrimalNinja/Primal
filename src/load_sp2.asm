;#dialect=RASM

BUILD_ADDR		equ #8000
STACKSIZE		equ 128

COPYBUFFERSIZE	equ 128
COPYBUFFERADDR	equ ADDR_BUFFERS
ALLOCSIZE		equ COPYBUFFERSIZE

CHAN_OPEN		equ #1601
KEY_CODE		equ #0333
KEY_SCAN		equ #028e
KEY_TABLE		equ #0205
KEY_TEST		equ #031e

				org BUILD_ADDR

								; WARNING NO CODE FROM HERE IN THIS FILE

LOADER:			jp Main			; loader is a platform dependent program loader

								; header
ADDR_RELOCTABLE:dw 0			; this isn't being relocated, so always 0
ADDR_BUILD:		dw BUILD_ADDR	; the build address, used for relocation
ALLOC_SIZE:		dw ALLOCSIZE	; allocate this amount of ram after loading this module so it isn't stored in the binary, usually it overwrites the relocation table
ADDR_VERSION:	dw 1			; version
ADDR_APICOMPAT:	dw 1			; API compatability ID
ADDR_REQMEMTYPE:db 1			; required memory type
ADDR_PATCHTABLE:dw PatchTable
ADDR_JUMPBLOCK:	dw JumpBlock	; pointer to the jumpblock
ADDR_ISR:		dw 0			; pointer to the ISR
ADDR_LOADER:	dw 0			; always 0 for loader
MSG_PRIMAL:		db "PRIMAL", 0	; type must be after the jump to main
				db "Loader for ZX Spectrum+2", 0	; description

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
SYSTEMPOOLADDR:	dw ADDR_BUFFERS + ALLOCSIZE, #bfff

				db 2
				dw #c000, #ffff

				db 0			; End of Block / can be patched to be an Extension Block
				dw 0, 0	

PS_RAMInit:		ret				; nothing to initialise?

								; table of property tables
PropertyTable:	dw PropertyTable1, 0

								; table of propertyname zero terminated, 16bit value
PropertyTable1:	
				db "CANSAVE", 0, "Y", 0			; is saving to the boot device possible?
				db "CANDELETE", 0, "Y", 0		; is file deletion possible from the boot device?
				db "CANBUILD", 0, "Y", 0		; is building possible?
				db "ISBUILT", 0, "N", 0			; is the system built already?
				db "HASCLIPARAMS", 0, "N", 0	; does the host have commandline parameter support?
				db "PROMPTONSTART", 0, "Y", 0	; prompt on startup?
				db "CANSETCURSORPOS", 0, "Y", 0	; can we set the cursor position?
				db "DEFTEXTRES", 0, 24, 32		; the text resolution (Y, X)
				db 0
				
ADDR_EIDI:		db 0;

					; ------------------------- disable interrupts (supports nesting)
PS_DI:			di
				push hl
				ld hl, ADDR_EIDI
				inc (hl)
				;push af
				;ld a, #c9
				;ld (adr_isr_intercept), a
				;pop af
				pop hl
				ret

PS_EI:			push af
				push hl
				ld hl, ADDR_EIDI
				dec (hl)
				ld a, (ADDR_EIDI)
				and a
				jr nz, PS_EIEND
				ei
				;ld a, #43
				;ld (adr_isr_intercept), a

PS_EIEND:		pop hl
				pop af
				ret

PS_CharIn:		call KEY_SCAN
				jr nz, PS_CharInNone
				call KEY_TEST
				jr nz, PS_CharInNone
				ld e, a
				ld c, 0
				ld d, 8
				call KEY_CODE
				and a
				ret
				
PS_CharInNone:				; return zero if no key or an error
				xor a
				ret

PS_CharOut:		;push af
				;ld a, 2		; select stream 2
				;call CHAN_OPEN
				;pop af
				rst 16			; print the character
				ret	
		
PS_CharWait:	call PS_CharIn
				jr z, PS_CharWait
				ret

PS_CommandLine:	ret				; get commandline parameters

PS_FileExists:	ret				; platform specific fileexists

PS_FileSize:	ret				; platform specific filesize

PS_FileDelete:	ret				; platform specific filedelete

PS_FileLoad:	ret				; platform specific fileload

PS_FileSave:	ret				; platform specific filesave

PS_StrInput:					; gets a string input
				ret	

PS_StrOutHL:					; outputs a string pointed to by HL
StrOutHL_Loop1:	
				ld a, (hl)	
				or a	
				jr z, StrOutHL_Loop1end	
				push hl	
				call SysCharOut
				pop hl	
				inc hl	
				jr StrOutHL_Loop1	
StrOutHL_Loop1end:	
				ret	
		
PS_Terminate:	ret				; terminate elegantly

ADDR_BUFFERS:

END_OF_LOADER:
