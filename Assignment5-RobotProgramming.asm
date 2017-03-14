;Griffin Obeid
;COSC 422
;Pulse servo with a timer interrupt
;We'll use the timer to generate an interrupt every 20 milliseconds


	LIST	p=16F628		;tell assembler what chip we are using
	include "P16F628.inc"		;include the defaults for the chip
	ERRORLEVEL	0,	-302	;suppress bank selection messages
	__config 0x3D18			;sets the configuration settings (oscillator type etc.)

; Registers we'll need:
;
; INTCON=0x0B
;		7	6	5	4	3	2	1	0
;		GIE	EEIE	TOIE	INTE	RBIE	TOIF	INTF	RBIF
; OPTION=0X81
;		RBPU	INTEDG	TOCS	TOSE	PSA	PS2	PS1	PS0
;
;		RBPU<-1 PORT B pull up resistors disabled
;		INTEGD<-1 rising edge on RB0/int
;		TOCS<-1 source is RB0, <-0 source is internal clock
;		PSA<-1 WDT, <-0 Timer0
;		PS2:PS0 prescaler 000<-wdt 1:1, timer0 1:2,etc . timer0 1:1 prescaler, set PSA<-1
;

;-------------------------------------------------------------------------------
	cblock	0X20
		COUNT
		COUNT1
	endc

	org	0x00
	goto start_it

; send out a high pulse for depending on A1A0
;
;	A1	A0	Pulse	Servo Position (hopefully)
;	0	0	1.0	Completely clockwise
;	0	1	1.33	One third counterclockwise from preceeding
;	1	0	1.66	Two thirds counterclockwise
;	1	1	2.0	Fully counterclockwise
;-------------------------------------------------------------------------------
	org 0x04		         	;interrupt vector
	movlw 0xff
	movwf	PORTB		     	;turn on lights
	call	OnePointZero	 	;we know there is a pulse of at least 1.0 msec

	btfsc	PORTA,0
	call	PointThreeThree	  	;A0=1, so pulse another 0.33 msec
	btfss	PORTA,1		      	;A1=1, so skip next statement
	goto 	Finish_Up
	call	PointThreeThree	  	;pulse another 0.33 msec
	call	PointThreeThree

Finish_Up
	movlw	0x00
	movwf	PORTB		       	;turn lights off
	movlw	d'99'		       	;set up timer 0 interrupt for 20 msec
	movwf	TMR0
	bcf	    INTCON,T0IF	        ;IMPORTANT - re-enable timer interrupt
	retfie
;-------------------------------------------------------------------------------
start_it						;Main

	movlw	0x07
	movwf	CMCON				;turn comparators off (make it like a 16F84)

	clrwdt						;just make sure nothing goes off!

	bsf	STATUS,RP0              ;Bank 1
	movlw	b'11010110'
	movwf	OPTION_REG	        ;128-1 prescaler with timer0
	movlw	0x00
	movwf	TRISB		        ;Port B is output
	movlw	0xff
	movwf	TRISA		        ;Port A is input
	bcf	STATUS,RP0	            ;back to bank 0

	bsf	INTCON,GIE	            ;enable global interrupts
	bsf	INTCON,T0IE	            ;enable timer 0 interrupt
	bcf	INTCON,T0IF

	movlw	d'99'		        ;256-99=157  , 157*128 is 20096, about 20 msec
	movwf	TMR0


	movlw	0x00
	movwf	PORTB				;turn off lights
more
	goto more					;wait for an interrupt
;-------------------------------------------------------------------------------
OnePointZero					;1.0 millisecond delay loop
	movlw 0x02
	movwf	COUNT1
xxx
	movlw	d'165'
	movwf	COUNT
here
	decfsz	COUNT
	goto here
	decfsz	COUNT1
	goto xxx
	return
;-------------------------------------------------------------------------------
PointThreeThree					;0.33 millisecond delay loop
	movlw	d'108'
	movwf	COUNT
here2
	decfsz	COUNT
	goto 	here2
	return
	end
