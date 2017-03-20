;Very simple program to flash infrared 38,000 times
;Pull up resistor on RA1
;Infrared LED on any pin on PORTB

	LIST	p=16F628		;tell assembler what chip we are using
	include "P16F628.inc"		;include the defaults for the chip
	__config 0x3D18			;sets the configuration settings (oscillator type etc.)

	cblock 	0x20 			;start of general purpose registers
	endc

	org	0x0000			;org sets the origin, 0x0000 for the 16F628,
					;this is where the program starts running
	movlw	0x07
	movwf	CMCON			;turn comparators off (make it like a 16F84)

	bsf	STATUS,RP0
	movlw	0x00
	movwf	TRISB		; Port B is output
	movlw	0xff
	movwf	TRISA		; Port A is input
	bcf	STATUS,RP0	; back to bank 0

top
	btfss	PORTA, 1
	call	flashIR
	goto	top

flashIR
	movlw 0x00
	movwf PORTB
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	movlw	0xff
	movwf	PORTB
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	btfss	PORTA, 1
	goto 	flashIR
	return

	end
