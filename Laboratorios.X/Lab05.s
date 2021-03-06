; Archivo:  Lab05.s
; Dispositivo:	PIC16F887
; Autor:    Fernando Arribas
; Compilador:	pic-as (v2.31), MPLABX V5.45
; 
; Programa: Contador con interupción que despliega los resultdados de 3 formas distintas  
; Hardware: Leds el PORTA, pushbottons en PORTB y 2 displays 7 segmentos en PORTD y PORTC
;
; Creado: 02 mar, 2021
; Ultima modificacion: 05 mar, 2021

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
    banksel PORTA   ;tiempo = 4*T_osc*prescaler*(256-TMR0)
    movlw   178	    ;Movemos el valor que el timer debe tener para sumar cada 10ms
    movwf   TMR0    ;Movemos W al registro TMR0
    bcf	    T0IF    ;Limpiamos la bandera de Overflow del Timer 0
    endm
  
;-----------------Variables-------------------
GLOBAL	w_temp, status_temp, var, flags, nibbles, display, unidad, decena, centena, prueba
    
PSECT udata_shr ;common memory
  w_temp:	DS 1	;1 byte
  status_temp:	DS 1

PSECT udata_bank0
    var:	DS 1	;1 byte
    flags:	DS 1
    nibbles:	DS 2	;2 bytes
    display:	DS 6
    unidad:	DS 1
    decena:	DS 1
    centena:	DS 1
    prueba:	DS 1
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
    btfsc   PORTB, 0	    ;Verificar si el boton en RB0 se esta presionando
    incf    PORTA	    ;Si se presiona incrementar el PORTA
    
    btfsc   PORTB, 1	    ;Verificar si el boton en RB1 se esta presionando
    decf    PORTA	    ;Si se presiona decrementar el PORTA
    
    bcf	    RBIF	    ;Limpiar la bandera de int on change B
    return
 
intTMR0:
    reinicioTMR0	    ;Reiniciamos el TMR0
    bcf	    PORTB, 2	    ;Limpiamos los pines RB2, RB3, RB4, RB5, RB6, RB7
    bcf	    PORTB, 3
    bcf	    PORTB, 4
    bcf	    PORTB, 5
    bcf	    PORTB, 6
    bcf	    PORTB, 7
    
    btfsc   flags, 0	    ;Verificamos si la bandera 0 esta prendida
    goto    display2	    ;Si esta prendido nos dirigimos al display 2
    
    btfsc   flags, 1	    ;Verificamos si la bandera 1 esta prendida
    goto    display3	    ;Si esta prendido nos dirigimos al display 3
    
    btfsc   flags, 2	    ;Verificamos si la bandera 2 esta prendida
    goto    display4	    ;Si esta prendido nos dirigimos al display 4
    
    btfsc   flags, 3	    ;Verificamos si la bandera 3 esta prendida
    goto    display5	    ;Si esta prendido nos dirigimos al display 5
    
    btfsc   flags, 4	    ;Verificamos si la bandera 4 esta prendida
    goto    display6	    ;Si esta prendido nos dirigimos al display 6
    
display1:
   movf	    display, W	    ;Movemos lo que esta en la variable a W
   movwf    PORTC	    ;Lo movemos al PORTC
   bsf	    PORTB, 2	    ;Activamos RB2
   goto	    next_display2   ;Nos dirigimos prepar las banderas para el siguiente display
   
display2:
   movf	    display+1, W    ;Movemos lo que esta en la variable a W
   movwf    PORTC	    ;Lo movemos al PORTC
   bsf	    PORTB, 3	    ;Activamos RB3
   goto	    next_display3   ;Nos dirigimos prepar las banderas para el siguiente display
   
display3:
   movf	    display+2, W    ;Movemos lo que esta en la variable a W
   movwf    PORTD	    ;Lo movemos al PORTD
   bsf	    PORTB, 4	    ;Activamos RB4
   goto	    next_display4   ;Nos dirigimos prepar las banderas para el siguiente display
   
display4:
   movf	    display+3, W    ;Movemos lo que esta en la variable a W
   movwf    PORTD	    ;Lo movemos al PORTD
   bsf	    PORTB, 5	    ;Activamos RB5
   goto	    next_display5   ;Nos dirigimos prepar las banderas para el siguiente display
   
display5:
   movf	    display+4, W    ;Movemos lo que esta en la variable a W
   movwf    PORTD	    ;Lo movemos al PORTD
   bsf	    PORTB, 6	    ;Activamos RB6
   goto	    next_display6   ;Nos dirigimos prepar las banderas para el siguiente display
   
display6:
   movf	    display+5, W    ;Movemos lo que esta en la variable a W
   movwf    PORTD	    ;Lo movemos al PORTD
   bsf	    PORTB, 7	    ;Activamos RB7
   goto	    next_display1   ;Nos dirigimos prepar las banderas para el siguiente display
   
next_display2:
    movlw   1		    ;Movemos 0000 0001B a W
    xorwf   flags, F	    ;Realizamos un XOR entre flags y W
    return
    
next_display3:
    movlw   3		    ;Movemos 0000 0011B a W
    xorwf   flags, F	    ;Realizamos un XOR entre flags y W
    return

next_display4:
    movlw   6		    ;Movemos 0000 0110B a W
    xorwf   flags, F	    ;Realizamos un XOR entre flags y W
    return
    
next_display5:
    movlw   12		    ;Movemos 0000 1100B a W
    xorwf   flags, F	    ;Realizamos un XOR entre flags y W
    return
    
next_display6:
    movlw   24		    ;Movemos 0001 1000B a W
    xorwf   flags, F	    ;Realizamos un XOR entre flags y W
    return
    
next_display1:
    clrf    flags, F	    ;Limpiamos todas las banderas
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
    
    banksel PORTA
    
;---------------loop principal---------------
loop:   
    movf    PORTA, W	    ;Movemos lo que esta en PORTA a W
    movwf   prueba	    ;Movemos lo que esta W a una variable
    
    call    centenas
    
    call    separar_contador
    call    display_setup
    goto    loop
      
;---------------sub rutinas------------------
config_IO:
    banksel ANSEL   ;Nos movemos al banco 3
    clrf    ANSEL   ;I/O Digital
    clrf    ANSELH
   
    banksel TRISA   ;Nos movemos al banco 1  
    clrf    TRISA   ;todas son salidas
    
    movlw   003h    ;Le indicamos a los primeros 2 puertos de B
    movwf   TRISB   ;que son entradas y el resto salidas
   
    clrf    TRISC   ;todas son salidas 
   	   
    clrf    TRISD   ;todos son salidas
      
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

separar_contador:
    movf    PORTA, W	    ;Movemos lo que esta en PORTA a W
    movwf   var		    ;Movemos lo que esta en W a var
   
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

    movf    unidad, W		;Mover lo que esta en la variable a W
    call    tabla		;Llamar a tabla
    movwf   display+2, F	;Mover lo que esta en W al tercer byte de la variable
    
    movf    decena, W		;Mover lo que esta en la variable a W
    call    tabla		;Llamar a tabla
    movwf   display+3, F	;Mover lo que esta en W al cuarto byte de la variable
    
    movf    centena, W		;Mover lo que esta en la variable a W
    call    tabla		;Llamar a tabla
    movwf   display+4, F	;Mover lo que esta en W al quinto byte de la variable
    
    movlw   00111111B		;Mover la literal a W
    movwf   display+5		;Mover lo que esta en W al sexto byte de la variable
    
    return
    
centenas:
    clrf    centena		;Limpiamos la variable
    movlw   100			;Movemos 100 a W
    subwf   prueba, W		;Restamos W a la variable prueba
    btfsc   STATUS, 0		;Si se pudo hacer la operación haga lo siguiente
    incf    centena		;Incrementar la variable centena
    btfsc   STATUS, 0		;Si se pudo hacer la operación haga lo siguiente
    movwf   prueba		;Mover lo que esta en W a prueba
    btfsc   STATUS, 0		;Si se pudo hacer la operación haga lo siguiente
    goto    $-7			;Regresar 7 casillas hacia atras
    call    decenas		;Nos dirigimos a dividir las centenas
    return
    
decenas:
    clrf    decena		;Limpiamos la variable
    movlw   10			;Movemos 10 a W
    subwf   prueba, W		;Restamos W a la variable prueba
    btfsc   STATUS, 0		;Si se pudo hacer la operación haga lo siguiente
    incf    decena		;Incrementar la variable decena
    btfsc   STATUS, 0		;Si se pudo hacer la operación haga lo siguiente
    movwf   prueba		;Mover lo que esta en W a prueba
    btfsc   STATUS, 0		;Si se pudo hacer la operación haga lo siguiente
    goto    $-7			;Regresar 7 casillas hacia atras
    call    unidades		;Nos dirigimos a dividir las unidades
    return
    
unidades:
    clrf    unidad		;Limpiamos la variable
    movlw   1			;Restamos W a la variable prueba
    subwf   prueba, F		;Restamos W a la variable prueba
    btfsc   STATUS, 0		;Si se pudo hacer la operación haga lo siguiente
    incf    unidad		;Incrementar la variable unidad
    btfss   STATUS, 0		;Si no se pudo hacer la operación haga lo siguiente
    return
    goto    $-6			;Regresar 6 casillas hacia atras
       
end