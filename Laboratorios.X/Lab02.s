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

PROCESSOR 16F887  ;Definición del procesador a utilizar 
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
  
;--------Definicion del Vector Reset----------
    
 PSECT resVect, class=CODE, abs, delta=2    ;Caracteristicas del vector reset

;---------------vector reset------------------
ORG 00h			    ;Posicion del vector reset
resetVec: 
    PAGESEL main
    goto main
    
PSECT code, delta=2, abs    ;Caracteristicas del codigo
ORG 100h		    ;posicion para el codigo
 
;---------------configuracion-----------------
main: 
   banksel ANSEL    ;Nos movemos al banco 3
   clrf    ANSEL    ;I/O Digital
   clrf	   ANSELH
   
   banksel TRISA    ;Nos movemos al banco 1
   movlw   0F0h	    ;Le indicamos que los ultimos 4 puertos de A
   movwf   TRISA    ;son entradas y el resto salidas
   
   movlw   01Fh	    ;Le indicamos a los primeros 5 puertos de B
   movwf   TRISB    ;que son entradas y el resto salidas
   
   movlw   0F0h	    ;Le indicamos a los primeros 4 puertos de C que
   movwf   TRISC    ;son salidas y el resto entradas
   
   movlw   0E0h	    ;Le indicamos a los primeros 5 puertos de D que
   movwf   TRISD    ;son salidas y el resto entradas
   
   banksel PORTA    ;Nos movemos al banco 0
   clrf	   PORTA    ;Se limpian los puertos A, B, C y D para que comienzen 
   clrf	   PORTB    ;en 0
   clrf	   PORTC
   clrf	   PORTD
   
;---------------loop principal---------------
   
 loop:
    btfsc   PORTB, 0	;Prueba del bit RB0
    call    inc_cont1	;Si se presiona el boton en RB0 se llama la Subrutina 
    btfsc   PORTB, 1	;Prueba del bit RB1	
    call    dec_cont1	;Si se presiona el boton en RB1 se llama la Subrutina
    
    btfsc   PORTB, 2	;Prueba del bit RB2
    call    inc_cont2	;Si se presiona el boton en RB2 se llama la Subrutina
    btfsc   PORTB, 3	;Prueba del bit RB3
    call    dec_cont2	;Si se presiona el boton en RB3 se llama la Subrutina
    
    btfsc   PORTB, 4	;Prueba del bit RB4
    call    sum		;Si se presiona el boton en RB4 se llama la Subrutina
    
    goto    loop	;Goto para mantener el programa activo todo el tiempo
 
;---------------sub rutinas------------------
 inc_cont1:		;Subrutina de incrementar el contador 1
    btfsc   PORTB, 0	;Antirebote, en donde si se mantiene ppresionado el 
    goto    $-1		;boton se mantiene en un loop
    incf    PORTA, 1	;Cuando se deja de presionar el boton el puerto A se incrementa en 1
    return		;Regreso al loop principal
    
 dec_cont1:		;Subrutina de decrementar el contador 1
    btfsc   PORTB, 1	;Antirebote (revisar el comentario en linea 89-90)
    goto    $-1
    decf    PORTA, 1	;Cuando se deja de presionar el boton el puerto A se decrementa en 1
    return		;Regreso al loop principal
      
 inc_cont2:		;Subrutina de incrementar el contador 2
    btfsc   PORTB, 2	;Antirebote (revisar el comentario en linea 89-90)
    goto    $-1
    incf    PORTC, 1	;Cuando se deja de presionar el boton el puerto C se incrementa en 1
    return		;Regreso al loop principal
    
 dec_cont2:		;Subrutina de decrementar el contador 2
    btfsc   PORTB, 3	;Antirebote (revisar el comentario en linea 89-90)
    goto    $-1
    decf    PORTC, 1	;Cuando se deja de presionar el boton el puerto C se decrementa en 1
    return		;Regreso al loop principal
    
 sum:
    btfsc   PORTB, 4	;Antirebote (revisar el comentario en linea 89-90)
    goto    $-1   
    
    movf    PORTA, 0	;Se mueve el dato de PORTA a W
    addwf   PORTC, 0	;Se suma el dato en W con el dato en PORTC y se guarda en W
    movwf   PORTD	;Se mueve el resultado de W al PORTD
    return		;Regreso al loop principal

    
end			;FIN