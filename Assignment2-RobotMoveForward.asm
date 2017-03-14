;Griffin Obeid
;COSC 422
;Program to make robot move forward

; uncomment following two lines if using 16f627 or 16f628. config uses internal oscillator
	LIST	p=16F628		;tell assembler what chip we are using
	include "P16F628.inc"	;include the defaults for the chip
	__config 0x3D18			;sets the configuration settings (oscillator type etc.)


; IMPORTANT : The following is very important
; Recall: there is user RAM available starting at location 0x20 upto 0x77 in each bank
; Instead of referring to these locations by NUMBER, why not refer to them by NAME
; counta is an alias for location 0x21
; countb is an alias for location 0x22. HIGHLY RECOMMENDED


	cblock 	0x20 			;start of general purpose registers
		counta 			    ;used in delay routine
		countb 			    ;used in delay routine
	endc


;	list	p=16f84a
;	__config h'3ff1'


	movlw  0x07
	movwf  CMCON			;turn comparators off (make it like a 16F84)

; set b port for output, a port for input

	bsf	   STATUS,RP0    ;Bank 1
	movlw  0x00
	movwf  TRISB		 ;portb is output
	movlw  0xff
	movwf  TRISA		 ;porta is input
	bcf    STATUS,RP0	 ;return to bank 0

top

;turn motor on
	movlw  0x0f
	movwf  PORTB
	call   delay_1_milli	  ;Wait for stop handled in delay loop
	movlw  0xff
	movwf  PORTB
	call   delay_1_milli

;turn motor off
	movlw  0x00
	movwf  PORTB
	call   delay_20_milli


;repeat
	goto   top

delay_20_milli
	movlw	.20
	movwf	countb			    ;careful!! don't use counta
delay_20_loop
	call	delay_1_milli
	decfsz	countb
	goto 	delay_20_loop
	return

delay_1_milli
	movlw 	0x8e                ;142
	movwf	counta
delay_1_loop
	nop
	nop
	decfsz	counta
	goto	delay_1_loop
	return

    end
