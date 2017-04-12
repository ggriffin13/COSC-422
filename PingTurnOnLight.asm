;Griffin Obeid
;3/22/2017
;===============================================================================
;When this program is finished it will turn on a light when the PING))) sesnsor
;receives its ultrasonic signal back.
;===============================================================================
; uncomment following two lines if using 16f627 or 16f628.
    LIST    p=16F628  ;tell assembler what chip we are using
    include "P16F628.inc" ;include the defaults for the chip
    __config 0x3D18   ;sets the configuration settings

    cblock  0x20    ;start of general purpose registers
        counterA   ;counterA is used in delay routines
        counterB   ;counterB is used in delay routines
        decrementer  ;decrement from 145 to 0 for waiting for signal
        interrupted
    endc

;same setup for every program using interrupts
    org 0x00
    goto  main
    org 0x04
    goto  isr

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
    btfss   interrupted, 1
    goto    wait
    clrf    interrupted
    goto    wait

;Subroutine: pulsePing
;Pulse RB0 line high for 3-4 microseconds
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

;Interrupt Subroutine
isr
    btfsc   INTCON, INTF    ;B0 interrupt?
    call    B0interrupt
    btfsc   INTCON, T0IF    ;TMR0 interrupt?
    call    T0interrupt

    movlw   d'1'
    movwf   interrupted
    retfie

B0interrupt ;check the number in TMR0 and set led
    bcf     INTCON, INTF
    movlw   .140            ;im not sure what this works out to but its here
    addwf   TMR0, w
    btfss   STATUS, C       ;check the carry out bit
    bsf     PORTA, RA2      ;Yellow LED
    btfsc   STATUS, C       ;check the carry out bit
    bcf     PORTA, RA2
    return

T0interrupt     ;Repulse the sensor when TMR0 overflows
    bcf     INTCON, T0IF
    call    pulsePing
    bsf     PORTA, RA0      ;Red LED
    clrf    TMR0            ;TODO I dont think we need to clear before we move something into the file
    movlw   d'99'           ;20 ms in tmr0 before pulsing again.
    movwf   TMR0
    return

  end
