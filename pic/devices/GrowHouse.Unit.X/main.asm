    List      P=16f690		; list directive to define processor

#include "P16F690.INC"

; CONFIG
; __CONFIG _CONFIG1, 0x30D5
 __CONFIG _INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF

; RA1 = Check for led strip 1
; RC2 = Check for led strip 2
; RB6 = Controller for fan

; RA5 = Temp in grow house
; RA4 = Temp for heat sink


; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
#define ARC_16F         1
;#define ARC_18F         1
#define REC_CUSTOM_JUMP     custom_command_handler
;#define CUSTOM_INTERRUPT    c_intserv
#define DEV_ID1 64
#define DEV_ID2 49
#define WRITE_EEPROM write_eeprom
#define READ_EEPROM read_eeprom
#include "../SpeedBus.PIC.Lib.X/speedlib_main.asm"

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

	radix dec

clock   equ     8       ; 8 MHz
baud    equ     19200  ; 19200, 57600, or 115200
brgdiv  equ     4       ; divider value for BRG16 = 1
brgval  equ     (clock*10000000/baud/brgdiv+5)/10-1


	cblock  USER_VARIABLE_SPACE
    res_h
    res_l

        divisL
        divisH
        remdrL    ; and then into partial remainder
        remdrH
        bitcnt
        res1
        res2
        res3
        res4
        a1
        a2
        b1
        b2
        temp1
        temp1r ; Inside house reminder
        temp2
        temp2r ; Outside house reminder
        fan_s
	endc

	org     0x000
	goto    v_reset
	org     0x004
	goto	intserv


v_reset:
	          clrf    STATUS ; force bank 0 and IRP = 0        |B0
              banksel INTCON
              bcf	  INTCON, GIE
	          goto    Init	 ;                                 |B0

	;; ******************************************************************
	;;   main init                                                      *
	;; ******************************************************************

Init:

              banksel ANSEL
	          clrf    ANSEL	     ; turn off ADC pins               |B2
	          banksel ANSELH
              clrf    ANSELH     ; turn off ADC pins               |B2

             banksel ADCON1
             MOVLW B'01100000'
             ;A/D RC clock
             MOVWF ADCON1
             banksel ANSEL
             BSF ANSEL,3
             BSF ANSEL,7

	;;
	;;   setup 8 MHz INTOSC
	;;
              banksel OSCCON

	          movlw   b'01110000' ; '01110000'                      |B1
	          movwf   OSCCON      ;                                 |B1
Stable:
	          btfss   OSCCON,HTS ; osc stable? yes, skip, else     |B1
	          goto    Stable     ; test again                      |B1
	;;
	;;   setup ports
	;;
            banksel TRISA
		  movlw b'11111111'
		  movwf TRISA	; Make PortA all input
	          clrf    TRISB	; setup PORT B all outputs        |B1
	          clrf    TRISC	; setup PORT C all outputs        |B1
              bsf     TRISC, 2
              bsf     TRISC, 3
    ;;
	;; Set interupts
	;;
        banksel PIE1
		movlw   b'00100000'
		movwf	PIE1

	;;
	;;   setup UART module for 19200 baud (8 MHz Clock)
	;;
              banksel SPBRG
	          movlw   low(brgval) ;                                 |B1
	          movwf   SPBRG	      ;                                 |B1
	          banksel SPBRGH
              movlw   high(brgval) ;                                 |B1
	          movwf   SPBRGH       ;                                 |B1
              banksel BAUDCTL
	          bsf     BAUDCTL,BRG16	; select 16 bit BRG               |B1
	          banksel TXSTA
              movlw   b'00100100'	; '0-------' CSRC, n/a (async)    |B1
	;;  '-0------' TX9 off, 8 bits      |B1
	;;  '--1-----' TXEN, tx enabled     |B1
	;;  '---0----' SYNC, async mode     |B1
	;;  '----0---' SENDB, send brk      |B1
	;;  '-----1--' BRGH, high speed     |B1
	;;  '------00' TRMT, TX9D           |B1
	          movwf   TXSTA	;                                 |B1
              banksel RCSTA
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
	;; SET RX/TX parameters
	;;
	banksel txreturn
	clrf	txreturn
	;; 	Do not clear the adress:es, use the one that is set, read the speedbus text, "Adress handeling system!"
	;; 	clrf	adress1
	;; 	movlw	0x7e
	;; 	movwf	adress1
	;; 	movlw	0x7d
	;; 	movwf	adress2
	;; 	clrf	adress1
	;; 	clrf	adress2

	;;
	;; Set Interrupts
	;;
        banksel  rc_gotflag
        bcf	rc_gotflag,0
        banksel INTCON
		bsf	INTCON, GIE
		bsf	INTCON, PEIE
        call    init_speedlib ; IMPORTANT to run this before, so the adresses are
                              ; imported from EEPROM

        banksel PORTB
        bsf     PORTB,6
        banksel fan_s
        clrf    fan_s
        bsf     fan_s,0



main:
    banksel RCSTA
	btfsc	RCSTA,OERR
	call    recerror
    banksel PORTC
    bcf     PORTC,0
	;btfsc	PORTA, 0
	;call 	txporta
    banksel rand
	incf	rand,F		; Increase the random value

        goto    main



custom_command_handler:
       	movlw	0x0A
        subwf	INDF,W
        btfsc	STATUS,Z
        goto	get_status

    	movlw	0x0B
        subwf	INDF,W
    	btfsc	STATUS,Z
        goto	get_temp

       	movlw	0x0C
        subwf	INDF,W
        btfsc	STATUS,Z
        goto	set_fan
        goto    restore

set_fan:
    banksel rcframe
	movlw	rcframe+7
    banksel FSR
    movwf   FSR
    banksel INDF
    movf    INDF,W
    banksel rcframe
    btfsc   rcframe+7,0
    bsf     PORTB,6
    btfss   rcframe+7,0
    bcf     PORTB,6
    btfsc   rcframe+7,0
    bsf     fan_s,0
    btfss   rcframe+7,0
    bcf     fan_s,0
    goto    restore

get_status:

        ;Store in GPR space
        movlw   12
        banksel framelen
        movwf   framelen
        ;; 0xff broadcast dst adress
       	movlw	rcframe+2         ;       dst addr
        banksel FSR
        movwf	FSR
        banksel INDF
        movf    INDF,W
        banksel txframe
        movwf   txframe
        ;; 0xff broadcast dst adress
       	movlw	rcframe+3         ;       dst addr
        banksel FSR
        movwf	FSR
        banksel INDF
        movf    INDF,W
        banksel txframe
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
        movlw   0x00
        movwf   txframe+5
        ;; Data
        movlw	0x0A
        movwf   txframe+6
        ;; Data
        clrf    txframe+7
        btfss   PORTA, 1
        bsf     txframe+7,0
        ;; Data
        clrf    txframe+8
        btfss   PORTC, 2
        bsf     txframe+8,0
        ;; Data
        movf    fan_s,W
        movwf   txframe+9
        ;; Padding bit
        movlw   0x00
        movwf   txframe+10

    	;; This is a broadcast package with adress on it

        call	txdo


        goto    restore

get_temp:
        call    set_temp

        ;Store in GPR space
        movlw   15
        banksel framelen
        movwf   framelen
        ;; 0xff broadcast dst adress
       	movlw	rcframe+2         ;       dst addr
        banksel FSR
        movwf	FSR
        banksel INDF
        movf    INDF,W
        banksel txframe
        movwf   txframe
        ;; 0xff broadcast dst adress
       	movlw	rcframe+3         ;       dst addr
        banksel FSR
        movwf	FSR
        banksel INDF
        movf    INDF,W
        banksel txframe
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
        movlw   0x00
        movwf   txframe+5
        ;; Data
        movlw	0x0B
        movwf   txframe+6
        ;; Data
        movlw   0
        movwf   txframe+7
        ;; Data
        movf    temp1,W
        movwf   txframe+8
        ;; Data
        movf    temp1r,W
        movwf   txframe+9
        ;; Data
        movlw   1
        movwf   txframe+10
        ;; Data
        movf    temp2,W
        movwf   txframe+11
        ;; Data
        movf    temp2r,W
        movwf   txframe+12
        ;; Padding bit
        movlw   0x00
        movwf   txframe+13

    	;; This is a broadcast package with adress on it

        call	txdo


        goto    restore

set_temp:



;        movlw   40
;        call    Delay ; Need some delay to make the ANSELA load up,
                      ; after switching TRISA to input


        banksel ADCON0
        ;
        movlw   b'10001101' ;Select channel AN0
        movwf   ADCON0
        movlw   40
        call    Delay

        ;Turn ADC On
;        call    SampleTime
        ;Acquisiton delay
        banksel ADCON0
        bsf     ADCON0,GO
        btfsc   ADCON0,GO ;Is conversion done?
        goto    $-1
        movlw   1
        call    Delay
        ;No, test again
        banksel ADRESH
        movf    ADRESH,W
        ;Read upper 2 bits
        banksel a2
        movwf   a2
        ;store in GPR space
        banksel ADRESL
        movf    ADRESL,W
        ;Read lower 8 bits
        banksel a1
        movwf   a1

        ; ARG temp as a2:a1
        call    temp_calc
        movwf   temp1
//        movlw   4
//        subwf   temp1,F ; Compensate -4 degrees
        call    temp_rem_calc
        movwf   temp1r

        banksel ADCON0
        clrf    ADCON0


        banksel ADCON0
        ;
        movlw   b'10011101' ;Select channel AN0
        movwf   ADCON0

        movlw   40
        call    Delay

        banksel ADCON0
        bsf     ADCON0,GO ;Start conversion
        btfsc   ADCON0,GO ;Is conversion done?
        goto    $-1
        movlw   1
        call    Delay
        ;No, test again
        banksel ADRESH
        movf    ADRESH,W
        ;Read upper 2 bits
        banksel a2
        movwf   a2
        ;store in GPR space
        banksel ADRESL
        movf    ADRESL,W
        ;Read lower 8 bits
        banksel a1
        movwf   a1

        banksel ADCON0
        clrf    ADCON0

        banksel temp2

        ; ARG temp as a2:a1
        call    temp_calc
        movwf   temp2
        call    temp_rem_calc
        movwf   temp2r
        return

temp_calc:
        movlw   b'00000001' ; ADRES * 488
        movwf   b2
        movlw   b'11101000'
        movwf   b1
        call    multi


        movlw   b'00000011' ; res / 1000
        movwf   divisH
        movlw   b'11101000'
        movwf   divisL

        call    divide
        movlw   78      ; Stored as signed, so, because the 0C is 50, add 78, so zero is 128
        addwf   res1,W
        ; REMEMBER -> The reminder is stored in the remdrH:remdrL
        return


temp_rem_calc:
        banksel res4
        clrf    res4
        clrf    res3
        movf    remdrH,W
        movwf   res2
        movf    remdrL,W
        movwf   res1
temp_rem_calc_l:
        banksel divisL
        clrf    divisH
        movlw   10
        movwf   divisL
        movlw   0
        subwf   res2,W
        btfsc   STATUS,Z
        goto    temp_rem_calc_iret
        call    divide
        goto    temp_rem_calc_l

temp_rem_calc_iret:
        banksel res1
        movf    res1,W
        return

multi:
	clrf    res4
	clrf    res3
	clrf    res2
	clrf    res1
    bsf     res2, 7
m1:
	rrf     a2, f
	rrf     a1, f
	btfss   STATUS, C
	goto    m2
	movf    b1, w
	addwf   res3, f
	movf    b2, w
	btfsc   STATUS, C
	incfsz  b2, w
	addwf   res4, f
m2:
	rrf     res4, f
	rrf     res3, f
	rrf     res2, f
	rrf     res1, f
	btfss   STATUS, C
	goto    m1
    return

divide:
       movlw 32      ; 32-bit divide by 16-bit
       movwf bitcnt
       clrf remdrH   ; Clear remainder
       clrf remdrL

dvloop:

       bcf  STATUS,C ; Set quotient bit to 0
                     ; Shift left dividend and quotient
       rlf res1    ; lsb
       rlf res2
       rlf res3
       rlf res4    ; lsb into carry
       rlf remdrL    ; and then into partial remainder
       rlf remdrH

       btfsc    STATUS,C ; Check for overflow
       goto     subd
       movfw    divisH  ; Compare partial remainder and divisor
       subwf    remdrH,w
       btfss    STATUS,Z
       goto     testgt   ; Not equal so test if remdrH is greater
       movfw    divisL  ; High bytes are equal, compare low bytes
       subwf    remdrL,w
testgt:
       btfss    STATUS,C          ; Carry set if remdr >= divis
       goto     remrlt

subd:
       movfw    divisL  ; Subtract divisor from partial remainder
       subwf    remdrL
       btfss    STATUS,C

       decf     remdrH   ; Subtract borrow
       movfw    divisH
       subwf    remdrH
       bsf      res1,0  ; Set quotient bit to 1
                          ; Quotient replaces dividend which is lost
remrlt:
       decfsz   bitcnt
       goto     dvloop
       return

; Untill further investigation, this functions need to be implemented explictly to
; each processor

read_eeprom:
        bsf     STATUS, RP1
        ;; Take the preset W number, and take the byte from the addr
        movwf   EEADR
        bsf     STATUS, RP0
        bcf     EECON1, EEPGD
        bsf     EECON1, RD
        bcf     STATUS, RP0
        ;; Put the result in W
        movf    EEDAT, W
        bcf     STATUS, RP1
        return

write_eeprom:
        bsf     STATUS, RP1
        movwf   EEDAT ; write the value already in W to EEDAT, the data
        bcf     STATUS, RP1 ; Need this to get rc_nocoll
        movf    rc_nocoll,W
        bsf     STATUS, RP1 ;; ^^^^^^^^^^^
        movwf   EEADR
        bsf     STATUS, RP0
        bcf     EECON1, EEPGD
        bsf     EECON1, WREN

        ; bcf   INTCON, GIE ; Well, GIE should be zero when it gets here
        movlw   0x55
        movwf   EECON2
        movlw   0xAA
        movwf   EECON2
        bsf     EECON1, WR
        ; bsf     INTCON, GIE

        btfsc   EECON1, WR
        goto    $-1


        bcf     EECON1, WREN
        bcf     STATUS, RP0
        bcf     STATUS, RP1
        return

    end