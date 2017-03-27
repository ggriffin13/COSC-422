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
    bsf	    INTCON, GIE		;enable interrupts
    bsf	    INTCON, INTE	;B0 is the interrupt line
    bcf     INTCON, T0IE

;set up the I/O
    bsf	    STATUS,RP0
    bcf	    0x81, INTEDG	;falling edge interrupts
    movlw   b'11111111'
    movwf   TRISB		    ;PORTB is input
    movlw   b'00000000'
    movwf   TRISA		    ;PORTA is output
    bcf	    STATUS,RP0		;return to bank 0

    movlw   B'11011000'
    movwf   OPTION_REG      ;TMR0 Setup

;Program Body:
loop
    call    listen
    goto    loop		  ;Lets  go forward until we hit something

;Subroutine: listen
;Count
listen




;Subroutine: wait1ms
;Wait for 1 ms so that we can pulse our servos motors high for the correct
;amount of time.
wait1ms
    movlw   0xC6		;1 ms
    movwf   counterA
    movlw   0x01
    movwf   counterB
wait1ms_in
    decfsz  counterA, f
    goto    $+2
    decfsz  counterB, f
    goto    wait1ms_in

    goto    $+1			;3 cycles
    nop

    return			;4 cycles

;Subroutine: pulsePing
;Pulse RB0 line high for 3-4 microseconds
pulsePing

    bsf     PORTB, 0
    nop
    nop
    bcf     PORTB, 0
    goto    wait_865micro
    movlw   d'99'
    movwf   TMR0
    bsf     INTCON, T0IE

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
    ;get the value of tmr0 here
    
    goto    endIsr		;back to going forward

endIsr
    bcf	    INTCON,INTF		;reset the interrupt
    retfie

	end
