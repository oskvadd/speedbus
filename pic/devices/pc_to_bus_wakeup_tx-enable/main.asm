List      P=16f690              ; list directive to define processor
#include <p16f690.inc>
             errorlevel -302
        	__config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOR_OFF & _IESO_OFF & _FCMEN_OFF)

;;;       __config  _FCMEN_OFF& _IESO_OFF& _MCLRE_OFF& _WDT_OFF& _INTOSCIO
;;; ;
;;; ;    _FCMEN_OFF           ; -- fail safe clock monitor enable off
;;; ;    _IESO_OFF            ; -- int/ext switch over enable off
;;; ;    _BOR_ON              ; default, brown out reset on
;;; ;    _CPD_OFF             ; default, data eeprom protection off
;;; ;    _CP_OFF              ; default, program code protection off
;;; ;    _MCLR_OFF            ; -- use MCLR pin as digital input
;;; ;    _PWRTE_OFF           ; default, power up timer off
;;; ;    _WDT_OFF             ; -- watch dog timer off
;;; ;    _INTOSCIO            ; -- internal osc, RA6 and RA7 I/O
;;; ;

;;; ;  --< constants >---------------------------------------------------

	radix dec

clock   equ     8       	; 8 MHz
baud    equ     19200  	; 19200, 57600, or 115200
brgdiv  equ     4       ; divider value for BRG16 = 1
brgval  equ     (clock*10000000/baud/brgdiv+5)/10-1
	

	cblock  0x20
	             d1		; Define three file registers for the
	             d2		; delay loop
	             d3
	             d4
	endc
	
	org     0x000
	goto 	Init
	org	0x004
	goto	intserv

Init:	
			bsf     STATUS,RP1 ; bank 2                          |B2
			clrf    ANSEL      ; turn off ADC pins               |B2
			clrf    ANSELH     ; turn off ADC pins               |B2
;;;
;;;    setup 8 MHz INTOSC
;;;
			bcf     STATUS,RP1 ; bank 0                          |B0
			bsf     STATUS,RP0 ; bank 1                          |B1
			movlw   b'01110000' ; '01110000'                      |B1
			movwf   OSCCON      ;                                 |B1
Stable:			
			btfss   OSCCON,HTS ; osc stable? yes, skip, else     |B1
			goto    Stable     ; test again                      |B1
;;;
;;;    setup ports
;;;
			movlw 0xFF
			movwf TRISA ; Make PortA all input
			clrf    TRISB ; setup PORT B all outputs        |B1
			clrf    TRISC ; setup PORT C all outputs        |B1
;;;
;;;  Set interupts
;;;

			movlw   b'00100000'
			movwf   PIE1

;;;
;;;    setup UART module for 19200 baud (8 MHz Clock)
;;;
			movlw   low(brgval) ;                                 |B1
			movwf   SPBRG       ;                                 |B1
			movlw   high(brgval) ;                                 |B1
			movwf   SPBRGH       ;                                 |B1
			bsf     BAUDCTL,BRG16 ; select 16 bit BRG               |B1
			movlw   b'00100100'   ; '0-------' CSRC, n/a (async)    |B1
;;;   '-0------' TX9 off, 8 bits      |B1
;;;   '--1-----' TXEN, tx enabled     |B1
;;;   '---0----' SYNC, async mode     |B1
;;;   '----0---' SENDB, send brk      |B1
;;;   '-----1--' BRGH, high speed     |B1
;;;   '------00' TRMT, TX9D           |B1
			movwf   TXSTA ;                                 |B1
			bcf     STATUS,RP0 ; bank 0                          |B0
			movlw   b'10010000' ; '1-------' SPEN, port enabled   |B0
;;;   '-0------' RX9 off, 8 bits      |B0
;;;   '--0-----' SREN, n/a (async)    |B0
;;;   '---1----' CREN, rx enabled     |B0
;;;   '----0---' ADDEN off            |B0
;;;   '-----000' FERR, OERR, RX9D     |B0
			movwf   RCSTA ;                                 |B0
			movf    RCREG,W ; flush Rx Buffer                 |B0
			movf    RCREG,W ;                                 |B0         
;;;
;;;  Set Interrupts
;;;

			bsf     INTCON, GIE
	                bsf     INTCON, PEIE
;;;
;;;  SET RX/TX parameters
;;;

;;;       Do not clear the adress:es, use the one that is set, read the speedbus text, "Adress handeling system!"
;;;       clrf    adress1
;;;       clrf    adress2
			bcf	PORTB,4
	
start:
			btfsc   RCSTA,OERR
			call 	recerror
			goto	start

intserv:
			bcf     INTCON, GIE
			bsf	PORTB,4
			bsf	PORTC,0
			bsf	PORTC,3
			clrf	RCREG
			
			btfsc   RCSTA,OERR
			call 	recerror
			movlw	0
			call 	Delay
			btfsc   PIR1,RCIF       	;       Check if the recived data bit is set
			goto    intserv
			bcf	PORTB,4
			bcf	PORTC,3
			retfie

recerror:
;;;  Do somthing
	        bcf     RCSTA,CREN
	        bsf     RCSTA,CREN
	        return
	
	
Delay:
;;;  499994 cycles
	        movwf   d3
	        movlw   0xFF
	        movwf   d2
	        movlw   50
	        movwf   d1
Delay_0:
	        decfsz  d1, f
	        goto    $-1
	        movlw   20	; Need this for tuning
	        movwf   d1
	        decfsz  d2, f
	        goto    $-6
	        movlw   100
	        movwf   d2
	        decfsz  d3, f
	        goto    Delay_0
	        return
	        end
	