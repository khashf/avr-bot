;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
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
.def	sendcode = r17
.def	lastcommand = r18
.def	command = r19
.def	waitcnt = r20			; Wait Loop Counter
.def	ilcnt = r21				; Inner Loop Counter
.def	olcnt = r22				; Outer Loop Counter

.equ	Button0 = 0
.equ	Button1 = 1
.equ	Button2 = 2
.equ	Button3 = 4
.equ	Button4 = 5
.equ	Button5 = 6
.equ	Button6 = 7


.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
.equ	Freeze = 0b11111000

.equ	BotAddress = 0b00011001
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi		mpr, low(RAMEND)	
	out		SPL, mpr			
	ldi		mpr, high(RAMEND)
	out		SPH, mpr
	;I/O 
	; Initialize Port B for output, this is for debugging what's going on with the transmitter
		ldi		mpr, $FF
		out		DDRB, mpr
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low	
	; Set Port D Data Direction Register
	ldi		mpr, (0<<Button0|0<<Button1|0<<Button2|0<<Button3|0<<Button4|0<<Button5)		
	out		DDRD, mpr		; for input
	; Initialize Port D Data Register
	ldi		mpr, (1<<Button0|1<<Button1|1<<Button2|1<<Button3|1<<Button4|1<<Button5)
	out		PORTD, mpr		; all Port D inputs are Tri-State
	;USART1
	ldi		mpr, 0 ;asynchronous normal mode
	sts		UCSR1A, mpr
	;Set baudrate at 2400bps, UBRR = 416
	ldi		mpr, high(416)
	sts		UBRR1H, mpr
	ldi		mpr, low(416)
	sts		UBRR1L, mpr
		;Enable transmitter
	ldi		mpr, (1<<TXEN1)
	sts		UCSR1B, mpr
		;Set frame format: 8 data bits, 2 stop bits
	ldi		mpr, (1<<USBS1|1<<UCSZ11|1<<UCSZ10)
	sts		UCSR1C, mpr
	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	rcall PollForInput
	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
PollForInput:
	ldi waitcnt, 10
	out PORTB, lastcommand
	in mpr, PIND
	sbrs mpr, Button0
	rjmp sendMovFwd
	sbrs mpr, Button1
	rjmp sendMovBck
	sbrs mpr, Button2
	rjmp sendTurnR
	sbrs mpr, Button3
	rjmp sendTurnL
	sbrs mpr, Button4
	rjmp sendHalt
	sbrs mpr, Button5
	rjmp sendFreeze
	sbrs mpr, Button6
	rjmp sendFreezeTest
	ret
	

SendMovFwd:
	ldi command, MovFwd
	rcall USART1_Transmit_Command
	rcall Wait
	ret

SendMovBck:
	ldi	command, MovBck
	rcall USART1_Transmit_Command
	rcall Wait
	ret

SendTurnR:
	ldi command, TurnR
	rcall USART1_Transmit_Command
	rcall Wait
	ret

SendTurnL:
	ldi command, TurnL
	rcall USART1_Transmit_Command
	rcall Wait
	ret

SendHalt:
	ldi command, Halt
	rcall USART1_Transmit_Command
	rcall Wait
	ret

SendFreeze:
	ldi command, Freeze
	rcall USART1_Transmit_Command
	rcall Wait
	ret

SendFreezeTest:
	ldi sendcode, 0b01010101
	rcall USART1_Transmit
	mov lastcommand, sendcode
	rcall Wait
	ret

USART1_Transmit_Command:
	ldi		sendcode, BotAddress
	rcall USART1_Transmit
	mov		sendcode, command
	rcall USART1_Transmit
	mov		lastcommand, command
	ret
USART1_Transmit:
	
	ldi		XH, high(UCSR1A)
	ldi		XL, low(UCSR1A)
	ld		mpr, X
	sbrs	mpr, UDRE1
	rjmp	USART1_Transmit	
	sts		UDR1, sendcode
	ret

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

;***********************************************************
;*	Additional Program Includes
;***********************************************************
