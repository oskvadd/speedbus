;#include "/usr/share/gputils/header/p16f690.inc"
;	     errorlevel -302

;
;   #define     REC_CUSTOM_JUMP         custom_command_handler ; This is the name of the command to use, if it is a custom command. like, "jump to this statment if it is a custom command"
;   #define     CUSTOM_INTERRUPT        c_intserv              ; NOTE: When use this define, remember that the jumpback, to the ordinary interupthandler, need to be "ci_restore", if the interupt does not belong to the custom rutine, jump direct back to "ci_restore"
;
;
; Using two device id:s, maybe not predefined, so...
; The definition of thease bytes should not be done in the lib file, but in the main asm file, so difrent deviceid:s on difrent sources can be used.

#ifndef DEV_ID1
#define DEV_ID1 0
#endif
#ifndef DEV_ID2
#define DEV_ID2 0
#endif

#define SPEEDLIB_RESPONSE_DELAY 9


	radix dec

#define     USER_VARIABLE_SPACE         0x49    ; 0x66 but added two, just in case
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
	     rc_listen		; |X-------|b7 = NoNE
                                ; |-X------|b6 = NoNE
                                ; |--X-----|b5 = NoNE
                                ; |---X----|b4 = NoNE
                                ; |----X---|b3 = This bit got set if the device recive a usual response package (0x00)
                                ; |-----X--|b2 = This is an internal function for the recsave rutine, so the cewd know that following byte is escaped.
                                ; |------X-|b1 = If you set this bit to 1 the cewd will handle the byte as loopback, and if it dosent match the byte in rc_nocoll
                                ; |-------X|b0 = This bit got set if the device recive an answer to a "check_addr" package, to confirm that the adress is ocupied
	     rc_counter 	; RC framelen
	     rc_gotflag		; Set to 1 if it "got a flag"
	     rc_nocoll		; Use this to confim that no collission has ocurred
	     rc_add_byte	; recsave_add temporary argument
             rsp_adress1	; The response adress at the bus
	     rsp_adress2	; The response adress at the bus
	     adress1		; The adress at the bus
	     adress2		; The adress at the bus
	     speedlib_config    ; |X-------|b7 = NoNE
                                ; |-X------|b6 = NoNE
                                ; |--X-----|b5 = NoNE
                                ; |---X----|b4 = NoNE
                                ; |----X---|b3 = NoNe
                                ; |-----X--|b2 = NoNe
                                ; |------X-|b1 = Set this bit 1 if adress is stamped.
                                ; |-------X|b0 = On, Off this bit, if you want to make the device check the adress on startup.
	     speedlib_main      ; |X-------|b7 = NoNE
                                ; |-X------|b6 = NoNE
                                ; |--X-----|b5 = NoNE
                                ; |---X----|b4 = NoNE
                                ; |----X---|b3 = NoNe
                                ; |-----X--|b2 = If this bit got set, the cewd will send a response package when returning to restore
                                ; |------X-|b1 = This bit should be set, if the device has sent an package, that should be responde to
                                ; |-------X|b0 = This bit, is SET when an interupt has occured. If you set this to zero before youre rutine, and check the bit after, you will se if an interupt has ocurred, during the routine. And, fore example with AD decorders, you can rerun the routine, and calculate a new value.
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
        ;; EEPROM
        ;; 0x00 ; addr1
        ;; 0x01 ; addr2
        ;; 0x02 ; Speedbus configuration register

.code_page0_ CODE

init_speedlib:
    ;; Preset some values
    bcf     speedlib_main,2
    bcf     speedlib_main,1
    bcf     PORTB,4
    bcf     rc_listen,1


    ;; Take adress from eeprom, if it is set.
    movlw   0
    call    read_eeprom
    movwf   adress1
    movlw   1
    call    read_eeprom
    movwf   adress2
    movlw   2
    call    read_eeprom
    movwf   speedlib_config
    btfsc   speedlib_config,0
    call    init_checkaddr

    ; If adress is 0xFFFF, force init_checkaddr
    movlw	0xFF		
    subwf	adress1,W
    btfss	STATUS,Z
    goto        init_speedlib_e
    movlw	0xFF
    subwf	adress2,W
    btfss	STATUS,Z
    goto        init_speedlib_e
    clrf        adress1
    clrf        adress2
    call        init_checkaddr

init_speedlib_e:

    return

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
        movlw	0x01
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7


	call	txdo

	
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
	return

	
init_checkaddr_ocupied:
	call	setaddr
	return

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
        movlw	0x01
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7


	call	txdo

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

	call	txdo

	bsf	rc_listen,0
	movlw	1
	call	Delay
	btfss	rc_listen,0
	goto	setaddr1
	decfsz	loop1,	f
	goto	setaddr_testloop_l
	return			; The adress sems nice! Returning, and keep the composed adress!
	
	
	
intserv:


        bsf     speedlib_main,0 ;       Set this bit to one, when an interupt ocurres


        btfss	speedlib_main,1         ;; Waiting for response STATE? Jump direct to recend_no_broadcast
        goto    intserv_norm
        btfsc 	PIR1,RCIF	;	Check if the recived data bit is set
	goto	rec		;	Jump to recive data rutine if the PIR1 bit is 1
        goto    restore

intserv_norm:
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
        #ifdef  CUSTOM_INTERRUPT
        goto    CUSTOM_INTERRUPT
ci_restore:
        #endif


 	btfsc 	PIR1,RCIF	;	Check if the recived data bit is set
	goto	rec		;	Jump to recive data rutine if the PIR1 bit is 1


restore:
			;	Restore the regisers
        btfsc	speedlib_main,1         ;; Waiting for response STATE? Dont
        retfie                          ;; restore saved, nothing is saved

        ;; If:  Send back a response package, to confirm that the package has been recived
;        btfss   speedlib_main,2
;        goto    restore_norm
;        bcf     speedlib_main,2
;        call    func_send_response
        ;;

restore_norm:


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
	
rec_start:
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

recend_tmp:

        btfsc   speedlib_main,1 ; No CUSTOM command when in Whait for RESP STATE
        goto    recend_no_broadcast

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

	movlw	0x00		; Got response
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_check_response

        btfsc   speedlib_main,1 ; No CUSTOM command when in Whait for RESP STATE
        goto    restore

 	movf    rcframe+5,W
	sublw   0x01
	btfsc	STATUS,Z
        call    func_send_response
;        bsf     speedlib_main,2 ; Set this bit, so the cewd knows that WHEN
;        btfss	STATUS,Z        ; returning to restore, send a response package
;        bcf     speedlib_main,2


        ;; Make sure that the FSR pointer is pointed right
	movlw	rcframe+6	; Move recived byte to W
	movwf	FSR

	movlw	0x01		; Send respons for, 0x01 message, destionated for me
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_is_ocupied_send_response
	
	movlw	0x02
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_setport

	movlw	0x03
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_speedlib_config

#ifdef  REC_CUSTOM_JUMP
        goto    custom_command_handler
#endif
	goto	restore

func_speedlib_config:
	movlw	9
	subwf	rc_counter,W
	btfsc	STATUS,Z
	goto	func_speedlib_config_basics

        btfsc   STATUS,C
        goto    func_speedlib_config_extended
        goto    restore

func_speedlib_config_extended:
        movlw	rcframe+7	; Move recived byte to W
	movwf	FSR
       	movlw	0x00
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_speedlib_config_basics
	movlw	0x01
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_speedlib_config_caddr
        goto    restore


func_speedlib_config_caddr:
        movlw	12
	subwf	rc_counter,W
	btfss	STATUS,C    ;; If rc_counter NOT is more och equal to twelve, jump back
        goto    restore

        call    func_send_response


        movlw	rcframe+8	; Move recived byte to W
	movwf	FSR
        movf    INDF,W
        movwf   adress1
        incf    FSR,f
        movf    INDF,W
        movwf   adress2

        bsf     speedlib_config,1
        ;; Here you probobly want some cewd that writes tha adress to eeprom TODO
        movlw   0
        movwf   rc_nocoll
        movf    adress1,W
        call    write_eeprom
        movlw   1
        movwf   rc_nocoll
        movf    adress2,W
        call    write_eeprom
        movlw   2
        movwf   rc_nocoll
        movf    speedlib_config,W
        call    write_eeprom
        goto    restore

func_speedlib_config_basics:
        movlw   12
        call    Delay
	movlw   11
	movwf   framelen
	;; 0xff broadcast dst adress
       	movlw	rcframe+2         ;       dst addr
	movwf	FSR
        movf    INDF,W
	movwf   txframe
	;; 0xff broadcast dst adress
       	movlw	rcframe+3         ;       dst addr
	movwf	FSR
        movf    INDF,W
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
        movlw	0x03
	movwf   txframe+6
        ;; 0x00 Basic config response
	movlw   0x00
        movwf   txframe+7
        ;; Send back speedlib_config
	movlw   speedlib_config
        movwf   txframe+8
	;; Padding bit
	movlw   0x00
        movwf   txframe+9

        call    txdo
        goto    restore

func_send_response:
        movlw   SPEEDLIB_RESPONSE_DELAY
        call    Delay
	movlw   9
	movwf   framelen
	;; 0xff broadcast dst adress
       	movlw	rcframe+2         ;       dst addr
	movwf	FSR
        movf    INDF,W
	movwf   txframe
	;; 0xff broadcast dst adress
       	movlw	rcframe+3         ;       dst addr
	movwf	FSR
        movf    INDF,W
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

	call	txdo
        return

func_check_response:
; May be more advanced in the future, but for now, i dont se any reason why
; we should make this functione more advanced, how many response packages are
; realy exchange in a cuple of ms? -.- //  Speedster
        bsf     rc_listen,3
        goto	restore


func_is_ocupied_send_response:
	movlw	12		; Pretty strange, but you need this, so no colission or somthing will be made betwen PC and ansoring device
	call	Delay
	;; Send Package:
        btfsc   rc_listen,0
        goto    func_is_ocupied_send_response_got_resp
        goto    func_is_ocupied_send_response_pack
func_is_ocupied_send_response_got_resp:
        bcf     rc_listen,0
        goto    restore

func_is_ocupied_send_response_pack:
	movlw   9
	movwf   framelen
	;; 0xff broadcast dst adress
       	movlw	rcframe+2         ;       dst addr
	movwf	FSR
        movf    INDF,W
	movwf   txframe
	;; 0xff broadcast dst adress
       	movlw	rcframe+3         ;       dst addr
	movwf	FSR
        movf    INDF,W
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
        movlw	0x01
	movwf   txframe+6
	;; Padding bit
	movlw   0x00
        movwf   txframe+7
	
	;; This is a broadcast package with adress on it

	call	txdo	

	goto	restore

	
func_bc:
; 120623 A new era has become speedbus, all package that are need to, shall for
; now be sent with an respons, and, for that reason, i no more use command 0x00
; for is_occupied commands. When an 0x01 NOT is broadcast(it got a real adress)
; It is ment to bee like an old 0x00, if it is not an bc, send is_occupied.
; For now on, 0x00 is used to respond packages that need a response! Over'n out
; // Speedster

	movlw	rcframe         ;       dst addr
	movwf	FSR
	
	movlw	0xFF		;	check dst adress1
	subwf	INDF,W
	btfss	STATUS,Z
	goto    recend_no_broadcast
	
	incf	FSR,W		;	Increase the address	
	movwf	FSR

	movlw	0xFF		;	check dst adress2
	subwf	INDF,W
	btfss	STATUS,Z
	goto    recend_no_broadcast

	movlw	rcframe+6        
	movwf	FSR
	movlw	0x01		
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_bc_sendaddr
	goto    restore
	
func_bc_sendaddr:	
	call	trd	 ; Three random delay:s before ansor broadcast

        call    func_set_rsp_addr ;; Set rsp_adress to the src adress of the last recived package

	;; Send Package:
	
	movlw   11
	movwf   framelen
	;; dst adress
	movf    rsp_adress1,W
	movwf   txframe
	;; dst adress
	movf    rsp_adress2,W
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
        ;; Data - DeviceID
        movlw   DEV_ID1
	movwf   txframe+7
	;; Data - DeviceID
        movlw	DEV_ID2
	movwf   txframe+8
	;; Padding bit
	movlw   0x00
        movwf   txframe+9
	
	;; This is a broadcast package with adress on it
;
	movlw	0x01
	subwf	rcframe+5,W
	btfsc	STATUS,Z
        goto    handle_response
        call    txdo
;

func_bc_sended_packet:
	goto	restore

func_setport:
	movlw	2
	addwf	FSR,F
	movf	INDF,W
	movwf	PORTC
	goto    restore

func_set_rsp_addr:
        ;; Add last rec package src addr to rsp_adress1 rsp_adress2
       	movlw	rcframe+2         ;       dst addr
	movwf	FSR
        movf    INDF,W
        movwf   rsp_adress1
	movlw	rcframe+3         ;       dst addr
	movwf	FSR
        movf    INDF,W
        movwf   rsp_adress2
        return

handle_response:
        bcf     rc_listen,3
        bsf     speedlib_main,1
        bcf	rc_listen,1


    ; Important, this should be run in "main space", not interupt space, soo,
    ; well, now it is runed somewheare in the middle, wait for response STATE
        bsf     INTCON,GIE
        movlw   10
        movwf   loop1
handle_response_loop:
        call    txdo
	movlw	250
	call 	Delay

        ;; If error
	btfsc	RCSTA,OERR
	call    recerror
        ;;
        btfsc   rc_listen,3
        goto    handle_response_ret
        decfsz  loop1,f
        goto    handle_response_loop

handle_response_ret:
        bcf     rc_listen,3
        bcf     speedlib_main,1
        goto    restore

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

        movlw   0x02
        movwf   d1
        movlw   0xFF
        decfsz  W,f
        goto    $-1
        decfsz  d1,f
        goto    $-4

	movf	txtmp,W
	bsf	rc_listen, 1
	movwf	rc_nocoll
	movwf	TXREG

        movlw   0x02
        movwf   d1
        movlw   0xFF
        decfsz  W,f
        goto    $-1
        decfsz  d1,f
        goto    $-4

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

	return

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