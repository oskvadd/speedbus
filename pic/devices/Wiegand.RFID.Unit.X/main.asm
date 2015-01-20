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
#define ARC_16F         1
;#define ARC_18F         1
#define REC_CUSTOM_JUMP     custom_command_handler
;#define CUSTOM_INTERRUPT    c_intserv
#define DEV_ID1 64
#define DEV_ID2 50
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
    pair
    pair_c
    w1
    w2
    w3
    w4
    main_commands          ; |X-------|b7 = NoNE
                           ; |-X------|b6 = NoNE
                           ; |--X-----|b5 = NoNE
                           ; |---X----|b4 = NoNE
                           ; |----X---|b3 = NoNE
                           ; |-----X--|b2 = NoNE
                           ; |------X-|b1 = If you set this to one, then the main loop will send back all the tags.
                           ; |-------X|b0 = If you set this to one, the next tag readed will be sent to the bus.
    w_loop_i
    w_tmp
    w_hresp_loop
    w_hresp_addr1
    w_hresp_addr2
    dd1
    dd2
    dd3
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



main:
    banksel RCSTA
	btfsc	RCSTA,OERR
	call    recerror
	;btfsc	PORTA, 0
	;call 	txporta
    banksel rand
	incf	rand,F		; Increase the random value

    banksel PORTA
    btfss   PORTA, 0
    goto    read_wiegand
    btfss   PORTA, 1
    goto    read_wiegand

    btfsc   main_commands, 1
    call    list_rfids

    goto    main


read_wiegand:
    banksel INTCON
    bcf     INTCON, GIE

    ;; Get parity bit at first.
    banksel PORTA
    btfss   PORTA, 0
    bcf     pair, 0
    btfss   PORTA, 1
    bsf     pair, 0
    call    read_wiegand_wait
    call    read_wiegand_delay

    movlw   w4
    movwf   FSR

    movlw   4
    movwf   d3
read_wiegand_loop1:
    ;; Write in bit 1
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 7
    btfss   PORTA, 1
    bsf     INDF, 7
    call    read_wiegand_wait
    call    read_wiegand_delay

    ;; Write in bit 2
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 6
    btfss   PORTA, 1
    bsf     INDF, 6
    call    read_wiegand_wait
    call    read_wiegand_delay

    ;; Write in bit 3
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 5
    btfss   PORTA, 1
    bsf     INDF, 5
    call    read_wiegand_wait
    call    read_wiegand_delay

    ;; Write in bit 4
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 4
    btfss   PORTA, 1
    bsf     INDF, 4
    call    read_wiegand_wait
    call    read_wiegand_delay

    ;; Write in bit 5
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 3
    btfss   PORTA, 1
    bsf     INDF, 3
    call    read_wiegand_wait
    call    read_wiegand_delay

    ;; Write in bit 6
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 2
    btfss   PORTA, 1
    bsf     INDF, 2
    call    read_wiegand_wait
    call    read_wiegand_delay

    ;; Write in bit 7
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 1
    btfss   PORTA, 1
    bsf     INDF, 1
    call    read_wiegand_wait
    call    read_wiegand_delay

    ;; Write in bit 8
    banksel PORTA
    btfss   PORTA, 0
    bcf     INDF, 0
    btfss   PORTA, 1
    bsf     INDF, 0
    call    read_wiegand_wait
    call    read_wiegand_delay


    decf    FSR, f
	decfsz	d3, f
    goto    read_wiegand_loop1

    ;; Get parity bit at last.
    banksel PORTA
    btfss   PORTA, 0
    bcf     pair, 1
    btfss   PORTA, 1
    bsf     pair, 1

    banksel INTCON
    bsf     INTCON, GIE

    ;; Parity check
    bcf     pair_c, 0
    bsf     pair_c, 1
    call    read_wiegand_pair_ceaven
    call    read_wiegand_pair_codd

    movf    pair, W
    xorwf   pair_c, f

    btfsc   pair_c, 0
    goto    read_wiegand_return
    btfsc   pair_c, 1
    goto    read_wiegand_return
    ;;

    btfsc   main_commands, 0
    call    send_rfidnr


    movlw   5
    movwf   w_loop_i

read_wiegand_seeprom_loop:

    movf    w_loop_i, W
    call    read_eeprom
    movwf    w_tmp

    btfsc   w_tmp, 0
    goto    read_wiegand_seeprom_loop_e


    movf    w_loop_i, W
    addlw   1
    call    read_eeprom
    subwf	w4,W
    btfss	STATUS,Z
    goto	read_wiegand_seeprom_loop_e

    movf    w_loop_i, W
    addlw   2
    call    read_eeprom
    subwf	w3,W
    btfss	STATUS,Z
    goto	read_wiegand_seeprom_loop_e

    movf    w_loop_i, W
    addlw   3
    call    read_eeprom
    subwf	w2,W
    btfss	STATUS,Z
    goto	read_wiegand_seeprom_loop_e

    movf    w_loop_i, W
    addlw   4
    call    read_eeprom
    subwf	w1,W
    btfss	STATUS,Z
    goto	read_wiegand_seeprom_loop_e

    ;; Got access
    bcf     PORTC,  7
    bsf     PORTC,  0

    movlw   20
    call    Delay
    bcf     PORTC,  6
    movlw   20
    call    Delay
    bsf     PORTC,  6

    movlw   100
    call    Delay
    bsf     PORTC,  7
    movlw   150
    call    Delay
    bcf     PORTC,  0
    ;;
    goto    read_wiegand_return

read_wiegand_seeprom_loop_e:
    movlw   5
    addwf   w_loop_i

    incfsz  w_loop_i, w
    goto    read_wiegand_seeprom_loop

read_wiegand_return:

    goto    main

read_wiegand_wait:
    banksel PORTA
    btfss   PORTA, 0
    goto    read_wiegand_wait
    banksel PORTA
    btfss   PORTA, 1
    goto    read_wiegand_wait
    return

send_rfidnr:
    ;; Send the readed rfid
	movlw   13
    banksel framelen
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
    movlw	0x0A
	movwf   txframe+6

    ;; 0x00 Basic config response
	movf    w4, W
    movwf   txframe+7

    ;; 0x00 Basic config response
	movf    w3, W
    movwf   txframe+8

    ;; Data - DeviceID
    movf    w2, W
	movwf   txframe+9

    ;; Data - DeviceID
    movf    w1, W
	movwf   txframe+10

	;; Padding bit
	movlw   0x00
    movwf   txframe+11
    call    txdo

    bcf     main_commands, 0

    return

read_wiegand_delay:
    movlw   40
    movwf   d2
read_wiegand_delay_loop:
    call    Delay_01_ms
    banksel PORTA
    btfss   PORTA, 0
    return
    btfss   PORTA, 1
    return
    banksel d2
	decfsz	d2, f
    goto    read_wiegand_delay_loop
    return

read_wiegand_pair_ceaven:
    btfsc   w4, 7
    call    read_wiegand_pari_c1
    btfsc   w4, 6
    call    read_wiegand_pari_c1
    btfsc   w4, 5
    call    read_wiegand_pari_c1
    btfsc   w4, 4
    call    read_wiegand_pari_c1
    btfsc   w4, 3
    call    read_wiegand_pari_c1
    btfsc   w4, 2
    call    read_wiegand_pari_c1
    btfsc   w4, 1
    call    read_wiegand_pari_c1
    btfsc   w4, 0
    call    read_wiegand_pari_c1
    btfsc   w3, 7
    call    read_wiegand_pari_c1
    btfsc   w3, 6
    call    read_wiegand_pari_c1
    btfsc   w3, 5
    call    read_wiegand_pari_c1
    btfsc   w3, 4
    call    read_wiegand_pari_c1
    btfsc   w3, 3
    call    read_wiegand_pari_c1
    btfsc   w3, 2
    call    read_wiegand_pari_c1
    btfsc   w3, 1
    call    read_wiegand_pari_c1
    btfsc   w3, 0
    call    read_wiegand_pari_c1
    return

read_wiegand_pair_codd:
    btfsc   w2, 7
    call    read_wiegand_pari_c2
    btfsc   w2, 6
    call    read_wiegand_pari_c2
    btfsc   w2, 5
    call    read_wiegand_pari_c2
    btfsc   w2, 4
    call    read_wiegand_pari_c2
    btfsc   w2, 3
    call    read_wiegand_pari_c2
    btfsc   w2, 2
    call    read_wiegand_pari_c2
    btfsc   w2, 1
    call    read_wiegand_pari_c2
    btfsc   w2, 0
    call    read_wiegand_pari_c2
    btfsc   w1, 7
    call    read_wiegand_pari_c2
    btfsc   w1, 6
    call    read_wiegand_pari_c2
    btfsc   w1, 5
    call    read_wiegand_pari_c2
    btfsc   w1, 4
    call    read_wiegand_pari_c2
    btfsc   w1, 3
    call    read_wiegand_pari_c2
    btfsc   w1, 2
    call    read_wiegand_pari_c2
    btfsc   w1, 1
    call    read_wiegand_pari_c2
    btfsc   w1, 0
    call    read_wiegand_pari_c2
    return

read_wiegand_pari_c1:
    movlw    B'00000001'
    xorwf    pair_c,F
    return

read_wiegand_pari_c2:
    movlw    B'00000010'
    xorwf    pair_c,F
    return


custom_command_handler:
       	movlw	0x0A            ;; Set the get tagg bit
        subwf	INDF,W
        btfsc	STATUS,Z
        goto	set_get_tag

    	movlw	0x0B
        subwf	INDF,W
    	btfsc	STATUS,Z
        goto    add_new_rfid

      	movlw	0x0C
        subwf	INDF,W
        btfsc	STATUS,Z
        goto	rm_rfid

      	movlw	0x0D
        subwf	INDF,W
        btfsc	STATUS,Z
        goto    list_rfids_dev

        goto    restore

set_get_tag:
        banksel main_commands
        bsf     main_commands, 0
        call    func_set_rsp_addr
        goto    restore

add_new_rfid:
        banksel loop2

        movlw   5
        movwf   loop2
add_new_rfid_loop:

        movf    loop2, W
        call    read_eeprom
        movwf   rc_nocoll

        btfss   rc_nocoll, 0
        goto    add_new_rfid_loop_e


        movf    loop2, W
        movwf   rc_nocoll
        movlw   0
        call    write_eeprom

        movf    loop2, W
        addlw   1
        movwf   rc_nocoll
        movf    rcframe+7, W
        call    write_eeprom

        movf    loop2, W
        addlw   2
        movwf   rc_nocoll
        movf    rcframe+8, W
        call    write_eeprom

        movf    loop2, W
        addlw   3
        movwf   rc_nocoll
        movf    rcframe+9, W
        call    write_eeprom

        movf    loop2, W
        addlw   4
        movwf   rc_nocoll
        movf    rcframe+10, W
        call    write_eeprom

        goto    restore

add_new_rfid_loop_e:
        ;; Check so that the rfid not already exists

        movf    loop2, W
        addlw   1
        call    read_eeprom
        movwf   loop1
        movf    rcframe+7, W
        subwf	loop1,W
        btfss	STATUS,Z
        goto	add_new_rfid_loop_ee

        movf    loop2, W
        addlw   2
        call    read_eeprom
        movwf   loop1
        movf    rcframe+8, W
        subwf	loop1,W
        btfss	STATUS,Z
        goto	add_new_rfid_loop_ee

        movf    loop2, W
        addlw   3
        call    read_eeprom
        movwf   loop1
        movf    rcframe+9, W
        subwf	loop1,W
        btfss	STATUS,Z
        goto	add_new_rfid_loop_ee

        movf    loop2, W
        addlw   4
        call    read_eeprom
        movwf   loop1
        movf    rcframe+10, W
        subwf	loop1,W
        btfss	STATUS,Z
        goto	add_new_rfid_loop_ee

    ;; Got access
    bcf     PORTC,  7
    bsf     PORTC,  0
    movlw   250
    call    Delay
    movlw   250
    call    Delay
    movlw   250
    call    Delay
    bcf     PORTC,  0
    bsf     PORTC,  7
    ;;


        ;; The rfid exists, return
        goto    restore

add_new_rfid_loop_ee:
        movlw   4
        addwf   loop2

        incfsz  loop2, f
        goto    add_new_rfid_loop
        goto    restore

rm_rfid:
        banksel loop2

        movlw   5
        movwf   loop2
rm_rfid_loop:

        movf    loop2, W
        call    read_eeprom
        movwf   rc_nocoll

        btfsc   rc_nocoll, 0
        goto    rm_rfid_loop_e

        ;; Find rfid

        movf    loop2, W
        addlw   1
        call    read_eeprom
        movwf   loop1
        movf    rcframe+7, W
        subwf	loop1,W
        btfss	STATUS,Z
        goto	rm_rfid_loop_e

        movf    loop2, W
        addlw   2
        call    read_eeprom
        movwf   loop1
        movf    rcframe+8, W
        subwf	loop1,W
        btfss	STATUS,Z
        goto	rm_rfid_loop_e

        movf    loop2, W
        addlw   3
        call    read_eeprom
        movwf   loop1
        movf    rcframe+9, W
        subwf	loop1,W
        btfss	STATUS,Z
        goto	rm_rfid_loop_e

        ;; Remove rfid
        movf    loop2, W
        movwf   rc_nocoll
        movlw   0xFF
        call    write_eeprom

        movf    loop2, W
        addlw   1
        movwf   rc_nocoll
        movlw   0xFF
        call    write_eeprom

        movf    loop2, W
        addlw   2
        movwf   rc_nocoll
        movlw   0xFF
        call    write_eeprom

        movf    loop2, W
        addlw   3
        movwf   rc_nocoll
        movlw   0xFF
        call    write_eeprom
        ;;

        ;; The rfid exists, return
        goto    restore

rm_rfid_loop_e:
        movlw   5
        addwf   loop2

        incfsz  loop2, w
        goto    rm_rfid_loop
        goto    restore

list_rfids_dev:
        banksel main_commands
        btfsc   main_commands, 1
        goto    restore                          ;; Device busy

        call    func_set_rsp_addr
        banksel rsp_adress1
        movf    rsp_adress1, W
        movwf   w_hresp_addr1
        movf    rsp_adress2, W
        movwf   w_hresp_addr2
        bsf     main_commands, 1
        goto    restore



list_rfids:
        movlw   5
        movwf   w_loop_i

list_rfids_loop:
        movf    w_loop_i, W
        call    read_eeprom
        movwf    w_tmp

        btfsc   w_tmp, 0
        goto    list_rfids_loop_e

        ;; Send the readed rfid
        movlw   13
        banksel framelen
        movwf   framelen

        movf    w_hresp_addr1, W
        movwf   txframe

        movf    w_hresp_addr2, W
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

        ;; Data
        movlw	0x0D
        movwf   txframe+6

        ;; 0x00 Basic config response
        movf    w_loop_i, W
        addlw   1
        call    read_eeprom
        movwf   txframe+7

        ;; 0x00 Basic config response
        movf    w_loop_i, W
        addlw   2
        call    read_eeprom
        movwf   txframe+8

        ;; Data - DeviceID
        movf    w_loop_i, W
        addlw   3
        call    read_eeprom
        movwf   txframe+9

        ;; Data - DeviceID
        movf    w_loop_i, W
        addlw   4
        call    read_eeprom
        movwf   txframe+10

        ;; Padding bit
        movlw   0x00
        movwf   txframe+11

list_rfids_handle_response:
        banksel rc_listen
        bcf     rc_listen,3

        movlw   10
        banksel w_hresp_loop
        movwf   w_hresp_loop


list_rfids_handle_response_loop:
        banksel INTCON
        bcf     INTCON, GIE
        call    txdo
        banksel INTCON
        bsf     INTCON, GIE
        banksel rc_listen
        bcf     rc_listen, 1
        bcf     rc_listen, 5

        ;; If error
        banksel RCSTA
        btfsc	RCSTA,OERR
        call    recerror
        ;;

        movlw	30
        call 	dDelay

        banksel rc_listen
        btfsc   rc_listen,3
        goto    list_rfids_loop_e
        decfsz  w_hresp_loop,f
        goto    list_rfids_handle_response_loop

list_rfids_loop_e:
        bcf     rc_listen,3

        movlw   5
        addwf   w_loop_i

        incfsz  w_loop_i, w
        goto    list_rfids_loop

        banksel main_commands
        bcf     main_commands, 1
        goto    main

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


Delay_01_ms:
			;199 cycles
	movlw	0x42
	movwf	d1
Delay_01_ms_0:
	decfsz	d1, f
	goto	Delay_01_ms_0
	return

dDelay:
    banksel dd1
	;; 499994 cycles
	movwf	dd3
	movlw	0xFF
	movwf	dd2
	movlw	50
	movwf	dd1
dDelay_0:
	decfsz	dd1, f
	goto	dDelay_0
	movlw	20                  ;; Need this for tuning
	movwf	dd1
	decfsz	dd2, f
	goto	dDelay_0
	movlw	100
	movwf	dd2
	decfsz	dd3, f
	goto	dDelay_0
	return

    end