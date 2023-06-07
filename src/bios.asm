;#dialect=RASM

								; WARNING NO CODE FROM HERE IN THIS FILE

								; patch data
PatchTable:		dw PatchLevel1, PatchLevel2, 0

				; API level, jumpblock size in bytes, address of jumpblock
PatchLevel1:	dw 1, (JUMPBLOCKLEVEL1END - JUMPBLOCKLEVEL1), JUMPBLOCKLEVEL1
PatchLevel2:	dw 2, (JUMPBLOCKLEVEL2END - JUMPBLOCKLEVEL2), JUMPBLOCKLEVEL2

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
SysMemTable:	jp 0
SysPatch:		jp 0
SysPropertyPC:	jp 0
SysRAMSize:		jp 0
SysRelocate:	jp 0
SysStrCompare:	jp 0
SysStrLen:		jp 0
SysStrOutPC:	jp 0
SysStrSkip:		jp 0

SysBankCount:	jp 0
SysBankedRAMSize: jp 0
SysBankEnd:		jp 0
SysBankSelect:	jp 0
SysBankSize:	jp 0
SysBankStart:	jp 0
SysBankUnSelect:jp 0

JUMPBLOCKLEVEL1END:

JUMPBLOCKLEVEL2:				; API Level 2

SysKeyIn:		jp PS_KeyIn
SysISRInit:		jp PS_ISRInit

SysAddDriver:	jp BIOS_AddDriver
SysGetDriver:	jp BIOS_GetDriver
SysLoadDriver:	jp BIOS_LoadDriver

JUMPBLOCKLEVEL2END:

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

BIOS_AddDriver:	ret

BIOS_GetDriver:	ret

BIOS_LoadDriver:ret

Main:			ret	
