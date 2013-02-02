    List      P=16f690		; list directive to define processor

#include "P16F690.INC"

; CONFIG
; __CONFIG _CONFIG1, 0x30D5
 __CONFIG _INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF


; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
#define ARC_16F         1
;#define ARC_18F         1
#define REC_CUSTOM_JUMP     custom_command_handler
;#define CUSTOM_INTERRUPT    c_intserv
#define DEV_ID1 64
#define DEV_ID2 48
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
        main_var
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

-              banksel ANSEL
	          clrf    ANSEL	     ; turn off ADC pins               |B2
	          banksel ANSELH
              clrf    ANSELH     ; turn off ADC pins               |B2
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
		  movlw b'11111001'
		  movwf TRISA	; Make PortA all input
	          clrf    TRISB	; setup PORT B all outputs        |B1
	          clrf    TRISC	; setup PORT C all outputs        |B1
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

        call    light_red
	;;
	;; Set Interrupts
	;;
        banksel INTCON
		bsf	INTCON, GIE
		bsf	INTCON, PEIE
        call    init_speedlib ; IMPORTANT to run this before, so the adresses are
                              ; imported from EEPROM
        banksel INTCON
        bcf     INTCON, GIE

    banksel adress1
	movlw	0x00
    subwf	adress1,W
	btfss	STATUS,Z
	goto    lg
	movlw	0x00
    subwf	adress2,W
	btfss	STATUS,Z
	goto    lg
    goto    lr

lg:
        call    light_green
        goto    dl
lr:
        call    light_red
        goto    dl
dl:

        clrf    main_var
        bcf     PORTB,4
	bcf	rc_gotflag,0
	movlw	250
	call	Delay		; Make sure that the ST485 IC circuits are started
    call    light_off
    banksel INTCON
    bsf     INTCON, GIE


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
        btfsc   PORTA,0
        call    run_button
        btfss   PORTA,0
        bcf     main_var,0
        goto    main

run_button:

        btfsc   main_var,0
        return
     	movlw	250
	call	Delay		; Make sure that the ST485 IC circuits are started
        btfss   PORTA,0
        goto    run_button_iah
	movlw	250
	call	Delay		; Make sure that the ST485 IC circuits are started
	movlw	250
	call	Delay		; Make sure that the ST485 IC circuits are started
	movlw	250
	call	Delay		; Make sure that the ST485 IC circuits are started
	movlw	250
	call	Delay		; Make sure that the ST485 IC circuits are started
        btfsc   PORTA,0
        goto    run_button_caddr
        return
run_button_iah:
        call    func_send_iam_here
        return

run_button_caddr:
        call    func_rand_addr
        call    func_send_iam_here
        call    light_red
	movlw	250
	call	Delay
        call    light_off
        bsf     main_var,0
        return

light_green:
    bsf     PORTA,1
    bcf     PORTA,2
    return
light_red:
    bcf     PORTA,1
    bsf     PORTA,2
    return
light_off:
    bcf     PORTA,1
    bcf     PORTA,2
    return

custom_command_handler:
        movlw   0x0A          ; Min  custom
        subwf   INDF,W        ; This is the command data byte, predefinde, before called by this funktion
        movwf   rand          ; Just use the random register rand(no reason why, just a temporary register availble)
        btfss   STATUS,C      ; Check so that the Commmand bit is >= 0x0A ; NOTE: If "addwf PC,F" Gets a zero, it brobubly will act like a "goto $"
        goto    restore

        movlw   1             ; MaxCommand; This is the number of functions in the list bellow, just to make sure its safe for buffer overflow
        subwf   rand,W        ; Command
        btfsc   STATUS,C      ; If Command >= MaxCommand then goto restore
        goto    restore

        movf    rand,W
        addwf   PCL,F
        call    transmit_remote
        goto    restore


transmit_remote:	
	movlw	rcframe+7
	movwf	FSR
	movf	INDF,W
	andlw	b'11110000'
	movwf	loop1		; Just a temoporary memmory, this was the best not in use

	movlw	0
	subwf	loop1,W
	btfsc	STATUS,Z
	goto	set_on_nexa_old

	movlw	16
	subwf	loop1,W
	btfsc	STATUS,Z
	goto	set_on_waveman_old

	movlw	32
	subwf	loop1,W
	btfsc	STATUS,Z
	goto	set_on_nexa

	
	goto	restore
	
set_on_nexa:
	;; this is just to make sure that re reciver is realy awake
	bsf	PORTC,0
	call	Delay_2500
	call	Delay_2500
	bcf	PORTC,0

	movlw	rcframe+7
	movwf	FSR
	btfsc	INDF,0
	goto	set_on_nexa_lern
	movlw	8		; Use this loop while just overall sending.
	movwf	loop1
	goto	set_on_nexa_r
set_on_nexa_lern:
	movlw	80		; Use this loop time when "learning"
	movwf	loop1
set_on_nexa_r:	
	;; Sync
  	call	sync_nexa
	;; start 0
	;;   	call	zero_nexa
	;; transmitter id 1010101010101010101010101010101010101010101010101010
	call	trans_id
	;; 
	movlw	rcframe+7
	movwf	FSR
	;; Grupp 0
	btfsc	INDF,3
 	call	m_one
	btfss	INDF,3
 	call	m_zero
	;; Dimmer,On,,Off : Dimmer 11, OBSERV, this, manchester, yes
	btfsc	INDF,2
 	call	one_nexa
	btfss	INDF,2
 	call	zero_nexa
	btfsc	INDF,1
 	call	one_nexa
	btfss	INDF,1
 	call	zero_nexa


	
	movlw	rcframe+8
	movwf	FSR
	;; Channel
	btfsc	INDF,3
 	call	m_one
	btfss	INDF,3
 	call	m_zero
	btfsc	INDF,2
 	call	m_one
	btfss	INDF,2
 	call	m_zero
	;; Button
	btfsc	INDF,1
 	call	m_one
	btfss	INDF,1
 	call	m_zero
	btfsc	INDF,0
 	call	m_one
	btfss	INDF,0
 	call	m_zero	
	;; Dim
	movlw	rcframe+9
	movwf	FSR
 	btfsc	INDF,3
 	call	m_one
 	btfss	INDF,3
 	call	m_zero
 	btfsc	INDF,2
 	call	m_one
 	btfss	INDF,2
 	call	m_zero
 	btfsc	INDF,1
 	call	m_one
 	btfss	INDF,1
 	call	m_zero
 	btfsc	INDF,0
 	call	m_one
 	btfss	INDF,0
 	call	m_zero
	;;

	;; Delay 10ms
        call    zero_nexa
  	call	Delay_2500
 	call	Delay_2500
  	call	Delay_2500
	call	Delay_2500
	decfsz	loop1,f
	goto	set_on_nexa_r
	return

m_zero:	
	call	zero_nexa
	call	one_nexa
	return
m_one:	
	call	one_nexa
	call	zero_nexa
	return
	
sync_nexa:
	bsf	PORTC,0
	call	Delay_295
	bcf	PORTC,0
	call	Delay_2500
	return
	
one_nexa:
        bsf     PORTC,0
	call    Delay_295
	bcf     PORTC,0
	call    Delay_920
	return

zero_nexa:
	bsf     PORTC,0
	call    Delay_295
	bcf     PORTC,0
	call    Delay_295
	return
	
set_on_nexa_old:
	bsf	loop2,0
	goto	set_on_old

set_on_waveman_old:
	bcf	loop2,0
	goto	set_on_old

set_on_old:
        movlw	rcframe+7
	movwf	FSR
	btfsc	INDF,0
	goto	set_on_old_lern
	movlw	8		; Use this loop while just overall sending.
	movwf	loop1
	goto	set_on_old_r
set_on_old_lern:
	movlw	80		; Use this loop time when "learning"
	movwf	loop1
set_on_old_r:	
	movlw	rcframe+8
	movwf	FSR
	;; Grupp 0
	btfsc	INDF,7
 	call	one
	btfss	INDF,7
 	call	zero
	btfsc	INDF,6
 	call	one
	btfss	INDF,6
 	call	zero
	btfsc	INDF,5
 	call	one
	btfss	INDF,5
 	call	zero
	btfsc	INDF,4
 	call	one
	btfss	INDF,4
 	call	zero
	btfsc	INDF,3
 	call	one
	btfss	INDF,3
 	call	zero
	btfsc	INDF,2
 	call	one
	btfss	INDF,2
 	call	zero
	btfsc	INDF,1
 	call	one
	btfss	INDF,1
 	call	zero
	btfsc	INDF,0
 	call	one
	btfss	INDF,0
 	call	zero
	movlw	rcframe+7
	movwf	FSR
	btfsc	INDF,2
 	goto	set_on_old_on
	btfss	INDF,2
 	goto	set_on_old_off

set_on_old_on:
	btfsc	loop2,0		; If it is one, goto nexa else, waveman
	goto	set_on_nexa_old_on
	goto	set_on_waveman_old_on
set_on_old_off:
	btfsc	loop2,0		; If it is one, goto nexa else, waveman
	goto	set_on_nexa_old_off
	goto	set_on_waveman_old_off
	
set_on_nexa_old_on:
	call    zero
	call    one
	call    one
	call    one
	goto	set_on_old_cont

set_on_nexa_old_off:
        call    zero
	call    one
        call    one
	call    zero
	goto	set_on_old_cont

set_on_waveman_old_on:
	call    zero
	call    one
	call    one
	call    one
	goto	set_on_old_cont

set_on_waveman_old_off:
        call    zero
	call    zero
        call    zero
	call    zero
	goto	set_on_old_cont

	
	
set_on_old_cont:
	call	ends
        decfsz  loop1,f	
	goto	set_on_old_r
	goto	restore

	
one:
	call	pack_end
	bsf	PORTC,0
	movlw	3
	call	Delay_old
	bcf	PORTC,0
	movlw	1
	call	Delay_old
	return
zero:
	call	pack_end
	bsf	PORTC,0
	movlw	1
	call	Delay_old
	bcf	PORTC,0
	movlw	3
	call	Delay_old
	return
pack_end:	
	bsf	PORTC,0
	movlw	1
	call	Delay_old
	bcf	PORTC,0
	movlw	3
	call	Delay_old
	return
	
ends:
	bsf	PORTC,0
	movlw	1
	call	Delay_old
	bcf	PORTC,0
	movlw	32
	call	Delay_old
	return	
	
Delay_old:
	movwf	d2
Delay_old_1:	
	;; 700 cycles
	movlw	0xE9
	movwf	d1
	decfsz	d1, f
	goto	$-1
	decfsz	d2, f
	goto	Delay_old_1
	return

Delay_170:
	;; 71
	movlw	0x85
	movwf	d1
Delay_1:	
	decfsz	d1, f
	goto	Delay_1
	return
	
Delay_295:	
	;; 589 cycles C4
	movlw	0x9F
	movwf	d1
Delay_2:	
	decfsz	d1, f
	goto	Delay_2
	return
	
Delay_920:	
	;; 1838 cycles 6F
	movlw	0xFB
	movwf	d1
	movlw	0x02
	movwf	d2
Delay_3:	
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_3
	return

Delay_2500:	
	movlw	0xE7
	movwf	d1
	movlw	0x04
	movwf	d2
Delay_4:	
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_4
	return

	;; 1010101010 01101010 010110 101001 1001100110 011001 010110
trans_id:
	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	zero_nexa
	call	one_nexa

	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	zero_nexa
	call	one_nexa

	call	zero_nexa
	call	one_nexa

	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	one_nexa
	call	zero_nexa

	call	zero_nexa
	call	one_nexa
	
	call	one_nexa
	call	zero_nexa

	call	zero_nexa
	call	one_nexa

	call	one_nexa
	call	zero_nexa

	call	zero_nexa
	call	one_nexa

	call	one_nexa
	call	zero_nexa

	call	zero_nexa
	call	one_nexa

	call	one_nexa
	call	zero_nexa

	call	zero_nexa
	call	one_nexa
	
	call	zero_nexa
	call	one_nexa

	call	zero_nexa
	call	one_nexa

	call	one_nexa
	call	zero_nexa
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