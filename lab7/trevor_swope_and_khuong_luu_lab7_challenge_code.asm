;***********************************************************
;*
;*	trevor_swope_and_khuong_luu_lab7_challenge_code.asm
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
.def	speed = r24
.def	timeCount = r23
.def	waitcnt = r20

;***********************************************************
;*	Constants
;***********************************************************

.equ	Button0 = 0				; Right Whisker Input Bit
.equ	Button1 = 1				; Left Whisker Input Bit
.equ	Button2 = 2				; Left Whisker Input Bit
.equ	Button3 = 3				; Left Whisker Input Bit
.equ	EngEnableL = 4			; Left engine enable bit
.equ	LED6 = 5				; L6 physically
.equ	LED7 = 6				; L7 physically
.equ	EngEnableR = 7			; Right engine enable bit
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
.org	$0018	; Timer/Counter1 compare match A
		rjmp	IncTime
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
		ldi		mpr, $FF
		out		DDRB, mpr
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
		ldi		mpr, (1<<ISC01|0<<ISC00|1<<ISC11|0<<ISC10|1<<ISC21|0<<ISC20|1<<ISC31|0<<ISC30)
		sts		EICRA, mpr
		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
	; Configure 8-bit Timer/Counters, 
		; no prescaling
		ldi		A, 0b01101001 ;Try CS00 = 1 or 0
		out		TCCR0, A
		ldi		A, 0b01101001
		out		TCCR2, A
		ldi		timeCount, 0
		rcall	LCDInit
		rcall	LCDClear
		rcall	WriteTime					

	; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd						; Load Move Forward Command
		out		PORTB, mpr						; Send command to motors
		
	; Set initial speed, display on Port B pins 3:0
		ldi		speed, 4
		ldi		mpr, 68
		out		OCR0, mpr ;start stopped, duty cycle at 0%
		out		OCR2, mpr
	; Configure 16-Bit Timer/Counter1
		ldi		mpr, (1<<WGM12|1<<CS12) ;initialize timer1 in CTC mode with pre-scale 256
		out		TCCR1B, mpr
		ldi		mpr, (1<<OCIE1A)
		out		TIMSK, mpr
		ldi		mpr, high(62500)
		out		OCR1AH, mpr
		ldi		mpr, low(62500)
		out		OCR1AL, mpr
		ldi		mpr, 0
		out		TCNT1H, mpr
		out		TCNT1L, mpr
		
	; Enable global interrupts (if any are used)
		sei




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
		out		OCR2, mpr

		ldi		timeCount, 0
		rcall	writeTime

		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr

IncSkip:

		rcall Wait5ms

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
		out		OCR2, mpr

		ldi		timeCount, 0
		rcall	writeTime

		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr

		DecSkip:

		rcall Wait5ms

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
		out		OCR2, mpr

		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr

		ldi		timeCount, 0
		rcall	writeTime

		rcall Wait5ms

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
		out		OCR2, mpr

		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr



		rcall Wait5ms

		ldi		timeCount, 0
		rcall	writeTime

		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		sei
		ret						; End a function with RET


IncTime:
		inc timeCount
WriteTime:
		ldi A, 0
		out	TCNT1H, A
		out	TCNT1L, A
		ldi XH, high($0107) ;line 1 of the LCD
		ldi	XL, low($0107)
		mov	A, timeCount
WriteLoop:
		ror A
		brcs Write1
		ldi mpr, '0'
		st X, mpr
		rjmp WriteCheck
Write1:
		ldi mpr, '1'
		st X, mpr
WriteCheck:
		dec XL
		cpi XL, $FF
		brne WriteLoop
		rcall LCDWrLn1
		sei
		ret
Wait5ms:						; this function exists because of debouncing being annoying
		push mpr
		in mpr, SREG
		push mpr
		ldi waitcnt, 160
WaitLoop0:
		ldi mpr, 100
WaitLoop1:
		ldi A, 50
WaitLoop2:
		dec A
		cpi A, 0
		brne WaitLoop2
		dec mpr
		cpi mpr, 0
		brne WaitLoop1
		dec waitcnt
		cpi waitcnt, 0
		brne WaitLoop0
		pop mpr
		out SREG, mpr
		pop mpr
		ret
;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************

.include "LCDDriver.asm"