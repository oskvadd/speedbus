List      P=16f690		; list directive to define processor
#include <p16f690.inc>
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

	radix dec

clock   equ     8       ; 8 MHz
baud    equ     19200  ; 19200, 57600, or 115200
brgdiv  equ     4       ; divider value for BRG16 = 1
brgval  equ     (clock*10000000/baud/brgdiv+5)/10-1
	

	cblock  0x20
	     d1      		; Define three file registers for the
      	     d2      		; delay loop
	     d3
	     d4
	     tmp_W
	     tmp_STATUS
	     tmp_PCLATH
	     d1_tmp
	     d2_tmp
	     d3_tmp
	     rand
	     loop1		; Loop mem 1
	     loop2		; Loop mem 2
	     rc_listen		; Set diffrent bit:s in this register if you want to do somthing whit diffrent types of pack:ets, look at the code
	     rc_counter 	; RC framelen
	     rc_gotflag		; Set to 1 if it "got a flag"
	     rc_nocoll		; Use this to confim that no collission has ocurred
	     rc_add_byte	; recsave_add temporary argument
	     adress1		; The adress at the bus
	     adress2		; The adress at the bus
	     sendc
	     crc0
	     crc1
	     crcloop
	     crctmp
	     framelen		; TX framelen
	     txtmp		; temporary before sending
	     txreturn		; Hardcoded return, if nessesary(in interupts)
	     txframe, tx1, tx2, tx3, tx4, tx5, tx6, tx7, tx8, tx9, tx10 ; Current package limit, 20B
             tx11, tx12, tx13, tx14, tx15, tx16, tx17, tx18, tx19, tx20
	     rcframe, rc1, rc2, rc3, rc4, rc5, rc6, rc7, rc8, rc9, rc10 ; Current package limit, 20B
	     rc11, rc12, rc13, rc14, rc15, rc16, rc17, rc18, rc19, rc20

	endc


	org     0x000
	goto v_reset
	org	0x004
	goto	intserv

	
v_reset
	          clrf    STATUS ; force bank 0 and IRP = 0        |B0
	          goto    Init	 ;                                 |B0

	;; ******************************************************************
	;;   main init                                                      *
	;; ******************************************************************

Init
	          bsf     STATUS,RP1 ; bank 2                          |B2
	          clrf    ANSEL	     ; turn off ADC pins               |B2
	          clrf    ANSELH     ; turn off ADC pins               |B2
	;;
	;;   setup 8 MHz INTOSC
	;;
	          bcf     STATUS,RP1 ; bank 0                          |B0
	          bsf     STATUS,RP0 ; bank 1                          |B1
	          movlw   b'01110000' ; '01110000'                      |B1
	          movwf   OSCCON      ;                                 |B1
Stable
	          btfss   OSCCON,HTS ; osc stable? yes, skip, else     |B1
	          goto    Stable     ; test again                      |B1
	;;
	;;   setup ports
	;;
		  movlw 0xFF
		  movwf TRISA	; Make PortA all input
	          clrf    TRISB	; setup PORT B all outputs        |B1
	          clrf    TRISC	; setup PORT C all outputs        |B1
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
	movlw	250
	call	Delay		; Make sure that the ST485 IC circuits are started
main:
	movlw   3
	call	Delay

	call	trd		; Three random delays before sending broadcast
	goto	init_checkaddr
init_checkaddr_done:	
;;; 	     btfss   PORTA,2
	goto    loopr
	;; 	     goto    main

loopr:
	movlw   3
	call	Delay
	goto 	txporta
	nop
	nop
	nop
	nop
	nop
loop:
	;; 	bsf     07h,0	; turn on LED C0 (DS1)
	;; 	clrf	TXREG
	movlw	2
	call    Delay
	;; 	clrf	PORTC
	;; 	movlw	2
	;; 	call    Delay
	btfsc	RCSTA,OERR
	call recerror
	btfsc	PORTA, 0
	call 	txporta
	;; 	bcf     07h,0
	;; 	call    Delay
	;; 	call	send
	;; 	movf	RCREG,W
	;;	decfsz  d4, f	
	;; 	movwf	TXREG
	incf	rand,F		; Increase the random value
	goto    loop


init_checkaddr:
	movlw	3
	movwf	loop1
	
init_checkaddr_l:
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
	movlw	0xff
	movwf   txframe+2
	;; 0xff broadcast adress
	movlw	0xff
	movwf   txframe+3
	;; 0x03 control bit
	movlw	0x03
	movwf	txframe+4
	;; 0x01	protocoll
        movlw   0x00
	movwf   txframe+5
	;; Data
        movlw	0x00
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7

	bsf	txreturn,0
	call	txdo
	bcf	txreturn,0
	
	bsf	rc_listen,0
	movlw	10
	call	Delay
	btfsc	rc_listen,0
	goto	init_checkaddr_not_ocupied
	goto	init_checkaddr_ocupied

init_checkaddr_not_ocupied:
	decfsz	loop1, f
	goto	init_checkaddr_l
	bcf	rc_listen,0	
	goto	init_checkaddr_done ;	Jump back to init 

	
init_checkaddr_ocupied:
	call	setaddr
	goto 	init_checkaddr_done ;   Jump back to init

setaddr:
	movlw	0x00
	movwf	adress1
	movlw	0x00
	movwf	adress2

setaddr1:	
	
	incfsz	adress2, f
	goto	setaddr2

	movlw	0x00
	movwf	loop2

	incfsz	adress1, f
	goto	setaddr2
	return			; ALERT!!! Change this to a rutin that show an error that no adress is availible (all ~65535 is taken)

setaddr2:
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
	movlw	0xff
	movwf   txframe+2
	;; 0xff broadcast adress
	movlw	0xff
	movwf   txframe+3
	;; 0x03 control bit
	movlw	0x03
	movwf	txframe+4
	;; 0x01	protocoll
        movlw   0x00
	movwf   txframe+5
	;; Data
        movlw	0x00
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7

	bsf	txreturn,0
	call	txdo
	bcf	txreturn,0
	bsf	rc_listen,0
	movlw	1
	call	Delay
	btfsc	rc_listen,0
	goto	setaddr_testloop
	goto	setaddr1

	
setaddr_testloop:		; Send this rutine another 2 times, to make sure that the previus packet not was droped
	movlw	2
	movwf	loop1
setaddr_testloop_l:	
        bsf	txreturn,0
	call	txdo
	bcf	txreturn,0
	bsf	rc_listen,0
	movlw	1
	call	Delay
	btfss	rc_listen,0
	goto	setaddr1
	decfsz	loop1,	f
	goto	setaddr_testloop_l
	return			; The adress sems nice! Returning, and keep the composed adress!
	
	
	
intserv:
	movwf	tmp_W		;	Register BKP before the interup code exec
	movf	STATUS,W
	clrf	STATUS
	movwf	tmp_STATUS
	movf	PCLATH,W
	movwf	tmp_PCLATH
	movf	d1,W
	movwf	d1_tmp
	movf	d2,W
	movwf	d2_tmp
	movf	d3,W
	movwf	d3_tmp
 	btfsc 	PIR1,RCIF	;	Check if the recived data bit is set
	goto	rec		;	Jump to recive data rutine if the PIR1 bit is 1

restore:			;	Restore the regisers
	movf	d1_tmp,W
	movwf	d1
	movf	d2_tmp,W
	movwf	d2
	movf	d3_tmp,W
	movwf	d3	
	movf 	tmp_PCLATH,W
	movwf	PCLATH
	movf	tmp_STATUS,W
	movwf	STATUS
	swapf	tmp_W,F
	swapf	tmp_W,W
	retfie
	

rec:
	btfss	rc_listen,1		; If rc_listen is set to NOT drop the loopback package, jump directly to the rec_start
	goto	rec_start		

	bcf	rc_listen,1		;; Start this rutine with checking that the recived bit NOT was send from this own device
	movf	rc_nocoll,W
	subwf	RCREG,W
	btfss	STATUS,Z
	goto	rec_oops_coll		; Anyway, if the rc_listen,1  is 1, and it do not match RCREG, we may be detected an collission
	goto 	restore
rec_oops_coll:
	bsf     PORTC,0
	bsf	txreturn,1
	goto	restore
	
rec_start
	movlw	0x7e
	subwf	RCREG,W
	btfsc	STATUS,Z
	goto	recx		; Jump if this is a flag bit
	btfsc	rc_gotflag,0
	goto	recsave		; Jump if the flag bit is set
	goto	recr
recx:	
	btfsc	rc_gotflag,0
	goto	recend		; If this may be end flag, check the package, finalize, check crc
	bsf	rc_gotflag,0	; Else set the gotflag, and start recording package!
	clrf	rc_counter	; Clear the counter :)
	goto	restore
recr:	
	; 	movf    RCREG,W
	; 	movwf   TXREG		
	goto	restore

recsave:
 	movlw	0x7d
 	subwf   RCREG,W
 	btfsc   STATUS,Z
 	goto	recsave_set	; Set bit in the rc_listen to aktivate escape routines when the next byte is recived
 	btfsc   rc_listen,2
	goto	recsave_unescape

	movf	RCREG,W
	goto	recsave_add

recsave_set:
	bsf	rc_listen,2
	goto	restore

recsave_unescape:
	bcf	rc_listen,2
	movlw   0x5e
	subwf   RCREG,W
	btfsc   STATUS,Z
	goto	recsave_unescape_1
	movlw   0x5d
	subwf   RCREG,W
	btfsc   STATUS,Z
	goto	recsave_unescape_2
	goto	restore		; Maybe you can change this, but a fail package that is the result, will also be CRC checked
	
recsave_unescape_1:
	movlw	0x7e
	goto	recsave_add
recsave_unescape_2:
        movlw   0x7d
	goto    recsave_add
	
recsave_add:
	movwf	rc_add_byte
	movlw	rcframe		; Place where to put the receiving byte
	addwf	rc_counter,W	; Add the number in rc_flow, to the pointer, like rcframe[rc_flow] 
	movwf	FSR
	movf	rc_add_byte,W
	movwf	INDF
	incf	rc_counter,W
	movwf	rc_counter
	goto	restore
	
recend:
	decf	rc_counter,W
	movwf	rc_counter
	movwf	crcloop
	movlw	rcframe
	movwf	FSR
	clrf	crc0
	clrf	crc1
	call	crcloopr	; Call CRC function


	movlw	rcframe
	addwf	rc_counter,W
	movwf	FSR
	
	movf	INDF,W
	subwf	crc1,W
	btfss	STATUS,Z
	goto	reccrcfail

	decf	FSR,W
	movwf	FSR
	
	movf	INDF,W
	subwf	crc0,W
	btfss	STATUS,Z
	goto	reccrcfail

	
	;; fix so that the cheksum is check:ed and do things ;)

	;; REMEMBER, if checksum is right, clear rc_gotflag, else, untuched
	bcf	rc_gotflag,0

	movlw	rcframe+6	; Move recived byte to W
	movwf	FSR


	movlw	0x00		; Just check, recive broadcast
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_is_ocupied
	

	movlw	0x01
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_bc

recend_no_broadcast:

	movlw	rcframe
	movwf	FSR
	movf	INDF,W		; Check so that the adress is destinated for me
	subwf	adress1,W
	btfss	STATUS,Z
	goto	restore
	incf	FSR,W
	movwf	FSR
	movf	INDF,W
	subwf	adress2,W
	btfss	STATUS,Z
	goto	restore

	movlw	rcframe+6	; Move recived byte to W
	movwf	FSR
	
	
	movlw	0x00		; Send respons for, 0x00 message, destionated for me
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_is_ocupied_send_response
	
	movlw	0x02
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_setport
	
	goto	restore

func_is_ocupied:
	btfsc	rc_listen,0
	goto	func_is_ocupied_recived_ocupied
	goto	recend_no_broadcast


func_is_ocupied_recived_ocupied:	
	movlw	rcframe+2		;	move four bit:s backward, to the src addr
	movwf	FSR

	movf	adress1,W		;	check src adress1
	subwf	INDF,W
	btfss	STATUS,Z
	goto	restore

	incf	FSR,W		;	Increase the address	
	movwf	FSR

	movf	adress2,W		;	check src adress2
	subwf	INDF,W
	btfss	STATUS,Z
	goto	restore

	bcf	rc_listen,0
	goto	restore

	
func_is_ocupied_send_response:
	movlw	20		; Pretty strange, but you need this, so no colission or somthing will be made betwen PC and ansoring device
	call	Delay
	;; Send Package:
	
	movlw   9
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
	;; Data
        movlw	0x00
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7
	
	;; This is a broadcast package with adress on it
	bsf	txreturn,0
	call	txdo	
	bcf	txreturn,0
	goto	restore

	
func_bc:
	movlw	rcframe+2	;	move six bit:s backward, to the dst addr
	movwf	FSR

	movf	INDF,W
        movwf	TXREG
	
	movlw	0xFF		;	check src adress1
	subwf	INDF,W
	btfss	STATUS,Z
	goto	restore
	
	incf	FSR,W		;	Increase the address	
	movwf	FSR

	movlw	0xFF		;	check src adress2	
	subwf	INDF,W
	btfss	STATUS,Z
	goto	restore
	
	goto	func_bc_sendaddr
		
	
func_bc_sendaddr:	

	call	trd	 ; Three random delay:s before ansor broadcast
	
	;; Send Package:
	
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
	;; Data
        movlw	0x01
	movwf   txframe+6
;;;  DEvice ID 0x0001
	movlw   0x00
	movwf   txframe+7
	;;  Data
	movlw   0x01
	movwf   txframe+8
	;; Padding bit
	movlw   0x00
        movwf   txframe+9

	
	;; This is a broadcast package with adress on it
	bsf	txreturn,0
	call	txdo
	

func_bc_sended_packet:
	bcf	txreturn,0
	goto	restore

func_setport:
	movlw	2
	addwf	FSR,F
	movf	INDF,W
	movwf	PORTC
	goto restore
	
reccrcfail:
	;; Because that this happend directrly after a crc-fail, here we need to clear the counter, so the newxt comming package will start allover
	clrf	rc_counter
	;; Do somthing
	movlw    B'00000001' 	;toggle bit3
	xorwf    PORTC,F
	goto	restore
	
recerror:
	;; Do somthing
	bcf	RCSTA,CREN
	bsf	RCSTA,CREN
	return
txoops:				; Colisson has ocurred
	bcf	txreturn,1
	call	lfsr
	movf	rand,W
	call	Delay
	goto	txdo2

tx_send:
	movwf	txtmp
	movlw	0x7e		
	subwf	txtmp,W		
	btfsc	STATUS,Z
	goto	tx_send_escape_1

	movlw	0x7d
	subwf	txtmp,W
	btfsc	STATUS,Z
	goto	tx_send_escape_2
	movf	txtmp,W
	
tx_send_noescape:	
	movwf	txtmp
	bsf     STATUS,RP0      ;bank 1                          |B1
	btfss   TXSTA,TRMT
	goto	$-1
	bcf     STATUS,RP0 ; bank 1                          |B1 
	movlw	1
	call	Delay
	movf	txtmp,W
	bsf	rc_listen, 1
	movwf	rc_nocoll
	movwf	TXREG
	movlw	1
	call 	Delay
	btfsc	txreturn,1
	goto	txoops
	return

tx_send_escape_1:
	movlw	0x7d
	call	tx_send_noescape
	movlw	0x5e
	call	tx_send_noescape
	return

tx_send_escape_2:
	movlw   0x7d
	call    tx_send_noescape
	movlw   0x5d
	call    tx_send_noescape
	return
	

txdo:				; This is like the funktion argumnents, they need to be set at every presense of crcloopr
	;; Set TX enable
	bsf	PORTB,4
	;; 
	movf	framelen,W
	movwf	crcloop
	movlw	txframe
	movwf	FSR
	clrf	crc0
	clrf	crc1
	call	crcloopr
	goto	txdo2
crcloopr:
	decfsz	crcloop, f
	goto	crccalc
	return

crccalc:	
	movf  INDF,W		;;load w with next databyte
	xorwf crc1,W		;;(a^x):(b^y)
	movwf crctmp            ;;
	andlw 0xf0              ;; W = (a^x):0
	swapf crctmp,F          ;; Index = (b^y):(a^x)
	xorwf crctmp,F          ;; Index = (a^b^x^y):(a^x) = i2:i1

	                        ;; High byte
	movf  crctmp,W
	andlw 0xf0
	xorwf crc0,W
	movwf crc1

	rlf  crctmp,W           ;; use rlf for PIC16
	rlf  crctmp,W           ;; use rlf for PIC16
	xorwf crc1,F
	andlw 0xe0
	xorwf crc1,F

	swapf crctmp,F
	xorwf crctmp,W
	movwf crc0
        incf    FSR,W
	movwf   FSR
	goto crcloopr

txdo2:
	movlw	0x7e
	call	tx_send_noescape
	movlw	txframe
	movwf	FSR
	movf	framelen,W
	movwf	crcloop
send:
	decfsz	crcloop,f
	goto 	lopp
	goto    crcsend
lopp:
	movf	INDF,W
	call	tx_send
	incf	FSR,W
	movwf	FSR
	goto 	send

crcsend:
	movf	crc0,W
	call	tx_send
	movf	crc1,W
	call	tx_send
	goto	endflag

endflag:
	movlw	0x7e
	call	tx_send_noescape
	;; Disable TX enable
	bcf	PORTB,4
	;; 
	btfss	txreturn,0
	goto	loop	
	return
	
	
txporta:
	;; Send porta over TX
	movlw   9
	movwf   framelen
	;; 0xff broadcast adress
	movlw	0xFF
	movwf   txframe	
	;; 0xff broadcas, adress
	movlw	0xFF
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
        movlw   0x01
	movwf   txframe+5
	;; Data
        movf	PORTA,W
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe

	
	goto txdo

trd:	
	call	lfsr		; Three random delays before sending broadcast
	movf	rand,W
	call	Delay
	call	lfsr
	movf	rand,W
	call	Delay
	call	lfsr
	movf	rand,W
	call	Delay
	return
	
lfsr:
	rlf     rand,W
	rlf     rand,W
	btfsc   rand,4
	xorlw   1
	btfsc   rand,5
	xorlw   1
	btfsc   rand,3
	xorlw   1
	movwf   rand
	retlw   0
	
Delay:
	;; 499994 cycles
	movwf	d3
	movlw	0xFF
	movwf	d2
	movlw	50
	movwf	d1
Delay_0:
	decfsz	d1, f
	goto	$-1
	movlw	20 		; Need this for tuning
	movwf	d1
	decfsz	d2, f
	goto	$-6
	movlw	100
	movwf	d2
	decfsz	d3, f
	goto	Delay_0
	return
	end