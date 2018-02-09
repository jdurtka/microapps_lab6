
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 5 - Real-Time Clock (RTC) on i2c bus
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
           
           
           XDEF rtc_stop
           XDEF rtc_start
           XDEF rtc_setup
           XDEF rtc_poll_state
           XDEF rtc_write
           XDEF rtc_disp_secs
           XDEF rtc_reset_secs
           
           XDEF RTC_REGADD
           XDEF RTC_REGVAL

MY_ZEROPAGE: SECTION  SHORT
	SECONDS: DC.B 1
	MINUTES: DC.B 1
	HOURS: DC.B 1
	DATE: DC.B 1
	MONTH: DC.B 1
	YEAR: DC.B 1
	
	RTC_REGADD: DC.B 1
	RTC_REGVAL: DC.B 1
MyCode:     SECTION

rtc_setup:
	RTS
	
;pause the RTC for updating purposes
rtc_stop:
	LDA #%11010000
	JSR i2c_address
	LDA #$0E			;write to the control register
	JSR i2c_send_8bit
	LDA #%10000000		;disable the oscillator
	JSR i2c_send_8bit
	JSR i2c_stop_condition
	RTS
	
;resume the RTC after updating
rtc_start:
	LDA #%11010000
	JSR i2c_address
	LDA #$0E			;write to the control register
	JSR i2c_send_8bit
	LDA #%00000000		;enable the oscillator
	JSR i2c_send_8bit
	JSR i2c_stop_condition
	RTS
	
;Low level subroutine to write to a single RTC register
;Before calling, populate values in the two variables RTC_REGADD and RTC_REGVAL
;	RTC_REGADD = register address, should be in the range [0x00,0x0F]
;	RTC_REGVAL = register value, should match the BCD format depending on the register
;				(e.g. if in seconds, should not exceed 59 BCD)
;There is no checking for correctness, so make sure the values are correct!
rtc_write:
	LDA #%11010000
	JSR i2c_address
	LDA RTC_REGADD
	JSR i2c_send_8bit
	LDA RTC_REGVAL
	JSR i2c_send_8bit
	JSR i2c_stop_condition
	RTS
	
;Grab the entire part of the state we want and save it
rtc_poll_state:
	LDA #%11010000		;first, write (so we start at register 0)
	JSR i2c_address
	LDA #$00			;start from the beginning
	JSR i2c_send_8bit
	LDA #%11010001		;now, read with repeated start
	JSR i2c_address_repst
	
	JSR i2c_recv_8bit
	STA SECONDS
	JSR i2c_send_ack
	
	JSR i2c_recv_8bit
	STA MINUTES
	JSR i2c_send_ack
	
	
	JSR i2c_recv_8bit
	STA HOURS
	JSR i2c_send_ack
	
	;skip day (of the week), we don't need it
	JSR i2c_recv_8bit
	JSR i2c_send_ack
	
	JSR i2c_recv_8bit
	STA DATE
	JSR i2c_send_ack
	
	JSR i2c_recv_8bit
	STA MONTH
	JSR i2c_send_ack
	
	JSR i2c_recv_8bit
	STA YEAR
	JSR i2c_send_nack		;NACK to indicate we are done
	JSR i2c_stop_condition	;Done with this read
	
	RTS

rtc_disp_secs:
    LDA SECONDS
    JSR LCD_Display_Byte_Hex
    RTS

rtc_reset_secs:
	JSR rtc_stop
	LDA #$00
	STA RTC_REGADD
	STA RTC_REGVAL
	JSR rtc_write
	JSR rtc_start
	RTS
