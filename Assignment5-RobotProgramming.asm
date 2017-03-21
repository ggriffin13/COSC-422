;Griffin Obeid
;Make the robot move forward using TMR0 and TMR2
;Some code borrowed from the second group of grad Students to present.
;
;In this program TMR0 deals with one wheel
;While TMR2 is on the other wheel.
;The main program body (loop) will deal with the sensors

	LIST	 p=16F628	;tell assembler what chip we are using
	include  "P16F628.inc"	;include the defaults for the chip
	__config 0x3D18		;sets the configuration settings

cblock 	0x20 			;start of general purpose registers

	controlR		;counter to toggle between 20ms and 1ms
	controlL		;counter to toggle between 20ms and 2ms
	CounterA
	CounterB
	CounterC

	endc

	org	0x00
	goto	main
	org	0x04		;as usual, an interrupt sets the PC to 0x04
	goto	isr

main
	;turn comparators off (make it like a 16F84)
	movlw	0x07
	movwf	CMCON

;in OPTION_REG:
;bit 5 - enable TMR0
;bit 3 - assign prescaler to TMR0
;bits 2:0 - set prescaler to 1:128
	banksel	OPTION_REG
	movlw	b'10000110'
	movwf	OPTION_REG

;in T2CON:
;bits 6:3 - set postscaler to 1:8
;bit 2 - turn TMR2 on
;bits 1:0 - set prescaler to 1:16
	banksel	T2CON
	movlw	b'01110111'
	movwf	T2CON

;enable TMR2 interrupt
	banksel	PIE1
	bsf	PIE1,TMR2IE

;bit 7 - enable global interrupt (GIE)
;bit 6 - enable peripheral interrupt
;bit 5 - enable TMR0 interrupt
	movlw	b'11100000'
	movwf	INTCON

	bsf	STATUS,RP0		;select bank 1
	movlw	b'11110000'		
	movwf	TRISB			;portb 7:4 input, 3:0 output
	movlw	b'11111000'
	movwf	TRISA			;Porta 7:3 input, 2:0 output
	bcf	STATUS,RP0		;return to bank 0

;PROGRAM BODY
;Movement of the wheels is controlled entirely through
;interrupts, leaving our program body free to deal with anything else really
;RA1 has right wheel | RA2 has left wheel
top
	call 	init_Servos
loop
	btfss	PORTB, 0		;RB0 has antenna sensors
	call	Reverse_and_turn
	goto	loop

;isr
;SUBROUTINE
;Checks INTCON,2 (TMR0 flag) and PIR1,1 (TMR2 flag)
;to determine which threw the interrupt and calls
;appropriate subroutine.
isr
	btfsc	INTCON,2		;check TMR0 interrupt flag
	call 	Right_wheel
	btfsc	PIR1,1			;check TMR2 interrupt flag
	call 	Left_wheel

	retfie
	
;isr2
;SUBROUTINE
;Same as isr but go in reverse instead
isr2
	btfsc	INTCON,2		;check TMR0 interrupt flag
	call 	Right_wheel_reverse
	btfsc	PIR1,1			;check TMR2 interrupt flag
	call 	Left_wheel_reverse

	retfie
	
;isr3
;SUBROUTINE
;Same as isr but turns the dude instead
isr3
	btfsc	INTCON,2		;check TMR0 interrupt flag
	call 	Right_wheel_reverse
	btfsc	PIR1,1			;check TMR2 interrupt flag
	call 	Left_wheel

	retfie

;Right_wheel
;SUBROUTINE
;Toggles RA1 between low for 20ms and high for 1ms.
;Bit 0 of controlR is used as a flag.
Right_wheel
	bcf	INTCON,2

	btfss	controlR,0
	bsf	PORTA,1
	btfsc	controlR,0
	bcf	PORTA,1

	btfss	controlR,0		;modify value in TMR0
	movlw	d'248'			;1 ms
	btfsc	controlR,0
	movlw	d'100'			;20 ms
	movwf	TMR0
	incf	controlR		;increment controlR (toggle "flag")

	retfie

;Right_wheel_reverse
;SUBROUTINE
;Toggles RA1 between low for 20ms and high for 2ms.
;Bit 0 of controlR is used as a flag.
Right_wheel_reverse
	bcf	INTCON,2

	btfss	controlR,0
	bsf	PORTA,1
	btfsc	controlR,0
	bcf	PORTA,1

	btfss	controlR,0		;modify value in TMR0
	movlw	d'240'			;2 ms
	btfsc	controlR,0
	movlw	d'100'			;20 ms
	movwf	TMR0
	incf	controlR		;increment controlR (toggle "flag")

	retfie

;Left_wheel
;SUBROUTINE
;Toggles RA2 between low for 20ms and high for 2ms.
;Bit 0 of controlL is used as a flag.
Left_wheel
	bcf	PIR1,1

	btfss	controlL,0
	bsf	PORTA,2
	btfsc	controlL,0
	bcf	PORTA,2

	btfss	controlL,0		;modify value in PR2
	movlw	d'16'			;2 ms
	btfsc	controlL,0
	movlw	d'156'			;20 ms

	banksel	PR2
	movwf	PR2
	bcf	STATUS,RP0
	incf	controlL		;increment controlL (toggle "flag")

	retfie

;Left_wheel_reverse
;SUBROUTINE
;Toggles RA2 between low for 20ms and high for 1ms.
;Bit 0 of controlL is used as a flag.
Left_wheel_reverse
	bcf	PIR1,1

	btfss	controlL,0
	bsf	PORTA,2
	btfsc	controlL,0
	bcf	PORTA,2

	btfss	controlL,0		;modify value in PR2
	movlw	d'8'			;1 ms
	btfsc	controlL,0
	movlw	d'156'			;20 ms

	banksel	PR2
	movwf	PR2
	bcf	STATUS,RP0
	incf	controlL		;increment controlL (toggle "flag")

	retfie

;Reverse_and_turn
;SUBROUTINE
;This subroutine gets called when the antenna sensor rams into the wall
;Reverses the dude, turns the dude, then dude starts moving forward again
Reverse_and_turn
	goto	init_Servos
	goto	isr2
	
	call	DelayOneSecond
	call	DelayOneSecond
	
	goto	init_Servos
	goto	isr3
	
	call	DelayOneSecond
	
	goto	init_Servos
	goto	isr
	return

;init_Servos
;SUBROUTINE
;Must Be called before the motor starts back up
init_Servos
	clrf	controlR
	clrf	controlL

	;set RA1 low and start TMR0 at 100
	;(256 - 100) * 128 ~ 20,000?, or 20ms
	bcf	PORTA,1
	movlw	d'100'
	movwf	TMR0

	;TMR2 resets when it matches value in PR2
	;set PR2 to 156
	;156 * 128 ~ 20,000?, or 20ms
	banksel	PR2
	movlw	d'156'
	movwf	PR2
	bcf	STATUS,RP0		;return to bank 0

	bcf	PORTA,2			;set RA2 low
	return

;DelayOneSecond
;SUBROUTINE DELAY
;Timed delay for 1 second
DelayOneSecond
	movlw	d'6'
	movwf	CounterC
	movlw	d'24'
	movwf	CounterB
	movlw	d'168'
	movwf	CounterA
keepGoing
	decfsz	CounterA, 1
	goto	keepGoing
	decfsz	CounterB, 1
	goto	keepGoing
	decfsz	CounterC, 1
	goto	keepGoing
	return

	end
