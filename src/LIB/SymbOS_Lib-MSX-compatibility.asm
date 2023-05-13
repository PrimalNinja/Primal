

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@     S Y M B O S   M S X - C O M P A T I B I L I T Y   L I B R A R Y        @
;@                       - ADDITIONAL SYMSHELL LIBRARY -                      @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;Author     NYYRIKKI
;Date       31.10.2021

; This library tries to make it more easy to port MSX-BIOS / MSX-DOS2 programs
; for SymbOS shell.

; These routines are only supporting most used calls and the functionality
; is not identical to original. Character output routines don't emulate
; VT-52, but use SymbOS control codes instead... So These are more like
; light weight "look alike" routines made to make porting commandline apps
; bit more easy, but not automatic. Make sure you understand the differences
; before using. By defalt I've commented out the disk routines to make
; sure you understand the differences first. Feel free to expand / modify
; to fit to your own needs.
;
; You can output single chraracters on SymbOS just like on MSX-BIOS, but
; practically printing lots of single characters same way as lots of BIOS
; using applications do will flood the messaging system so that the output
; becomes really slow. This is why we introduce a buffer instead. The down
; side of this approach is that if you stop making character I/O you need
; to manually call FLUSH_CHAR_BUFFER in order to print remaining characters
; from buffer to screen.

  DEFINE CHAR_BUFFER_IN_USE

CHAR_BUFFER_SIZE: EQU 64

FLUSH_CHAR_BUFFER:

	PUSH AF
	PUSH HL

        LD HL,MSX_CHAR_BUFFER
        LD A,(HL)
        AND A
        CALL NZ,.PRINT

	POP HL
	POP AF
	RET

.PRINT
        PUSH HL
	PUSH DE
	PUSH BC
        call SyShell_STROUT0
        POP BC
        POP DE
        POP HL

        LD (MSX_CHAR_LOCATION),HL
        LD (HL),0
        LD A,CHAR_BUFFER_SIZE
        LD (MSX_CHAR_COUNT),A

        RET


MSX_CHAR_LOCATION:  DW MSX_CHAR_BUFFER
MSX_CHAR_COUNT:     DB CHAR_BUFFER_SIZE
MSX_CHAR_BUFFER:    DS CHAR_BUFFER_SIZE

CHGET:
	PUSH HL
	PUSH DE
	PUSH BC
        CALL FLUSH_CHAR_BUFFER

        CALL SyShell_CHRINP0

        POP BC
        POP DE
	POP HL
	AND A
	RET


CLS:    ld a,12

OUTDO:
CHPUT:
        PUSH AF
        PUSH HL

        LD HL,(MSX_CHAR_LOCATION)
        LD (HL),A
        INC HL
        LD (HL),0
        LD (MSX_CHAR_LOCATION),HL

        LD HL,MSX_CHAR_COUNT
        DEC (HL)
        CALL Z,FLUSH_CHAR_BUFFER

        POP HL
        POP AF
        RET

POSIT:
        ; In SymShell 2.0 and older there are bugs handling multi byte
        ; control codes... This is why this routine looks a bit funny.

        call FLUSH_CHAR_BUFFER ; Going around bug
        ld a,27
        call OUTDO      ; Going around bug
        ld a,31
        call OUTDO
        ld a,h
        call OUTDO
        ld a,l
        call OUTDO
        ld a,27
        call OUTDO      ; Going around bug
        ret

DCOMPR: ; You need to replace RST with CALL
        ; You may also consider using:
        ; or a : sbc hl,de : add hl,de

        ld      a,h
        sub     d
        ret     nz
        ld      a,l
        sub     e
        ret

QINLIN:
        ld      a,"?"
        call    OUTDO
        ld      a," "
        call    OUTDO
PINLIN:
INLIN:
        call FLUSH_CHAR_BUFFER
        ld hl,MSX_Input_Buffer
        call SyShell_STRINP0
        ld hl,MSX_Input_Buffer-1
        ret

MSX_Input_Buffer:
        ds 256


        ifused BDOS
BDOS:
           ld a,c
           and a
           jr z,.EXIT
           dec a ;#1
           jr z,.Console_Input
           dec a ;#2
           jr z,.Console_Output
           sub    #9-#2
           jr z,.String_Output
           dec a ;#A
           jr z,.String_Input
/*
           sub    #40-#A
           jp z,.FIND_FIRST_ENTRY
           dec a ;#41
           jp z,.FIND_NEXT_ENTRY
           dec a ;#42
           dec a ;#43
           jp z,.OPEN_FILE_HANDLE
           dec a ;#44
           dec a ;#45
           jp z,.CLOSE_FILE_HANDLE
           sub    #48-#45
           jp z,.READ_FROM_FILE_HANDLE
           dec a ;#49
           jp z,.WRITE_TO_FILE_HANDLE:
*/
           ; Not supported, print warning.
           ld de,.BDOS_NUM
           ld a,c
	   call .Num1
	   ld a,c
	   call .Num2
           ld hl,.BDOS_WARNING
           call FLUSH_CHAR_BUFFER
           jp SyShell_STROUT0

.Num1	   rra
	   rra
	   rra
	   rra
.Num2	   or #f0
	   daa
	   add a,#A0
	   adc a,#40
	   ld (de),a
	   inc de
	   ret


.EXIT:
           call FLUSH_CHAR_BUFFER
           ld e,0
           call SyShell_EXIT
           jp SySystem_EXIT
.Console_Input:
           call CHGET
           ld l,a
           ret
.Console_Output:
           ld a,e
           jp CHPUT
.String_Output:
           ld a,(de)
           cp "$"
           ret z
           call CHPUT
           inc de
           jr .String_Output
.String_Input:
           ex de,hl
           inc hl
           inc hl
           push hl
           call FLUSH_CHAR_BUFFER
           call SyShell_STRINP0
           pop hl
           push hl
           ld b,2
           xor a
           cpir
           dec hl
           ld (hl),13
           xor a
           pop de
           push de
           sbc hl,de
           ld a,l
           pop hl
           dec hl
           ld (hl),a
           ret

/*
.FIND_FIRST_ENTRY
           push ix
           pop hl
           ex de,hl
           ld ixl,b
           ld iy,0
           ld (.FIND_FILE_COUNT),IY
           ld bc,255
           ld a,(App_Bank_Number)
           ld ixh,a
           jp SyFile_DIRINP

.FIND_NEXT_ENTRY
           push ix
           pop hl
           ex de,hl
           ld ixl,b
           ld iy,0
.FIND_FILE_COUNT: EQU $-2
           inc iy
           ld (.FIND_FILE_COUNT),IY
           ld bc,255
           ld a,(App_Bank_Number)
           ld ixh,a
           jp SyFile_DIRINP

.OPEN_FILE_HANDLE
           ld a,(App_Bank_Number)
           ld ixh,a
           ex de,hl
           ld a,b
           call SyFile_FILOPN
           ld b,a
           ret

.CREATE_FILE_HANDLE:
           ld a,(App_Bank_Number)
           ld ixh,a
           ex de,hl
           ld a,b
           call SyFile_FILNEW
           ld b,a
           ret

.CLOSE_FILE_HANDLE:
           ld a,b
           jp SyFile_FILCLO

.READ_FROM_FILE_HANDLE
           push hl
           ld a,(App_Bank_Number)
           ld l,a
           ld a,b
           pop bc
           ex de,hl
           call SyFile_FILINP
           push bc
           pop hl
           ret

.WRITE_TO_FILE_HANDLE:
           push hl
           ld a,(App_Bank_Number)
           ld l,a
           ld a,b
           pop bc
           ex de,hl
           call SyFile_FILOUT
           push bc
           pop hl
           ret
*/

.BDOS_WARNING:
           db 10,13,"!!! Unsupported BDOS call #"
.BDOS_NUM: db "  ",10,13,0

        endif ; BDOS
