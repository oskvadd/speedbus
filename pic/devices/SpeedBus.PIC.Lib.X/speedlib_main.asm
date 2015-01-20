;#include "/usr/share/gputils/header/p16f690.inc"
;	     errorlevel -302

;
;   #define     REC_CUSTOM_JUMP         custom_command_handler ; This is the name of the command to use, if it is a custom command. like, "jump to this statment if it is a custom command"
;   #define     CUSTOM_INTERRUPT        c_intserv              ; NOTE: When use this define, remember that the jumpback, to the ordinary interupthandler, need to be "ci_restore", if the interupt does not belong to the custom rutine, jump direct back to "ci_restore"
;
;
; Using two device id:s, maybe not predefined, so...
; The definition of thease bytes should not be done in the lib file, but in the main asm file, so difrent deviceid:s on difrent sources can be used.

; REMEMBER: Well, byte 0-9 is reserved for speedbus in eeprom

; The I/O where the txen for the 485buss should be output
#ifndef OUTREG
#define OUTREG PORTB
#endif
#ifndef OUTNUM
#define OUTNUM 4
#endif


#ifndef DEV_ID1
#define DEV_ID1 0
#endif
#ifndef DEV_ID2
#define DEV_ID2 0
#endif

#ifndef FSR
#define FSR FSR1L
#endif

#ifndef INDF
#define INDF INDF1
#endif

#ifndef EEDAT
#define EEDAT EEDATA
#endif

#define SPEEDLIB_RESPONSE_DELAY 9

radix dec
; IMPORTANT, do NOT change any of the varables down here, to a new bank, because
; the banksel instructions are configured, as all the varables bellow are in the
; same bank. As they should be.
#define     USER_VARIABLE_SPACE         0x67    ; 0x65 but added two, just in case
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
	     loop1          ; Loop mem 1
	     loop2          ; Loop mem 2
	     rc_listen              ; |X-------|b7 = NoNE
                                ; |-X------|b6 = NoNE
                                ; |--X-----|b5 = This bit is used as the old "rc_gotflag", sets to 1, if it "got a flag".
                                ; |---X----|b4 = This bit specifies, that when reciving an 0x01, destionated for ME, do not send a "is ocupied package". This is good if you want to "search for units"
                                ; |----X---|b3 = This bit got set if the device recive a usual response package (0x00)
                                ; |-----X--|b2 = This is an internal function for the recsave rutine, so the cewd know that following byte is escaped.
                                ; |------X-|b1 = If you set this bit to 1 the cewd will handle the byte as loopback, and if it dosent match the byte in rc_nocoll
                                ; |-------X|b0 = If you set this bit to one, when the device recives a "is ocupied" pack, itn will uncheck this bit.
                                ;                If this bit is zero, the device will send a "i am ocupied" pack.
	     rc_counter 	; RC framelen
	     rc_nocoll		; Use this to confim that no collission has ocurred
	     rc_add_byte	; recsave_add temporary argument
         rsp_adress1	; The response adress at the bus
	     rsp_adress2	; The response adress at the bus
	     adress1		; The adress at the bus
	     adress2		; The adress at the bus
	     speedlib_config        ; |X-------|b7 = NoNE
                                ; |-X------|b6 = NoNE
                                ; |--X-----|b5 = NoNE
                                ; |---X----|b4 = NoNE
                                ; |----X---|b3 = NoNe
                                ; |-----X--|b2 = NoNe
                                ; |------X-|b1 = Set this bit 1 if adress is stamped.
                                ; |-------X|b0 = On, Off this bit, if you want to make the device check the adress on startup.
	     speedlib_main          ; |X-------|b7 = NoNE
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
#ifndef FSR
    clrf    FSR1H
#endif


    ;; Preset some values
    banksel speedlib_main
    bcf     speedlib_main,2
    bcf     speedlib_main,1
    banksel OUTREG
    bcf     OUTREG,OUTNUM
    banksel rc_listen
    bcf     rc_listen,1
    bcf     rc_listen,4
    bcf     rc_listen,5         ;; Clear got flag
    bcf     txreturn, 1

#ifdef  READ_EEPROM
    ;; Take adress from eeprom, if it is set.
    movlw   0
    call    READ_EEPROM
    banksel adress1
    movwf   adress1
    movlw   1
    call    READ_EEPROM
    banksel adress2
    movwf   adress2
    movlw   2
    call    READ_EEPROM
    banksel speedlib_config
    movwf   speedlib_config
#endif

    ;; If adress is 255.255, change to 0.0
    movlw       0xFF
    banksel     adress1
    subwf       adress1,W
    btfss       STATUS,Z
    return
    movlw       0xFF
    banksel     adress2
    subwf       adress2,W
    btfss       STATUS,Z
    return

    banksel     adress1
    clrf        adress1
    clrf        adress2

#ifdef  WRITE_EEPROM
    movlw   0
    movwf   rc_nocoll
    movf    adress1,W
    call    WRITE_EEPROM
    banksel rc_nocoll
    movlw   1
    movwf   rc_nocoll
    movf    adress2,W
    call    WRITE_EEPROM
#endif

    ;; Because the dreprecated version of the fucked up "checkaddr" function,
    ;; i removed the code. In wait for the new system.
    ;;
    ;; Handle response, needs testing.

    return


intserv:

    banksel speedlib_main
    bsf     speedlib_main,0     ;; Set this bit to one, when an interupt ocurres


    btfss	speedlib_main,1     ;; Waiting for response STATE? Jump direct to recend_no_broadcast
    goto    intserv_norm
    banksel PIR1
    btfsc 	PIR1,RCIF           ;; Check if the recived data bit is set
	goto	rec                 ;; Jump to recive data rutine if the PIR1 bit is 1
    goto    restore

intserv_norm:
    banksel tmp_W
	movwf	tmp_W               ;; Register BKP before the interup code exec
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

    banksel PIR1
 	btfsc 	PIR1,RCIF           ;; Check if the recived data bit is set
	goto	rec                 ;; Jump to recive data rutine if the PIR1 bit is 1


restore:
	banksel speedlib_main       ;; Restore the regisers
    btfsc	speedlib_main,1     ;; Waiting for response STATE? Dont
    retfie                      ;; restore saved, nothing is saved

                                ;;; If:  Send back a response package, to confirm that the package has been recived
;;  btfss   speedlib_main,2
;;  goto    restore_norm
;;  bcf     speedlib_main,2
;;  call    func_send_response
                                ;;;

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
    banksel rc_listen
	btfss	rc_listen,1         ;; If rc_listen is set to NOT drop the loopback package, jump directly to the rec_start
	goto	rec_start		

	bcf     rc_listen,1         ;; Start this rutine with checking that the recived bit NOT was send from this own device
	movf	rc_nocoll,W
    banksel RCREG
	subwf	RCREG,W
	btfss	STATUS,Z
	goto	rec_oops_coll		;; Anyway, if the rc_listen,1  is 1, and it do not match RCREG, we may be detected an collission
	goto 	restore

rec_oops_coll:
    banksel txreturn
	bsf     txreturn,1
	goto	restore
	
rec_start:
    banksel RCREG
	movlw	0x7e
	subwf	RCREG,W
	btfsc	STATUS,Z
	goto	recx                ;; Jump if this is a flag bit
    banksel rc_listen
	btfsc	rc_listen,5
	goto	recsave             ;; Jump if the flag bit is set
	goto	restore

recx:
    banksel rc_listen
	btfsc	rc_listen,5
	goto	recend              ;; If this may be end flag, check the package, finalize, check crc
	bsf     rc_listen,5         ;; Else set the gotflag, and start recording package!
	clrf	rc_counter          ;; Clear the counter :)
	goto	restore

recsave:
    banksel RCREG
 	movlw	0x7d
 	subwf   RCREG,W
 	btfsc   STATUS,Z
 	goto	recsave_set         ;; Set bit in the rc_listen to aktivate escape routines when the next byte is recived
 	banksel rc_listen
    btfsc   rc_listen,2
	goto	recsave_unescape

    banksel RCREG
	movf	RCREG,W
	goto	recsave_add

recsave_set:
    banksel rc_listen
	bsf     rc_listen,2
	goto	restore

recsave_unescape:
    banksel rc_listen
	bcf     rc_listen,2
	movlw   0x5e
    banksel RCREG
	subwf   RCREG,W
	btfsc   STATUS,Z
	goto	recsave_unescape_1
	movlw   0x5d
	subwf   RCREG,W
	btfsc   STATUS,Z
	goto	recsave_unescape_2
	goto	restore             ;; Maybe you can change this, but a fail package that is the result, will also be CRC checked
	
recsave_unescape_1:
	movlw	0x7e
	goto	recsave_add
recsave_unescape_2:
    movlw   0x7d
	goto    recsave_add
	
recsave_add:
    banksel rc_add_byte
	movwf	rc_add_byte
	movlw	rcframe             ;; Place where to put the receiving byte
	addwf	rc_counter,W        ;; Add the number in rc_flow, to the pointer, like rcframe[rc_flow]
	banksel FSR
    movwf	FSR
    banksel rc_add_byte
	movf	rc_add_byte,W
    banksel INDF
	movwf	INDF
    banksel rc_counter
	incf	rc_counter,F
	goto	restore
	
recend:
    movlw   5
    subwf   rc_counter,W
    btfss   STATUS,C
    goto    reccrcfail
    banksel rc_counter
	decf	rc_counter,W
	movwf	rc_counter
	movwf	crcloop
	movlw	rcframe
    banksel FSR
	movwf	FSR
    banksel crc0
	clrf	crc0
	clrf	crc1
	call	crcloopr	; Call CRC function

    banksel rcframe
	movlw	rcframe
	addwf	rc_counter,W
    banksel FSR
	movwf	FSR

    banksel INDF
	movf	INDF,W

    banksel crc1
	subwf	crc1,W
	btfss	STATUS,Z
	goto	reccrcfail
    banksel FSR
	decf	FSR,W
	movwf	FSR

    banksel INDF
	movf	INDF,W

    banksel crc0
	subwf	crc0,W
	btfss	STATUS,Z
	goto	reccrcfail

	banksel rc_listen           ;; REMEMBER, if checksum is right, clear "got flag", else, untuched
    bcf     rc_listen,5

	movlw	rcframe+6           ;; Move recived byte to W
	banksel FSR
    movwf	FSR

recend_tmp:
    banksel speedlib_main
    btfsc   speedlib_main,1     ;; No CUSTOM command when in Whait for RESP STATE
    goto    recend_no_broadcast
	goto	func_bc

recend_no_broadcast:
    banksel rcframe
	movlw	rcframe
    banksel FSR
	movwf	FSR
    banksel INDF
	movf	INDF,W              ;; Check so that the adress is destinated for me
	banksel adress1
    subwf	adress1,W
	btfss	STATUS,Z
	goto	restore
    banksel FSR
	incf	FSR,W
	movwf	FSR
    banksel INDF
	movf	INDF,W
    banksel adress2
	subwf	adress2,W
	btfss	STATUS,Z
	goto	restore

	movlw	rcframe+6           ;; Move recived byte to W
    banksel FSR
    movwf	FSR

	movlw	0x00                ;; Got response
	banksel INDF
    subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_check_response

    banksel speedlib_main
    btfsc   speedlib_main,1     ;; No CUSTOM command when in Whait for RESP STATE
    goto    restore

 	movf    rcframe+5,W
	sublw   0x01
	btfsc	STATUS,Z
    call    func_send_response


        
	movlw	rcframe+6           ;; Make sure that the FSR pointer is pointed right
	banksel FSR
    movwf	FSR

	movlw	0x01                ;; Send respons for, 0x01 message, destionated for me
	banksel INDF
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
    goto    REC_CUSTOM_JUMP
#endif
	goto	restore

func_speedlib_config:
	movlw	9
    banksel rc_counter
	subwf	rc_counter,W
	btfsc	STATUS,Z
	goto	func_speedlib_config_basics

    btfsc   STATUS,C
    goto    func_speedlib_config_extended
    goto    restore

func_speedlib_config_extended:
    movlw	rcframe+7           ;; Make sure that the FSR pointer is pointed right
	banksel FSR
    movwf	FSR
    movlw	0x00
    banksel INDF
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
    banksel rc_counter
	subwf	rc_counter,W
	btfss	STATUS,C            ;; If rc_counter NOT is more och equal to twelve, jump back
    goto    restore

    call    func_send_response
        
    movlw	rcframe+8           ;; Move recived byte to W
    banksel FSR
	movwf	FSR
    movlw   0xFF
    banksel INDF
    subwf   INDF,W
    btfss   STATUS,Z
    goto    func_speedlib_config_caddr_f
    banksel FSR
    incf    FSR,F
    movlw   0xFF
    banksel INDF
    subwf   INDF,W
    btfss   STATUS,Z
    goto    func_speedlib_config_caddr_f
    goto    restore

func_speedlib_config_caddr_f:
    movlw	rcframe+8	; Move recived byte to W
    banksel FSR
	movwf	FSR
    banksel INDF
    movf    INDF,W
    banksel adress1
    movwf   adress1
    banksel FSR
    incf    FSR,f
    banksel INDF
    movf    INDF,W
    banksel adress2
    movwf   adress2

    bsf     speedlib_config,1
#ifdef  WRITE_EEPROM
    ;; Write adress to eeprom
    movlw   0
    movwf   rc_nocoll
    movf    adress1,W
    call    WRITE_EEPROM
    banksel rc_nocoll
    movlw   1
    movwf   rc_nocoll
    movf    adress2,W
    call    WRITE_EEPROM
    banksel rc_nocoll
    movlw   2
    movwf   rc_nocoll
    movf    speedlib_config,W
    call    WRITE_EEPROM
#endif
    goto    restore

func_speedlib_config_basics:
    movlw   12
    call    Delay
	movlw   11
    banksel framelen
	movwf   framelen

    movlw	rcframe+2
	banksel FSR
    movwf	FSR
    banksel INDF
    movf    INDF,W
    banksel txframe
	movwf   txframe

    movlw	rcframe+3
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
    banksel framelen
	movlw   9
	movwf   framelen

    movlw	rcframe+2
    banksel FSR
    movwf	FSR
    banksel INDF
    movf    INDF,W
    banksel txframe
	movwf   txframe

    movlw	rcframe+3
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
    movlw   0x00                ;; No response on response
	movwf   txframe+5   

	;; Data             
    movlw	0x00
	movwf   txframe+6

	;; Padding bit
	movlw   0x00
    movwf   txframe+7

	call	txdo
    return

func_check_response:
; May be more advanced in the future, but for now, i dont se any reason why
; we should make this functione more advanced, how many response packages are
; realy exchange in a cuple of ms? -.- //  Speedster
    banksel rc_listen
    bsf     rc_listen,3
    goto	restore


func_is_ocupied_send_response:
	movlw	12                  ;; Pretty strange, but you need this, so no colission or somthing will be made betwen PC and ansoring device
	call	Delay

    banksel rc_listen
	;; Send Package:
    btfsc   rc_listen,0
    goto    func_is_ocupied_send_response_got_resp
    goto    func_is_ocupied_send_response_pack
func_is_ocupied_send_response_got_resp:
    bcf     rc_listen,0
    goto    restore

func_is_ocupied_send_response_pack:
    btfsc   rc_listen,4
    goto    restore
	movlw   9
    banksel framelen
	movwf   framelen

  	movlw	rcframe+2
	banksel FSR
    movwf	FSR
    banksel INDF
    movf    INDF,W
    banksel txframe
	movwf   txframe

   	movlw	rcframe+3
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
    movlw	0x01
	movwf   txframe+6

	;; Padding bit
	movlw   0x00
    movwf   txframe+7

	call	txdo	

	goto	restore

	
func_bc:
; 120623 A new era has become speedbus, all package that are need to, shall for
; now be sent with an respons, and, for that reason, i no more use command 0x00
; for is_occupied commands. When an 0x01 NOT is broadcast(it got a real adress)
; It is ment to bee like an old 0x00, if it is not an bc, send is_occupied.
; For now on, 0x00 is used to respond packages that need a response! Over'n out
; // Speedster

    banksel rcframe
	movlw	rcframe
	banksel FSR
    movwf	FSR
	
	movlw	0xFF                ;;	check dst adress1
	banksel INDF
    subwf	INDF,W
	btfss	STATUS,Z
	goto    recend_no_broadcast

    banksel FSR
	incf	FSR,W               ;;	Increase the address
	movwf	FSR

	movlw	0xFF                ;;	check dst adress2
	banksel INDF
    subwf	INDF,W
	btfss	STATUS,Z
	goto    recend_no_broadcast
        
	movlw	rcframe+6        
	banksel FSR
    movwf	FSR
	movlw	0x01
    banksel INDF
	subwf	INDF,W
	btfsc	STATUS,Z
	goto	func_bc_01

#ifdef  on_got_IAH
    movlw	0x03
    banksel INDF
	subwf	INDF,W
	btfss	STATUS,Z
	goto	restore
    banksel INDF
    incf    FSR, F
    movlw	0x01
    banksel INDF
	subwf	INDF,W
	btfss	STATUS,Z
	goto	restore
    goto    on_got_IAH
#endif
	goto    restore

func_bc_01:
    movlw	rcframe+5
	banksel FSR
    movwf	FSR
	movlw	0x01
    banksel INDF
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    func_bc_sendaddr
    movlw	0x00
    subwf	INDF,W
	btfsc	STATUS,Z
    call    func_send_response
    goto    restore


func_bc_sendaddr:	
	call	trd                 ;; Three random delay:s before ansor broadcast

    call    func_set_rsp_addr   ;; Set rsp_adress to the src adress of the last recived package

	;; Send Package:
	banksel framelen
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
	movlw	0x01
	subwf	rcframe+5,W
	btfsc	STATUS,Z
    goto    handle_response
    call    txdo

	goto	restore

func_send_iam_here:             ;; IMPORTANT, this function "return", use "call func_send_iam_here"
	movlw   12
    banksel framelen
	movwf   framelen

    movlw   0xFF
	movwf   txframe

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
    movlw   0x00
	movwf   txframe+5

    ;; Data
    movlw	0x03
	movwf   txframe+6

    ;; 0x00 Basic config response
	movlw   0x01
    movwf   txframe+7

    ;; Data - DeviceID
    movlw   DEV_ID1
	movwf   txframe+8

    ;; Data - DeviceID
    movlw	DEV_ID2
	movwf   txframe+9
	;; Padding bit
	movlw   0x00
    movwf   txframe+10

    call    txdo
    return  

func_rand_addr:
    banksel rand
    movf    rand,W
    movwf   adress1
    call    lfsr_func
    banksel rand
    movf    rand,W
    movwf   adress2
    return

func_setport:
	movlw	2
    banksel FSR
	addwf	FSR,F
    banksel INDF
	movf	INDF,W
#ifdef PORTC
    banksel PORTC
	movwf	PORTC
#endif
	goto    restore

func_set_rsp_addr:
    ;; Add last rec package src addr to rsp_adress1 rsp_adress2
    movlw	rcframe+2
    banksel FSR
	movwf	FSR
    banksel INDF
    movf    INDF,W
    banksel rsp_adress1
    movwf   rsp_adress1

	movlw	rcframe+3
    banksel FSR
	movwf	FSR
    banksel INDF
    movf    INDF,W
    banksel rsp_adress2
    movwf   rsp_adress2
    return

handle_response:
    banksel rc_listen
    bcf     rc_listen,3
    bsf     speedlib_main,1
    bcf	rc_listen,1

    ;; Important, this should be run in "main space", not interupt space, soo,
    ;; well, now it is runed somewheare in the middle, wait for response STATE
    banksel INTCON
    bsf     INTCON,GIE
    movlw   10
    banksel rsp_adress1
    movwf   rsp_adress1

handle_response_loop:
    call    txdo
	movlw	250
	call 	Delay

    ;; If error
    banksel RCSTA
	btfsc	RCSTA,OERR
	call    recerror
    ;;

    banksel rc_listen
    btfsc   rc_listen,3
    goto    handle_response_ret
    decfsz  rsp_adress1,f
    goto    handle_response_loop

handle_response_ret:
    bcf     rc_listen,3
    bcf     speedlib_main,1
    goto    restore

reccrcfail:
	;; Because that this happend directrly after a crc-fail, here we need to clear the counter, so the next comming package will start allover
    banksel rc_counter
    movlw   5
    subwf   rc_counter,W
    btfss   STATUS,C
    goto    reccrcfail_end

    movlw    250
    call    Delay

reccrcfail_end:
    banksel rc_counter
    clrf	rc_counter
	goto	restore
	
recerror:
	;; Do somthing
    banksel RCSTA
	bcf	RCSTA,CREN
	bsf	RCSTA,CREN
	return

txoops:
    ;; Colisson has ocurred
    banksel rc_listen
    bcf	    rc_listen,1
	bcf     txreturn,1
	call	lfsr_func
    banksel rand
	movf	rand,W
	call	Delay
	goto	txdo2

tx_send:
    banksel txtmp
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
    banksel txtmp
    movwf	txtmp

    banksel rc_listen
    bsf     rc_listen,1

    banksel txtmp
    movf	txtmp,W
    movwf	rc_nocoll
    banksel TXREG
    movwf	TXREG

    banksel TXSTA
tx_send_noescape_l:
    btfss   TXSTA,TRMT
    goto	tx_send_noescape_l

    banksel d1
    movlw   0x90
    movwf   d1
tx_send_noescape_k:
    decfsz  d1,f
    goto    tx_send_noescape_k
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
	
txdo:				
    ;; This is like the function argumnents, they need to be set at every presense of crcloopr
    banksel framelen
	movf	framelen,W
    bsf	    rc_listen,1
	movwf	crcloop
	movlw	txframe
    banksel FSR
	movwf	FSR
    banksel crc0
	clrf	crc0
	clrf	crc1
	call	crcloopr
	goto	txdo2
crcloopr:
    banksel crcloop
	decfsz	crcloop, f
	goto	crccalc
	return

crccalc:
    banksel INDF
	movf    INDF,W              ;; Load W with next databyte
    banksel crc1
	xorwf   crc1,W              ;;(a^x):(b^y)
	movwf   crctmp              ;;
	andlw   0xf0                ;; W = (a^x):0
	swapf   crctmp,F            ;; Index = (b^y):(a^x)
	xorwf   crctmp,F            ;; Index = (a^b^x^y):(a^x) = i2:i1

                                ;; High byte
	movf    crctmp,W
	andlw   0xf0
	xorwf   crc0,W
	movwf   crc1
#ifdef  ARC_18F
    rlcf    crctmp,W            ;; use rlf for PIC18
	rlcf    crctmp,W            ;; use rlf for PIC18
#endif
#ifdef  ARC_16F
	rlf     crctmp,W            ;; use rlf for PIC16
	rlf     crctmp,W            ;; use rlf for PIC16
#endif
#ifdef  ARC_12F
	rlf     crctmp,W            ;; use rlf for PIC12
	rlf     crctmp,W            ;; use rlf for PIC12
#endif
	xorwf   crc1,F
	andlw   0xe0
	xorwf   crc1,F

	swapf   crctmp,F
	xorwf   crctmp,W
	movwf   crc0
    banksel FSR
    incf    FSR,W
	movwf   FSR
	goto    crcloopr

txdo2:
    ;; Set TX enable
    banksel OUTREG
	bsf     OUTREG,OUTNUM
	;;
    banksel rc_listen
    bsf	    rc_listen,1
	movlw	0x7e
	call	tx_send_noescape
	banksel txframe
    movlw	txframe
    banksel FSR
	movwf	FSR
    banksel framelen
	movf	framelen,W
	movwf	crcloop
send:
    banksel crcloop
	decfsz	crcloop,f
	goto 	lopp
	goto    crcsend
lopp:
    banksel INDF
	movf	INDF,W
	call	tx_send
    banksel FSR
	incf	FSR,F
	goto 	send

crcsend:
    banksel crc0
	movf	crc0,W
	call	tx_send
    banksel crc1
	movf	crc1,W
	call	tx_send
	goto	endflag

endflag:
	movlw	0x7e
	call	tx_send_noescape
    banksel TXSTA
endflag_l:
	btfss   TXSTA,TRMT
	goto	endflag_l
    banksel txreturn
    btfsc	txreturn,1          ;; Cant allow this rutine, the device sends back flags and crc, but the rest is zeroes (?)
    goto	txoops
    bcf	    rc_listen,1

    ;; Disable TX enable
    banksel OUTREG
	bcf     OUTREG,OUTNUM

	return

trd:
    ;; Three random delays before sending broadcast
	call	lfsr_func		
    banksel rand
	movf	rand,W
	call	Delay
	call	lfsr_func
    banksel rand
	movf	rand,W
	call	Delay
	call	lfsr_func
    banksel rand
	movf	rand,W
	call	Delay
	return
	
lfsr_func:
    banksel rand
#ifdef  ARC_18F
    rlcf     rand,W
	rlcf     rand,W
#endif
#ifdef  ARC_16F
	rlf     rand,W
	rlf     rand,W
#endif
#ifdef  ARC_12F
	rlf     rand,W
	rlf     rand,W
#endif
	btfsc   rand,4
	xorlw   1
	btfsc   rand,5
	xorlw   1
	btfsc   rand,3
	xorlw   1
	movwf   rand
	retlw   0
	
Delay:
    banksel d1
	;; 499994 cycles
	movwf	d3
	movlw	0xFF
	movwf	d2
	movlw	50
	movwf	d1
Delay_0:
	decfsz	d1, f
	goto	Delay_0
	movlw	20                  ;; Need this for tuning
	movwf	d1
	decfsz	d2, f
	goto	Delay_0
	movlw	100
	movwf	d2
	decfsz	d3, f
	goto	Delay_0
	return