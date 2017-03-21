;Griffin Obeid
;Make the robot move forward using TMR0 and TMR2
;Some code borrowed from the second group of grad Students to present.
;I figured since I'm turning this in late that I should use interrupts for
;the wheels.
;
;In this program each TMR0 deals with one wheel while
;While TMR2 is on the other wheel.
;This will leave our main program open for whatever we want in the future.

	LIST	 p=16F628	    ;tell assembler what chip we are using
	include  "P16F628.inc"	    ;include the defaults for the chip
	__config 0x3D18		    ;sets the configuration settings

cblock 	0x20			    ;start of general purpose registers

	controlR		    ;counter to toggle between 20ms and 1ms
	controlL		    ;counter to toggle between 20ms and 2ms

	endc

	;as usual, an interrupt sets the PC to 0x04
	org	0x00
	goto	main
	org	0x04
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

	bsf	STATUS,RP0	    ;select bank 1
	movlw	0x00
	movwf	TRISB		    ;portb is output
	movlw	b'11111000'
	movwf	TRISA		    ;Porta 7:3 input, 2:0 output
	bcf	STATUS,RP0	    ;return to bank 0

;PROGRAM BODY
;Movement of the wheels is controlled entirely through
;interrupts, leaving our program body free to deal with anything else really
;RA1 has right wheel | RA2 has left wheel
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
	bcf	STATUS,RP0	    ;return to bank 0

	bcf	PORTA,2		    ;set RA2 low

loop
	;I'll use this area in the future for the sensors
	goto	loop

;isr
;SUBROUTINE
;Checks INTCON,2 (TMR0 flag) and PIR1,1 (TMR2 flag)
;to determine which threw the interrupt and calls
;appropriate subroutine.
isr
	btfsc	INTCON,2	    ;check TMR0 interrupt flag
	call 	Right_wheel
	btfsc	PIR1,1		    ;check TMR2 interrupt flag
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

	btfss	controlR,0	    ;modify value in TMR0
	movlw	d'248'
	btfsc	controlR,0
	movlw	d'100'
	movwf	TMR0
	incf	controlR	    ;increment controlR (toggle "flag")

	return

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

	btfss	controlL,0	    ;modify value in PR2
	movlw	d'16'
	btfsc	controlL,0
	movlw	d'156'

	banksel	PR2
	movwf	PR2
	bcf	STATUS,RP0
	incf	controlL	    ;increment controlL (toggle "flag")

	return
	
	end
