;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                   S Y M B O S   M A C R O   L I B R A R Y                  @
;@                            - SjAsmPlus Macros -                            @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author     NYYRIKKI
;Date       12.10.2021

; These macros have been testeed with SjAsmPlus v 1.18.3


;******************************************************************************
;*** Name           SIZE
;*** Input          String, lenght
;*** Output         Fixed size string padded with zeros
;******************************************************************************

           macro SIZE string,len
.start
             db string
             ds len -($-.start),0

           endm


;******************************************************************************
;*** Name           Graphic_Simple
;*** Input          X-size, Y-size
;*** Output         SymbOS Standard graphics header
;***                for CPC-style, 4-color graphics
;******************************************************************************

           macro Graphic_Simple x_val,y_val

@.X          equ x_val
@.Y          equ y_val
.XB          equ x_val/4
@.ByteCount  equ .XB*y_val
             db .XB,x_val,y_val
@.Data:
           endm

;******************************************************************************
;*** Name           Graphic_Extended
;*** Input          X-size, Y-size
;*** Output         SymbOS Extended graphics header
;***                for MSX-style, 16-color graphics
;******************************************************************************

           macro Graphic_Extended x_val,y_val

@.Offset     equ $ - Compile_Address
@.X          equ x_val
@.Y          equ y_val
.XB          equ x_val/2
@.ByteCount  equ .XB*y_val
             db .XB,x_val,y_val
             dw .Data,.Encoding,.ByteCount
@.Encoding:  db 5
@.Data:
           endm



