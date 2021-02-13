; Archivo:  Lab02.s
; Dispositivo:	PIC16F887
; Autor:    Fernando Arribas
; Compilador:	pic-as (v2.31), MPLABX V5.45
; 
; Programa: Contador en puerto B
; Hardware: LEDs en el puerto A, C y D
;
; Creado: 9 feb, 2021
; Ultima modificacion: 1 feb, 2021

PROCESSOR 16F887   
#include <xc.inc>

;CONFIG1
 CONFIG  FOSC = XT             ; Oscillator Selection bits (XT oscillator: Crystal/resonator on RA6/OSC2/CLKOUT and RA7/OSC1/CLKIN)
 CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
 CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
 CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
 CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
 CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
 CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
 CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
 CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
 CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

;CONFIG2
 CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
 CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  

 PSECT udata_bank0
   cont_1: DS 1
   cont_2: DS 1
    
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
   banksel ANSEL    ;Nos movemos al banco 3
   clrf    ANSEL    ;I/O Digital
   clrf	   ANSELH
   
   banksel TRISA    ;Nos movemos al banco 1
   movlw   0F0h
   movwf   TRISA
   
   movlw   01Fh
   movwf   TRISB 
   
   movlw   0F0h
   movwf   TRISC
   
   movlw   0E0h
   movwf   TRISD
   
   banksel PORTA
   clrf	   PORTA
   clrf	   PORTB
   clrf	   PORTC
   clrf	   PORTD
   
;---------------loop principal---------------
   
 loop:
    btfsc   PORTB, 0
    call    inc_cont1
    btfsc   PORTB, 1
    call    dec_cont1
    
    btfsc   PORTB, 2
    call    inc_cont2
    btfsc   PORTB, 3
    call    dec_cont2
    
    btfsc   PORTB, 4
    call    sum
    
    goto    loop
 
;---------------sub rutinas------------------
 inc_cont1:
    btfsc   PORTB, 0
    goto    $-1
    incf    PORTA, 1
    return
    
 dec_cont1:
    btfsc   PORTB, 1
    goto    $-1
    decf    PORTA, 1
    return
      
 inc_cont2:
    btfsc   PORTB, 2
    goto    $-1
    incf    PORTC, 1
    return
    
 dec_cont2:
    btfsc   PORTB, 3
    goto    $-1
    decfsz    PORTC, 1
    return
    
 sum:
    btfsc   PORTB, 4
    goto    $-1   
    
    movf    PORTA, 0
    addwf   PORTC, 0
    movwf   PORTD
    return
    
    ;movf    PORTA, 0
    ;movwf   cont_1
    
    ;movf    PORTC, 0
    ;movwf   cont_2
    
    ;addwf   cont_1, 1
    ;movf    cont_1, 0
    ;movwf   PORTD
    
end  