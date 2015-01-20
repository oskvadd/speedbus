LIST P=18F4550, F=INHX32

#define DEV_ID1 64
#define DEV_ID2 47

#include "P18F4550.INC"
; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
;#define ARC_16F         1
#define ARC_18F         1
#define on_got_IAH  got_iah
;#define REC_CUSTOM_JUMP custom_command_handler

	     errorlevel -302

        CONFIG	FOSC=INTOSC_HS					; HS oscillator, HS used by USB
	CONFIG	PWRT=ON					; Power on timer
	CONFIG	BOR=OFF					; Brown out off
	CONFIG	WDT=OFF					; Watch dog off
	CONFIG	PBADEN=OFF				; Port B en digital IO
	CONFIG	LVP=OFF					; Pas de prog single supply
	CONFIG	ICPRT=OFF				; Port de debug off
	CONFIG	DEBUG=OFF				; Debug off

        CONFIG  XINST=OFF
        CONFIG  MCLRE=OFF


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
;	cblock      USER_VARIABLE_SPACE
;        servo_1_val
;        endc
;

	radix dec ;

clock   equ     8       ; 8 MHz
baud    equ     19200  ; 19200, 57600, or 115200
brgdiv  equ     4       ; divider value for BRG16 = 1
;brgval  equ     (clock*10000000/baud/brgdiv+5)/10-1
brgval  equ     25

	cblock  0x69
        current_s
        button_mem
        main_var
; b3 Nouse
; b2 Nouse
; b1 Used at change addr
; b0 Used at IAH change addr....
        c_iah_addr1
        c_iah_addr2
        c_iah_addr1s
        c_iah_addr2s
        divisL
        divisH
        divid0    ; lsb
        divid1
        divid2
        divid3    ; lsb into carry
        remdrL    ; and then into partial remainder
        remdrH
        bitcnt
        temp
        temp1
        temp2
        tmp1,tmp2,tmp3,tmp4,tmp5,tmp6,tmp7,tmp8,tmp9,tmp10
	endc


	org     0x000
	goto    v_reset
        org	0x016
	goto	intserv

v_reset:


                   movlw   b'01110011' ; '01110000'                      |B1
                   movwf   OSCCON      ;                                 |B1

                  movlw   0x0f
                  movwf   ADCON1

                  movlw   0x07
                  movwf   CMCON

                  movlw   b'00111111'
                  movwf   TRISA	; Make PortA all input
                  clrf    PORTA
	          clrf    TRISB	; setup PORT B all outputs        |B1
	          clrf    TRISC	; setup PORT C all outputs        |B1
                  bsf     TRISC,7 ; For USART
                  bsf     TRISC,6 ; For USART
                  clrf    TRISD


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
                  #ifdef    ARC_16
	          bsf     BAUDCTL,BRG16	; select 16 bit BRG               |B1
	          #endif
                  #ifdef    ARC_18
                  clrf    BAUDCON
;                  bsf     BAUDCON,TXCKP
                  bsf     BAUDCON,BRG16	; select 16 bit BRG               |B1
                  #endif
                  movlw   b'00100110'	; '0-------' CSRC, n/a (async)    |B1
	;;  '-0------' TX9 off, 8 bits      |B1
	;;  '--1-----' TXEN, tx enabled     |B1
	;;  '---0----' SYNC, async mode     |B1
	;;  '----0---' SENDB, send brk      |B1
	;;  '-----1--' BRGH, high speed     |B1
	;;  '------00' TRMT, TX9D           |B1
	          movwf   TXSTA	;                                 |B1
;	          bcf     STATUS,RP0 ; bank 0                          |B0
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
        call    init_speedlib
        ;;
        ;; Put a inalization value in the servo area/:s....

        ;clrf    PORTB

        call    start_display
        call    screen_0

        movlw   50
        call    Delay

        clrf    main_var

        movlb   0

main:

        call    check_buttons
	btfsc	RCSTA,OERR
	call    recerror
        bcf     PORTC,0
	;btfsc	PORTA, 0
	;call 	txporta
	incf	rand,F		; Increase the random value
        goto    main

got_iah:
        banksel main_var
        btfsc   main_var,0 ; If this bit is set, the device is waiting for a IAH
        goto    got_iah_serve
        goto    restore

got_iah_serve:
        bcf     main_var,0
        call    screen_3
        goto    restore

printW:
        ; Remember, the function print directly! and backwards
        clrf    FSR0H
        clrf    temp
        clrf    bitcnt
        bcf     STATUS,Z

printW_loop:
        clrf    divisH
        movlw   10
        movwf   divisL
        call    divide
        movlw   tmp1
        addwf   temp,W
        movwf   FSR0L
        movf    remdrL,W
        addlw   48
        movwf   INDF0
        incf    temp,F
        movlw   0
        subwf   divid0,W
        btfss   STATUS,Z
        goto    printW_loop

        movf    temp,W
        movwf   temp1

printW_loop2:
        movlw   tmp1
        addwf   temp,W
        movwf   FSR0L
        decf    FSR0L,F
        movf    INDF0,W
        call    w_char
        decfsz  temp,F
        goto    printW_loop2

        return

check_buttons:
; Buttons at PORTA
; [X] +---------------+ [X]
; [2] | bzzzzz        | [5]
; [0] | peep peep     | [4]
; [1] +---------------+ [3]



        banksel button_mem
        movf    PORTA,W
        subwf	button_mem,W
        btfsc	STATUS,Z
        return
        movf    PORTA,W
        movwf   button_mem
        movlw   200
        call    d10ms
        movlw	0
        subwf	PORTA,W
        btfsc	STATUS,Z
        return


        movlw	0
        subwf	current_s,W
        btfsc	STATUS,Z
        goto    check_buttons_0
        movlw	1
        subwf	current_s,W
        btfsc	STATUS,Z
        goto    check_buttons_1
        movlw	2
        subwf	current_s,W
        btfsc	STATUS,Z
        goto    check_buttons_2
        movlw	3
        subwf	current_s,W
        btfsc	STATUS,Z
        goto    check_buttons_3
        movlw	4
        subwf	current_s,W
        btfsc	STATUS,Z
        goto    check_buttons_4
        movlw	5
        subwf	current_s,W
        btfsc	STATUS,Z
        goto    check_buttons_5
        movlw	6
        subwf	current_s,W
        btfsc	STATUS,Z
        goto    check_buttons_6
        return

check_buttons_0:
        btfsc   PORTA,0
        call    screen_1
        btfsc   PORTA,1
        call    screen_2
        return

check_buttons_1:
        btfsc   PORTA,1
        goto    check_buttons_1_b
check_buttons_1_b:
        bcf     main_var,0
        call    screen_0
        return

check_buttons_2:
        btfsc   PORTA,1
        call    screen_0
        btfsc   PORTA,2
        call    screen_2
        return
check_buttons_3:
        btfsc   PORTA,1
        call    screen_0
        btfsc   PORTA,3
        goto    check_buttons_3_s4
        return

check_buttons_3_s4:
        bsf     main_var,1
        call    screen_4
        return

check_buttons_4:
        btfsc   PORTA,1
        call    check_buttons_4_back
        btfsc   PORTA,0
        goto    check_buttons_4_stamp
        btfsc   PORTA,5
        goto    check_buttons_4_addrX
        btfsc   PORTA,4
        call    check_buttons_4_inc_addrX
        btfsc   PORTA,3
        call    check_buttons_4_dec_addrX
        btfss   PORTA,3
        return
        btfss   PORTA,4
        return
        goto    check_buttons_4_clear_num

check_buttons_4_back:
        call    disable_marker
        call    screen_0
        return

check_buttons_4_stamp:
        movlw   0xFF
        subwf   c_iah_addr1,W
        btfss   STATUS,Z
        goto    check_buttons_4_stamp_f
        movlw   0xFF
        subwf   c_iah_addr2,W
        btfss   STATUS,Z
        goto    check_buttons_4_stamp_f
        goto    check_buttons_4_stamp_fail
check_buttons_4_stamp_f:
        call    disable_marker
        call    screen_5
        return

check_buttons_4_stamp_fail:
        call    disable_marker
        call    screen_6
        return

check_buttons_4_clear_num:
        btfss   main_var,1
        clrf    c_iah_addr1
        btfsc   main_var,1
        clrf    c_iah_addr2
        call    screen_4
        return

check_buttons_4_inc_addrX:
        btfss   main_var,1
        incf    c_iah_addr1,F
        btfsc   main_var,1
        incf    c_iah_addr2,F
        call    screen_4
        return

check_buttons_4_dec_addrX:
        btfss   main_var,1
        decf    c_iah_addr1,F
        btfsc   main_var,1
        decf    c_iah_addr2,F
        call    screen_4
        return

check_buttons_4_addrX:
        btg     main_var,1
        call    screen_4
        return

check_buttons_5:
        btfsc   PORTA,1
        call    screen_0
        btfsc   PORTA,0
        call    screen_5
        return

check_buttons_6:
        btfss   PORTA,1
        return
        call    enable_marker
        call    screen_4
        return

screen_6:
        movlw   6
        banksel current_s
        movwf   current_s

        call    clear_screen

        movlw   0
        call    set_daddr

        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   't'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char

        movlw   64
        call    set_daddr

        movlw   'F'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'l'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   't'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   's'
        call    w_char
        movlw   't'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char

        movlw   20
        call    set_daddr

        movlw   'A'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'i'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'b'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   's'
        call    w_char
        movlw   't'
        call    w_char
        movlw   '?'
        call    w_char
        movlw   84
        call    set_daddr
        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'B'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   ' '
        call    w_char
        return

screen_5:
        movlw   5
        banksel current_s
        movwf   current_s

        call    clear_screen

        movlw   0
        call    set_daddr

        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   't'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char

        movlw   20
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'T'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'y'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'g'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char


        movlw   84
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'B'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   ' '
        call    w_char


        movlw   64
        call    set_daddr

        movlw   'S'
        call    w_char
        movlw   't'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'g'
        call    w_char




        movlw   3
        movwf   temp1
        bcf     rc_listen,3
        bcf     rc_listen,0
screen_5_stamp_rsp:
      	;; Send porta over TX
	movlw   12
	movwf   framelen
	;; * adress
	movf	c_iah_addr1s,W
	movwf   txframe
	;; * adress
	movf	c_iah_addr2s,W
	movwf   txframe+1
	;; 0xff broadcast adress
	movf	adress1,W
	movwf   txframe+2
	;; 0xff broadcast adress
	movf	adress2,W
	movwf   txframe+3
	;; 0x03 control bit
	movlw	0x03
	movwf	txframe+4
	;; 0x01	protocoll
        movlw   0x00
	movwf   txframe+5
	;; Data
        movlw	0x03
	movwf   txframe+6
	;; Data
	movlw   0x01
        movwf   txframe+7
        ;; Data
        movf    c_iah_addr1,W
	movwf   txframe+8
	;; Data
        movf    c_iah_addr2,W
	movwf   txframe+9
	;; Padding
	movlw   0x00
        movwf   txframe+10

	call	txdo

        movlw   200
        call    Delay
        btfsc   rc_listen,3
        goto    screen_5_stamp_got_rsp

	;; Send porta over TX
	movlw   9
	movwf   framelen
	;; * adress
	movf	adress1,W
	movwf   txframe
	;; * adress
	movf	adress2,W
	movwf   txframe+1
	;; 0xff broadcast adress
	movf	adress1,W
	movwf   txframe+2
	;; 0xff broadcast adress
	movf	adress2,W
	movwf   txframe+3
	;; 0x03 control bit
	movlw	0x03
	movwf	txframe+4
	;; 0x01	protocoll
        movlw   0x00
	movwf   txframe+5
	;; Data
        movlw	0x01
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7
	call	txdo
        movlw   200
        call    Delay
        btfsc   rc_listen,0
        goto    screen_5_stamp_got_rsp
        movlw   '.'
        call    w_char
        decfsz  temp1,f
        goto    screen_5_stamp_rsp

        bsf     rc_listen,3
        bsf     rc_listen,0

        movlw   64
        call    set_daddr

        movlw   'N'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        return

screen_5_stamp_got_rsp:

        movlw   64
        call    set_daddr

        movlw   'A'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'g'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   's'
        call    w_char
        movlw   't'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   '!'
        call    w_char
        return


screen_4:
        movlw   4
        banksel current_s
        movwf   current_s

        call    clear_screen

        movlw   0
        call    set_daddr

        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'C'
        call    w_char
        movlw   'h'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'g'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char


        movlw   20
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   't'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'U'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   '-'
        call    w_char
        movlw   '>'
        call    w_char


        movlw   84
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'B'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'D'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'w'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   '-'
        call    w_char
        movlw   '>'
        call    w_char

        movlw   64
        call    set_daddr

        movlw   'A'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ':'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   71
        movwf   temp2
        clrf    temp1
        movf    c_iah_addr1,W
        movwf   divid0
        clrf    divid1
        clrf    divid2
        clrf    divid3
        call    printW
        movlw   '.'
        call    w_char
        movf    temp1,W
        addwf   temp2,F
        movf    c_iah_addr2,W
        movwf   divid0
        clrf    divid1
        clrf    divid2
        clrf    divid3
        call    printW

        movlw   80
        call    set_daddr
        movlw   'X'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   '-'
        call    w_char
        movlw   '>'
        call    w_char

        ; IMPORTANT, thise peace of cewd need to be at the end
        btfss   main_var,1
        goto    screen_4_caddr2
        incf    temp1,W ; incf because of the character between the numberes '.'
        addwf   temp2,F
screen_4_caddr2:
        movf    temp2,W
        call    set_daddr
        call    enable_marker
        return


screen_3:
        movlw   3
        banksel current_s
        movwf   current_s

        call    clear_screen

        movlw   0
        call    set_daddr

        movlw   ' '
        call    w_char
        movlw   'C'
        call    w_char
        movlw   'h'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'g'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'I'
        call    w_char
        movlw   'A'
        call    w_char
        movlw   'H'
        call    w_char
        movlw   ' '
        call    w_char

        movlw   84
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'B'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   '-'
        call    w_char
        movlw   '>'
        call    w_char

        movlw   64
        call    set_daddr

        movlw   'D'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'v'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   ':'
        call    w_char
        movlw   ' '
        call    w_char

        clrf    divid0
        clrf    divid1
        clrf    divid2
        clrf    divid3
        movlw   divid0
        clrf    FSR0H
        banksel rc_counter
        movlw   10
        subwf   rc_counter,W
        movwf   temp
        movwf   tmp3
        clrf    tmp1

devid_divid:
        decf    tmp3,F
        movlw   rcframe+8
        addwf   tmp3,W
        movwf   FSR0L
        movf    INDF0,W
        movwf   tmp2
        movlw   divid0
        addwf   tmp1,W
        movwf   FSR0L
        movf    tmp2,W
        movwf   INDF0
        incf    tmp1,F
        decfsz  temp,F
        goto    devid_divid
        call    printW


        movlw   20
        call    set_daddr

        movlw   'A'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   ':'
        call    w_char
        movlw   ' '
        call    w_char
        

        movf    rcframe+2,W
        movwf   c_iah_addr1
        movwf   c_iah_addr1s
        movwf   divid0
        clrf    divid1
        clrf    divid2
        clrf    divid3
        call    printW

        movlw   '.'
        call    w_char

        movf    rcframe+3,W
        movwf   c_iah_addr2
        movwf   c_iah_addr2s
        movwf   divid0
        clrf    divid1
        clrf    divid2
        clrf    divid3
        call    printW

        movlw   ' '
        call    w_char

        return

screen_2:
        movlw   2
        banksel current_s
        movwf   current_s

        call    clear_screen

        movlw   0
        call    set_daddr

        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'T'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'l'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'h'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char

        movlw   64
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'T'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'g'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   ' '

        movlw   84
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'B'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char

        movlw   20
        call    set_daddr

        movlw   'S'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'h'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'g'
        call    w_char

        bsf     rc_listen,4  ; Do not send "is occupied response" to the 0x01
        bsf     rc_listen,0

	movlw   9
	movwf   framelen
        movlw   0xFF
	movwf   txframe
	;; 0xff broadcast dst adress
        movlw   0xFF
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
        movlw	0x01
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7

        call    txdo

        movlw   '.'
        call    w_char

        movlw   255
        call    Delay

        btfss   rc_listen,0
        goto    screen_2_live

        movlw   '.'
        call    w_char

        movlw   255
        call    Delay

        btfss   rc_listen,0
        goto    screen_2_live

        movlw   '.'
        call    w_char

        movlw   255
        call    Delay

        btfss   rc_listen,0
        goto    screen_2_live

        movlw   '.'
        call    w_char

        movlw   255
        call    Delay

        btfss   rc_listen,0
        goto    screen_2_live
        goto    screen_2_broken

screen_2_live:
        movlw   20
        call    set_daddr

        movlw   'S'
        call    w_char
        movlw   'u'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   's'
        call    w_char
        movlw   '!'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        return

screen_2_broken:
        movlw   20
        call    set_daddr

        movlw   'L'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   's'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'b'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'n'
        call    w_char

        return

screen_1:
        movlw   1
        banksel current_s
        movwf   current_s

        call    clear_screen

        movlw   0
        call    set_daddr

        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'f'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'I'
        call    w_char
        movlw   'A'
        call    w_char
        movlw   'H'
        call    w_char

        movlw   20
        call    set_daddr

        movlw   'W'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   't'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'g'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'f'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'I'
        call    w_char
        movlw   'A'
        call    w_char
        movlw   'H'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char

        movlw   84
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'B'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char
        movlw   ' '
        call    w_char

        bsf     main_var,0
        return

screen_0: ; Init screen
        movlw   0
        banksel current_s
        movwf   current_s

        call    clear_screen

        movlw   0
        call    set_daddr
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   'p'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'b'
        call    w_char
        movlw   'u'
        call    w_char
        movlw   's'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'p'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'k'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'U'
        call    w_char
        movlw   'I'
        call    w_char

        movlw   20
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'd'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'f'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'o'
        call    w_char
        movlw   'm'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'I'
        call    w_char
        movlw   'A'
        call    w_char
        movlw   'H'
        call    w_char

        movlw   84
        call    set_daddr

        movlw   '<'
        call    w_char
        movlw   '-'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'T'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   's'
        call    w_char
        movlw   't'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'l'
        call    w_char
        movlw   'i'
        call    w_char
        movlw   'n'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   ' '
        call    w_char
        movlw   'S'
        call    w_char
        movlw   'e'
        call    w_char
        movlw   'a'
        call    w_char
        movlw   'r'
        call    w_char
        movlw   'c'
        call    w_char
        movlw   'h'
        call    w_char
        movlw   ' '
        call    w_char

;        call    write_hello
;        movlw   64
;        call    set_daddr
;        call    write_hello
;        movlw   84
;        call    set_daddr
;        call    write_hello

        return

byte_to_str:
        movwf   c_iah_addr1
        clrf    divid0
        clrf    divid1
        clrf    divid2
        clrf    divid3
        movwf   divid0
        return
; Resume here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

set_daddr:
        movwf   d1
        bsf     d1,7
        movf    d1,W
        call    w_ins
        return

clear_screen:
        movlw   b'00000001'
        call    w_ins
        movlw   150
        call    d10ms
        return

enable_marker:
        movlw   b'00001111' ; Display on | Cursor | Blink
        call    w_ins
        movlw   150
        call    d10ms
        return

disable_marker:
        movlw   b'00001100' ; Display on | Cursor | Blink
        call    w_ins
        movlw   150
        call    d10ms
        return

start_display:
        clrf    PORTC
        clrf    PORTD
        movlw   b'00111111'
        call    w_ins
        movlw   b'00001100' ; Display on | Cursor | Blink
        call    w_ins
        movlw   b'00000001'
        call    w_ins
        movlw   b'00000010'
        call    w_ins
        movlw   b'00000110'
        call    w_ins
        movlw   150
        call    d10ms
        return

w_ins:
        bcf     PORTC,1
        goto    w_lcd
w_char:
        bsf     PORTC,1
w_lcd:
        movwf   PORTD
        bsf     PORTC,0
        movlw   10
        call    d10ms
        bcf     PORTC,0
        movlw   11
        call    d10ms
        return

divide:
       movlw 32      ; 32-bit divide by 16-bit
       movwf bitcnt
       clrf remdrH   ; Clear remainder
       clrf remdrL

dvloop:
       bcf  STATUS,C          ; Set quotient bit to 0
                     ; Shift left dividend and quotient
       rlcf divid0    ; lsb
       rlcf divid1
       rlcf divid2
       rlcf divid3    ; lsb into carry
       rlcf remdrL    ; and then into partial remainder
       rlcf remdrH

       btfsc STATUS,C         ; Check for overflow
       goto subd
       movf divisH,W  ; Compare partial remainder and divisor
       subwf remdrH,w
       btfss STATUS,Z
       goto testgt   ; Not equal so test if remdrH is greater
       movf divisL,W  ; High bytes are equal, compare low bytes
       subwf remdrL,w
testgt:

       btfss STATUS,C          ; Carry set if remdr >= divis
       goto remrlt

subd:
       movf divisL,W  ; Subtract divisor from partial remainder
       subwf remdrL
       btfss STATUS,C ; Test for borrow

       decf remdrH   ; Subtract borrow
       movf divisH,W
       subwf remdrH
       bsf divid0,0  ; Set quotient bit to 1
                     ; Quotient replaces dividend which is lost
remrlt:
       decfsz bitcnt
       goto dvloop
       return


d10ms:

			;19998 cycles
        movwf   d3
d10ms__:
	movlw	0x8F
	movwf	d1
	movlw	0x02
	movwf	d2
d10ms_:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	d10ms_
	decfsz	d3, f
	goto	d10ms__
        return

d1s:
	movlw	0x03
	movwf	d1
	movlw	0x18
	movwf	d2
	movlw	0x02
	movwf	d3
d1s_0:
	decfsz	d1, f
	goto	d1s_0
	decfsz	d2, f
	goto	d1s_0
	decfsz	d3, f
	goto	d1s_0
        return



#include "../SpeedBus.PIC.Lib.X/speedlib_main.asm"

        end