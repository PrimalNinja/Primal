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
				db "KERNEL", 0	; description

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
SysStrInput:	jp 0
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
SysDriverList:	jp 0
SysError: 		jp 0
SysHeapAlloc:	jp 0
SysHeapFree:	jp 0
SysHeapInit:	jp 0
SysHeapList:	jp 0
SysLDRPCFile:	jp 0
SysListAppend:	jp 0
SysListDelete:	jp 0
SysListInit:	jp 0
SysListPrepend:	jp 0
SysListSearch:	jp 0
SysListSort:	jp 0
SysListTraverse: jp 0
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

Main:			ret	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 6510 emulation

ret_ok:        equ  0               ; no error (space to exit)

zero_page:	   ds #ff				; 6502 zero page
stack_bottom:  ds 64             	; 6502 stack base MSB
stack_top:

Execute6502:   ex   de,hl           ; PC stays in DE throughout
               ld   iy,0            ; X=0, Y=0
               ld   ix,main_loop    ; decode loop after non-read/write

               ld   b,a             ; set A from Z80 A
               xor  a               ; clear carry
               ld   c,a             ; set Z, clear N
               ex   af,af'

               exx
               ld   hl,stack_top    ; 6502 stack pointer in HL'
               ld   d,%00000100     ; interrupts disabled
               ld   e,0             ; clear V
               exx

read_write_loop:
write_loop:    

main_loop:     push bc
			   ld   a,(de)          ; fetch opcode
               inc  de              ; PC=PC+1
               
			   ld l,a
			   ld h,0
			   add hl,hl
			   ld bc,decode_table
			   add hl,bc
			   
			   pop bc

               ld   a,(hl)          ; handler low
               inc  h
               ld   h,(hl)          ; handler high
               ld   l,a
               jp   (hl)            ; execute!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Instruction implementations

i_nop:         equ  main_loop
i_undoc_1:     equ  main_loop
i_undoc_3:     inc  de              ; 3-byte NOP
i_undoc_2:     inc  de              ; 2-byte NOP
               jp   (ix)


i_bpl:         inc  c
               dec  c
               jp   p,i_branch      ; branch if plus
               inc  de
               jp   (ix)

i_bmi:         inc  c
               dec  c
               jp   m,i_branch      ; branch if minus
               inc  de
               jp   (ix)

i_bvc:         exx
               bit  6,e
               exx
               jr   z,i_branch      ; branch if V clear
               inc  de
               jp   (ix)

i_bvs:         exx
               bit  6,e
               exx
               jr   nz,i_branch     ; branch if V set
               inc  de
               jp   (ix)

i_bcc:         ex   af,af'
               jr   nc,i_branch_ex  ; branch if C clear
               ex   af,af'
               inc  de
               jp   (ix)

i_bcs:         ex   af,af'
               jr   c,i_branch_ex   ; branch if C set
               ex   af,af'
               inc  de
               jp   (ix)

i_beq:         inc  c
               dec  c
               jr   z,i_branch      ; branch if zero
               inc  de
               jp   (ix)

i_bne:         inc  c
               dec  c
               jr   nz,i_branch     ; branch if not zero
               inc  de
               jp   (ix)

i_branch_ex:   ex   af,af'
i_branch:      ld   a,(de)
               inc  de
               ld   l,a             ; offset low
               rla                  ; set carry with sign
               sbc  a,a             ; form high byte for offset
               ld   h,a
               add  hl,de           ; PC=PC+e
               ex   de,hl
               jp   (ix)


i_jmp_a:       ex   de,hl           ; JMP nn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               jp   (ix)

i_jmp_i:       ex   de,hl           ; JMP (nn)
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               ex   de,hl
               ld   e,(hl)
               inc  l               ; 6502 bug wraps within page, *OR*
;              inc  hl              ; 65C02 spans pages correctly
               ld   d,(hl)
               jp   (ix)

i_jsr:         ex   de,hl           ; JSR nn
               ld   e,(hl)          ; subroutine low
               inc  hl              ; only 1 inc - we push ret-1
               ld   d,(hl)          ; subroutine high
               ld   a,h             ; PCh
               exx
               ld   (hl),a          ; push ret-1 high byte
               dec  l               ; S--
               exx
               ld   a,l             ; PCl
               exx
               ld   (hl),a          ; push ret-1 low byte
               dec  l               ; S--
               exx
               jp   (ix)

i_brk: ; fall through
i_rts:         exx                  ; RTS
               inc  l               ; S++
               ld   a,ret_ok
               ret  z               ; finish if stack empty
               ld   a,(hl)          ; PC LSB
               exx
               ld   e,a
               exx
               inc  l               ; S++
               ld   a,(hl)          ; PC MSB
               exx
               ld   d,a
               inc  de              ; PC++ (strange but true)
               jp   (ix)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

i_clc:         and  a               ; clear carry
               ex   af,af'
               jp   (ix)

i_sec:         scf                  ; set carry
               ex   af,af'
               jp   (ix)

i_cli:         exx                  ; clear interrupt disable
               res  2,d
               exx
               jp   (ix)

i_sei:         exx                  ; set interrupt disable
               set  2,d
               exx
               jp   (ix)

i_clv:         exx                  ; clear overflow
               ld   e,0
               exx
               jp   (ix)

i_cld:         exx                  ; clear decimal mode
               res  3,d
               exx
               xor  a               ; NOP
               ld   (adc_daa),a     ; use binary mode for adc
               ld   (sbc_daa),a     ; use binary mode for sbc
               jp   (ix)

i_sed:         exx                  ; set decimal mode
               set  3,d
               exx
               ld   a,#27           ; DAA
               ld   (adc_daa),a     ; use decimal mode for adc
               ld   (sbc_daa),a     ; use decimal mode for sbc
               jp   (ix)


i_rti:         exx
               inc  l               ; S++
               ld   a,ret_ok
               ret  z               ; finish if stack empty
               ld   a,(hl)          ; pop P
               ld   c,a             ; keep safe
               and  %00001100       ; keep D and I
               or   %00110000       ; force T and B
               ld   d,a             ; set P
               ld   a,c
               and  %01000000       ; keep V
               ld   e,a             ; set V
               ld   a,c
               rra                  ; carry from C
               ex   af,af'          ; set carry
               ld   a,c
               and  %10000010       ; keep N Z
               xor  %00000010       ; zero for Z
               exx
               ld   c,a             ; set N Z
               exx
               inc  l               ; S++
               ld   a,(hl)          ; pop return LSB
               exx
               ld   e,a             ; PCL
               exx
               inc  l               ; S++
               ld   a,(hl)          ; pop return MSB
               exx
               ld   d,a             ; PCH
               ex   af,af'
               inc  l               ; S++
               ld   a,(hl)          ; pop return MSB
               exx
               ld   d,a
               ex   af,af'
               ld   e,a
               pop  af              ; restore from above
               ex   af,af'          ; set A and flags
               jp   (ix)


i_php:         ex   af,af'          ; carry
               inc  c
               dec  c               ; set N Z
               push af              ; save flags
               ex   af,af'          ; protect carry
               exx
               pop  bc
               ld   a,c
               and  %10000001       ; keep Z80 N and C
               bit  6,c             ; check Z80 Z
               jr   z,php_nonzero
               or   %00000010       ; set Z
php_nonzero:   or   e               ; merge V
               or   d               ; merge T D I
               or   %00010000       ; B always pushed as 1
               ld   (hl),a
               dec  l               ; S--
               exx
               jp   (ix)

i_plp:         exx
               inc  l               ; S++
               ld   a,(hl)          ; pop P
               ld   c,a             ; keep safe
               and  %00001100       ; keep D and I
               or   %00110000       ; force T and B
               ld   d,a             ; set P
               ld   a,c
               and  %01000000       ; keep V
               ld   e,a             ; set V
               ld   a,c
               rra                  ; carry from C
               ex   af,af'          ; set carry
               ld   a,c
               and  %10000010       ; keep N Z
               xor  %00000010       ; zero for Z
               exx
               ld   c,a             ; set N Z
               jp   (ix)

i_pha:         ld   a,b             ; A
               exx
               ld   (hl),a          ; push A
               dec  l               ; S--
               exx
               jp   (ix)

i_pla:         exx                  ; PLA
               inc  l               ; S++
               ld   a,(hl)          ; pop A
               exx
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix)


i_dex:         dec  iyh             ; X--
               ld   c,iyh           ; set N Z
               jp   (ix)

i_dey:         dec  iyl             ; Y--
               ld   c,iyl           ; set N Z
               jp   (ix)

i_inx:         inc  iyh             ; X++
               ld   c,iyh           ; set N Z
               jp   (ix)

i_iny:         inc  iyl             ; Y++
               ld   c,iyl           ; set N Z
               jp   (ix)


i_txa:         ld   b,iyh           ; A=X
               ld   c,b             ; set N Z
               jp   (ix)

i_tya:         ld   b,iyl           ; A=Y
               ld   c,b             ; set N Z
               jp   (ix)

i_tax:         ld   iyh,b           ; X=A
               ld   c,b             ; set N Z
               jp   (ix)

i_tay:         ld   iyl,b           ; Y=A
               ld   c,b             ; set N Z
               jp   (ix)

i_txs:         ld   a,iyh           ; X
               exx
               ld   l,a             ; set S (no flags set)
               exx
               jp   (ix)

i_tsx:         exx
               ld   a,l             ; S
               exx
               ld   iyh,a           ; X=S
               ld   c,a             ; set N Z
               jp   (ix)


i_lda_ix:      ld   a,(de)          ; LDA ($nn,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               ld   b,(hl)          ; set A
               ld   c,b             ; set N Z
               jp   (ix) ; zread_loop

i_lda_z:       ld   a,(de)          ; LDA $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   b,(hl)          ; set A
               ld   c,b             ; set N Z
               jp   (ix) ; zread_loop

i_lda_a:       ex   de,hl           ; LDA $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   b,(hl)          ; set A
               ld   c,b             ; set N Z
               jp   (ix) ; read_loop

i_lda_iy:      ld   a,(de)          ; LDA ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l               ; (may wrap in zero page)
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               ld   b,(hl)          ; set A
               ld   c,b             ; set N Z
               jp   (ix) ; read_loop

i_lda_zx:      ld   a,(de)          ; LDA $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   b,(hl)          ; set A
               ld   c,b             ; set N Z
               jp   (ix) ; zread_loop

i_lda_ay:      ld   a,(de)          ; LDA $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   b,(hl)          ; set A
               ld   c,b             ; set N Z
               jp   (ix) ; read_loop

i_lda_ax:      ld   a,(de)          ; LDA $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   b,(hl)          ; set A
               ld   c,b             ; set N Z
               jp   (ix) ; read_loop

i_lda_i:       ld   a,(de)          ; LDA #$nn
               inc  de
               ld   b,a             ; set A
               ld   c,b             ; set N Z
               jp   (ix)


i_ldx_z:       ld   a,(de)          ; LDX $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   c,(hl)          ; set N Z
               ld   iyh,c           ; set X
               jp   (ix) ; zread_loop

i_ldx_a:       ex   de,hl           ; LDX $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   c,(hl)          ; set N Z
               ld   iyh,c           ; set X
               jp   (ix) ; read_loop

i_ldx_zy:      ld   a,(de)          ; LDX $nn,Y
               inc  de
               add  a,iyl           ; add Y (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   c,(hl)          ; set N Z
               ld   iyh,c           ; set X
               jp   (ix) ; zread_loop

i_ldx_ay:      ld   a,(de)          ; LDX $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   c,(hl)          ; set N Z
               ld   iyh,c           ; set X
               jp   (ix) ; read_loop

i_ldx_i:       ld   a,(de)          ; LDX #$nn
               inc  de
               ld   iyh,a           ; set X
               ld   c,a             ; set N Z
               jp   (ix)


i_ldy_z:       ld   a,(de)          ; LDY $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   c,(hl)          ; set N Z
               ld   iyl,c           ; set Y
               jp   (ix) ; zread_loop

i_ldy_a:       ex   de,hl           ; LDY $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   c,(hl)          ; set N Z
               ld   iyl,c           ; set Y
               jp   (ix) ; read_loop

i_ldy_zx:      ld   a,(de)          ; LDY $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   c,(hl)          ; set N Z
               ld   iyl,c           ; set Y
               jp   (ix) ; zread_loop

i_ldy_ax:      ld   a,(de)          ; LDY $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   c,(hl)          ; set N Z
               ld   iyl,c           ; set Y
               jp   (ix) ; read_loop

i_ldy_i:       ld   a,(de)          ; LDY #$nn
               inc  de
               ld   c,a             ; set N Z
               ld   iyl,c           ; set Y
               jp   (ix)


i_sta_ix:      ld   a,(de)          ; STA ($xx,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               ld   (hl),b          ; store A
               jp   (ix) ; zwrite_loop

i_sta_z:       ld   a,(de)          ; STA $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   (hl),b          ; store A
               jp   (ix) ; zwrite_loop

i_sta_iy:      ld   a,(de)          ; STA ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               ld   (hl),b          ; store A
               jp   write_loop

i_sta_zx:      ld   a,(de)          ; STA $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   (hl),b          ; store A
               jp   (ix) ; zwrite_loop

i_sta_ay:      ld   a,(de)          ; STA $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   (hl),b          ; store A
               jp   write_loop

i_sta_ax:      ld   a,(de)          ; STA $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   (hl),b          ; store A
               jp   write_loop

i_sta_a:       ex   de,hl           ; STA $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   (hl),b          ; store A
               jp   write_loop


i_stx_z:       ld   a,(de)          ; STX $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyh           ; X
               ld   (hl),a
               jp   (ix) ; zwrite_loop

i_stx_zy:      ld   a,(de)          ; STX $nn,Y
               inc  de
               add  a,iyl           ; add Y (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyh           ; X
               ld   (hl),a
               jp   (ix) ; zwrite_loop

i_stx_a:       ex   de,hl           ; STX $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   a,iyh           ; X
               ld   (hl),a
               jp   write_loop


i_sty_z:       ld   a,(de)          ; STY $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               ld   (hl),a
               jp   (ix) ; zwrite_loop

i_sty_zx:      ld   a,(de)          ; STY $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               ld   (hl),a
               jp   (ix) ; zwrite_loop

i_sty_a:       ex   de,hl           ; STY $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   a,iyl           ; Y
               ld   (hl),a
               jp   write_loop


i_stz_zx:      ld   a,(de)          ; STZ $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   (hl),h
               jp   (ix) ; zwrite_loop

i_stz_ax:      ld   a,(de)          ; STZ $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   (hl),0
               jp   write_loop

i_stz_a:       ex   de,hl           ; STZ $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   (hl),0
               jp   write_loop


i_adc_ix:      ld   a,(de)          ; ADX ($xx,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               jp   i_adc

i_adc_z:       ld   a,(de)          ; ADC $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               jp   i_adc

i_adc_a:       ex   de,hl           ; ADC $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               jp   i_adc

i_adc_zx:      ld   a,(de)          ; ADC $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               jp   i_adc

i_adc_ay:      ld   a,(de)          ; ADC $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               jp   i_adc

i_adc_ax:      ld   a,(de)          ; ADC $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               jp   i_adc

i_adc_iy:      ld   a,(de)          ; ADC ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l               ; (may wrap in zero page)
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               jp   i_adc

i_adc_i:       ld   h,d
               ld   l,e
               inc  de
i_adc:         ex   af,af'          ; carry
               ld   a,b             ; A
               adc  a,(hl)          ; A+M+C
adc_daa:       nop
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               exx
               jp   pe,adcsbc_v
               ld   e,%00000000
               exx
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop
adcsbc_v:      ld   e,%01000000
               exx
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop


i_sbc_ix:      ld   a,(de)          ; SBC ($xx,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               jp   i_sbc

i_sbc_z:       ld   a,(de)          ; SBC $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               jp   i_sbc

i_sbc_a:       ex   de,hl           ; SBC $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               jp   i_sbc

i_sbc_zx:      ld   a,(de)          ; SBC $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               jp   i_sbc

i_sbc_ay:      ld   a,(de)          ; SBC $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               jp   i_sbc

i_sbc_ax:      ld   a,(de)          ; SBC $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               jp   i_sbc

i_sbc_iy:      ld   a,(de)          ; SBC ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l               ; (may wrap in zero page)
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               jp   i_sbc

i_sbc_i:       ld   h,d
               ld   l,e
               inc  de
i_sbc:         ex   af,af'          ; carry
               ccf                  ; uses inverted carry
               ld   a,b
               sbc  a,(hl)          ; A-M-(1-C)
sbc_daa:       nop
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               ccf                  ; no carry for overflow
               exx
               jp   pe,adcsbc_v
               ld   e,%00000000
               exx
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop


i_and_ix:      ld   a,(de)          ; AND ($xx,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_and_z:       ld   a,(de)          ; AND $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_and_a:       ex   de,hl           ; AND $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_and_zx:      ld   a,(de)          ; AND $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_and_ay:      ld   a,(de)          ; AND $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_and_ax:      ld   a,(de)          ; AND $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_and_iy:      ld   a,(de)          ; AND ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l               ; (may wrap in zero page)
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_and_i:       ld   h,d
               ld   l,e
               inc  de
               ld   a,b             ; A
               and  (hl)            ; A#x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop


i_eor_ix:      ld   a,(de)          ; EOR ($xx,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_eor_z:       ld   a,(de)          ; EOR $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_eor_a:       ex   de,hl           ; EOR $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_eor_zx:      ld   a,(de)          ; EOR $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_eor_ay:      ld   a,(de)          ; EOR $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_eor_ax:      ld   a,(de)          ; EOR $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_eor_iy:      ld   a,(de)          ; EOR ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l               ; (may wrap in zero page)
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_eor_i:       ld   h,d
               ld   l,e
               inc  de
               ld   a,b             ; A
               xor  (hl)            ; A^x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop


i_ora_ix:      ld   a,(de)          ; ORA ($xx,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_ora_z:       ld   a,(de)          ; ORA $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_ora_a:       ex   de,hl           ; ORA $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_ora_zx:      ld   a,(de)          ; ORA $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_ora_ay:      ld   a,(de)          ; ORA $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_ora_ax:      ld   a,(de)          ; ORA $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_ora_iy:      ld   a,(de)          ; ORA ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l               ; (may wrap in zero page)
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop

i_ora_i:       ld   h,d
               ld   l,e
               inc  de
               ld   a,b             ; A
               or   (hl)            ; A|x
               ld   b,a             ; set A
               ld   c,a             ; set N Z
               jp   (ix) ; read_loop


i_cmp_ix:      ld   a,(de)          ; CMP ($xx,X)
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,(hl)
               inc  hl
               ld   h,(hl)
               ld   l,a
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cmp_z:       ld   a,(de)          ; CMP $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cmp_a:       ex   de,hl           ; CMP $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cmp_zx:      ld   a,(de)          ; CMP $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cmp_ay:      ld   a,(de)          ; CMP $nnnn,Y
               inc  de
               add  a,iyl           ; add Y
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cmp_ax:      ld   a,(de)          ; CMP $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cmp_iy:      ld   a,(de)          ; CMP ($nn),Y
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ld   a,iyl           ; Y
               add  a,(hl)
               inc  l               ; (may wrap in zero page)
               ld   h,(hl)
               ld   l,a
               adc  a,h
               sub  l
               ld   h,a
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cmp_i:       ld   h,d
               ld   l,e
               inc  de
               ex   af,af'          ; carry
               ld   a,b             ; A
               sub  (hl)            ; A-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop


i_cpx_z:       ld   a,(de)          ; CPX $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'          ; carry
               ld   a,iyh           ; X
               sub  (hl)            ; X-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cpx_a:       ex   de,hl           ; CPX $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ex   af,af'          ; carry
               ld   a,iyh           ; X
               sub  (hl)            ; X-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cpx_i:       ld   h,d
               ld   l,e
               inc  de
               ex   af,af'          ; carry
               ld   a,iyh           ; X
               sub  (hl)            ; X-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop


i_cpy_z:       ld   a,(de)          ; CPY $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'          ; carry
               ld   a,iyl           ; Y
               sub  (hl)            ; Y-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cpy_a:       ex   de,hl           ; CPY $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ex   af,af'          ; carry
               ld   a,iyl           ; Y
               sub  (hl)            ; Y-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop

i_cpy_i:       ld   h,d
               ld   l,e
               inc  de
               ex   af,af'          ; carry
               ld   a,iyl           ; Y
               sub  (hl)            ; Y-x (result discarded)
               ld   c,a             ; set N Z
               ccf
               ex   af,af'          ; set carry
               jp   (ix) ; read_loop


i_dec_z:       ld   a,(de)          ; DEC $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               dec  (hl)            ; zero-page--
               ld   c,(hl)          ; set N Z
               jp   (ix) ; zread_write_loop

i_dec_zx:      ld   a,(de)          ; DEC $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               dec  (hl)            ; zero-page--
               ld   c,(hl)          ; set N Z
               jp   (ix) ; zread_write_loop

i_dec_a:       ex   de,hl           ; DEC $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               dec  (hl)            ; mem--
               ld   c,(hl)          ; set N Z
               jp   read_write_loop

i_dec_ax:      ld   a,(de)          ; DEC $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               dec  (hl)            ; mem--
               ld   c,(hl)          ; set N Z
               jp   read_write_loop


i_inc_z:       ld   a,(de)          ; INC $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               inc  (hl)            ; zero-page++
               ld   c,(hl)          ; set N Z
               jp   (ix) ; zread_write_loop

i_inc_zx:      ld   a,(de)          ; INC $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               inc  (hl)            ; zero-page++
               ld   c,(hl)          ; set N Z
               jp   (ix) ; zread_write_loop

i_inc_a:       ex   de,hl           ; INC $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               inc  (hl)            ; mem++
               ld   c,(hl)          ; set N Z
               jp   read_write_loop

i_inc_ax:      ld   a,(de)          ; INC $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               inc  (hl)            ; mem++
               ld   c,(hl)          ; set N Z
               jp   read_write_loop


i_asl_z:       ld   a,(de)          ; ASL $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               sla  (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_asl_zx:      ld   a,(de)          ; ASL $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               sla  (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_asl_a:       ex   de,hl           ; ASL $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ex   af,af'
               sla  (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_asl_ax:      ld   a,(de)          ; ASL $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ex   af,af'
               sla  (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_asl_acc:     ex   af,af'
               sla  b               ; A << 1
               ld   c,b             ; set N Z
               ex   af,af'          ; set carry
               jp   (ix)


i_lsr_z:       ld   a,(de)          ; LSR $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               srl  (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_lsr_zx:      ld   a,(de)          ; LSR $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               srl  (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_lsr_a:       ex   de,hl           ; LSR $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ex   af,af'
               srl  (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_lsr_ax:      ld   a,(de)          ; LSR $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ex   af,af'
               srl  (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_lsr_acc:     ex   af,af'
               srl  b               ; A >> 1
               ld   c,b             ; set N Z
               ex   af,af'          ; set carry
               jp   (ix)


i_rol_z:       ld   a,(de)          ; ROL $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               rl   (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_rol_zx:      ld   a,(de)          ; ROL $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               rl   (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_rol_a:       ex   de,hl           ; ROL $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ex   af,af'
               rl   (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_rol_ax:      ld   a,(de)          ; ROL $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ex   af,af'
               rl   (hl)            ; x << 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_rol_acc:     ex   af,af'
               rl   b
               ld   c,b             ; set N Z
               ex   af,af'          ; set carry
               jp   (ix)


i_ror_z:       ld   a,(de)          ; ROR $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               rr   (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_ror_zx:      ld   a,(de)          ; ROR $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               ex   af,af'
               rr   (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_ror_a:       ex   de,hl           ; ROR $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               ex   af,af'
               rr   (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_ror_ax:      ld   a,(de)          ; ROR $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               ex   af,af'
               rr   (hl)            ; x >> 1
               ld   c,(hl)          ; set N Z
               ex   af,af'          ; set carry
               jp   write_loop

i_ror_acc:     ex   af,af'
               rr   b
               ld   c,b             ; set N Z
               ex   af,af'          ; set carry
               jp   (ix)


i_bit_z:       ld   a,(de)          ; BIT $nn
               inc  de
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               jp   i_bit

i_bit_zx:      ld   a,(de)          ; BIT $nn,X
               inc  de
               add  a,iyh           ; add X (may wrap in zero page)
               ;ld   l,a
               ;ld   h,zero_page_msb
			   ld hl,zero_page
			   ld c,a
			   ld b,0
			   add hl,bc
               jp   i_bit

i_bit_a:       ex   de,hl           ; BIT $nnnn
               ld   e,(hl)
               inc  hl
               ld   d,(hl)
               inc  hl
               ex   de,hl
               jp   i_bit

i_bit_ax:      ld   a,(de)          ; BIT $nnnn,X
               inc  de
               add  a,iyh           ; add X
               ld   l,a
               ld   a,(de)
               inc  de
               adc  a,0
               ld   h,a
               jp   i_bit

i_bit_i:       ld   h,d             ; BIT #$nn
               ld   l,e
               inc  de
i_bit:         ld   c,(hl)          ; x
               ld   a,c
               and  %01000000       ; V flag from bit 6 of x
               exx
               ld   e,a             ; set V
               exx
               ld   a,(de)
               and  %11011111
               cp   #d0             ; BNE or BEQ next?
               jr   z,bit_setz
               ld   c,(hl)          ; set N
               jp   (ix) ; read_loop
bit_setz:      ld   a,b             ; A
               and  c               ; perform BIT test
               ld   c,a             ; set Z
               jp   (ix) ; read_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

decode_table:  defw i_brk,i_ora_ix,i_undoc_1,i_undoc_2     ; 00
               defw i_undoc_1,i_ora_z,i_asl_z,i_undoc_2    ; 04
               defw i_php,i_ora_i,i_asl_acc,i_undoc_2      ; 08
               defw i_undoc_3,i_ora_a,i_asl_a,i_undoc_2    ; 0C

               defw i_bpl,i_ora_iy,i_undoc_2,i_undoc_2     ; 10
               defw i_undoc_1,i_ora_zx,i_asl_zx,i_undoc_2  ; 14
               defw i_clc,i_ora_ay,i_undoc_1,i_undoc_3     ; 18
               defw i_undoc_3,i_ora_ax,i_asl_ax,i_undoc_2  ; 1C

               defw i_jsr,i_and_ix,i_undoc_1,i_undoc_2     ; 20
               defw i_bit_z,i_and_z,i_rol_z,i_undoc_2      ; 24
               defw i_plp,i_and_i,i_rol_acc,i_undoc_2      ; 28
               defw i_bit_a,i_and_a,i_rol_a,i_undoc_2      ; 2C

               defw i_bmi,i_and_iy,i_undoc_2,i_undoc_2     ; 30
               defw i_bit_zx,i_and_zx,i_rol_zx,i_undoc_2   ; 34
               defw i_sec,i_and_ay,i_undoc_1,i_undoc_3     ; 38
               defw i_bit_ax,i_and_ax,i_rol_ax,i_undoc_2   ; 3C

               defw i_rti,i_eor_ix,i_undoc_1,i_undoc_2     ; 40
               defw i_undoc_2,i_eor_z,i_lsr_z,i_undoc_2    ; 44
               defw i_pha,i_eor_i,i_lsr_acc,i_undoc_2      ; 48
               defw i_jmp_a,i_eor_a,i_lsr_a,i_undoc_2      ; 4C

               defw i_bvc,i_eor_iy,i_undoc_2,i_undoc_2     ; 50
               defw i_undoc_2,i_eor_zx,i_lsr_zx,i_undoc_2  ; 54
               defw i_cli,i_eor_ay,i_undoc_1,i_undoc_3     ; 58
               defw i_undoc_3,i_eor_ax,i_lsr_ax,i_undoc_2  ; 5C

               defw i_rts,i_adc_ix,i_undoc_1,i_undoc_2     ; 60
               defw i_undoc_2,i_adc_z,i_ror_z,i_undoc_2    ; 64
               defw i_pla,i_adc_i,i_ror_acc,i_undoc_2      ; 68
               defw i_jmp_i,i_adc_a,i_ror_a,i_undoc_2      ; 6C

               defw i_bvs,i_adc_iy,i_undoc_2,i_undoc_2     ; 70
               defw i_stz_zx,i_adc_zx,i_ror_zx,i_undoc_2   ; 74
               defw i_sei,i_adc_ay,i_undoc_1,i_undoc_3     ; 78
               defw i_undoc_3,i_adc_ax,i_ror_ax,i_undoc_2  ; 7C

               defw i_undoc_2,i_sta_ix,i_undoc_2,i_undoc_2 ; 80
               defw i_sty_z,i_sta_z,i_stx_z,i_undoc_2      ; 84
               defw i_dey,i_bit_i,i_txa,i_undoc_2          ; 88
               defw i_sty_a,i_sta_a,i_stx_a,i_undoc_2      ; 8C

               defw i_bcc,i_sta_iy,i_undoc_2,i_undoc_2     ; 90
               defw i_sty_zx,i_sta_zx,i_stx_zy,i_undoc_2   ; 94
               defw i_tya,i_sta_ay,i_txs,i_undoc_2         ; 98
               defw i_stz_a,i_sta_ax,i_stz_ax,i_undoc_2    ; 9C

               defw i_ldy_i,i_lda_ix,i_ldx_i,i_undoc_2     ; A0
               defw i_ldy_z,i_lda_z,i_ldx_z,i_undoc_2      ; A4
               defw i_tay,i_lda_i,i_tax,i_undoc_2          ; A8
               defw i_ldy_a,i_lda_a,i_ldx_a,i_undoc_2      ; AC

               defw i_bcs,i_lda_iy,i_undoc_2,i_undoc_2     ; B0
               defw i_ldy_zx,i_lda_zx,i_ldx_zy,i_undoc_2   ; B4
               defw i_clv,i_lda_ay,i_tsx,i_undoc_3         ; B8
               defw i_ldy_ax,i_lda_ax,i_ldx_ay,i_undoc_2   ; BC

               defw i_cpy_i,i_cmp_ix,i_undoc_2,i_undoc_2   ; C0
               defw i_cpy_z,i_cmp_z,i_dec_z,i_undoc_2      ; C4
               defw i_iny,i_cmp_i,i_dex,i_undoc_1          ; C8
               defw i_cpy_a,i_cmp_a,i_dec_a,i_undoc_2      ; CC

               defw i_bne,i_cmp_iy,i_undoc_2,i_undoc_2     ; D0
               defw i_undoc_2,i_cmp_zx,i_dec_zx,i_undoc_2  ; D4
               defw i_cld,i_cmp_ay,i_undoc_1,i_undoc_1     ; D8
               defw i_undoc_3,i_cmp_ax,i_dec_ax,i_undoc_2  ; DC

               defw i_cpx_i,i_sbc_ix,i_undoc_2,i_undoc_2   ; E0
               defw i_cpx_z,i_sbc_z,i_inc_z,i_undoc_2      ; E4
               defw i_inx,i_sbc_i,i_nop,i_undoc_2          ; E8
               defw i_cpx_a,i_sbc_a,i_inc_a,i_undoc_2      ; EC

               defw i_beq,i_sbc_iy,i_undoc_2,i_undoc_2     ; F0
               defw i_undoc_2,i_sbc_zx,i_inc_zx,i_undoc_2  ; F4
               defw i_sed,i_sbc_ay,i_undoc_1,i_undoc_3     ; F8
               defw i_undoc_3,i_sbc_ax,i_inc_ax,i_undoc_2  ; FC

RelocationTable:
				dw relocate_count
				relocate_table
				relocate_end

RELOC_END:
