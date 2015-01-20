List      P=16f690		; list directive to define processor

#include "p16f690.inc"

; CONFIG
; __CONFIG _CONFIG1, 0x30D5
 __CONFIG _INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF

; RA1 = Check for led strip 1
; RC2 = Check for led strip 2
; RB6 = Controller for fan

; RA5 = Temp in grow house
; RA4 = Temp for heat sink



; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
#define ARC_16F             1
;#define ARC_18F            1
#define REC_CUSTOM_JUMP     custom_command_handler
#define REC_SPB_PARAMETERS  spb_parameters
;#define CUSTOM_INTERRUPT   c_intserv
#define DEV_ID4             200
#define WRITE_EEPROM        write_eeprom
#define READ_EEPROM         read_eeprom
#include "../SpeedBus.PIC.LibV2.X/speedlibV2_main.asm"

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
    dd1
    dd2
    dd3
    w1
    w2
    w3
    w4
    w5
    main_commands          ; |X-------|b7 = NoNE
                           ; |-X------|b6 = NoNE
                           ; |--X-----|b5 = NoNE
                           ; |---X----|b4 = NoNE
                           ; |----X---|b3 = NoNE
                           ; |-----X--|b2 = PIR Beep on movment, set.
                           ; |------X-|b1 = If you set this to one, then the main loop will send back all the tags.
                           ; |-------X|b0 = If you set this to one, the next tag readed will be sent to the bus.
    csum
    divisL
    divisH
    remdrL    ; and then into partial remainder
    remdrH
    bitcnt
    divid0
    divid1
    divid2
    divid3
    temp_parameter
    temprem_parameter
    hum_parameter
    humrem_parameter
    spb_bool_params        ; |X-------|b7 = NoNE
                           ; |-X------|b6 = NoNE
                           ; |--X-----|b5 = NoNE
                           ; |---X----|b4 = NoNE
                           ; |----X---|b3 = NoNE
                           ; |-----X--|b2 = NoNE
                           ; |------X-|b1 = Beep on PIR movment. Parm5
                           ; |-------X|b0 = Light up led on PIR movment: Parm4
    beep_on_movmentc
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
              bsf     ANSEL, 2
	          banksel ANSELH
              clrf    ANSELH     ; turn off ADC pins               |B2

             banksel ADCON1
             MOVLW B'01100000'
             ;A/D RC clock
             MOVWF ADCON1
             ;banksel ANSEL
             ;BSF ANSEL,3
             ;BSF ANSEL,7

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
              ;bsf     TRISC, 2
              ;bsf     TRISC, 3
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
        banksel INTCON
		bsf	INTCON, GIE
		bsf	INTCON, PEIE
        call    init_speedlib ; IMPORTANT to run this before, so the adresses are
                              ; imported from EEPROM

        banksel PORTC
        bcf     PORTC, 0
        bsf     PORTC, 7
        bsf     PORTC, 6

        banksel main_commands
        bcf     main_commands, 0
        bcf     main_commands, 1
        bcf     spb_bool_params, 0
        bcf     spb_bool_params, 1

main:
    banksel RCSTA
	btfsc	RCSTA,OERR
	call    recerror
	;btfsc	PORTA, 0
	;call 	txporta
    banksel rand
	incf	rand,F		; Increase the random value


    banksel spb_bool_params
    btfsc   spb_bool_params, 0
    goto    led_on_pir_movment
main_ret1:
    banksel spb_bool_params
    btfsc   spb_bool_params, 1
    goto    beep_on_pir_movment
main_ret2:

    goto    main


led_on_pir_movment:
    banksel PORTA
    btfsc   PORTA, 4
    bsf     PORTB, 6
    btfss   PORTA, 4
    bcf     PORTB, 6
    goto    main_ret1

beep_on_pir_movment:
    banksel PORTA
    btfss   PORTA, 4
    goto    beep_on_pir_movment_ret
    btfsc   main_commands, 2
    goto    main_ret2
    bsf     main_commands, 2

    banksel PORTC
    bsf     PORTC, 5
    movlw   25
    call    Delay
    banksel PORTC
    bcf     PORTC, 5
    movlw   25
    call    Delay
    banksel PORTC
    bsf     PORTC, 5
    movlw   25
    call    Delay
    banksel PORTC
    bcf     PORTC, 5
    goto    main_ret2

beep_on_pir_movment_ret:
    bcf     main_commands, 2
    goto    main_ret2


spb_parameters:
    call    func_set_rsp_addr

    movlw   rcframe+7
    movwf   FSR

    ; Get temp
    if_parameter 0x00, spb_parameters_temp
    ; Get hum
    if_parameter 0x01, spb_parameters_hum
    ; Get light
    if_parameter 0x02, spb_parameters_light
    ; Get/Set Led
    if_parameter 0x03, spb_parameters_led
    ; Get/Set PIR Led
    if_parameter 0x04, spb_parameters_pir_led
    ; Get/Set PIR Beep
    if_parameter 0x05, spb_parameters_pir_beep
    ; Get/Set Beep
    if_parameter 0x06, spb_parameters_beep

    goto    restore


spb_parameters_led:
    if_sget_parameter   spb_setparameters_led, spb_getparameters_led

spb_parameters_beep:
    if_sget_parameter   spb_setparameters_beep, spb_getparameters_beep
spb_parameters_pir_led:
    if_sget_parameter   spb_setparameters_pir_led, spb_getparameters_pir_led
spb_parameters_pir_beep:
    if_sget_parameter   spb_setparameters_pir_beep, spb_getparameters_pir_beep


spb_parameters_temp:
    call    read_humtemp
    call    set_humtemp_parameter
    ;;; Send back parameter ->

    ;; Send the readed rfid
    banksel framelen
	movlw   12
	movwf   framelen

    movf    rsp_adress1, W
	movwf   txframe

    movf    rsp_adress2, W
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
    movlw	0x04
	movwf   txframe+6

    ;; 0x00 Basic config response
    movlw   0x00
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel temp_parameter
	movf    temp_parameter, W
    banksel txframe
    movwf   txframe+8

    ;; 0x00 Basic config response
    banksel temprem_parameter
	movf    temprem_parameter, W
    banksel txframe
    movwf   txframe+9

	;; Padding bit
	movlw   0x00
    movwf   txframe+10
    call    txdo

    ;;;
    goto    restore

spb_parameters_hum:
    call    read_humtemp
    call    set_humtemp_parameter
    ;;; Send back parameter ->

    ;; Send the readed rfid
    banksel framelen
	movlw   12
	movwf   framelen

    movf    rsp_adress1, W
	movwf   txframe

    movf    rsp_adress2, W
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
    movlw	0x04
	movwf   txframe+6

    ;; 0x00 Basic config response
    movlw   0x01
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel hum_parameter
	movf    hum_parameter, W
    banksel txframe
    movwf   txframe+8

    ;; 0x00 Basic config response
    banksel humrem_parameter
	movf    humrem_parameter, W
    banksel txframe
    movwf   txframe+9

	;; Padding bit
	movlw   0x00
    movwf   txframe+10
    call    txdo

    ;;;
    goto    restore


spb_parameters_light:
    ;;; Read AD value ->
    banksel ADCON1
    movlw b'01110000'
    movwf   ADCON1
    banksel ANSEL
    movlw   2
    movwf   ANSEL
    banksel ADCON0
    movlw b'10001011'
    movwf   ADCON0
    call    Delay_005_ms
    call    Delay_005_ms
    call    Delay_005_ms
    call    Delay_005_ms
    banksel ADCON0
    btfsc   ADCON0, GO
    goto    $-1
    bcf     ADCON0, 7


    ;; Send the readed rfid
    banksel framelen
	movlw   12
	movwf   framelen

    movf    rsp_adress1, W
	movwf   txframe

    movf    rsp_adress2, W
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
    movlw	0x04
	movwf   txframe+6

    ;; 0x00 Basic config response
    movlw   0x02
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel ADRESH
    movf    ADRESH, W
    banksel txframe
    movwf   txframe+8

    ;; 0x00 Basic config response
    banksel ADRESL
    movf    ADRESL, W
    banksel txframe
    movwf   txframe+9

	;; Padding bit
	movlw   0x00
    movwf   txframe+10
    call    txdo

    ;;;
    goto    restore

spb_setparameters_led:
    movlw   rcframe+8
    movwf   FSR

    banksel rcframe
    btfsc   INDF, 0
    goto    spb_setparameters_led_on
    btfss   INDF, 0
    goto    spb_setparameters_led_off

spb_setparameters_led_on:
    banksel PORTB
    bsf     PORTB, 6
    goto    spb_getparameters_led

spb_setparameters_led_off:
    banksel PORTB
    bcf     PORTB, 6
    goto    spb_getparameters_led


spb_getparameters_led:

    ;; Send the readed rfid
    banksel framelen
	movlw   11
	movwf   framelen

    movf    rsp_adress1, W
	movwf   txframe

    movf    rsp_adress2, W
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
    movlw	0x04
	movwf   txframe+6

    ;; 0x00 Basic config response
    movlw   0x03
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel PORTB
    btfsc   PORTB, 6
    goto    spb_getparameters_led_on
    btfss   PORTB, 6
    goto    spb_getparameters_led_off

spb_getparameters_led_on:
    movlw   1
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_led_ret

spb_getparameters_led_off:
    movlw   0
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_led_ret

spb_getparameters_led_ret:
	;; Padding bit
	movlw   0x00
    movwf   txframe+9
    call    txdo

    ;;;
    goto    restore

spb_setparameters_pir_led:
    movlw   rcframe+8
    movwf   FSR

    banksel rcframe
    btfsc   INDF, 0
    goto    spb_setparameters_pir_led_on
    btfss   INDF, 0
    goto    spb_setparameters_pir_led_off

spb_setparameters_pir_led_on:
    banksel spb_bool_params
    bsf     spb_bool_params, 0
    goto    spb_getparameters_pir_led

spb_setparameters_pir_led_off:
    banksel spb_bool_params
    bcf     spb_bool_params, 0
    goto    spb_getparameters_pir_led


spb_getparameters_pir_led:

    ;; Send the readed rfid
    banksel framelen
	movlw   11
	movwf   framelen

    movf    rsp_adress1, W
	movwf   txframe

    movf    rsp_adress2, W
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
    movlw	0x04
	movwf   txframe+6

    ;; 0x00 Basic config response
    movlw   0x04
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel spb_bool_params
    btfsc   spb_bool_params, 0
    goto    spb_getparameters_pir_led_on
    btfss   spb_bool_params, 0
    goto    spb_getparameters_pir_led_off

spb_getparameters_pir_led_on:
    movlw   1
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_pir_led_ret

spb_getparameters_pir_led_off:
    movlw   0
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_pir_led_ret

spb_getparameters_pir_led_ret:
	;; Padding bit
	movlw   0x00
    movwf   txframe+9
    call    txdo

    ;;;
    goto    restore

spb_setparameters_pir_beep:
    movlw   rcframe+8
    movwf   FSR

    banksel rcframe
    btfsc   INDF, 0
    goto    spb_setparameters_pir_beep_on
    btfss   INDF, 0
    goto    spb_setparameters_pir_beep_off

spb_setparameters_pir_beep_on:
    banksel spb_bool_params
    bsf     spb_bool_params, 1
    goto    spb_getparameters_pir_beep

spb_setparameters_pir_beep_off:
    banksel spb_bool_params
    bcf     spb_bool_params, 1
    goto    spb_getparameters_pir_beep


spb_getparameters_pir_beep:

    ;; Send the readed rfid
    banksel framelen
	movlw   11
	movwf   framelen

    movf    rsp_adress1, W
	movwf   txframe

    movf    rsp_adress2, W
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
    movlw	0x04
	movwf   txframe+6

    ;; 0x00 Basic config response
    movlw   0x05
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel spb_bool_params
    btfsc   spb_bool_params, 1
    goto    spb_getparameters_pir_beep_on
    btfss   spb_bool_params, 1
    goto    spb_getparameters_pir_beep_off

spb_getparameters_pir_beep_on:
    movlw   1
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_pir_beep_ret

spb_getparameters_pir_beep_off:
    movlw   0
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_pir_beep_ret

spb_getparameters_pir_beep_ret:
	;; Padding bit
	movlw   0x00
    movwf   txframe+9
    call    txdo

    ;;;
    goto    restore


spb_setparameters_beep:
    movlw   rcframe+8
    movwf   FSR

    banksel rcframe
    btfsc   INDF, 0
    goto    spb_setparameters_beep_on
    btfss   INDF, 0
    goto    spb_setparameters_beep_off

spb_setparameters_beep_on:
    banksel PORTC
    bsf     PORTC, 5
    goto    spb_getparameters_beep

spb_setparameters_beep_off:
    banksel PORTC
    bcf     PORTC, 5
    goto    spb_getparameters_beep


spb_getparameters_beep:

    ;; Send the readed rfid
    banksel framelen
	movlw   11
	movwf   framelen

    movf    rsp_adress1, W
	movwf   txframe

    movf    rsp_adress2, W
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
    movlw	0x04
	movwf   txframe+6

    ;; 0x00 Basic config response
    movlw   0x06
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel PORTC
    btfsc   PORTC, 5
    goto    spb_getparameters_beep_on
    btfss   PORTC, 5
    goto    spb_getparameters_beep_off

spb_getparameters_beep_on:
    movlw   1
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_beep_ret

spb_getparameters_beep_off:
    movlw   0
    banksel txframe
    movwf   txframe+8
    goto    spb_getparameters_beep_ret

spb_getparameters_beep_ret:
	;; Padding bit
	movlw   0x00
    movwf   txframe+9
    call    txdo

    ;;;
    goto    restore


read_humtemp:

    movlw   w5
    movwf   FSR

    banksel TRISA
    bcf     TRISA, 0
    banksel PORTA
    bcf     PORTA, 0
    call    Delay_005_ms
    call    Delay_005_ms
    call    Delay_005_ms
    call    Delay_005_ms        ;; 2ms
    banksel TRISA
    bsf     TRISA, 0
    call    Delay_005_ms

    call    read_humtemp_delay
    call    read_humtemp_wait
    call    read_humtemp_delay

    movlw   5
    banksel dd3
    movwf   dd3
read_humtemp_loop1:
    ;; Write in bit 1
    call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 7
    btfsc   PORTA, 0
    bsf     INDF, 7
    call    read_humtemp_wait
    call    read_humtemp_delay

    ;; Write in bit 2
    call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 6
    btfsc   PORTA, 0
    bsf     INDF, 6
    call    read_humtemp_wait
    call    read_humtemp_delay

    ;; Write in bit 3
     call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 5
    btfsc   PORTA, 0
    bsf     INDF, 5
    call    read_humtemp_wait
    call    read_humtemp_delay

    ;; Write in bit 4
    call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 4
    btfsc   PORTA, 0
    bsf     INDF, 4
    call    read_humtemp_wait
    call    read_humtemp_delay

    ;; Write in bit 5
    call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 3
    btfsc   PORTA, 0
    bsf     INDF, 3
    call    read_humtemp_wait
    call    read_humtemp_delay

    ;; Write in bit 6
    call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 2
    btfsc   PORTA, 0
    bsf     INDF, 2
    call    read_humtemp_wait
    call    read_humtemp_delay

    ;; Write in bit 7
    call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 1
    btfsc   PORTA, 0
    bsf     INDF, 1
    call    read_humtemp_wait
    call    read_humtemp_delay

    ;; Write in bit 8
    call    Delay_005_ms
    btfss   PORTA, 0
    bcf     INDF, 0
    btfsc   PORTA, 0
    bsf     INDF, 0
    call    read_humtemp_wait
    call    read_humtemp_delay

    decf    FSR, f
	decfsz	dd3, f
    goto    read_humtemp_loop1

    banksel csum
    clrf    csum
    movf    w5, W
    addwf   csum
    movf    w4, W
    addwf   csum
    movf    w3, W
    addwf   csum
    movf    w2, W
    addwf   csum

    movf    w1, W
    subwf	csum,W
    btfss	STATUS,Z
    goto	read_humtemp_ret



read_humtemp_ret:
    return

read_humtemp_wait:
    banksel PORTA
    btfsc   PORTA, 0
    goto    read_humtemp_wait
    return

read_humtemp_delay:
    banksel dd2
    movlw   40
    movwf   dd2
read_humtemp_delay_loop:
    call    Delay_001_ms
    banksel PORTA
    btfsc   PORTA, 0
    return
    banksel dd2
	decfsz	dd2, f
    goto    read_humtemp_delay_loop
    return


set_humtemp_parameter:
    ;;
    banksel divid0
    clrf    divid0
    clrf    divid1
    clrf    divid2
    clrf    divid3


; Take the Humidelty and divide by 10.
    clrf    divisH
    movlw   10
    movwf   divisL

    movf    w5, W
    movwf   divid1
    movf    w4, W
    movwf   divid0
;
    call    divide

    movf    divid0, W
    movwf   hum_parameter
    movf    remdrL, W
    movwf   humrem_parameter

; Take temp and divide by 10
    clrf    divisH
    movlw   10
    movwf   divisL

    clrf    divid2
    clrf    divid3
    movf    w3, W
    movwf   divid1
; Clear the below zero bit
    bcf     divid1, 7
    movf    w2, W
    movwf   divid0
;
    call    divide

    btfsc   w3, 7
    goto    temp_below_zero
    ; Temp is abowe or zero
    movf    divid0, W
    movwf   temp_parameter
    movf    remdrL, W
    movwf   temprem_parameter
    return

temp_below_zero:
    ; Temp is below or zero
    movlw   255
    movwf   dd1
    movf    divid0, W
    subwf   dd1, W
    movwf   temp_parameter
    movf    remdrL, W
    movwf   temprem_parameter
    return


send_humtemp:
    ;; Send the readed rfid
    banksel framelen
	movlw   13
	movwf   framelen

    movlw   20
	movwf   txframe

    movlw   20
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

    ;; 0x00 Basic config response
    banksel w5
	movf    w5, W
    banksel txframe
    movwf   txframe+7

    ;; 0x00 Basic config response
    banksel w4
	movf    w4, W
    banksel txframe
    movwf   txframe+8

    ;; 0x00 Basic config response
    banksel divid0
	movf    divid0, W
    banksel txframe
    movwf   txframe+9

    ;; Data - DeviceID
    banksel remdrL
    movf    remdrL, W
    banksel txframe
	movwf   txframe+10

	;; Padding bit
	movlw   0x00
    movwf   txframe+11
    call    txdo
    return


custom_command_handler:
      	movlw	0x0A            ;; Set the get tagg bit
        bankisel rcframe
        subwf	INDF,W
        btfsc	STATUS,Z
        goto    get_humtemp
        goto    restore

get_humtemp:
        call    read_humtemp
        call    send_humtemp
        goto    restore


divide:
    movlw   32      ; 32-bit divide by 16-bit
    movwf   bitcnt
    clrf    remdrH   ; Clear remainder
    clrf    remdrL

dvloop:
    clrc          ; Set quotient bit to 0
                     ; Shift left dividend and quotient
    rlf     divid0    ; lsb
    rlf     divid1
    rlf     divid2
    rlf     divid3    ; lsb into carry
    rlf     remdrL    ; and then into partial remainder
    rlf     remdrH

    skpnc         ; Check for overflow
    goto    subd
    movfw   divisH  ; Compare partial remainder and divisor
    subwf   remdrH,w
    skpz
    goto    testgt   ; Not equal so test if remdrH is greater
    movfw   divisL  ; High bytes are equal, compare low bytes
    subwf   remdrL,w
testgt:
    skpc          ; Carry set if remdr >= divis
    goto    remrlt

subd:
    movfw   divisL  ; Subtract divisor from partial remainder
    subwf   remdrL
    skpc          ; Test for borrow

    decf    remdrH   ; Subtract borrow
    movfw   divisH
    subwf   remdrH
    bsf     divid0,0  ; Set quotient bit to 1
                     ; Quotient replaces dividend which is lost
remrlt:
    decfsz  bitcnt
    goto    dvloop
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

Delay_001_ms:
			;19 cycles
	movlw	0x06
	movwf	dd1
Delay_001_ms_loop:
	decfsz	dd1, f
	goto	Delay_001_ms_loop
	return

Delay_005_ms:
			;100 cycles
	movlw	0x21
	movwf	dd1
Delay_005_ms_loop:
	decfsz	dd1, f
	goto	Delay_005_ms_loop
    return

end