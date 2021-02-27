; Archivo:  Lab04.s
; Dispositivo:	PIC16F887
; Autor:    Fernando Arribas
; Compilador:	pic-as (v2.31), MPLABX V5.45
; 
; Programa: Contador con TMR0 y pushbottons que funcionan a base de interupciones  
; Hardware: Leds el PORTA, pushbottons en PORTB y 2 displays 7 segmentos en PORTD y PORTC
;
; Creado: 23 feb, 2021
; Ultima modificacion: 27 feb, 2021

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
  contTMR0:	DS 1 ;1 byte
  cont:		DS 1
  w_temp:	DS 1
  status_temp:	DS 1
    
;--------Definicion del Vector Reset----------
    
PSECT resVect, class=CODE, abs, delta=2    ;Caracteristicas del vector reset

;---------------vector reset------------------
ORG 00h			    ;Posicion del vector reset
resetVec: 
    PAGESEL main
    goto main
    
;--------------Vector Interrupcion------------
PSECT	intvect, class=CODE, abs, delta=2
org 04h

push:
    movwf   w_temp	    ;Guardar lo que esta en W para no modificarlo
    swapf   STATUS, W	    ;Mover lo que esta en STATUS a W cambiando los nibbles de lugar
    movwf   status_temp	    ;Mover lo que esta en W(STATUS) para evitar modificarlo
    
isr:
    btfsc   RBIF	    ;Verificar si la bandera de int on change en B esta activa
    call    intB	    ;Si esta activa llamar la subrutina
    
    btfsc   T0IF	    ;Verificar si la bandera de overflow del TMR0 esta activa    
    call    intTMR0	    ;Si esta activa llamar la subrutina
    
pop: 
   swapf    status_temp, W  ;Rotar los nibbles y guardarlo en W
   movwf    STATUS	    ;Mover lo que esta en W a STATUS
   swapf    w_temp, F	    ;Rotar los nibbles y guardarlo en w_temp
   swapf    w_temp, W	    ;Rotarlo de nuevo para no modificar el orden y guardarlo en W
   retfie
   
;--------------subrutinas Interupcion--------
intB:
    banksel PORTA	    ;Nos movemos al banco 0
    btfss   PORTB, 0	    ;Verificar si el boton en RB0 se esta presionando
    incf    PORTA	    ;Si se presiona incrementar el PORTA
    
    btfss   PORTB, 1	    ;Verificar si el boton en RB1 se esta presionando
    decf    PORTA	    ;Si se presiona decrementar el PORTA
    
    bcf	    RBIF	    ;Limpiar la bandera de int on change B
    return

intTMR0:
    banksel PORTA	    ;Nos movemos al banco 0
    incf    cont	    ;Incrementar la variable cada ves que exista un overflow del TMR0
    call    reinicioTMR0    ;Se reinicia el TMR0
    return
    
;---------------Posicion codigo---------------    
PSECT code, delta=2, abs    ;Caracteristicas del codigo
ORG 100h

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
    call    config_int	    ;Configuracion del las interupciones
    call    config_intchB   ;Configuracion de la interupcion on change B
    banksel PORTA	    ;Banco 0
    
;---------------loop principal---------------
loop:
    call dispush    ;Control del display controlado por Pushbotons
    
    call delay	    ;Control del display controlado por el TMR0
    
    goto loop
    
;---------------sub rutinas------------------
config_IO:
    banksel ANSEL   ;Nos movemos al banco 3
    clrf    ANSEL   ;I/O Digital
    clrf    ANSELH
   
    banksel TRISA   ;Nos movemos al banco 1  
    movlw   0f0h    ;Colocar los cuatro primeros pines como salidas
    movwf   TRISA   ;y el resto como salidas
    
    movlw   003h    ;Le indicamos a los primeros 2 puertos de B
    movwf   TRISB   ;que son entradas y el resto salidas
   
    clrf    TRISC   ;todas son salidas 
   	   
    clrf    TRISD   ;todos son salidas
    
    bcf	    OPTION_REG, 7   ;Activar los PullUps internos en el puerto B
    bsf	    WPUB, 0	    ;Habilitar el pullup interno en RB0
    bsf	    WPUB, 1	    ;Habilitar el pullup interno en RB1
    
   
    banksel PORTA   ;Nos movemos al banco 0  
    clrf    PORTA
    clrf    PORTB   ;Se limpian los puertos B, C ,D y A para que comienzen
    clrf    PORTC   ;en 0
    clrf    PORTD
    return
    
config_CLK:
    banksel OSCCON  ;Banco 1
    bsf	    IRCF2   ;Reloj de 8 MHz IRCF = 111
    bsf	    IRCF1
    bsf	    IRCF0
    bsf	    SCS	    ;Reloj Interno
    return

config_int:
    banksel PORTA   ;Banco 0
    bsf	    GIE	    ;Habilitar las interupciones globales
    bsf	    RBIE    ;Habilitar las interupciones on change en B
    bcf	    RBIF    ;Limpiar la bandera de int on change B
    
    bsf	    T0IE    ;Habilitamos la interupcion por overflow del TMR0
    bcf	    T0IF    ;Limpiar la bandera de overflow del TMR0
    return
    
config_intchB:
    banksel TRISA	;Banco 1
    bsf	    IOCB, 0	;Habilitar int on change en RB0
    bsf	    IOCB, 1	;Habilitar int on change en RB1
    
    banksel PORTA	;Banco 0
    movf    PORTB, W	;Al leer termina condicion de mismatch
    bcf	    RBIF	;Limpiar la bandera de int on change B
    return
    
dispush:
    movf    PORTA, W	;Mover lo que esta en PORTA a W
    call    tabla	;Llamar a tabla
    movwf   PORTC, F	;Mover lo que esta en W al PORTC
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
    movlw   178	    ;Movemos el valor que el timer debe tener para sumar cada 10ms
    movwf   TMR0    ;Movemos W al registro TMR0
    bcf	    T0IF    ;Limpiamos la bandera de Overflow del Timer 0
    return
    
delay:
    movlw   100		;Mover un literal de 100 a W
    subwf   cont, w	;Restar la variable cont de W
    btfss   STATUS, 2	;Verificar si zero se enciende
    return		;Si no se enciende regresar
    incf    contTMR0	;Si se enciende incrementar la variable
    movf    contTMR0, w	;Moverla a W
    call    tabla	;Llamar a tabla
    movwf   PORTD	;Mover lo que se trajo de tabla a PORTD
    clrf    cont	;Limpiar la variable
    return

end