;***********************************************************
;*
;*	trevor_swope_and_khuong_luu_lab7_sourcecode.asm
;*
;*	
;*
;*	
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
.def	waitcnt = r20

;***********************************************************
;*	Constants
;***********************************************************

; Button order from right to left
.equ	Button0 = 0				; to increase speed
.equ	Button1 = 1				; to decrease speed
.equ	Button2 = 2				; to set max speed
.equ	Button3 = 3				; to set min speed

; LED to indicate speed and direction
.equ	LED1 = 0				; L1 physically - indicator - Lowest significant bit 
.equ	LED2 = 1				; L2 physically
.equ	LED3 = 2				; L3 physically
.equ	LED4 = 3				; L4 physically - indicator - Highest significant bit
.equ	EngEnableL = 4			; L5 physically - Left engine enable bit
.equ	LeftEngineDir = 5		; L6 physically - Left engine direction
.equ	RightEngineDir = 6		; L7 physically - Right engine direction
.equ	EngEnableR = 7			; L8 physically - Right engine enable bit

; Brightness inc/dec magnitude
.equ	step = 17				; Each inc/dec is 17/255 ~ 6.7% duty cycle

;***********************************************************
;These macros are the values to make the TekBot Move.
;***********************************************************

.equ	MovFwd = (1<<LeftEngineDir|1<<RightEngineDir); Move Forward Command
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
.org	$0002	; INT0 - Button S1
		rjmp	IncreaseSpeed
		reti
.org	$0004	; INT1 - Button S2
		rjmp	DecreaseSpeed
		reti	
.org	$0006	; INT2 - Button S3
		rjmp	SetMaxSpeed
		reti
.org	$0008	; INT3 - Button S4
		rjmp	SetMinSpeed
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
		out		PORTD, mpr		; all Port D inputs are Tri-State
	; Configure external interrupts for 4 buttons
		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01|0<<ISC00|1<<ISC11|0<<ISC10|1<<ISC21|0<<ISC20|1<<ISC31|0<<ISC30)
		sts		EICRA, mpr
		; Enable the External Interrupt Mask
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
	; Configure 8-bits Timer/Counter0 and Timer/Counter2
		; WGM01:WGM00 = 11 - Fast PWM mode
		; COM01:COM00 = 10 - Clear OC0 on compare match, set OC0 at TOP
		; CS02:CS01:CS00 = 001 - No prescaling
		ldi		A, (0<<FOC0|1<<WGM00|1<<COM01|0<<COM00|1<<WGM01|0<<CS02|0<<CS01|1<<CS00)
		out		TCCR0, A
		out		TCCR2, A
	; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd						; 
		out		PORTB, mpr						; Make bot move forward	
	; Set initial speed, display on Port B pins 3:0
		ldi		speed, 4
	; Set initial brightness
		ldi		mpr, 68
		out		OCR0, mpr		; OC0 starts at 68% duty cycle 
		out		OCR2, mpr		; OC2 starts at 68% duty cycle 
	; Configure 16-Bit Timer/Counter1
		ldi		mpr, (1<<CS12) ;initialize timer1 with pre-scale 256
		out		TCCR1B, mpr
		ldi		mpr, high(62500)
		out		OCR1AH, mpr
		ldi		mpr, low(62500)
		out		OCR1AL, mpr
		ldi		mpr, 0
		out		TCNT1H, mpr
		out		TCNT1L, mpr	
	; Set global interrupts
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		mov		mpr, speed		; indicate speed in binary by L1-L4
		ori		mpr, MovFwd		; keep moving forward
		out		PORTB, mpr		; display speed and direction
		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; IncreaseSpeed	
;-----------------------------------------------------------
IncreaseSpeed:
		; start ignoring interrupts
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3) 
		out		EIMSK, mpr
		out		EIFR, mpr
		
		; increase speed
		cpi		speed, 15		; if speed is current max
		breq	IncSkip			; then skip increament
		ldi		mpr, 1			; otherwise, 
		add		speed, mpr		; increase by 1
		
		; increase brightness of LED L5 and L8
		in		mpr, OCR0		; load current OCR0 value
		ldi		A, step			 
		add		mpr, A
		out		OCR0, mpr		; OCR0 += step (17)
		out		OCR2, mpr		; OCR2 += step (17)

		; display speed and direction
		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr

IncSkip:
		rcall Wait5ms			; debouncing

		; start listening for interrupt again
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIFR, mpr
		out		EIMSK, mpr
		sei
		
		ret						

;-----------------------------------------------------------
; DecreaseSpeed		
;-----------------------------------------------------------
DecreaseSpeed:
		; start ignoring interrupts
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr

		; decrease speed
		cpi		speed, 0
		breq	DecSkip
		subi	speed, 1

		; decrease brightness of LED L5 and L8
		in		mpr, OCR0
		subi	mpr, step
		out		OCR0, mpr
		out		OCR2, mpr

		; display speed and direction
		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr

DecSkip:
		rcall Wait5ms	; debouncing

		; start listening for interrupt again
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		sei

		ret						

;-----------------------------------------------------------
; SetMaxSpeed		
;-----------------------------------------------------------
SetMaxSpeed:
		; start ignoring interrupts
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr

		; set speed max value
		ldi		speed, 15

		; set max brightness for L5 and L8
		ldi		mpr, 255
		out		OCR0, mpr
		out		OCR2, mpr
		
		; display speed and direction
		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr

		rcall Wait5ms		; debouncing

		; start listening for interrupt again
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		sei

		ret						; End a function with RET

;-----------------------------------------------------------
; SetMinSpeed		
;-----------------------------------------------------------
SetMinSpeed:
		; start ignoring interrupts
		cli
		ldi		mpr, (0<<INT0|0<<INT1|0<<INT2|0<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr

		; set speed
		ldi		speed, 0

		; set brightness
		ldi		mpr, 0
		out		OCR0, mpr
		out		OCR2, mpr

		; display speed and direction
		mov		mpr, speed
		ori		mpr, MovFwd
		out		PORTB, mpr

		rcall Wait5ms		; debouncing

		; start listening for interrupt again
		ldi		mpr, (1<<INT0|1<<INT1|1<<INT2|1<<INT3)
		out		EIMSK, mpr
		out		EIFR, mpr
		sei

		ret						; End a function with RET

;-----------------------------------------------------------
; Wait5ms		
; Description: 
;	Used for debouncing
;	Use 3 loops for delaying
;-----------------------------------------------------------
Wait5ms:						
		; push stack
		push mpr			; save mpr
		in mpr, SREG		
		push mpr			; save SREG

		ldi waitcnt, 160	; load wait count
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
		; delay ends

		; pop stack
		pop mpr				; load SREG
		out SREG, mpr		
		pop mpr				; load mpr

		ret
