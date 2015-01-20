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

; IMPORTATNT! All the speedlib pre definitions, MUST be definde before the include
#define ARC_16F             1
;#define REC_CUSTOM_JUMP     custom_command_handler
;#define CUSTOM_INTERRUPT   c_intserv
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
	movlw   b'11111111'
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


main:
    banksel RCSTA
	btfsc	RCSTA,OERR
	call    recerror
	;btfsc	PORTA, 0
	;call 	txporta
    banksel rand
	incf	rand,F		; Increase the random value


    goto    main


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

end