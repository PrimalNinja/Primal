;#dialect=RASM

								; WARNING NO CODE FROM HERE IN THIS FILE

								; patch data
TABLE_PATCH:	dw PATCHLEVEL1, PATCHLEVEL2, 0

				; API level, jumpblock size in bytes, address of jumpblock
PATCHLEVEL1:	dw 1, (END_JUMPBLOCKLEVEL1 - START_JUMPBLOCKLEVEL1), START_JUMPBLOCKLEVEL1
PATCHLEVEL2:	dw 2, (END_JUMPBLOCKLEVEL2 - START_JUMPBLOCKLEVEL2), START_JUMPBLOCKLEVEL2

JUMPBLOCK:						; jumpblock to be patched

START_JUMPBLOCKLEVEL1:				; API Level 1

SysDI:			jp 0
SysEI:			jp 0
SysError: 		jp 0

SysBuild:		jp 0
SysCheckPrimal:	jp 0
SysCommandLine:	jp 0
SysPropertyPC:	jp 0
SysRestore:		jp 0
SysSave:		jp 0
SysTerminate:	jp 0

SysCharIn:		jp 0
SysCharOut:		jp 0
SysCharWait:	jp 0
SysMathMinDEHL:	jp 0
SysStrCompare:	jp 0
SysStrInput:	jp 0
SysStrLen:		jp 0
SysStrOutHL:	jp 0
SysStrOutPC:	jp 0
SysStrSkip:		jp 0

SysFileDelete:	jp 0
SysFileExists:	jp 0
SysFileLoad:	jp 0
SysFileSave:	jp 0
SysFileSize:	jp 0

SysDecompress:	jp 0
SysDriverList:	jp 0
SysLDRPCFile:	jp 0
SysPatch:		jp 0
SysRelocate:	jp 0

SysMemTable:	jp 0
SysCopyBuffer: 	jp 0
SysCopyBufferSize: jp 0
SysHeapAddMemory: jp 0
SysHeapAlloc:	jp 0
SysHeapCreateNode: jp 0
SysHeapFree:	jp 0
SysHeapHeader:	jp 0
SysHeapInit:	jp 0
SysHeapRAMSize: jp 0
SysHeapSelect:	jp 0
SysHeapType:	jp 0

SysListAppend:	jp 0
SysListDelete:	jp 0
SysListInit:	jp 0
SysListLast:	jp 0
SysListPrepend:	jp 0
SysListSearch:	jp 0
SysListSort:	jp 0
SysListTraverse: jp 0

SysBankCount: 	jp 0
SysBank:		jp 0
SysBankEnd:		jp 0
SysBankSelect:	jp 0
SysBankSize:	jp 0
SysBankStart:	jp 0
SysBankUnSelect:jp 0
SysMemCopyF2F:	jp 0
SysMemCopyF2N:	jp 0
SysMemCopyN2F:	jp 0

END_JUMPBLOCKLEVEL1:

START_JUMPBLOCKLEVEL2:				; API Level 2

SysKeyIn:		jp PS_KeyIn
SysISRInit:		jp PS_ISRInit

SysAddDriver:	jp BIOS_AddDriver
SysGetDriver:	jp BIOS_GetDriver
SysLoadDriver:	jp BIOS_LoadDriver

END_JUMPBLOCKLEVEL2:

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

BIOS_AddDriver:	ret

BIOS_GetDriver:	ret

BIOS_LoadDriver:ret

Main:			ret	
