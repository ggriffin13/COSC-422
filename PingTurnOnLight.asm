;Griffin Obeid
;3/22/2017
;===============================================================================
;This program moves the boe-bot forward until the antenna sensors hit something
;then it moves backwards shortly, turns to the right ~ 90 degrees, and then
;continues moving forward.
;===============================================================================
; uncomment following two lines if using 16f627 or 16f628.
    LIST    p=16F628	;tell assembler what chip we are using
    include "P16F628.inc"	;include the defaults for the chip
    __config 0x3D18		;sets the configuration settings

    cblock 	0x20 		;start of general purpose registers
	   counterA		;counterA is used in delay routines
	   counterB		;counterB is used in delay routines
       decrementer  ;decrement from 145 to 0 for waiting for signal
       interrupted
	endc

;same setup for every program using interrupts
	org	0x00
	goto	main
	org	0x04
	goto	isr

main
;turn comparators off (make it like a 16F84)
    movlw   0x07
    movwf   CMCON

;turn B0 interrupts on (peripheral)
    bsf	   INTCON, GIE		;enable interrupts

    bcf    INTCON, T0IE    ;disable interrupts on TMR0 until ready

;set up the I/O
    bsf	    STATUS,RP0
    bcf	    0x81, INTEDG	;falling edge interrupts
    movlw   b'11111101'
    movwf   TRISB		    ;PORTB is input
    movlw   b'00000000'
    movwf   TRISA		    ;PORTA is output
    bcf	    STATUS,RP0		;return to bank 0

    movlw   B'11011110'
    movwf   OPTION_REG      ;TMR0 Setup

    bsf     PORTA, 1
    clrf    interrupted

loop
    ;turn on the led if we get a pulse back within the time it takes for
    ;it to decrements
    call    pulsePing
    clrf    TMR0
    movlw   d'113'          ;20 ms in tmr0 before pulsing again.
    movwf   TMR0
    bsf     INTCON, T0IE    ;enable tmr0 interrupts

waitForT0
    btfss   interrupted, 1
    goto    waitForT0
    clrf    interrupted
    goto    loop
;Subroutine: pulsePing
;Pulse RB0 line high for 3-4 microseconds
pulsePing
    bcf     INTCON, INTE
    bsf     PORTB, 1
    nop
    nop
    nop
    bcf     PORTB, 1
    call    wait_865micro
    bsf     INTCON, INTE	    ;B0 is the interrupt line
    return

;Subroutine: wait_865micro
;Waits 865 micro seconds for the sonar echo holdoff
wait_865micro
    movlw   0xAB        ;171
    movwf   counterA
again
    nop
    nop
    nop
    decfsz  counterA
    goto    again
    nop
    nop
    nop
    nop
    return

;Interrupt Subroutine
isr
    btfsc   INTCON, INTF
    bsf     PORTA, 2

    movlw   d'1'
    movwf   interrupted
    bcf     INTCON, INTF
    bcf     INTCON, T0IF
    retfie

	end
