List      P=16f690		; list directive to define processor
#include "/usr/share/gputils/header/p16f690.inc"
; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
#define ARC_16F         1
;#define ARC_18F         1
#define REC_CUSTOM_JUMP     custom_command_handler
#define CUSTOM_INTERRUPT    c_intserv
#define DEV_ID1 35
#define DEV_ID2 98
#define WRITE_EEPROM        write_eeprom
#define READ_EEPROM         read_eeprom
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
        larm_dec
        larm_sig
        larm_mem    ; Help the rutine to only send the movment package ONCE
        ad_lo
        ad_hi
        lamp_timer
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
	          movlw   b'00000111' ; '00000000'                      |B2
	          movwf   ANSEL      ;                                 |B2
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
		  movlw b'11111111'
		  movwf TRISA	; Make PortA all input
	          clrf    TRISB	; setup PORT B all outputs        |B1
	          clrf    TRISC	; setup PORT C all outputs        |B1
	;;
	;; Set interupts
	;;


		movlw   b'00100001'
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

        ;; Activate AD decoder
        movlw   b'10000001'
        movwf   ADCON0

        ;; Activate Timer1
        movlw   b'00110000'
        movwf   T1CON

        clrf    TMR1L
        clrf    TMR1H

        clrf    PORTB

        movlw   255
        movwf   larm_mem
        call    trd         ; Just to delay to make sure that the detectors realy are startup BEFORE the AD are started to check.

        call    init_speedlib

main:
	btfsc	RCSTA,OERR
	call    recerror
        bcf     PORTC,0
	;btfsc	PORTA, 0
	;call 	txporta
	incf	rand,F		; Increase the random value

        call    larm_check
        goto    main


c_intserv:
        btfsc 	PIR1,TMR1IF	;	Check if the Timer bit is set
        goto    c_intserv_timer1
        goto    ci_restore
c_intserv_timer1:
        bcf     PIR1,TMR1IF

        bcf     T1CON,0
        clrf    TMR1L
        clrf    TMR1H
        bsf     T1CON,0
        decfsz	lamp_timer, f
        goto    ci_restore
        bcf     PORTC,1
        bcf     T1CON,0
        goto    ci_restore

custom_command_handler:
        movlw   0x0A          ; Min  custom
        subwf   INDF,W        ; This is the command data byte, predefinde, before called by this funktion
        movwf   rand          ; Just use the random register rand(no reason why, just a temporary register availble)
        btfss   STATUS,C      ; Check so that the Commmand bit is >= 0x0A ; NOTE: If "addwf PC,F" Gets a zero, it brobubly will act like a "goto $"
        goto    restore

        movlw   3             ; MaxCommand; This is the number of functions in the list bellow, just to make sure its safe for buffer overflow
        subwf   rand,W        ; Command
        btfsc   STATUS,C      ; If Command >= MaxCommand then goto restore
        goto    restore

        movf    rand,W
        addwf   PCL,F
        goto    set_PORTC
        goto    rx_set_servo
        goto    get_AD
        goto    restore


rx_set_servo:
       	movlw	rcframe+7	; Move recived byte to W
	movwf	FSR
        movf    INDF,W
        call    set_servo
        goto    restore

set_servo:
        movwf   servo_1_val

        movlw   3               ; Maybe increase this later, if servo wont play..
        movwf   loop1

set_servo_loop:
        call Delay__00
        bsf     PORTC,0
        movf    servo_1_val,W
        call Delay__11
        bcf     PORTC,0
        call Delay__00
        bsf     PORTC,0
        movf    servo_1_val,W
        call Delay__11
        bcf     PORTC,0
        decfsz	loop1,	f
        goto    set_servo_loop
        return


set_PORTC:
       	movlw	rcframe+7	; Move recived byte to W
	movwf	FSR
        btfsc   INDF,0
        bsf     PORTC,1
        btfss   INDF,0
        bcf     PORTC,1
        goto    restore

get_AD:
        call    trd

        movlw   b'10001001'
        movwf   ADCON0
        call    Delay__00
        bsf     ADCON0,GO
        btfsc   ADCON0,GO
        goto    $-1

        banksel framelen
	movlw   11
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
        movlw   0x01
	movwf   txframe+5
	;; First Data byte
        movlw	0x0c
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


larm_check:
        ; Check sabotage 3  ; The builtin antitamp, on the device
        movlw   2
        movwf   larm_dec
        btfss   PORTA,3
        goto    larm_alert_tamp

        ; Check detector 1
        movlw   0
        movwf   larm_dec
        movlw   3
        movwf   loop1   ; Speedlib variable, free to use :D

larm_check_d1:
        bcf     speedlib_main,0     ; Clear this bit, before the rutine
        movlw   b'10000001'
        movwf   ADCON0
        call    Delay__00
        bsf     ADCON0,GO
        btfsc   ADCON0,GO
        goto    $-1

        bsf     STATUS,RP0
	movf    ADRESL,W
        bcf     STATUS,RP0
        movwf   ad_lo
        movf    ADRESH,W
        movwf   ad_hi
        btfsc   speedlib_main,0      ; If this bit is ONE, an interupt has ocurred, and the value in AD may be false, rerun the calc
        goto    larm_check_d1

        btfss   ad_hi,1
        goto    larm_alert_tamp

        movf	ad_hi,W
	sublw   2
	btfss	STATUS,Z
        goto    larm_check_d1_end
        movlw   0xdf
        subwf   ad_lo,W
	btfss	STATUS,C
        goto    larm_check_d1_loopcheck ; Dont go with the first check on the AD, get three values and make sure everyone are right before alert
        goto    larm_check_d1_end

larm_check_d1_loopcheck:
        decfsz  loop1,F
        goto    larm_check_d1
        goto    larm_alert_movment

larm_check_d1_end:
        ; Check detector 2
        movlw   1
        movwf   larm_dec
        movlw   3
        movwf   loop1   ; Speedlib variable, free to use :D

larm_check_d2:
        bcf     speedlib_main,0     ; Clear this bit, before the rutine
        movlw   b'10000101'
        movwf   ADCON0
        call    Delay__00
        bsf     ADCON0,GO
        btfsc   ADCON0,GO
        goto    $-1

        bsf     STATUS,RP0
	movf    ADRESL,W
        bcf     STATUS,RP0
        movwf   ad_lo
        movf    ADRESH,W
        movwf   ad_hi
        btfsc   speedlib_main,0      ; If this bit is ONE, an interupt has ocurred, and the value in AD may be false, rerun the calc
        goto    larm_check_d2


        btfss   ADRESH,1
        goto    larm_alert_tamp

        movf	ADRESH,W
	sublw   2
	btfss	STATUS,Z
        goto    larm_check_d2_end
        movlw   0xdf
        subwf   ad_lo,W
	btfss	STATUS,C
        goto    larm_check_d2_loopcheck ; Dont go with the first check on the AD, get three values and make sure everyone are right before alert
        goto    larm_check_d2_end

larm_check_d2_loopcheck:
        decfsz  loop1,F
        goto    larm_check_d2
        goto    larm_alert_movment

larm_check_d2_end:
        clrf    larm_mem                ; This is not only usefull for the generall, only send one package, it also usefull for the init rutine, the startup delay at some detectors.
        return



larm_alert_movment:
        movlw   1
        movwf   larm_sig
        call    lamp_power_up
        movf    larm_dec,W
        addwf   PCL,F
        goto    larm_alert_movment_dec1
        goto    larm_alert_movment_dec2

larm_alert_movment_dec1:
        btfsc   larm_mem,0
        return
        bsf     larm_mem,0
        call    lamp_movment
        goto    larm_send
larm_alert_movment_dec2:
        btfsc   larm_mem,1
        return
        bsf     larm_mem,1
        call    lamp_movment
        goto    larm_send


larm_alert_tamp:
        movlw   0
        movwf   larm_sig
        call    lamp_power_up_d
        goto    larm_send

larm_send:
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
        movlw	0xAA    ; This means alarm
	movwf   txframe+6
	;; Second Data byte
        movf    larm_sig,W       ; This means sabotage
        movwf   txframe+7
	;; Third Data Byte
        movf    larm_dec,W       ; This indicate twitch detector that
        movwf   txframe+8
	;; Padding bit
	movlw   0x00
        movwf   txframe+9

	;; This is a broadcast package with adress on it
	bsf	txreturn,0
	call	txdo

        call    Delay__00
        return

lamp_movment:
        btfss   larm_dec,0
        movlw   14  ;   If it is detector 0, move the camera to position 14
        btfsc   larm_dec,0
        movlw   7   ;   If it is detector 1, move the camera to position 8
        call    set_servo
        return

lamp_power_up:
        bcf     speedlib_main,0     ; Clear this bit, before the rutine
        movlw   b'10001001'
        movwf   ADCON0
        call    Delay__00
        bsf     ADCON0,GO
        btfsc   ADCON0,GO
        goto    $-1

        bsf     STATUS,RP0
	movf    ADRESL,W
        bcf     STATUS,RP0
        movwf   ad_lo
        movf    ADRESH,W
        movwf   ad_hi
        btfsc   speedlib_main,0      ; If this bit is ONE, an interupt has ocurred, and the value in AD may be false, rerun the calc
        goto    lamp_power_up

        btfsc   ad_hi,0
        return
        btfsc   ad_hi,1
        return
lamp_power_up_d:
        clrf    TMR1L
        clrf    TMR1H
        bsf     T1CON,0
        movlw   120
        movwf   lamp_timer
        bsf     PORTC,1
        return

; Delay = 0.02 seconds
; Clock frequency = 8 MHz

; Actual delay = 0.02 seconds = 40000 cycles
; Error = 0 %
;; The delay variables is predefined in the libaray
Delay__00:

			;39998 cycles
	movlw	0x3F
	movwf	d1
	movlw	0x20
	movwf	d2
Delay__0:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay__0

			;2 cycles
	goto	$+1
        return

; Delay = 0.0001 seconds
; Clock frequency = 8 MHz

; Actual delay = 0.0001 seconds = 200 cycles
; Error = 0 %
;; The delay variables is predefined in the libaray
Delay__11:
			;199 cycles
        movwf  d2
Delay_1_1:
	movlw	0x42
	movwf	d1
Delay__1:
	decfsz	d1, f
	goto	Delay__1
        decfsz  d2, f
        goto    Delay_1_1
			;1 cycle
	nop
        return

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