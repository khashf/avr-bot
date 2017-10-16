;***********************************************************
;*
;*	Enter name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;.include "LCDDriver.asm"		; Include LCD driver
;; We are not allowed to include "LCDDriver.asm" here because
;; this is a purely pre-compiler directives. This contains
;; actual assembly instructins and thus cannot be inlucded
;; at the beginning of our main program file.
;; As indicated in the AVR Starter Guide, any included code
;; files are cindlued at the end of the main program
;; i.e. the last line(s)

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							
		; Initialize Stack Pointer
		; Point SP to the end of RAM (RAMEND)
		ldi		mpr, low(RAMEND)
		out		SPL, mpr			
		ldi		mpr, high(RAMEND)
		out		SPH, mpr
		;; NOTE
		;; To be able to call any function (subroutine),
		;; we must initialize the Stack Pointer 
		;; at very first

		;; Initialize LCD Display
		rcall	LCDInit			; init LCD
		;rcall	LCDClear		; Clear both lines of the LCD

		;; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING_BEG << 1)
		ldi		ZH, high(STRING_BEG << 1)
		ldi		YL, low(STRING_END << 1)
		ldi		YH, high(STRING_END << 1)
		;; Point X-register to the appropriate mem location
		ldi		XH, $01
		ldi		XL, $00

		;; X, Y,Z register
		;; X is for displaying
		;; Z is for holding STRING_BEG
		;; Y is for holding STRING_END

		;; Set up PORTB for non-device test
		ldi		mpr, $ff
		out		PORTB, mpr		; all pins at port B is 1
		out		DDRB, mpr		; set port B as output (for testing our string)

		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the MAIN program

;***********************************************************
;*	Loop
;***********************************************************
LOOP:
		
		

		;; Load byte into mpr
		lpm		mpr, Z+			; Load byte from Program Mem into mpr
		

		;; Display
		st		X+, mpr
		rcall	LCDWrite		; Write to both lines of the LCD
		;out	PORTB, mpr		; Display the byte we just read onto the LCD Display

		cp		ZL, YL			; Check if we have reached the end of string
		breq	DONE1			; End of program

		;; Move the 
		;st		Y+, mpr			; DataMemory[Y] <- mpr, Y++

		rjmp	LOOP			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

SCROLL:
		ldi		XH, $01			; X register holds first line pointer
		ldi		XL, $00			
		ldi		YH, $11			; Y register holds second line pointer
		ldi		YL, $00

		;ldi	mpr, X
		;ldi	line, 1
		;ldi	count (X+offset)%16


DONE1:	
		cp		ZH, YH			; Check if we have reached the end of string
		breq	DONE2			; TODO: When will this happen?
		rjmp	LOOP			; Loop infinte

DONE2:
		rjmp	DONE2			; Loop infinte
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		
		rjmp	LOOP
		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: 
; Desc: 
;		
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variables by pushing them to the stack

		; Execute the function here
		
		; Restore variables by popping them from the stack,
		; in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:							; Use for first line
.DB		"Khuong Luu      "			; My name							; Display second line
.DB		"Hello World!    "			; Declare string Hello Word!
STRING_END:


;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
