;TODO: Add header
; uncomment following two lines if using 16f627 or 16f628.
    LIST    p=16F628  ;tell assembler what chip we are using
    include "P16F628.inc" ;include the defaults for the chip
    __config 0x3D18   ;sets the configuration settings

    cblock  0x20    ;start of general purpose registers
        counterA    ;counterA is used in delay routines
        counterB    ;counterB is used in delay routines
        numTurns    ;Used to time the turning of boebot
    endc

;same setup for every program using interrupts
    org 0x00
        goto    main
    org 0x04
        goto    isr

main
;turn comparators off (make it like a 16F84)
    movlw   0x07
    movwf   CMCON

;turn B0 interrupts on (peripheral)
    movlw   b'10110000' ;INTCON register setup: B0, TMR0, and GIE turned on
    movwf   INTCON

;set up the I/O
    bsf     STATUS, RP0
    bcf     OPTION_REG, INTEDG    ;falling edge interrupts
    movlw   b'11111101'
    movwf   TRISB           ;PORTB is input
    movlw   b'00000000'
    movwf   TRISA           ;PORTA is output
    movlw   B'10010110'     ;128:1 prescalar
    movwf   OPTION_REG      ;TMR0 Setup
    bcf     STATUS, RP0     ;return to bank 0



    call    wait_865micro
    call    pulsePing

    clrf    TMR0            ;TODO I dont think we need to clear before we move something into the file
    movlw   d'99'          ;20 ms in tmr0 before pulsing again.
    movwf   TMR0
    bsf     INTCON, T0IE    ;enable tmr0 interrupts

wait   ;wait here for an interupt to happen

    goto    wait

;===============================================================================
;The following area is for subroutines
;===============================================================================

;Subroutine: pulsePing
;Pulse RB0 line high for 3-4 microseconds
;This allows the ping sensor to start up
pulsePing
    bcf     INTCON, INTE    ;turn off B0 interrupts
    bsf     STATUS, RP0     ;bank1
    movlw   b'11111110'
    movwf   TRISB           ;PORTB is input
    bcf     STATUS, RP0     ;bank0

    bsf     PORTB, RB0
    nop
    nop
    nop
    nop
    nop
    bcf     PORTB, RB0
    ;call    wait_865micro

    bsf     STATUS, RP0     ;bank1
    movlw   b'11111111'
    movwf   TRISB           ;PORTB is input
    bcf     STATUS, RP0     ;bank0
    bcf     INTCON, INTF    ;Make sure the flag is clear
    bsf     INTCON, INTE    ;turn B0 interrupts back on
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
    return

;Subroutine: wait1ms
;Wait for 1 ms so that we can pulse our servos motors high for the correct
;amount of time.
wait1ms
    movlw   0xC6		      ;1 ms
    movwf   counterA
    movlw   0x01
    movwf   counterB
wait1ms_in
    decfsz  counterA, f
    goto    $+2
    decfsz  counterB, f
    goto    wait1ms_in
    goto    $+1			       ;3 cycles
    nop
    return			           ;4 cycles

;Interrupt Subroutine
isr
    btfsc   INTCON, INTF    ;B0 interrupt?
    call    B0interrupt
    btfsc   INTCON, T0IF    ;TMR0 interrupt?
    call    T0interrupt

    retfie

;Subroutine: B0interrupt
;Handles the case that we get a B0 interrupt.
;If the boebot is close enough to an object it will turn.
B0interrupt ;check the number in TMR0 and set led
    bcf     INTCON, INTF    ;Clear B0 interrupt flag
    movlw   .140            ;Change this to affect ping distance
    addwf   TMR0, w

    btfss   STATUS, C       ;check the carry out bit
    ;TODO: Not sure if turn will work here
    call    turn            ;Handles the situation in which we are close to obj
    ;btfsc   STATUS, C       ;check the carry out bit
    ;bcf     PORTA, RA2
    return

;Subroutine: T0interrupt
;Handles the case that we get a TMR0 interrupt
;This subroutine handles the boebot moving forward since we have 20 ms in TMR0
T0interrupt     ;Repulse the sensor when TMR0 overflows
    bcf     INTCON, T0IF    ;Clear TMR0 interrupt flag
    call    pulsePing
    bsf     PORTA, RA0      ;Red LED
    call    goForward
    clrf    TMR0            ;TODO I dont think we need to clear before we move something into the file
    movlw   d'99'           ;20 ms in tmr0 before pulsing again.
    movwf   TMR0
    return

;Subroutine: goForward
;Robot will move forwards
;Pulse right wheel for 1ms and left wheel for 2ms
;Left wheel = RA2 & Right wheel = RA1
goForward
    movlw   b'00000110'
    movwf   PORTA		;runs both servos as high
    call    wait1ms		;for 1ms
    bcf	    PORTA, 1		;turns off right servo
    call    wait1ms		;for 1ms
    bcf	    PORTA, 2		;turns off the left servo
    return


;Subroutine: turn
;Turns the robot approximately 90 degrees to the right
turn
    movlw   .7			;decrementer for timing the angle of the turn
    movwf   numTurns
rightStart
    movlw   b'00000110'
    movwf   PORTA
    call    wait1ms
    call    wait1ms		;waits for 2ms (forward full speed for both)

    movlw   b'00000000'
    movwf   PORTA

    decfsz  numTurns, f
    goto    rightStart

    return

  end       ;need it
