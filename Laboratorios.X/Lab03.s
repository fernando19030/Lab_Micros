; Archivo:  Lab02.s
; Dispositivo:	PIC16F887
; Autor:    Fernando Arribas
; Compilador:	pic-as (v2.31), MPLABX V5.45
; 
; Programa: Contador con TMR0, Contador con botones y 7 Seg y Alarma 
; Hardware: LEDs en el puerto C y E, pushbotons en el puerto B y 7seg en puerto D
;
; Creado: 16 feb, 2021
; Ultima modificacion: 20 feb, 2021

PROCESSOR 16F887  ;Definición del procesador a utilizar
#include <xc.inc>

; CONFIG1
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

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

;-----------------Variables-------------------
PSECT udata_shr ;common memory
  contador: DS 2 ;2 byte
    
;--------Definicion del Vector Reset----------
    
PSECT resVect, class=CODE, abs, delta=2    ;Caracteristicas del vector reset

;---------------vector reset------------------
ORG 00h			    ;Posicion del vector reset
resetVec: 
    PAGESEL main
    goto main
    
PSECT code, delta=2, abs    ;Caracteristicas del codigo
ORG 100h		    ;posicion para el codigo

;-------------------Tabla---------------------
tabla:
    clrf    PCLATH	    ;Limpiamos PCLATH
    bsf	    PCLATH, 0	    ;Colocamos el PCLATH como 01
    andlw   0x0f	    ;Realizamo un AND entre W y 0x0f para que W solo tenga los 4 bits menos signf
    addwf   PCL, 1	    ;Añadimos W a PCL para que asi el PC = PCLATH + PCL + W
    retlw   00111111B	    ;0
    retlw   00000110B	    ;1
    retlw   01011011B	    ;2
    retlw   01001111B	    ;3
    retlw   01100110B	    ;4
    retlw   01101101B	    ;5
    retlw   01111101B	    ;6
    retlw   00000111B	    ;7
    retlw   01111111B	    ;8
    retlw   01101111B	    ;9
    retlw   01110111B	    ;A
    retlw   01111100B	    ;b
    retlw   00111001B	    ;C
    retlw   01011110B	    ;d
    retlw   01111001B	    ;E
    retlw   01110001B	    ;F
    
;---------------configuracion-----------------
main: 
    call    config_IO	    ;Configuracion de los pines
    call    config_CLK	    ;Configuracion del reloj
    call    config_TMR0	    ;Configuracion del Timer 0
    banksel PORTA   
    
;---------------loop principal---------------
loop:
    btfss   T0IF	    ;Verificamos si la bandera de overflow del Timer0 esta
    goto    $-1		    ;encendida
    call    reinicioTMR0
    incf    PORTC, f	    ;Al terminar la subrutina incrementamos el puerto C
    
    btfsc   PORTB, 0	    ;Si el pinr RB0 esta encendido llamamos a la subrutina
    call    inc_cont
    
    btfsc   PORTB, 1	    ;Si el pinr RB1 esta encendido llamamos a la subrutina
    call    dec_cont
    
    bcf	    PORTE, 0	    ;Colocamos en 0 el pin RE0
    call    alarma	    
    
    goto    loop
    
;---------------sub rutinas------------------
config_IO:
    banksel ANSEL   ;Nos movemos al banco 3
    clrf    ANSEL   ;I/O Digital
    clrf    ANSELH
   
    banksel TRISA   ;Nos movemos al banco 1  
    movlw   002h    ;Le indicamos a los primeros 2 puertos de B
    movwf   TRISB   ;que son entradas y el resto salidas
   
    movlw   0F0h    ;Le indicamos a los primeros 4 puertos de C que
    movwf   TRISC   ;son salidas y el resto entradas
   	   
    clrf    TRISD   ;todos son salidas
    
    movlw   0FEh    ;Pin RE0 es una salida y el resto son entradas
    movwf   TRISE
   
    banksel PORTA   ;Nos movemos al banco 0  
    clrf    PORTB   ;Se limpian los puertos B, C ,D y E para que comienzen
    clrf    PORTC   ;en 0
    clrf    PORTD
    clrf    PORTE
    return
    
config_CLK:
    banksel OSCCON  ;Banco 1
    bcf	    IRCF2   ;Reloj de 500 KHz IRCF = 011
    bsf	    IRCF1
    bsf	    IRCF0
    bsf	    SCS	    ;Reloj Interno
    return
    
config_TMR0:
    banksel TRISA   ;Nos movemos al banco 1
    bcf	    T0CS    ;TMR0 usa el reloj interno
    bcf	    PSA	    ;Prescaler es utilizado por el TMR0
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;Prescaler PS (111) = 1:256	    
    banksel PORTA   ;Nos movemos al banco 0
    call    reinicioTMR0
    return

reinicioTMR0:
    movlw   12	    ;Movemos el valor que el timer debe tener para sumar cada 500ms
    movwf   TMR0    ;Movemos W al registro TMR0
    bcf	    T0IF    ;Limpiamos la bandera de Overflow del Timer 0
    return
    
inc_cont:
    btfsc   PORTB, 0	    ;Mientras que se presione el boton no se incrementa
    goto    $-1		    ;el contador
    incf    contador	    ;Se incrementa el contador y se guarda en la variable
    movf    contador, 0	    ;Se mueve lo que esta en la variable a W
    call    tabla	    ;Llamamos a la subrutina tabla que mostrara el resultado en el 7seg
    movwf   PORTD, 1	    ;Movemos el resultado de la tabla al puerto D
    return
    
dec_cont:
    btfsc   PORTB, 1	    ;Mientras que se presione el boton no se decrementa
    goto    $-1		    ;el contador
    decf    contador	    ;Se decrementa el contador y se guarda en la variable
    movf    contador, 0	    ;Se mueve lo que esta en la variable a W
    call    tabla	    ;Llamamos a la subrutina tabla que mostrara el resultado en el 7seg
    movwf   PORTD, 1	    ;Movemos el resultado de la tabla al puerto D
    return
    
alarma:
    movf    contador, 0	    ;Mover la variable a W
    subwf   PORTC, 0	    ;Restar el contador del timer0 del 7segmentos
    btfsc   STATUS, 2	    ;Verificar el flag Z que se encuentra en STATUS
    call    led_alarma	    ;Si la flag zero se enciende se llama la subrutina
    return
 
led_alarma:
    bsf	    PORTE, 0	    ;Se prende la alarma
    clrf    PORTC	    ;Se limpia el contador del Timer0
    return
END
