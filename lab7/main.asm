;***********************************************************
;*
;*	trevor_swope_and_khuong_luu_lab7_sourcecode.asm
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Trevor Swope, Khuong Luu
;*	   Date: Nov. 12, 2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	A = r17
.def	speed = r18
.def	timeCount = r19

;***********************************************************
;*	Constants
;***********************************************************

.equ	Button0 = 0				; Right Whisker Input Bit
.equ	Button1 = 1				; Left Whisker Input Bit
.equ	Button2 = 2				; Left Whisker Input Bit
.equ	Button3 = 3				; Left Whisker Input Bit

.equ	LED6 = 5				; L6 physically
.equ	LED7 = 6				; L7 physically

.equ	LED1 = 0				; L1 physically
.equ	LED2 = 1				; L2 physically
.equ	LED3 = 2				; L3 physically
.equ	LED4 = 3				; L4 physically
.equ	step = 17
;***********************************************************
;These macros are the values to make the TekBot Move.
;***********************************************************

.equ	MovFwd = (1<<LED6|1<<LED7)		; Move Forward Command
.equ	MinSpeed = (0b00000000|MovFwd)
.equ	MaxSpeed = (0b00001111|MovFwd)

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
		rjmp	SetMaxSpeed
		reti
.org	$0008	; INT3
		rjmp	SetMinSpeed
		reti

; Timer Interrupt Vectors
; See page 23, AVR Starter Guide
;.org	$001E ;Timer0_Comp
;		rjmp
;		reti
;.org	$0020 ;Timer0_Overflow
;		rjmp
;		reti

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
		;ldi		mpr, (1<<Button0|1<<Button1|1<<Button2|1<<Button3)		
		;out		PORTD, mpr		; so all Port D inputs are Tri-State
	; Configure External Interrupts, if needed
		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01|0<<ISC00|1<<ISC11|0<<ISC10|1<<ISC21|0<<ISC20|1<<ISC31|0<<ISC30)
		sts		EICRA, mpr
		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
	; Configure 8-bit Timer/Counters, 
		; no prescaling
		ldi		A, 0b01111000 ;Try CS00 = 1 or 0
		out		TCCR0, A
								

	; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd						; Load Move Forward Command
		out		PORTB, mpr						; Send command to motors
		
	; Set initial speed, display on Port B pins 3:0
		ldi		mpr, 0
		out		OCR0, mpr ;start stopped, duty cycle at 0%
		ldi		speed, 0
	; Enable global interrupts (if any are used)

	; Challenge: add seconds-since-last-change counter
		sei

;***********************************************************
;*	NOTES
;***********************************************************

;Fast PWN Mode: 
;Timer/Counter0 consists of 3 registers:
;- Timer/Counter 0 register:			TCNT0
;- Output Compare Register 0:			OCR0
;- Timer/Counter Control Register 0:	TCCR0

;Most basic way to use: Write value to TCNT0 and let it
;count up to max value 
;-> Timer/Counter Overflow 0 (TOV0) is set
;-> Detect:	manually: section 5.4.4
;			generate interrupt 5.4.3
;-> Elapsed time: Page ...

; TIMSK
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
		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr
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
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3) ;this doesn't seem to be working to fulfill requirement #3 so far :(
		out		EIMSK, mpr
		out		EIFR, mpr
		
		cpi		speed, 15
		breq	IncSkip
		ldi		mpr, 1
		add		speed, mpr
		in		mpr, OCR0
		ldi		A, step
		add		mpr, A	
		out		OCR0, mpr
IncSkip:
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIFR, mpr
		out		EIMSK, mpr
		sei
		
		ret						; End a function with RET

;-----------------------------------------------------------
; DecreaseSpeed
; 
;		
;-----------------------------------------------------------
DecreaseSpeed:
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		cpi		speed, 0
		breq	DecSkip
		subi	speed, 1
		in		mpr, OCR0
		subi	mpr, step
		out		OCR0, mpr
		DecSkip:
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		sei
		ret						; End a function with RET

;-----------------------------------------------------------
; SetMaxSpeed
; 
;		
;-----------------------------------------------------------
SetMaxSpeed:
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr

		ldi		speed, 15
		ldi		mpr, 255
		out		OCR0, mpr

		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		sei
		ret						; End a function with RET

;-----------------------------------------------------------
; SetMinSpeed
; 
;		
;-----------------------------------------------------------
SetMinSpeed:
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr

		ldi		speed, 0
		ldi		mpr, 0
		out		OCR0, mpr

		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		sei
		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
