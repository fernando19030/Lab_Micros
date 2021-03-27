; Archivo:  Lab06.s
; Dispositivo:	PIC16F887
; Autor:    Fernando Arribas
; Compilador:	pic-as (v2.31), MPLABX V5.45
; 
; Programa: Contador con interupción que despliega los resultdados de 3 formas distintas  
; Hardware: Leds el PORTA, pushbottons en PORTB y 2 displays 7 segmentos en PORTD y PORTC
;
; Creado: 23 mar, 2021
; Ultima modificacion: 23 mar, 2021

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
 
;------------------Macros---------------------
reinicioTMR0 macro
    banksel PORTA   ;tiempo = 4*T_osc*prescaler*(256-TMR0) = 254
    movlw   254	    ;Movemos el valor que el timer debe tener para sumar cada 2ms
    movwf   TMR0    ;Movemos W al registro TMR0
    bcf	    T0IF    ;Limpiamos la bandera de Overflow del Timer 0
    endm
    
reinicioTMR1 macro
    banksel PORTA   ;tiempo = 4*T_osc*prescaler*(65536-TMR1) = 34286
    movlw   238	    ;Movemos el valor que el timer debe tener para sumar cada 1s
    movwf   TMR1L   ;Movemos W al registro TMR1L
    
    movlw   133
    movwf   TMR1H   ;Movemos W al registro TMR1H
    bcf	    TMR1IF  ;Limpiamos la bandera de Overflow del Timer 1
    endm
    
reinicioTMR2 macro
    banksel TRISA   ;tiempo = 4*T_osc*prescaler*postscaler*PR2 = 245
    movlw   245	    ;Movemos el valor que el timer debe tener para sumar cada 250ms
    movwf   PR2     ;Movemos W al registro PR2
    
    banksel PORTA
    bcf	    TMR2IF    ;Limpiamos la bandera de Overflow del Timer 2
    endm
 
;-----------------Variables-------------------
GLOBAL	w_temp, status_temp, var, flags, nibbles, display
    
PSECT udata_shr ;common memory
  w_temp:	DS 1	;1 byte
  status_temp:	DS 1

PSECT udata_bank0
    var:	DS 1	;1 byte
    flags:	DS 1
    nibbles:	DS 2	;2 bytes
    display:	DS 2
    
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
    btfsc   T0IF	    ;Verificar si la bandera de overflow del TMR0 esta activa    
    call    intTMR0	    ;Si esta activa llamar la subrutina
    
    btfsc   TMR1IF	    ;Verificar si la bandera de overflow del TMR1 esta activa    
    call    intTMR1	    ;Si esta activa llamar la subrutina
    
    btfsc   TMR2IF	    ;Verificar si la bandera de overflow del TMR2 esta activa    
    call    intTMR2	    ;Si esta activa llamar la subrutina
    
pop: 
   swapf    status_temp, W  ;Rotar los nibbles y guardarlo en W
   movwf    STATUS	    ;Mover lo que esta en W a STATUS
   swapf    w_temp, F	    ;Rotar los nibbles y guardarlo en w_temp
   swapf    w_temp, W	    ;Rotarlo de nuevo para no modificar el orden y guardarlo en W
   retfie

;--------------subrutinas Interupcion--------
intTMR0:
    reinicioTMR0	    ;Reiniciamos el TMR0
    bcf	    PORTD, 0	    ;Limpiamos los pines RD0, RD1
    bcf	    PORTD, 1
    
    btfsc   flags, 0	    ;Verificamos si la bandera 0 esta prendida
    goto    display2	    ;Si esta prendido nos dirigimos al display 2
    
display1:
   movf	    display, W	    ;Movemos lo que esta en la variable a W
   movwf    PORTC	    ;Lo movemos al PORTC
   bsf	    PORTD, 0	    ;Activamos RD0
   goto	    next_display2   ;Nos dirigimos prepar las banderas para el siguiente display
   
display2:
   movf	    display+1, W    ;Movemos lo que esta en la variable a W
   movwf    PORTC	    ;Lo movemos al PORTC
   bsf	    PORTD, 1	    ;Activamos RD1
   bcf	    flags, 0
   return
   
next_display2:
    movlw   1		    ;Movemos 0000 0001B a W
    xorwf   flags, F	    ;Realizamos un XOR entre flags y W
    return
    
intTMR1:
    reinicioTMR1	    ;Reiniciamos el TMR1
    incf    var, F	    ;Incrementamos la variable
    return
    
intTMR2:
    reinicioTMR2	    ;Reiniciamos el TMR2
    
    btfsc   flags, 1	    ;Revisamos si el bit esta encendido
    goto    encendido
    
apagado:
    bsf	    flags, 1	    ;Encender la bandera 
    return
    
encendido:
    bcf	    flags, 1	    ;Apagamos la bandera
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
    call    config_TMR1	    ;Condiguracion del Timer 1
    call    config_TMR2	    ;Condiguracion del Timer 2
    call    config_int	    ;Configuracion del las interupciones
    
    banksel PORTA
    
;---------------loop principal---------------
loop:
    call    separar_contador
    
    btfss   flags, 1	    ;verficamos si la bandera esta apagada
    call    display_setup
    
    btfsc   flags, 1	    ;verficamos si la bandera esta encendida
    call    turnoff

    goto    loop

;---------------sub rutinas-------------------
config_IO:
    banksel ANSEL   ;Nos movemos al banco 3
    clrf    ANSEL   ;I/O Digital
    clrf    ANSELH
   
    banksel TRISA   ;Nos movemos al banco 1  
    clrf    TRISC      ;todas son salidas 
   	   
    bcf     TRISD, 0   ;RD0 como salida
    bcf     TRISD, 1   ;RD1 como salida
    bcf     TRISD, 2   ;RD2 como salida
      
    banksel PORTA   ;Nos movemos al banco 0  
    clrf    PORTC   ;Se limpian los puertos B, C ,D y A para que comienzen
    clrf    PORTD   ;en 0
    return
    
config_CLK:
    banksel OSCCON  ;Banco 1
    bsf	    IRCF2   ;Reloj de 1 MHz IRCF = 111
    bcf	    IRCF1
    bcf	    IRCF0
    bsf	    SCS	    ;Reloj Interno
    return

config_int:
    banksel PORTA   ;Banco 0
    bsf	    GIE	    ;Habilitar las interupciones globales
    bsf	    PEIE
    
    bsf	    T0IE    ;Habilitamos la interupcion por overflow del TMR0
    bcf	    T0IF    ;Limpiar la bandera de overflow del TMR0
    
    banksel TRISA
    bsf	    TMR1IE  ;Habilitamos la interupcion por overflow del TMR1
    bsf	    TMR2IE  ;Habilitamos la interupcion por overflow del TMR2
    
    banksel PORTA
    bcf	    TMR1IF  ;Limpiar la bandera de overflow del TMR1
    bcf	    TMR2IF  ;Limpiar la bandera de overflow del TMR2
    return
    
config_TMR0:
    banksel TRISA   ;Nos movemos al banco 1
    bcf	    T0CS    ;TMR0 usa el reloj interno
    bcf	    PSA	    ;Prescaler es utilizado por el TMR0
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	    ;Prescaler PS (111) = 1:256	 
    
    banksel PORTA   ;Nos movemos al banco 0
    reinicioTMR0
    return
    
config_TMR1:
    banksel PORTA
    bsf	    TMR1ON  ;TMR1 enable
    bcf	    TMR1CS  ;TMR1 clock internal
    bsf	    T1CKPS0 ;Prescaler (ss) 1:8
    bsf	    T1CKPS1
    
    banksel PORTA
    reinicioTMR1
    return
    
config_TMR2:
    banksel PORTA
    bsf	    T2CKPS1 ;Prescaler (11): 1:16
    bsf	    T2CKPS0
    bsf	    TMR2ON  ;Encendemos TMR2
    bsf	    TOUTPS3 ;Postscaler (1111): 1:16
    bsf	    TOUTPS2
    bsf	    TOUTPS1
    bsf	    TOUTPS0
    
    banksel TRISA
    reinicioTMR2
    return

separar_contador: 
    movf    var, W	    ;Movemos lo que esta en Var de nuevo a W
    andlw   0x0f	    ;Realizamos un AND para dejar el nibble menos significativo 
    movwf   nibbles	    ;Colocamos el nibble menos significativo en el primer byte de la variable
    
    swapf   var, W	    ;Movemos lo que esta en Var de nuevo a W
    andlw   0x0f	    ;Realizamos un AND para dejar el nibble mas significativo 
    movwf   nibbles + 1	    ;Colocamos el nibble mas significativo en el segundo byte de la variable
    return

display_setup:
    movf    nibbles, W		;Mover lo que esta en PORTA a W
    call    tabla		;Llamar a tabla
    movwf   display, F		;Mover lo que esta en W al primer byte de la variable
    
    movf    nibbles+1, W	;Mover lo que esta en PORTA a W
    call    tabla		;Llamar a tabla
    movwf   display+1, F	;Mover lo que esta en W al segundo byte de la variable
    
    bsf	    PORTD, 2		;Encendemos el led en RD2
    return
    
turnoff:
    clrf    display		;Apagamos los displays
    clrf    display+1
    
    bcf     PORTD, 2		;Apagamos el led en RD2
    return
    
end
    