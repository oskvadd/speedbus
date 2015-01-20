List      P=16f690		; list directive to define processor
radix     dec           ; Default use ordinary decimal in syntax

#include "p16f690.inc"

; CONFIG
 __CONFIG _INTOSCIO & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF
;;
;;;    _FCMEN_OFF           ; -- fail safe clock monitor enable off
;;;    _IESO_OFF            ; -- int/ext switch over enable off
;;;    _BOR_ON              ; default, brown out reset on
;;;    _CPD_OFF             ; default, data eeprom protection off
;;;    _CP_OFF              ; default, program code protection off
;;;    _MCLR_OFF            ; -- use MCLR pin as digital input
;;;    _PWRTE_OFF           ; default, power up timer off
;;;    _WDT_OFF             ; -- watch dog timer off
;;;    _INTOSCIO            ; -- internal osc, RA6 and RA7 I/O
;;

;; 6 - RA4 E
;; 4 - RA5 RS

; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
#define ARC_16F             1
;#define REC_CUSTOM_JUMP     custom_command_handler
;#define CUSTOM_INTERRUPT   c_intserv
#define REC_SPB_PARAMETERS  spb_parameters
#define DEV_ID3             64
#define DEV_ID4             51
#define WRITE_EEPROM        write_eeprom
#define READ_EEPROM         read_eeprom
#include "../SpeedBus.PIC.LibV2.X/speedlibV2_main.asm"


;; SpeedBus Serial Speed
clock   equ     8       ; 8 MHz
baud    equ     19200  ; 19200, 57600, or 115200
brgdiv  equ     4       ; divider value for BRG16 = 1
brgval  equ     (clock*10000000/baud/brgdiv+5)/10-1
;

;; Variable space.
	cblock  USER_VARIABLE_SPACE
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
                           ; |-----X--|b2 = NoNE
                           ; |------X-|b1 = If you set this to one, then the main loop will send back all the tags.
                           ; |-------X|b0 = If you set this to one, the next tag readed will be sent to the bus.
    csum
	endc
;

;; Specify adresses for initial and interupt code.
	org     0x000
	goto    init_reset
	org     0x004
	goto	intserv
;

;; Force bank 0 and IRP = 0
init_reset:
    clrf    STATUS
    banksel INTCON
    bcf     INTCON, GIE
;

;; Setup 8 MHz INTOSC
    banksel OSCCON
    movlw   b'01110000'
    movwf   OSCCON
Stable:
    btfss   OSCCON,HTS ; osc stable? yes, skip, else     |B1
	goto    Stable     ; test again                      |B1
;

;; Turn off ADC pins
    banksel ANSEL
    clrf    ANSEL
    banksel ANSELH
    clrf    ANSELH
    banksel ADCON1
    MOVLW   B'01100000'
    ;A/D RC clock
    MOVWF   ADCON1
;

;; Setup ports
    banksel TRISA
	movlw   b'11001111'
	movwf   TRISA
	clrf    TRISB
	clrf    TRISC
;

;; Set interupts
    banksel PIE1
	movlw   b'00100000'
	movwf	PIE1
;

;; Setup UART module for SpeedBus
    banksel SPBRG
    movlw   low(brgval)
    movwf   SPBRG
    banksel SPBRGH
    movlw   high(brgval)
    movwf   SPBRGH
    banksel BAUDCTL
    bsf     BAUDCTL,BRG16
    banksel TXSTA
    movlw   b'00100100'
    movwf   TXSTA
    banksel RCSTA
    movlw   b'10010000'
    movwf   RCSTA
    movf    RCREG,W
    movf    RCREG,W
;


;; Start up Interrupts
        banksel INTCON
		bsf	INTCON, GIE
		bsf	INTCON, PEIE
;

;; Init Speedbus Library
        call    init_speedlib ; IMPORTANT to run this before, so the adresses are
;                             ; imported from EEPROM


;; Init display
    banksel PORTA
    bcf     PORTA, 5 ; Clear RS
	movlw   b'00110000'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_1
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA

	movlw   b'00111100'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_1
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA

	movlw   b'00001000'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_1
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA

	movlw   b'00000001'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_1
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA

	movlw   b'00000110'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_1
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA

	movlw   b'00001100'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_1
    banksel PORTA

    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA

	movlw   b'01001100'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
	movwf   PORTC
    bsf     PORTA, 5 ; Set E
    call    Delay_1
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA

    banksel w1
    movlw   80
    movwf   w1
    banksel PORTC
    movf    PORTC, W
    banksel w2
    movwf   w2
loop_text:
    incf    PORTC, F
    bsf     PORTA, 4 ; Set E
    call    Delay_1
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_1
    banksel PORTA
    movlw   20
    call    Delay
    banksel PORTA
    decfsz  w1, f
    goto    loop_text


main:
    banksel RCSTA
	btfsc	RCSTA,OERR
	call    recerror
	;btfsc	PORTA, 0
	;call 	txporta
    banksel rand
	incf	rand,F		; Increase the random value


    goto    main

spb_parameters:
    call    func_set_rsp_addr

    movlw   rcframe+7
    movwf   FSR

    ; Set status 
	movlw	0x00
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_status

;     P1         P2         P3         P4
; XXXXXXXXXX XXXXXXXXXX XXXXXXXXXX XXXXXXXXXX
;
;     P5         P6         P7         P8
; XXXXXXXXXX XXXXXXXXXX XXXXXXXXXX XXXXXXXXXX


    ; Set segment P1
	movlw	0x01
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s1

    ; Set segment P2
	movlw	0x02
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s2

    ; Set segment P3
	movlw	0x03
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s3

    ; Set segment P4
	movlw	0x04
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s4

    ; Set segment P5
	movlw	0x05
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s5

    ; Set segment P6
	movlw	0x06
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s6

    ; Set segment P7
	movlw	0x07
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s7

    ; Set segment P8
	movlw	0x08
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    spbp_display_s8


    goto    restore


spbp_display_status:
    banksel PORTA
    bcf     PORTA, 5
    movlw   b'00001111'
	movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    goto    restore

spbp_display_s1:
    banksel PORTA
    bcf     PORTA, 5
    movlw   0
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s1_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s1_loop
    goto    restore

spbp_display_s2:
    banksel PORTA
    bcf     PORTA, 5
    movlw   10
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s2_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s2_loop
    goto    restore

spbp_display_s3:
    banksel PORTA
    bcf     PORTA, 5
    movlw   20
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s3_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s3_loop
    goto    restore

spbp_display_s4:
    banksel PORTA
    bcf     PORTA, 5
    movlw   30
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s4_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s4_loop
    goto    restore

spbp_display_s5:
    banksel PORTA
    bcf     PORTA, 5
    movlw   64
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s5_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s5_loop
    goto    restore

spbp_display_s6:
    banksel PORTA
    bcf     PORTA, 5
    movlw   74
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s6_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s6_loop
    goto    restore

spbp_display_s7:
    banksel PORTA
    bcf     PORTA, 5
    movlw   84
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s7_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s7_loop
    goto    restore

spbp_display_s8:
    banksel PORTA
    bcf     PORTA, 5
    movlw   94
	movwf   PORTC
    bsf     PORTC, 7
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA

    movlw   10
    movwf   w1
    movlw   rcframe+8
    movwf   FSR

spbp_display_s8_loop:
    banksel PORTA
    bsf     PORTA, 5
    movf    INDF, W
    movwf   PORTC
    bsf     PORTA, 4 ; Set E
    call    Delay_2
    banksel PORTA
    bcf     PORTA, 4 ; Clear E
    call    Delay_2
    banksel PORTA
    incf    FSR, f
    decfsz  w1, f
    goto    spbp_display_s8_loop
    goto    restore


; Untill further investigation, this functions need to be implemented explictly to
; each processor

read_eeprom:
    banksel EEADR
    ;; Take the preset W number, and take the byte from the addr
    movwf   EEADR
    banksel EECON1
    bcf     EECON1, EEPGD
    bsf     EECON1, RD
    banksel EEDAT
    ;; Put the result in W
    movf    EEDAT, W
    ;; Get back to bank 0
    bcf     STATUS, RP0
    bcf     STATUS, RP1
    return

write_eeprom:
    banksel EEDAT
    movwf   EEDAT ; write the value already in W to EEDAT, the data
    banksel rc_nocoll
    movf    rc_nocoll,W
    banksel EEADR
    movwf   EEADR
    banksel EECON1
    bcf     EECON1, EEPGD
    bsf     EECON1, WREN
    movlw   0x55
    banksel EECON2
    movwf   EECON2
    movlw   0xAA
    movwf   EECON2
    banksel EECON1
    bsf     EECON1, WR
    btfsc   EECON1, WR
    goto    $-1
    bcf     EECON1, WREN

    ;; Get back to bank 0
    bcf     STATUS, RP0
    bcf     STATUS, RP1
    return

Delay_1:
    ; 5ms
    banksel d1
			;9998 cycles
	movlw	0xCF
	movwf	d1
	movlw	0x08
	movwf	d2
Delay1_0:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay1_0

    return


Delay_2:
    ; 500ns
    banksel d1
			;998 cycles
	movlw	0xC7
	movwf	d1
	movlw	0x01
	movwf	d2
Delay_2_0:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_2_0

    return

end