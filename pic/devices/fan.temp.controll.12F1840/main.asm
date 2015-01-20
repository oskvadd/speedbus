    LIST P=12F1840

#define ARC_12F         1
#define DEV_ID1 64
#define DEV_ID2 45
#define REC_CUSTOM_JUMP     custom_command_handler
#define OUTREG PORTA
#define OUTNUM 2
#define WRITE_EEPROM        write_eeprom
#define READ_EEPROM         read_eeprom
#include "p12f1840.inc"
#include "/home/oscar/speedbus/pic/mplabx.proj/speedlib/SpeedBus.PIC.Lib.X/speedlib_main.asm"
; CONFIG1
; __CONFIG _CONFIG1, 0xFFA4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
; CONFIG2
; __CONFIG _CONFIG2, 0xFFFF
 __CONFIG _CONFIG2, _WRT_OFF & _PLLEN_OFF & _STVREN_OFF & _BORV_LO & _LVP_OFF

clock   equ     8       ; 8 MHz
baud    equ     19200  ; 19200, 57600, or 115200
brgdiv  equ     4       ; divider value for BRG16 = 1
brgval  equ     (clock*10000000/baud/brgdiv+5)/10-1
cblock  USER_VARIABLE_SPACE
        speed
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
        timer1
        temp_goal
        mspeed
        f_controll
endc
        org     0x0000
        goto    start
        org     0x0004
        goto    intserv

start:
	          movlw   low(brgval) ;                                 |B1
              banksel SPBRG
	          movwf   SPBRG	      ;                                 |B1
	          movlw   high(brgval) ;                                 |B1
              banksel SPBRGH
              movwf   SPBRGH
              banksel BAUDCON
              clrf    BAUDCON
              bsf     BAUDCON,BRG16	; select 16 bit BRG               |B1
	          movlw   b'00100100'	; '0-------' CSRC, n/a (async)    |B1
	;;  '-0------' TX9 off, 8 bits      |B1
	;;  '--1-----' TXEN, tx enabled     |B1
	;;  '---0----' SYNC, async mode     |B1
	;;  '----0---' SENDB, send brk      |B1
	;;  '-----1--' BRGH, high speed     |B1
	;;  '------00' TRMT, TX9D           |B1
              banksel TXSTA
	          movwf   TXSTA	;                                 |B1
              banksel RCSTA
	          movlw   b'10010000' ; '1-------' SPEN, port enabled   |B0
	;;  '-0------' RX9 off, 8 bits      |B0
	;;  '--0-----' SREN, n/a (async)    |B0
	;;  '---1----' CREN, rx enabled     |B0
	;;  '----0---' ADDEN off            |B0
	;;  '-----000' FERR, OERR, RX9D     |B0
	          movwf   RCSTA	;                                 |B0

        banksel OSCCON
        movlw   b'01110011'
        movwf   OSCCON

        banksel PIE1
        clrf    PIE1
        bsf     PIE1, RCIE
        banksel INTCON
		bsf	INTCON, GIE
		bsf	INTCON, PEIE
        banksel T1GCON
        bcf     T1GCON,TMR1GE
        banksel TMR1L
        clrf    TMR1L
        banksel TMR1H
        clrf    TMR1H
        banksel T1CON
        movlw   b'00110101'
        movwf   T1CON
        banksel timer1
        movlw   5
        movwf   timer1
        banksel APFCON
        bsf     APFCON,7
        bsf     APFCON,2
        banksel ADCON0
        bsf     ADCON0,ADON

        banksel ADCON1
        movlw   B'11100000' ;Right justify, Frc
        movwf   ADCON1
        banksel WPUA
        clrf    WPUA
        banksel ANSELA
        clrf    ANSELA
        bsf     ANSELA,1
        banksel PORTA
        clrf    PORTA
        banksel LATA
        clrf    LATA
        banksel TRISA
        movlw   b'00110010'
        movwf   TRISA
        banksel PORTA
        clrf    PORTA

        bsf     PORTA,0

        call    load_eeprom
        call    init_speedlib
;        movlw   200
;        movwf   speed
main:
        banksel PIR1
        btfsc   PIR1,TMR1IF
        call    custom_ihandler
        banksel RCSTA
        btfsc	RCSTA,OERR
        call    recerror
        banksel speed
        movlw   0
        subwf   speed,W
        btfsc   STATUS,Z
        goto    main2
        banksel PORTA
        bsf     PORTA,0
        banksel speed
        movf    speed,W
        call    Dla
        movlw   255
        subwf   speed,W
        btfsc   STATUS,Z
        goto    main
main2:
        banksel PORTA
        bcf     PORTA,0
        movlw   25
        call    Dla
        goto    main

load_eeprom:
        movlw   10
        call    read_eeprom
        banksel speed
        movwf   speed
        movlw   11
        call    read_eeprom
        banksel temp_goal
        movwf   temp_goal
        movlw   12
        call    read_eeprom
        banksel mspeed
        movwf   mspeed
        movlw   13
        call    read_eeprom
        banksel f_controll
        movwf   f_controll
        return

custom_ihandler:
        banksel PIR1
        bcf     PIR1,TMR1IF
        banksel timer1
        decfsz  timer1, f
        return
;        banksel PORTA
;        bsf     PORTA,2
;        movlw   200
;        call    Delay
;        banksel PORTA
;        bcf     PORTA,2
        movlw   120
        banksel timer1
        movwf   timer1
        call    fan_termos
        return

fan_termos:
        call    set_temp
        banksel temp1
        movf    temp1,W
        subwf   temp_goal,W
        btfss   STATUS,C
        goto    fan_termos_more
        goto    fan_termos_less ; Goal is less or the same as the outside temp


fan_termos_less:
        banksel temp2
        movf    temp2,W
        subwf   temp_goal,W
        btfss   STATUS,C
        goto    fan_on_l
        goto    fan_off
        return

fan_termos_more:
        banksel temp2
        movf    temp2,W
        subwf   temp_goal,W
        btfsc   STATUS,C
        goto    fan_on_m
        goto    fan_off
        return

fan_on_l:
        banksel f_controll
        btfsc   f_controll,0
        return
        movlw   128
        subwf   temp_goal,W
        btfsc   STATUS,Z
        return
        movlw   0
        subwf   mspeed,W
        btfsc   STATUS,Z
        goto    fan_on_max
        movf    mspeed,W
        movwf   speed
        return

fan_on_m:
        banksel f_controll
        btfsc   f_controll,0
        return
        movlw   128
        subwf   temp_goal,W
        btfsc   STATUS,Z
        return
        movlw   0
        subwf   mspeed,W
        btfsc   STATUS,Z
        goto    fan_on_max
        movf    mspeed,W
        movwf   speed
        return

fan_on_max:
        banksel f_controll
        btfsc   f_controll,0
        return
        movlw   128
        subwf   temp_goal,W
        btfsc   STATUS,Z
        return
        banksel speed
        movlw   255
        movwf   speed
        return

fan_off:
        btfsc   f_controll,0
        return
        movlw   0
        banksel speed
        movwf   speed
        return

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

get_vars:

        ;Store in GPR space
        movlw   13
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
        movlw	0x0E
        movwf   txframe+6
        ;; Data
        movf    speed,W
        movwf   txframe+7
        ;; Data
        movf    temp_goal,W
        movwf   txframe+8
        ;; Data
        movf    mspeed,W
        movwf   txframe+9
        ;; Data
        movf    f_controll,W
        movwf   txframe+10
        ;; Padding bit
        movlw   0x00
        movwf   txframe+11

    	;; This is a broadcast package with adress on it

        call	txdo


        goto    restore

set_temp:



        banksel TRISA
        bsf     TRISA, 2
;        movlw   40
;        call    Delay ; Need some delay to make the ANSELA load up,
                      ; after switching TRISA to input
        banksel ANSELA
        bsf     ANSELA,2
        banksel ADCON0
        ;
        movlw   b'00001001' ;Select channel AN0
        movwf   ADCON0
        movlw   1
        call    Delay 

        ;Turn ADC On
;        call    SampleTime
        ;Acquisiton delay
        banksel ADCON0
        bsf     ADCON0,ADGO ;Start conversion
        btfsc   ADCON0,ADGO ;Is conversion done?
        goto    $-1
        banksel ANSELA
        bcf     ANSELA,2
        banksel TRISA
        bcf     TRISA, 2
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
        movlw   4
        subwf   temp1,F ; Compensate -4 degrees
        call    temp_rem_calc
        movwf   temp1r

        banksel ADCON0
        clrf    ADCON0


        banksel ADCON0
        ;
        movlw   b'00000101' ;Select channel AN0
        movwf   ADCON0

        movlw   1
        call    Delay 

        banksel ADCON0
        bsf     ADCON0,ADGO ;Start conversion
        btfsc   ADCON0,ADGO ;Is conversion done?
        goto    $-1
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


custom_command_handler:
       	movlw	0x0A
        subwf	INDF,W
        btfsc	STATUS,Z
        goto	set_fan

    	movlw	0x0B
        subwf	INDF,W
    	btfsc	STATUS,Z
        goto	get_temp

       	movlw	0x0C
        subwf	INDF,W
        btfsc	STATUS,Z
        goto	set_temp_c

    	movlw	0x0D
        subwf	INDF,W
    	btfsc	STATUS,Z
        goto	set_mspeed

    	movlw	0x0E
        subwf	INDF,W
    	btfsc	STATUS,Z
        goto	get_vars

        goto    restore

set_fan:
    banksel rcframe
	movlw	rcframe+7
    banksel FSR
    movwf   FSR
    banksel INDF
    movf    INDF,W
    banksel speed
    movwf   speed
    movlw   10
    movwf   rc_nocoll
    movf    speed,W
    call    write_eeprom
    banksel f_controll
    bsf     f_controll,0
    movlw   0
    subwf   speed,W
    btfsc   STATUS,Z
    bcf     f_controll,0
    btfsc   STATUS,Z
    call    fan_termos
    banksel rc_nocoll
    movlw   13
    movwf   rc_nocoll
    movf    f_controll,W
    call    write_eeprom
    goto    restore

set_temp_c:
    banksel rcframe
	movlw	rcframe+7
    banksel FSR
    movwf   FSR
    banksel INDF
    movf    INDF,W
    banksel temp_goal
    movwf   temp_goal
    movlw   128
    addwf   temp_goal,F
    movlw   11
    movwf   rc_nocoll
    movf    temp_goal,W
    call    write_eeprom

    btfsc   f_controll,0
    goto    restore

    banksel temp_goal
    movlw   128
    subwf   temp_goal,W
    btfsc   STATUS,Z
    clrf    speed
    btfsc   STATUS,Z
    goto    restore
    call    fan_termos
    goto    restore

set_mspeed:
    banksel rcframe
	movlw	rcframe+7
    banksel FSR
    movwf   FSR
    banksel INDF
    movf    INDF,W
    banksel mspeed
    movwf   mspeed
    movlw   12
    movwf   rc_nocoll
    movf    mspeed,W
    call    write_eeprom
    banksel f_controll
    btfsc   f_controll,0
    goto    restore
    movlw   0
    subwf   speed,W
    btfsc   STATUS,Z
    goto    restore
    movlw   0
    subwf   mspeed,W
    btfsc   STATUS,Z
    goto    set_mspeed_max
    goto    set_mspeed_set
set_mspeed_max:
    movlw   255
    movwf   speed
    goto    restore
set_mspeed_set:
    movf    mspeed,W
    movwf   speed
    goto    restore

Dla:
    banksel d1
			;999997 cycles
	movwf	d1
	movwf	d2
Dla_0:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Dla_0

			;3 cycles
	goto	$+1
	nop
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

read_eeprom:
        banksel EEADRH
        clrf    EEADRH
        movwf   EEADRL
        ;Data Memory
        ;Address to read
        bcf     EECON1, CFGS ;Deselect Config space
        bcf     EECON1, EEPGD;Point to DATA memory
        bsf     EECON1, RD
        ;EE Read
        movf    EEDATL, W
        return

write_eeprom:
        banksel EEDATL
        movwf   EEDATL ;Data Memory Value to write
        clrf    EEDATH
        banksel rc_nocoll
        movf    rc_nocoll,W
        banksel EEADRL
        clrf    EEADRH
        movwf   EEADRL ;Data Memory Address to write
        bcf     EECON1, CFGS ;Deselect Configuration space
        bcf     EECON1, EEPGD ;Point to DATA memory
        bsf     EECON1, WREN ;Enable writes
        movlw   55h ;
        movwf   EECON2 ;Write 55h
        movlw   0AAh ;
        movwf   EECON2 ;Write AAh
        bsf     EECON1,WR ;Set WR bit to begin write
        btfsc   EECON1,WR ;Wait for write to complete
        goto $-1
        bcf     EECON1,WREN ;Disable writes
        return
        end