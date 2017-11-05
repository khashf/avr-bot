;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Enter your name
;*	   Date: Enter Date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.def	nHits = r20				; Number of continual alternative whisker hits
.def	hitSide = r21			; flag indicating bot was hit left the last time

.equ	ReverseTime = 100				; Time to keep the bot waiting in the wait loop
.equ	TurnLeftTime = 20		; Time to keep the bot turning for 1 secs to turn left
.equ	TurnRightTime = 20		; Time to keep the bot turning for 1 secs to turn right
.equ	TurnAroundTime = 200	; Time to keep the bot turning for 3 secs to turn around

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	WasHitLeft = 0			; 
.equ	WasHitRight = 1			;
.equ	WasNeither = 2

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used
.org $0002
		rjmp	HitRight
		reti
.org $0004
		rjmp	HitLeft
		reti
		; This is just an example:
;.org	$002E					; Analog Comparator IV
;		rcall	HandleAC		; Call function to handle interrupt
;		reti					; Return from interrupt


.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)	; initialize Stack Pointer
		out		SPL, mpr			
		ldi		mpr, high(RAMEND)
		out		SPH, mpr
		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low	
		; Initialize Port D for input
		ldi		mpr, (0<<WskrL|0<<WskrR)		; Set Port D Data Direction Register
		out		DDRD, mpr						; for input
		ldi		mpr, (1<<WskrL|1<<WskrR)		; Initialize Port D Data Register
		out		PORTD, mpr						; so all Port D inputs are Tri-State
		; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd						; Load Move Forward Command
		out		PORTB, mpr						; Send command to motors
		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
		sts		EICRA, mpr
		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0|1<<INT1)
		out		EIMSK, mpr
		; Turn on interrupts
		sei
			; NOTE: This must be the last thing to do in the INIT function

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		ldi		nHits, 0		; number of hits
		ldi		hitSide, WasNeither

		ldi		mpr, MovFwd		; the bot always move forward by default when not turning
		out		PORTB, mpr		; 

		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the 
;	left whisker interrupt, one to handle the right whisker 
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
HitRight:							; Begin a function with a label
		; Clear interrupt and disable interrupts
		cli
		ldi		mpr, (0<<INT0|0<<INT1)
		out		EIFR, mpr

		; Move back
		ldi mpr, MovBck
		out PORTB, mpr

		; Wait <waitcnt> secs
		ldi		waitcnt, ReverseTime
		rcall Wait

		; If (this's an alternating turn)
		cpi		hitSide, WasHitLeft
		breq	CountAltTurnRight	; count hit
		; Else
		ldi		nHits, 0			; reset nHits = 0 => loose the streak
		rjmp	SetTurnLeftTime			; set up time to turn left

CountAltTurnRight:
		inc		nHits				; count up this hit
		; If (this is the 6th alternating hit)
		cpi		nHits, 6
		breq	SetTurnAroundTimeInLeft		; set up time to turn around
		; Else
		rjmp	SetTurnLeftTime
		
SetTurnAroundTimeInLeft:
		ldi		nHits, 0			; reset nHits = 0 
		ldi		waitcnt, TurnAroundTime
		ldi		hitSide, WasNeither
		rjmp	TurnLeft

SetTurnLeftTime:
		ldi		waitcnt, TurnLeftTime
		ldi		hitSide, WasHitRight
		rjmp	TurnLeft

TurnLeft:
		; Turn
		ldi mpr, TurnL
		out PORTB, mpr
		rcall Wait

		; Reset input
		cbi PORTD, WskrL
		cbi PORTD, WskrR

		; Set interrupt back and start listen for interrupt
		ldi		mpr, (1<<INT0|1<<INT1)
		out		EIFR, mpr
		sei

		ret					; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
HitLeft:	
		; Clear interrupt and disable interrupts
		cli
		ldi		mpr, (0<<INT0|0<<INT1)
		out		EIFR, mpr

		; Move back
		ldi		mpr, MovBck
		out		PORTB, mpr

		; Wait <waitcnt> secs
		ldi		waitcnt, ReverseTime
		rcall	Wait

		; If (this's an alternating turn)
		cpi		hitSide, WasHitRight
		breq	CountAltTurnLeft	; count hit
		; Else
		ldi		nHits, 0			; reset nHits = 0 => loose the streak
		rjmp	SetTurnRightTime			; set up time to turn left

CountAltTurnLeft:
		inc		nHits				; count up this hit
		; If (this is the 6th alternating hit)
		cpi		nHits, 6
		breq	SetTurnAroundTimeInRight		; set up time to turn around
		; Else
		rjmp	SetTurnRightTime
		
SetTurnAroundTimeInRight:
		ldi		nHits, 0			; reset nHits = 0 
		ldi		waitcnt, TurnAroundTime
		ldi		hitSide, WasNeither
		rjmp	TurnRight

SetTurnRightTime:
		ldi		waitcnt, TurnRightTime
		ldi		hitSide, WasHitLeft
		rjmp	TurnRight

TurnRight:
		; Turn
		ldi mpr, TurnR
		out PORTB, mpr
		rcall Wait

		; Reset input
		cbi PORTD, WskrL
		cbi PORTD, WskrR

		; Set interrupt back and start listen for interrupt
		ldi		mpr, (1<<INT0|1<<INT1)
		out		EIFR, mpr
		sei

		ret					; End a function with RET

Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program