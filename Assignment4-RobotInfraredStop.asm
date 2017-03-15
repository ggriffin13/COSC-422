

; filename: using_timer_interrupts.asm

; This program demonstrates two of the PIC 16F628's timers and
; the use of timer interrupts to trigger events. Each timer
; controls the pulse modulation on one wheel of the Boebot.
; TMR0 controls the right wheel and alternates between a 20ms
; delay and a 1ms delay. TMR2 controls the left wheel and
; alternates between a 20ms delay and a 2ms delay.

; Since the wheels are controlled through an interrupt subroutine,
; the program body is free for other functionality.

	LIST	p=16F628		;tell assembler what chip we are using
	include "P16F628.inc"	;include the defaults for the chip

	__config 0x3D18			;sets the configuration settings

cblock 	0x20 		;start of general purpose registers

	; counter to toggle between 20ms and 1ms
	controlR

	; counter to toggle between 20ms and 2ms
	controlL
	count1 			;used in delay routine
	counta 			;used in delay routine
	countb 			;used in delay routine

	endc

	; as usual, an interrupt sets the PC to 0x04
	org	0x00
	goto	main
	org	0x04
	goto	isr

main

	; turn comparators off (make it like a 16F84)
	movlw	0x07
	movwf	CMCON
init
	banksel	OPTION_REG

	; in OPTION_REG:
	;  bit 6 - 1: Rising edge interrupts 0: falling edge interrupts
	;  bit 5 - enable TMR0
	;  bit 3 - assign prescaler to TMR0
	;  bits 2:0 - set prescaler to 1:128
	movlw	b'11000110'
	movwf	OPTION_REG

	banksel	T2CON

	; in T2CON:
	; bits 6:3 - set postscaler to 1:8
	; bit 2 - turn TMR2 on
	; bits 1:0 - set prescaler to 1:16
	movlw	b'01110111'
	movwf	T2CON

	; enable TMR2 interrupt
	banksel	PIE1
	bsf	PIE1,TMR2IE

	; bit 7 - enable global interrupt (GIE)
	; bit 6 - enable peripheral interrupt
	; bit 5 - enable TMR0 interrupt
	; bit 4 - enable INTE (External interrupts) - for the IR sensor on RB0
	movlw	b'11100000'
	movwf	INTCON

	bsf	STATUS,RP0	;bank 1	
	movlw	b'11111000'
	movwf	TRISA		;porta is input
	movlw	b'11111111'
	movwf	TRISB		;portb is input
	bcf	STATUS,RP0	;return to bank 0

; PROGRAM BODY
; Movement of the wheels is controlled entirely through
; interrupts, leaving our program body free to deal with the IR sensor
;
; RA1 = right wheel, RA2 = left wheel

	clrf	controlR
	clrf	controlL

	; set RA1 low and start TMR0 at 100
	; (256 - 100) * 128 ~ 20,000?, or 20ms
	bcf	PORTA,1
	movlw	d'100'
	movwf	TMR0

	; TMR2 resets when it matches value in PR2`
	; set PR2 to 156
	; 156 * 128 ~ 20,000?, or 20ms
	banksel	PR2
	movlw	d'156'
	movwf	PR2
	bcf	STATUS,RP0	; return to bank 0

	; set RA2 low
	bcf	PORTA,2

loop
	; This is the main loop of the program. Anything
	; can go in here without disrupting or being
	; disrupted by the motion of the wheels.
	btfss	PORTB, 0
	goto	STOP
	goto	loop
	
motorIsOff
	nop
	nop
	nop
	btfss	PORTB, 0
	goto	START
	goto	motorIsOff

; isr
; SUBROUTINE
; Checks INTCON,2 (TMR0 flag) and PIR1,1 (TMR2 flag)
; to determine which threw the interrupt and calls
; appropriate subroutine.
isr
	; check TMR0 interrupt flag
	btfsc	INTCON,2
	call	Right_wheel

	; check TMR2 interrupt flag
	btfsc	PIR1,1
	call	Left_wheel

	retfie

; Right_wheel
; SUBROUTINE
; Toggles RA1 between low for 20ms and high for 1ms.
; Bit 0 of controlR is used as a flag.
Right_wheel
	bcf	INTCON, 2

	btfss	controlR,0
	bsf	PORTA,1
	btfsc	controlR,0
	bcf	PORTA,1

	; modify value in TMR0
	btfss	controlR,0
	movlw	d'248'		;(256 - 248) * 128 ~ 1ms
	btfsc	controlR,0
	movlw	d'100'		;(256 - 100) * 128 ~ 20ms

	movwf	TMR0

	; increment controlR (toggle "flag")
	incf	controlR

	return

; Left_wheel
; SUBROUTINE
; Toggles RA2 between low for 20ms and high for 2ms.
; Bit 0 of controlL is used as a flag.
Left_wheel
	bcf	PIR1,1

	btfss	controlL,0
	bsf	PORTA,2
	btfsc	controlL,0
	bcf	PORTA,2

	; modify value in PR2
	btfss	controlL,0
	movlw	d'16'		;16 * 128 ~ 2000, 2ms
	btfsc	controlL,0
	movlw	d'156'		;156 * 128 ~ 20,000, 20ms

	banksel	PR2
	movwf	PR2
	bcf	STATUS,RP0

	; increment controlL (toggle "flag")
	incf	controlL

	return

START
	call	isr
	goto	loop
	return
	
STOP
	movlw	d'0'	
	movwf	TMR0
	movlw	d'256'
	banksel	PR2
	movwf	PR2
	goto	motorIsOff
	return

	end
