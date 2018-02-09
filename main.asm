
;*******************************************************************
; James Durtka
;
; EELE 465 - Microcontroller Applications
; Lab 5 - Real-Time Clock (RTC) on i2c bus
;
;*******************************************************************

; Naming conventions:
;	-Normal subroutines as a mixture of camel and snake case: my_Subroutine
;	-Utility functions as snake case with a leading underscore: _my_utility
;	-ISRs as utility functions, but with camel case: _My_Interrupt
;	-Main loop and startup: mainLoop and _Startup
;	-Variables and constants as all caps snake case: MY_VARIABLE
;
; Version control via git

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            

; export symbols
            XDEF _Startup, main
            ; we export both '_Startup' and 'main' as symbols. Either can
            ; be referenced in the linker .prm file or from C/C++ later on
            
            
            
            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack
            
            XREF _refresh_LEDs
            XREF setup_LCD
            XREF setup_Timer
            
            XREF _keypad_polling
            XREF keypad_Decoder
            XREF KEY_CODE
            XREF KEY_VAL
            
            XREF LCD_Cursor_Shift
            XREF LCD_Write_Char
            XREF LCD_Line_0
            XREF LCD_Line_1
            XREF LCD_Clear
            XREF LCD_Display_Byte_Dec
            XREF LCD_Display_Byte_Hex
            XREF LCD_Display_Nibble
            XREF LCD_Display_16_Dec
            XREF LCD_Display_16_Hex
            
            XREF _delay_loop
            
            XREF i2c_setup
            
            XREF rtc_setup
            ;XREF rtc_state_dump
            XREF rtc_stop
            XREF rtc_start
            XREF rtc_poll_state
            XREF rtc_display_state
            XREF rtc_entry_prompt
            XREF rtc_write
            XREF RTC_REGADD
            XREF RTC_REGVAL
            XREF rtc_disp_secs
            
            ;XREF lm92_state_dump
            XREF lm92_disp_temp
            
            XREF tec_setup
            XREF tec_disp_state
            XREF tec_change_state

; variable/data section
MY_ZEROPAGE: SECTION  SHORT         ; Insert here your data definition
		
		LAST_KEY: DC.B 1		;Keep track of the last keycode received
		NUM_CHARS: DC.B 1		;Keep track of how many characters are on the screen
		
		LOOP_MAX: DC.B 1 		;Keep track of how many samples we are averaging
		CUR_ITER: DC.B 1		;Keep track of how many samples need to be taken
		
		DATA_ENTRY: DC.B 1		;Keep track of data entry on the keypad
					   
		
		
; code section
MyCode:     SECTION
main:
_Startup:
            LDHX   #__SEG_END_SSTACK ; initialize the stack pointer
            TXS
			
			LDA #$53
			STA SOPT1	; Disable Watchdog
			
			;Setup the data direction registers for LED I/O (SET = output)
			;BSET 3, PTADD
			
			;Data direction for LCD control lines
			BSET 0, PTADD ;R/W
			BSET 1, PTADD ;RS
			
			;Setup bus and port registers to write (default state)
			LDA #$FF
			STA PTBDD
			
			;Init "last key" to FF
			LDA #$FF
			STA LAST_KEY
			LDA #$00
			STA NUM_CHARS
			
			;Initialize the LED ticker into a known state
			;LDA #%10010110
			LDA #$00
			JSR _refresh_LEDs
			
			;Setup LCD display
			JSR setup_LCD
			
			;Setup ADC
			;JSR setup_ADC
			;Setup i2c
			JSR i2c_setup
			;Setup RTC
			JSR rtc_setup
			
			JSR tec_setup
			
			
			;Setup MTIM parameters
			JSR setup_Timer
			
			CLI			; enable interrupts
			
			;setup sampling loop parameters
			;1 sample
			LDA #$01
			STA LOOP_MAX
			;start at 1
			LDA #$01
			STA CUR_ITER
			
			BRA mainLoop
	
	
inputPoll:
	;Poll keypad
	JSR _keypad_polling
	
	;Check what keys have been pressed, and update accordingly
	;(debouncing occurs here)
	JSR keypad_Decoder
	
	;Avoid duplicating keys
	LDA KEY_CODE
	CMPA LAST_KEY
	BNE nodeb
	;delay to debounce
	LDA #$FE
	JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	BRA _no_new_key
	
	nodeb:
	;This is the code for "no new key"
	CMPA #$FF
	BEQ _no_new_key
	
	;Reject any keys except 0-2
	LDA KEY_VAL
	;CMP #$00
	;BEQ _no_new_key
	CMP #$02
	BHI _no_new_key
	
	;reset our sampling loop
	LDA KEY_VAL
	STA LOOP_MAX
	STA CUR_ITER
	
	;whatever is entered goes to TEC state
	LDA KEY_VAL
	JSR tec_change_state
	
	;delay to prevent early repetition
	;LDA #$FE
	;JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	;LDA #$FE
	;JSR _delay_loop
	
	;return to caller
	RTS
	
	;whether new keys came in or not, we update the "last key"
	_no_new_key:
	LDA KEY_CODE
	STA LAST_KEY
	
	RTS

mainLoop:
	JSR inputPoll
	
	JSR LCD_Clear
	
	JSR LCD_Line_0
	JSR msg_tec_state
	JSR tec_disp_state
	
	JSR LCD_Line_1
	JSR msg_temp_0
	JSR lm92_disp_temp
	JSR msg_temp_1
	JSR rtc_disp_secs
	JSR msg_temp_2
	
	LDA #$FF			;Delay prevents cursor "snow"
	JSR _delay_loop
	
	BRA mainLoop

	
msg_tec_state:
	;"TEC state:      "
	LDA #$54	;T
	JSR LCD_Write_Char
	LDA #$45	;E
	JSR LCD_Write_Char
	LDA #$43	;C
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	LDA #$73	;s
	JSR LCD_Write_Char
	LDA #$74	;t
	JSR LCD_Write_Char
	LDA #$61	;a
	JSR LCD_Write_Char
	LDA #$74	;t
	JSR LCD_Write_Char
	LDA #$65	;e
	JSR LCD_Write_Char
	LDA #$3A	;":"
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	RTS
	
msg_temp_0:
	;"T92: "
	LDA #$54	;T
	JSR LCD_Write_Char
	LDA #$39	;9
	JSR LCD_Write_Char
	LDA #$32	;2
	JSR LCD_Write_Char
	LDA #$3A	;":"
	JSR LCD_Write_Char
	RTS
	
msg_temp_1:
	;"K@T="
	LDA #$4B	;K
	JSR LCD_Write_Char
	LDA #$40	;@
	JSR LCD_Write_Char
	LDA #$54	;T
	JSR LCD_Write_Char
	LDA #$3D	;"="
	JSR LCD_Write_Char
	LDA #$20	;" "
	JSR LCD_Write_Char
	RTS

msg_temp_2:
	;"s"
	LDA #$73	;s
	JSR LCD_Write_Char
	RTS
