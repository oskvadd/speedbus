List      P=16f690		; list directive to define processor
#include "/usr/share/gputils/header/p16f690.inc"
; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
#define ARC_16F         1
;#define ARC_18F         1
#define REC_CUSTOM_JUMP custom_command_handler
#include "../SpeedBus.PIC.Lib.X/speedlib_main.asm"

	     errorlevel -302
	 		__config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOR_OFF & _IESO_OFF & _FCMEN_OFF)

	;; 	__config  _FCMEN_OFF& _IESO_OFF& _MCLRE_OFF& _WDT_OFF& _INTOSCIO
;;;
;;;    _FCMEN_OFF           ; -- fail safe clock monitor enable off
;;;    _IESO_OFF            ; -- int/ext switch over enable off
;;;    _BOR_ON              ; default, brown out reset on
;;;    _CPD_OFF             ; default, data eeprom protection off
;;;    _CP_OFF              ; default, program code protection off
;;;    _MCLR_OFF            ; -- use MCLR pin as digital input
;;;    _PWRTE_OFF           ; default, power up timer off
;;;    _WDT_OFF             ; -- watch dog timer off
;;;    _INTOSCIO            ; -- internal osc, RA6 and RA7 I/O
;;;

;;;  --< constants >---------------------------------------------------
	cblock      USER_VARIABLE_SPACE
        servo_1_val
        endc
;

	radix dec ;

clock   equ     8       ; 8 MHz
baud    equ     19200  ; 19200, 57600, or 115200
brgdiv  equ     4       ; divider value for BRG16 = 1
brgval  equ     (clock*10000000/baud/brgdiv+5)/10-1



	org     0x000
	goto    v_reset
        org	0x004
	goto	intserv

v_reset:
                  bsf   PORTC,0
	          clrf    STATUS ; force bank 0 and IRP = 0        |B0
	          goto    Init	 ;                                 |B0

	;; ******************************************************************
	;;   main init                                                      *
	;; ******************************************************************

Init:
	          bsf     STATUS,RP1 ; bank 2                          |B2
	          clrf    ANSEL	     ; turn off ADC pins               |B2
	          clrf    ANSELH     ; turn off ADC pins               |B2
                  bsf     ANSEL,0
	;;
	;;   setup 8 MHz INTOSC
	;;
	          bcf     STATUS,RP1 ; bank 0                          |B0
	          bsf     STATUS,RP0 ; bank 1                          |B1
                  ;; AD CONFIG
                  movlw   b'01110000'
                  movwf   ADCON1

	          movlw   b'01110000' ; '01110000'                      |B1
	          movwf   OSCCON      ;                                 |B1
Stable:
	          btfss   OSCCON,HTS ; osc stable? yes, skip, else     |B1
	          goto    Stable     ; test again                      |B1
	;;
	;;   setup ports
	;;
		  movlw 0xFF
		  movwf TRISA	; Make PortA all input
	          clrf    TRISB	; setup PORT B all outputs        |B1
	          clrf    TRISC	; setup PORT C all outputs        |B1

                  ; FOR THE AD conversion, TRISC,0 need to be set 1
                  bsf     TRISC,0
	;;
	;; Set interupts
	;;

		movlw   b'00100000'
		movwf	PIE1

	;;
	;;   setup UART module for 19200 baud (8 MHz Clock)
	;;
	          movlw   low(brgval) ;                                 |B1
	          movwf   SPBRG	      ;                                 |B1
	          movlw   high(brgval) ;                                 |B1
	          movwf   SPBRGH       ;                                 |B1
	          bsf     BAUDCTL,BRG16	; select 16 bit BRG               |B1
	          movlw   b'00100100'	; '0-------' CSRC, n/a (async)    |B1
	;;  '-0------' TX9 off, 8 bits      |B1
	;;  '--1-----' TXEN, tx enabled     |B1
	;;  '---0----' SYNC, async mode     |B1
	;;  '----0---' SENDB, send brk      |B1
	;;  '-----1--' BRGH, high speed     |B1
	;;  '------00' TRMT, TX9D           |B1
	          movwf   TXSTA	;                                 |B1
	          bcf     STATUS,RP0 ; bank 0                          |B0
	          movlw   b'10010000' ; '1-------' SPEN, port enabled   |B0
	;;  '-0------' RX9 off, 8 bits      |B0
	;;  '--0-----' SREN, n/a (async)    |B0
	;;  '---1----' CREN, rx enabled     |B0
	;;  '----0---' ADDEN off            |B0
	;;  '-----000' FERR, OERR, RX9D     |B0
	          movwf   RCSTA	;                                 |B0
	          movf    RCREG,W ; flush Rx Buffer                 |B0
	          movf    RCREG,W ;                                 |B0

	;;
	;; Set Interrupts
	;;

		bsf	INTCON, GIE
		bsf	INTCON, PEIE
	;;
	;; SET RX/TX parameters
	;;

	clrf	txreturn

	;; 	Do not clear the adress:es, use the one that is set, read the speedbus text, "Adress handeling system!"
	;; 	clrf	adress1
	;; 	movlw	0x7e
	;; 	movwf	adress1
	;; 	movlw	0x7d
	;; 	movwf	adress2
	;; 	clrf	adress1
	;; 	clrf	adress2

	bcf	rc_gotflag,0

        ;;
        ;; Put a inalization value in the servo area/:s....
        movlw   0x0E
        movwf   servo_1_val

        clrf    PORTB

        ;; Activate AD decoder
        movlw   b'10010001'
        movwf   ADCON0

        call init_checkaddr

main:
	btfsc	RCSTA,OERR
	call    recerror
        bcf     PORTC,0
	;btfsc	PORTA, 0
	;call 	txporta
	incf	rand,F		; Increase the random value
        goto    main

custom_command_handler:
        movlw   0x0A          ; Min  custom
        subwf   INDF,W        ; This is the command data byte, predefinde, before called by this funktion
        movwf   rand          ; Just use the random register rand(no reason why, just a temporary register availble)
        btfss   STATUS,C      ; Check so that the Commmand bit is >= 0x0A ; NOTE: If "addwf PC,F" Gets a zero, it brobubly will act like a "goto $"
        goto    restore

        movlw   2             ; MaxCommand; This is the number of functions in the list bellow, just to make sure its safe for buffer overflow
        subwf   rand,W        ; Command
        btfsc   STATUS,C      ; If Command >= MaxCommand then goto restore
        goto    restore

        movf    rand,W
        addwf   PCL,F
        goto    func1
        goto    func2
        goto    restore



func1:
        call    trd

        bsf     ADCON0,GO
        btfsc   ADCON0,GO
        goto    $-1

      	movlw	rcframe+7	; Move recived byte to W
	movwf	FSR

	movlw   11
	movwf   framelen
	;; 0xff broadcast dst adress
	movlw	0xff
	movwf   txframe
	;; 0xff broadcast dst adress
	movlw	0xff
	movwf   txframe+1
	;; * my own src adress
	movf	adress1, W
	movwf   txframe+2
	;; * my own src adress
	movf	adress2, W
	movwf   txframe+3
	;; 0x03 control bit
	movlw	0x03
	movwf	txframe+4
	;; 0x01	protocoll
        movlw   0x01
	movwf   txframe+5
	;; First Data byte
        movlw	0x02
	movwf   txframe+6
	;; Second Data byte
        bsf     STATUS,RP0
	movf    ADRESL,W
        bcf     STATUS,RP0
        movwf   txframe+7
	;; Third Data Byte
        movf    ADRESH,W
        movwf   txframe+8
	;; Padding bit
	movlw   0x00
        movwf   txframe+9

	;; This is a broadcast package with adress on it
	bsf	txreturn,0
	call	txdo
        goto    restore

func2:
        goto    restore

end