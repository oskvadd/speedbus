;
; Define macros for speedbus!
;
;
; 150111 20:54 - Speedster
;

if_parameter macro _if, jumpto
	movlw	_if
    bankisel rcframe
	subwf	INDF,W
	btfsc	STATUS,Z
    goto    jumpto
endm

if_sget_parameter macro _if_setparameter, _if_getparameter
    banksel rc_counter
    movlw   10
    subwf   rc_counter,W
    btfsc   STATUS,Z
    goto    _if_getparameter
    goto    _if_setparameter
    goto    restore
endm