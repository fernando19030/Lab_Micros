; Archivo:  main.s
; Dispositivo:	PIC16F887
; Autor:    Jose Morales
; Compilador:	pic-as (v2.31), MPLABX V5.45
; 
; Programa: contador en el puerto A
; Hardware: LEDs en el puerto A
;
; Creado: 1 feb, 2021
; Ultima modificacion: 1 feb, 2021

PROCESSOR 16F887
#include <xc.inc>
    
; CONFIGURATION WORD 1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIGURATION WORD 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
PSECT udata_bank0 ;common memory
  cont_small: DS 1 ;1 byte
  cont_big:   DS 1
 
PSECT resVect, class=CODE, abs, delta=2

;---------------vector reset------------------
ORG 00h
resetVec: 
    PAGESEL main
    goto main
    
PSECT code, delta=2, abs
ORG 100h ;posicion para el codigo
 
;---------------configuracion-----------------
main: 
    bsf	    STATUS, 5	;banco 11
    bsf	    STATUS, 6
    clrf    ANSEL	;pines digitales
    clrf    ANSELH
    
    bsf	    STATUS, 5	;banco 01
    bcf	    STATUS, 6
    clrf    TRISA	;port A como salida
    
    bcf	    STATUS, 5	;banco 00
    bcf	    STATUS, 6
    
;---------------loop principal---------------
loop: 
    incf    PORTA, 1
    call    delay_big 
    goto    loop                              	; loop forever
    
;---------------sub rutinas------------------
delay_big: 
    movlw   199		; valor inicial del contador
    movwf   cont_big
    call    delay_small ; rutina de delay
    decfsz  cont_big, 1 ; decrementar el contador
    goto    $-2		; ejecutar dos lineas atras
    return
    
delay_small:
    movlw   248		    ; valor inicial del contador
    movwf   cont_small
    decfsz  cont_small, 1   ; decrementar el contador
    goto    $-1		    ; ejecutar linea anterior
    return
    
end