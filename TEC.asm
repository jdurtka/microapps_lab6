
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 6 - LM92 on i2c bus
;
;*******************************************************************

           INCLUDE 'derivative.inc' 

			XDEF tec_setup
           	XDEF tec_disp_state
           	XDEF tec_change_state
           	XDEF TEC_STATE
           	XREF _update_LEDs

			XREF rtc_reset_secs
           
           ;XREF LCD_Display_Byte_Hex
           XREF LCD_Write_Char

MY_ZEROPAGE: SECTION  SHORT
	TEC_STATE: DC.B 1
			
MyCode:     SECTION

tec_setup:
	LDA #$00
	STA TEC_STATE
	RTS

tec_disp_state:
	LDA TEC_STATE
	CMP #$00
	BEQ _dispoff
	DECA
	BEQ _dispheat
	DECA
	BEQ _dispcool
	BRA _disperr
	
	_dispoff:
		LDA #$6F	;o
		JSR LCD_Write_Char
		LDA #$66	;f
		JSR LCD_Write_Char
		LDA #$66	;f
		JSR LCD_Write_Char
		RTS
	_dispheat:
		LDA #$68	;h
		JSR LCD_Write_Char
		LDA #$65	;e
		JSR LCD_Write_Char
		LDA #$61	;a
		JSR LCD_Write_Char
		LDA #$74	;t
		JSR LCD_Write_Char
		RTS
	_dispcool:
		LDA #$63	;c
		JSR LCD_Write_Char
		LDA #$6F	;o
		JSR LCD_Write_Char
		LDA #$6F	;o
		JSR LCD_Write_Char
		LDA #$6C	;l
		JSR LCD_Write_Char
		RTS
	_disperr:
		LDA #$65	;e
		JSR LCD_Write_Char
		LDA #$72	;r
		JSR LCD_Write_Char
		LDA #$72	;r
		JSR LCD_Write_Char
		RTS

tec_change_state:
	STA TEC_STATE
	JSR _update_LEDs
	JSR rtc_reset_secs
	RTS
