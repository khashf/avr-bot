;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions
;***********************************************************
.def	mpr = r16				; Multipurpose register

;***********************************************************
;*	Constants
;***********************************************************

.equ	Button0 = 0				; Right Whisker Input Bit
.equ	Button1 = 1				; Left Whisker Input Bit
.equ	Button2 = 2				; Left Whisker Input Bit
.equ	Button3 = 3				; Left Whisker Input Bit

.equ	EngEnR = 4				; right Engine Enable Bit
.equ	EngEnL = 7				; left Engine Enable Bit
.equ	EngDirR = 5				; right Engine Direction Bit
.equ	EngDirL = 6				; left Engine Direction Bit

;***********************************************************
;These macros are the values to make the TekBot Move.
;***********************************************************

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

; Input Button Interrupt Vectors
.org	$0002	; INT0
		rjmp	IncreaseSpeed
		reti
.org	$0004	; INT1
		rjmp	DecreaseSpeed
		reti	
.org	$0006	; INT2
		rjmp	MaxSpeed
		reti
.org	$0008	; INT3
		rjmp	MinSpeed
		reti

; Timer Interrupt Vectors
; See page 23, AVR Starter Guide
.org	$0012	Timer2_Comp
		rjmp	Timer2_Comp
		reti
.org	$0014	Timer2_Overflow
		rjmp	Timer2_Overflow
		reti
.org	$001E	Timer0_Comp
		rjmp	Timer0_Comp
		reti
.org	$0020	Timer0_Overflow
		rjmp	Timer0_Overflow
		reti

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)	; initialize Stack Pointer
		out		SPL, mpr			
		ldi		mpr, high(RAMEND)
		out		SPH, mpr
	; Configure I/O ports
		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low	
		; Initialize Port D for input
		; Set Port D Data Direction Register
		ldi		mpr, (0<<Button0|0<<Button1|0<<Button2|0<<Button3)		
		out		DDRD, mpr		; for input
		; Initialize Port D Data Register
		ldi		mpr, (1<<Button0|1<<Button1|1<<Button2|1<<Button3)		
		out		PORTD, mpr		; so all Port D inputs are Tri-State
	; Configure External Interrupts, if needed
		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
		sts		EICRA, mpr
		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
	; Configure 8-bit Timer/Counters
		
								; no prescaling

	; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd						; Load Move Forward Command
		out		PORTB, mpr						; Send command to motors
	; Set initial speed, display on Port B pins 3:0

	; Enable global interrupts (if any are used)
		sei

;***********************************************************
;*	NOTES
;***********************************************************

;Fast PWN Mode: 
;Timer/Counter0 consists of 3 registers:
;- Timer/Counter 0 register:			TCNT0
;- Output Compare Register 0:		OCR0
;- Timer/Counter Control Register 0: TCCR0

;Most basic way to use: Write value to TCNT0 and let it
;count up to max value 
;-> Timer/Counter Overflow 0 (TOV0) is set
;-> Detect:	manually: section 5.4.4
;			generate interrupt 5.4.3
;-> Elapsed time: Page ...

;The exact behavior of Timer/Counter0 depends on its mode of operation 
;(see Section 5.4.4), which is controlled by setting TCCR0 (see Section 5.4.5).

;Enable TOV0 and OCF0 as interrupt by configuring 
;Timer/Counter Interrupt Mask Register TIMSK

;OCF0 and TOV0 flags are masked by OCIE0 and TOIE0 bits, respectively, in TIMSK
;OCIE0 and TOIE bits must be set to 1 to enable these interrupts

;Format of TCCR0: page 163
;Set up TCCR0 with not prescale: CS02 = CS01 = 0; CS00 = 1
;Set up Fast PWM mode: WGM01 = 1; WGM00 = 1, 

;COMM01 and COMM00: See page 164
;FOC0: See page 164
;
;
;
;Fast PWM: (page 161)
;- TCNT0 counts up from BOTTOM(0x00) to MAX (0xFF) then restarts at BOTTOM
;For a non-inverted PWM output, OC0 signal is set to 0 when TCNT0 and OCR0 match,
;and is set to 1 when the computer transitions from 0xFF to 0x00.


;***********************************************************
;*	Example Programs: See page 167 in Ben's textbook
;***********************************************************


;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		
		; poll Port D pushbuttons (if needed)

								; if pressed, adjust speed
								; also, adjust speed indication

		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; IncreaseSpeed
; 
;		
;-----------------------------------------------------------
IncreaseSpeed:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; DecreaseSpeed
; 
;		
;-----------------------------------------------------------
DecreaseSpeed:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; MaxSpeed
; 
;		
;-----------------------------------------------------------
MaxSpeed:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; MinSpeed
; 
;		
;-----------------------------------------------------------
MinSpeed:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Timer0_Comp
; 
;		
;-----------------------------------------------------------
Timer0_Comp:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Timer0_Overflow
; 
;		
;-----------------------------------------------------------
Timer0_Overflow:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Timer2_Comp
; 
;		
;-----------------------------------------------------------
Timer2_Comp:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Timer2_Overflow
; 
;		
;-----------------------------------------------------------
Timer2_Overflow:	
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		

		
		
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
