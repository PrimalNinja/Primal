;#dialect=RASM

BUILD_ADDR		equ #0000
ALLOCSIZE		equ 0

				org BUILD_ADDR
				relocate_start

								; WARNING NO CODE FROM HERE IN THIS FILE

RELOC_START:	jp Main			; jump to entry point

								; header
				dw RelocationTable - RELOC_START
				dw BUILD_ADDR
				dw ALLOCSIZE	; allocate this amount of ram after loading this module so it isn't stored in the binary, usually it overwrites the relocation table
				dw 1			; version
				dw 1			; API compatability ID
				db 1			; required memory type
				dw PatchTable
				dw JumpBlock	; pointer to the jumpblock
				dw 0			; pointer to the ISR
				dw 0			; pointer to the component that loaded this
				db "PRIMAL", 0	; type must be after the jump to main
				db "SHELL", 0	; description

								; patch data
								
PatchTable:		dw PatchLevel1, PatchLevel2, PatchLevel3, 0

				; API level, jumpblock size in bytes, address of jumpblock
PatchLevel1:	dw 1, (JUMPBLOCKLEVEL1END - JUMPBLOCKLEVEL1), JUMPBLOCKLEVEL1
PatchLevel2:	dw 2, (JUMPBLOCKLEVEL2END - JUMPBLOCKLEVEL2), JUMPBLOCKLEVEL2
PatchLevel3:	dw 3, (JUMPBLOCKLEVEL3END - JUMPBLOCKLEVEL3), JUMPBLOCKLEVEL3

JumpBlock:						; jumpblock to be patched

JUMPBLOCKLEVEL1:				; API Level 1

SysCharIn:		jp 0
SysCharOut:		jp 0
SysCharWait:	jp 0
SysDI:			jp 0
SysEI:			jp 0
SysFileDelete:	jp 0
SysFileExists:	jp 0
SysFileLoad:	jp 0
SysFileSave:	jp 0
SysFileSize:	jp 0
SysStrIn:		jp 0
SysStrOutHL:	jp 0
SystemRestore:	jp 0
SystemSave:		jp 0
SysTerminate:	jp 0

SysBuild:		jp 0
SysCheckPrimal:	jp 0
SysCommandLine:	jp 0
SysCopyBuffer: 	jp 0
SysCopyBufferSize: jp 0
SysDecompress:	jp 0
SysError: 		jp 0
SysLDRPCFile:	jp 0
SysMathMinDEHL:	jp 0
SysMemTable:	jp 0
SysPatch:		jp 0
SysPropertyPC:	jp 0
SysRAMSize:		jp 0
SysRelocate:	jp 0
SysStrCompare:	jp 0
SysStrLen:		jp 0
SysStrOutPC:	jp 0
SysStrSkip:		jp 0

SysBank:		jp 0
SysBankCount:	jp 0
SysBankedRAMSize: jp 0
SysBankEnd:		jp 0
SysBankSelect:	jp 0
SysBankSize:	jp 0
SysBankStart:	jp 0
SysBankUnSelect:jp 0
SysMemCopyF2F:	jp 0
SysMemCopyF2N:	jp 0
SysMemCopyN2F:	jp 0

JUMPBLOCKLEVEL1END:

JUMPBLOCKLEVEL2:				; API Level 2

SysKeyIn:		jp 0
SysISRInit:		jp 0

SysAddDriver:	jp 0
SysGetDriver:	jp 0
SysLoadDriver:	jp 0

JUMPBLOCKLEVEL2END:

JUMPBLOCKLEVEL3:				; API Level 3

SysExecute6502:	jp 0

JUMPBLOCKLEVEL3END:

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

Main:			call SysStrOutPC
				db "Hello, World!", 0	
				call SysTerminate
				ret	

RelocationTable:
				dw relocate_count
				relocate_table
				relocate_end

RELOC_END:
