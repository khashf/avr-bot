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
;*	Internal Register Definitions
;***********************************************************

.def	mpr = r16				; Multipurpose register 
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.def	nHits = r20				; Number of continual alternative whisker hits
.def	hitSide = r21			; flag indicating bot was hit left the last time
.def	buffer = r22			; buffer for received incoming data frame
.def	ReceiverSR = r23
.def	currentmotion = r24
;***********************************************************
;*	Constants
;***********************************************************
.equ	ReverseTime = 100		; Time to keep the bot waiting for .. secs in the wait loop
.equ	TurnLeftTime = 100		; Time to keep the bot turning for .. secs to turn left
.equ	TurnRightTime = 100		; Time to keep the bot turning for .. secs to turn right
.equ	TurnAroundTime = 200	; Time to keep the bot turning for .. secs to turn around

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	WasHitLeft = 0			; The last time was a left hit 
.equ	WasHitRight = 1			; The last hit was a right hit
.equ	WasNeither = 2			; The last hit was neither right nor left hit
								; (can be the first time the bot startup,
								; or after the bot just turned around
.equ	ExpectingData = 0
.equ	SkipFreezeFlag = 1
.equ    FreezeCnt1 = 2
.equ	FreezeCnt2 = 3
.equ	Frozen = 4


; USARTs
.equ	ThisBotAddress = 0b00011001 ; This bot's address

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code

.equ	MovFwdCmd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b01100000 Move Forward Action Code
.equ	MovBckCmd =  ($80|$00)						;0b00000000 Move Backward Action Code
.equ	TurnRCmd =   ($80|1<<(EngDirL-1))				;0b01000000 Turn Right Action Code
.equ	TurnLCmd =   ($80|1<<(EngDirR-1))				;0b00100000 Turn Left Action Code
.equ	HaltCmd =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b10010000 Halt Action Code
.equ	FreezeCmd = 0b11111000

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0002
		rjmp	HitRight
		reti
.org	$0004
		rjmp	HitLeft
		reti
.org	$003C					;USART1, Rx complete
		rjmp	USART1_RXC
		reti
.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
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
		ldi		currentmotion, MovFwd						; Load Move Forward Command
		out		PORTB, currentmotion					; Send command to motors
	; Initialize Logic-Control Flags
		ldi		nHits, 0						; 
		ldi		hitSide, WasNeither
		ldi		ReceiverSR, 0
	; USART1
		; Set asynchronous normal mode
		ldi		mpr, 0 
		sts		UCSR1A, mpr
		; Set baudrate at 2400bps, UBRR = 416
		ldi		mpr, high(416)
		sts		UBRR1H, mpr
		ldi		mpr, low(416)
		sts		UBRR1L, mpr
		; Enable receiver and enable receive interrupts
		;ldi		mpr, (1<<RXEN1)
		ldi		mpr, (1<<TXEN1|1<<RXEN1|1<<RXCIE1) ;uncomment this to enable interrupt behavior
		sts		UCSR1B, mpr
		; Set frame format: 8 data bits, 2 stop bits
		ldi		mpr, (1<<USBS1|1<<UCSZ11|1<<UCSZ10)
		sts		UCSR1C, mpr
	; Initialize external interrupts
		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)
		sts		EICRA, mpr
		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0|1<<INT1)
		out		EIMSK, mpr
		; Turn on interrupts
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		out		PORTB, currentmotion
		;out		PORTB, ReceiverSR
		;rcall UsartPollReceive
		rjmp	MAIN

/*UsartPollReceive:
		lds mpr, UCSR1A
		out PORTB, mpr
		sbrs mpr, RXC1
		rjmp PollSkip
ReadUDR1:
		lds mpr, UDR1
		out PORTB, mpr
PollSkip:
		lds mpr, UCSR1A
		sbrs mpr, FE1 ;this will be written to 0 when you read UDR1
		rjmp PollSkip
		rcall Wait
		lds mpr, UCSR1B
		out PORTB, mpr
		rcall Wait
		lds mpr, UCSR1C
		out PORTB, mpr
		rcall WAIT
		ret*/
;-----------------------------------------------------------
; Func: HitRight()
; Desc: React when the right whisker is hit
;		
;-----------------------------------------------------------
HitRight:							; Begin a function with a label
		; Clear interrupt and disable interrupts
		cli							; clear I-bit in SREG
		ldi		mpr, (0<<INT0|0<<INT1) ; clear corresponding bit
		out		EIMSK, mpr			; in EIMSK register
		out		EIFR, mpr			; in EIFR register

		; Move back
		ldi		mpr, MovBck
		out		PORTB, mpr

		; Wait <waitcnt> secs
		ldi		waitcnt, ReverseTime
		rcall	Wait

		; If (this's an alternating turn or is the first time)
		cpi		hitSide, WasNeither
		breq	CountAltTurnRight	; count hit
		cpi		hitSide, WasHitLeft
		breq	CountAltTurnRight	; count hit
		; Else (same side)
		ldi		nHits, 1			; lose the streak => lose streak
		rjmp	SetTurnLeftTime		; set up time to turn left

CountAltTurnRight:
		inc		nHits				; count up this hit
		; If (this is the 6th alternating hit)
		cpi		nHits, 6
		breq	SetTurnAroundTimeInLeft		; set up time to turn around
		; Else
		rjmp	SetTurnLeftTime
		
SetTurnAroundTimeInLeft:
		ldi		nHits, 0			; reset nHits to 0 
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
		out		EIMSK, mpr			; in EIMSK register
		out		EIFR, mpr			; in EIFR register
		sei							; set I-bit in SREG

		ret					; End a function with RET

;-----------------------------------------------------------
; Func: HitLeft(void)
; Desc: React when the left whisker is hit
;		
;-----------------------------------------------------------
HitLeft:	
		; Clear interrupt and disable interrupts
		cli							; clear I-bit in SREG
		ldi		mpr, (0<<INT0|0<<INT1)
		out		EIMSK, mpr			; in EIMSK register
		out		EIFR, mpr			; in EIFR register

		; Move back
		ldi		mpr, MovBck
		out		PORTB, mpr

		; Wait <waitcnt> secs
		ldi		waitcnt, ReverseTime
		rcall	Wait

		; If (this's an alternating turn)
		cpi		hitSide, WasNeither
		breq	CountAltTurnLeft	; count hit
		cpi		hitSide, WasHitRight
		breq	CountAltTurnLeft	; count hit
		; Else
		ldi		nHits, 1			; reset nHits = 0 => lose the streak
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
		out		EIMSK, mpr			; in EIMSK register
		out		EIFR, mpr			; in EIFR register
		sei							; set I-bit in SREG

		ret					; End a function with RET

;***********************************************************
;*	USART1_RXC
;***********************************************************
USART1_RXC:
		; push stack
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;
		
		; is this address or data?
		out		PORTB, ReceiverSR
ReceiveLoop:
		ldi		XH, high(UCSR1A)
		ldi		XL, low(UCSR1A)
		ld		mpr, X
		sbrs	mpr, RXC1
		rjmp	ReceiveLoop
		ldi		XH, high(UDR1)
		ldi		XL, low(UDR1)
		ld		mpr, X
		sbrs	mpr, UDR17		; check the MSB
		rjmp	RECEIVE_ADDRESS ; receive address
		rjmp	RECEIVE_DATA	; otherwise, receive data

RECEIVE_ADDRESS:
		; if it's an address (start with 0)
		;	if address match
		;		turn on the expect_data flag
		cpi		mpr, 0b01010101 ;this is the freeze command sent from another bot
		breq	FREEZE_HANDLE
		cpi		mpr, ThisBotAddress
		;out		PORTB, mpr
		breq	START_EXPECTING_DATA
		rjmp	END

FREEZE_HANDLE:
		sbrc	ReceiverSR, SkipFreezeFlag
		breq	FREEZE_SKIP
		;add check to see if this bot just sent a freeze command or not
		ldi		mpr, Halt
		out		PORTB, mpr
		ldi		waitcnt, 100
		ldi		ilcnt, 5
FREEZE_LOOP:
		rcall	Wait
		dec ilcnt
		cpi	ilcnt, 0
		brne FREEZE_LOOP
FREEZE_INC:
		sbrc	ReceiverSR, FreezeCnt2 ;this must be the third freeze, loop forever
		rjmp	FREEZE_INF_LOOP
		sbrc	ReceiverSR, FreezeCnt1
		sbr		ReceiverSR, (1<<FreezeCnt2) ;set freezecnt2 to true
		sbrs	ReceiverSR, FreezeCnt1
		sbr		ReceiverSR, (1<<FreezeCnt1) ;set freezecnt1 to true
		rjmp	END
FREEZE_INF_LOOP:
		rjmp	FREEZE_INF_LOOP

FREEZE_SKIP:
		cbr		ReceiverSR, (1<<SkipFreezeFlag)
		rjmp	END

START_EXPECTING_DATA:
		sbr		ReceiverSR, (1<<ExpectingData)	; turn on the expect_data flag expecting a command (0 = expecting_data, 1 = ignore freeze)
		cbr		ReceiverSR, (1<<SkipFreezeFlag)
		rjmp	END

RECEIVE_DATA:
		; if it's an data frame	
		;	if expect_data is set
		
		;		execute command
		;		turn off expect_data flag

		; if flag is set
		sbrc	ReceiverSR, ExpectingData	
		rjmp	LOOK_UP_COMMAND
		rjmp	END

LOOK_UP_COMMAND:
		
		; look up commannd

		; do something with data
		mov		buffer, mpr ;mpr already contains the 

		; turn off expect_data flag
		cbr		ReceiverSR, (1<<ExpectingData)

		; compare with each address
		cpi		buffer, TurnLCmd
		breq	GoLeft
		cpi		buffer, TurnRCmd
		breq	GoRight
		cpi		buffer, MovFwdCmd
		breq	GoForward
		cpi		buffer, MovBckCmd
		breq	GoBackward
		cpi		buffer, HaltCmd
		breq	SetHalt
		cpi		buffer, FreezeCmd
		breq	SendFreeze
		rjmp	END

GoLeft:
		ldi		currentmotion, TurnL
		out		PORTB, currentmotion
		rjmp	END

GoRight:
		ldi		currentmotion, TurnR
		out		PORTB, currentmotion
		rjmp	END

GoForward:
		ldi		currentmotion, MovFwd
		out		PORTB, currentmotion
		rjmp	END

GoBackward:
		ldi		currentmotion, MovBck
		out		PORTB, currentmotion
		rjmp	END

SetHalt:
		ldi		currentmotion, Halt
		out		PORTB, currentmotion
		rjmp	END

SendFreeze:
		lds		mpr, UCSR1A
		sbrs	mpr, UDRE1
		rjmp	SendFreeze
		ldi		mpr, 0b01010101
		sts		UDR1, mpr
		sbr		ReceiverSR, (1<<SkipFreezeFlag)
		rjmp	END

END:
		; pop stack
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		; set global interrupt back
		sei		

		ret

;-----------------------------------------------------------
; Func: Wait(waitcnt)
; Desc: Wait an amount of 10*<waitcnt> miliseconds
;		
;-----------------------------------------------------------
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
