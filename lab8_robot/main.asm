;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Trevor Swope, Khuong Luu
;*	   Date: Nov. 13 2017
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = 0b00011001 ;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

;Should have Interrupt vectors for:
.org	$0002					;INT0, left whisker
	rjmp RightWhiskerHit
	reti
.org	$0004					;INT1, right whisker
	rjmp LeftWhiskerHit
	reti
;- Left whisker
;- Right whisker
;- USART receive
.org	$003C					;USART1, Rx complete
	rjmp USART1_RXC
	reti
.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi		mpr, low(RAMEND)	; initialize Stack Pointer
	out		SPL, mpr			
	ldi		mpr, high(RAMEND)
	out		SPH, mpr
	;I/O Ports
	; Initialize Port B for output
	ldi		mpr, $FF
	out		DDRB, mpr
	ldi		mpr, $00		; Initialize Port B Data Register
	out		PORTB, mpr		; so all Port B outputs are low	
	; Initialize Port D for input
	; Set Port D Data Direction Register
	ldi		mpr, (0<<WskrR|0<<WskrL)		
	out		DDRD, mpr		; for input
	; Initialize Port D Data Register
	ldi		mpr, (1<<WskrR|1<<WskrL)		
	out		PORTD, mpr		; all Port D inputs are Tri-State
	;USART1
	ldi		mpr, 0 ;asynchronous normal mode
	sts		UCSR1A, mpr
	;Set baudrate at 2400bps, UBRR = 416
	ldi		mpr, high(416)
	sts		UBRR1H, mpr
	ldi		mpr, low(416)
	sts		UBRR1L, mpr
		;Enable receiver and enable receive interrupts
	ldi		mpr, (1<<RXEN1|1<<RXCIE1)
	sts		UCSR1B, mpr
		;Set frame format: 8 data bits, 2 stop bits
	ldi		mpr, (1<<USBS1|1<<UCSZ11|1<<UCSZ10)
	sts		UCSR1C, mpr
	;External Interrupts
		;Set the External Interrupt Mask
		;Set the Interrupt Sense Control to falling edge detection
	ldi		mpr, (1<<ISC01|0<<ISC00|1<<ISC11|0<<ISC10)
	sts		EICRA, mpr
	ldi		mpr, (1<<INT0|1<<INT1)
	out		EIMSK, mpr
	sei
	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
LeftWhiskerHit:

	ret

RightWhiskerHit:
	
	ret

USART1_RXC:

	ret
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
