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
	reverseTime	
	numTurns	
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
	
;set up the I/O
    bsf	    STATUS,RP0
    bcf	    0x81, INTEDG	;falling edge interrupts
    movlw   b'00000001'
    movwf   TRISB		;PORTB7:1 = output, PORTB0 = input
    movlw   b'11111000'
    movwf   TRISA		;PORTA7:3 = input, PORTA2:0 = output
    bcf	    STATUS,RP0		;return to bank 0

;Program Body:
			
driveLoop	
    call    goForward
    goto    driveLoop		;Lets  go forward until we hit something

;Subroutine: goForward
;Robot will move forwards
;Pulse right wheel for 1ms and left wheel for 2ms
;Left wheel = RA2 & Right wheel = RA1
goForward	
    bsf	    PORTB, 4
    movlw   b'00000110'
    movwf   PORTA		;runs both servos as high
    call    wait1ms		;for 1ms
			
    bcf	    PORTA, 1		;turns off right servo
    call    wait1ms		;for 1ms

    bcf	    PORTA, 2		;turns off the left servo

    call    waiter		;waits for the rest of the required time
    return

;Subroutine: goBackward
;Robot will move backwards
;Pulse right wheel for 2ms and left wheel for 1ms
;Left wheel = RA2 & Right wheel = RA1
goBackward
    movlw   0x50
    movwf   reverseTime

backward	
    movlw   b'00000110'	
    movwf   PORTA		;runs both servos as high
    call    wait1ms		;for 1ms
			
    bcf	    PORTA, 2		;turns off left servo
    call    wait1ms		;for 1ms

    bcf	    PORTA, 1		;turns off the right servo

    call    waiter		;waits for the rest of the required time
    decfsz  reverseTime, f
    goto    backward
			
    return

;Subroutine: turn
;Turns the robot approximately 90 degrees to the right
turn	
    movlw   0x7			;decrementer for timing the angle of the turn
    movwf   numTurns
rightStart	
    movlw   b'00000110'
    movwf   PORTA
    call    wait1ms
    call    wait1ms		;waits for 2ms (forward full speed for both)

    movlw   0x00
    movwf   PORTA
    
    call    waiter
    decfsz  numTurns, f
    goto    rightStart
			
    return

;Subroutine: waiter
;Waits for about 20ms for inbetween pulses on the servos motors
waiter 		
    movlw   0x3A		;20ms 
    movwf   counterA
    movlw   0x10
    movwf   counterB
waiter_in	
    decfsz  counterA, f
    goto    $+2
    decfsz  counterB, f
    goto    waiter_in
			
    goto    $+1			;3 cycles
    nop
			
    return			;4 cycles
			
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
			
;Interrupt Subroutine
isr
    call    goBackward		;lets go back
    
    call    turn		;now lets turn		
    goto    endIsr		;back to going forward

endIsr		
    bcf	    INTCON,INTF		;reset the interrupt	
    retfie

	end