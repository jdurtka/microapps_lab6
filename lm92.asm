
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 6 - LM92 on i2c bus
;
;*******************************************************************

;
; Real-Time Clock (RTC) interface routines
; 


           INCLUDE 'derivative.inc' 

           XREF _delay_loop
           
           ;XREF i2c_setup
           XREF i2c_address
           XREF i2c_address_repst
           XREF i2c_send_8bit
           XREF i2c_recv_8bit
           XREF i2c_send_ack
           XREF i2c_send_nack
           XREF i2c_stop_condition
           
           XREF LCD_Clear
           XREF LCD_Line_0
           XREF LCD_Line_1
           XREF LCD_Write_Char
           XREF LCD_Display_Byte_Hex
           ;XREF LCD_Display_Byte_Dec
           XREF LCD_Display_16_Dec
           XREF celsius_to_kelvin
           
           XDEF lm92_poll_state
           XDEF lm92_disp_temp
           ;XDEF lm92_state_dump
           

MY_ZEROPAGE: SECTION  SHORT

	LM92_TEMP_HIGH: DC.B 1
	LM92_TEMP_LOW: DC.B 1
	
MyCode:     SECTION

lm92_disp_temp:
	LDA LM92_TEMP_HIGH
	
	;LDA #$13
	;STA LM92_TEMP_HIGH
	;LDA #$38
	;STA LM92_TEMP_LOW
	
	;JSR LCD_Display_Byte_Hex
	;LDA LM92_TEMP_LOW
	;JSR LCD_Display_Byte_Hex
	;RTS
	
	
	;will never be negative for this project
	;CMPA #%10000000		;sign bit?
	;BHS temp_neg		;negative
	;get rid of the sign bit!
	LSLA
	
	temp_pos:
	PSHA				;save momentarily...
	LDA LM92_TEMP_LOW
	AND #%10000000
	BEQ low_zero
	;CMPA #%10000000		;what's the low bit?
	;BHS low_zero
	
	low_one:
	PULA
	ORA #$01
	;JSR LCD_Display_Byte_Dec
	JSR celsius_to_kelvin
	JSR LCD_Display_16_Dec
	;done
	RTS
	
	low_zero:
	PULA
	AND #$FE
	;JSR LCD_Display_Byte_Dec
	JSR celsius_to_kelvin
	JSR LCD_Display_16_Dec
	;done
	RTS

lm92_poll_state:
	LDA #%10010001		;10010xy is device addr, xy are both pulled to gnd, last 1 = read operation
	JSR i2c_address
	JSR i2c_recv_8bit
	STA LM92_TEMP_HIGH
	JSR i2c_send_ack
	JSR i2c_recv_8bit
	STA LM92_TEMP_LOW
	JSR i2c_send_ack
	JSR i2c_stop_condition
	RTS

;NOTE: This will fail if done more often than the device is capable!
;To ensure correct operation, the LM92 should be polled periodically,
;e.g. via the timer interrupt, not constantly!
;lm92_state_dump:
;	LDA #%10010001		;10010xy is device addr, xy are both pulled to gnd, last 1 = read operation
;	JSR i2c_address
;	JSR i2c_recv_8bit
;	JSR LCD_Display_Byte_Hex
;	JSR i2c_send_ack
;	JSR i2c_recv_8bit
;	JSR LCD_Display_Byte_Hex
;	JSR i2c_send_ack
;	JSR i2c_stop_condition
;	RTS
