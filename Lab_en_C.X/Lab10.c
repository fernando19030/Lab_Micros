// Archivo:  Lab10.c
// Dispositivo:	PIC16F887
// Autor:    Fernando Arribas
// Compilador:	pic-as (v2.31), MPLABX V5.45
// 
// Programa: Transmición y recepción por medio del módulo EUSART
//           
// Hardware: 2 servos en PORTC y 2 potenciometros en PORTA 
//
// Creado: 04 may, 2021
// Ultima modificacion: 08 may, 2021

// PIC16F887 Configuration Bit Settings

// 'C' source line config statements

// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = ON       // Power-up Timer Enable bit (PWRT enabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = ON         // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

// #pragma config statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

#include <xc.h>
#include <stdint.h>
#include <stdio.h>

//******************************************************************************
// Directivas del Compilador
//******************************************************************************
#define _XTAL_FREQ  8000000     //Definimos el valor del reloj para los delays

//******************************************************************************
// Variables
//******************************************************************************

//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup(void);           //Definimos las funciones que vamos a utilizar 
void putch(char data);
void display (void);

//******************************************************************************
// Ciclo Principal
//******************************************************************************

void main(void) {
    setup();                //Llamamos a la configuracion del PIC

//******************************************************************************
//Loop principal
//******************************************************************************    
    
    while (1) 
    {
        display();
            
    }

    return;
    
}

//******************************************************************************
// Configuracion
//******************************************************************************

void setup(void) {
    //Configuracion de los puertos
    ANSEL   = 0X00;       //Colocamos RA0 y RA1 como entradas analogicas
    ANSELH  = 0X00;       
    
    TRISA   = 0X00;       //Colocamos RA0 y RA1 como entradas y el resto del
    TRISB   = 0X00;

    PORTA   = 0x00;
    PORTB   = 0x00;
    //Configuracion del Oscilador
    OSCCONbits.IRCF2 = 1;       //Reloj interno de 8MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS   = 1;
            
    //Configuracion Interupciones
    INTCONbits.GIE   = 1;       //Activamos las interupciones ADC 
    INTCONbits.PEIE  = 1;
    PIE1bits.RCIE    = 1;       //Activamos interupcion de recepcion
    PIE1bits.TXIE    = 1;       //Activamos interupcion de transmicion
    PIR1bits.RCIF    = 0;
    PIR1bits.TXIF    = 0;
    
    //Configuracion de TX y RX
    TXSTAbits.SYNC  = 0;    //Modo asincrono
    TXSTAbits.BRGH  = 1;    //Activamos la alta velocidad del Baud rate
    
    BAUDCTLbits.BRG16   = 1;    //Utilizamos los 16 bits del Baud rate
    
    SPBRG   = 207;  //Elegimos el baud rate 9600
    SPBRGH  = 0;
    
    RCSTAbits.SPEN  = 1;    //Activamos los puertos seriales
    RCSTAbits.RX9   = 0;    //No utilizamos los nueve bits
    RCSTAbits.CREN  = 1;    //Activamos la recepción continua
    
    TXSTAbits.TXEN  = 1;    //Activamos la transmición
   
    return;
}

//******************************************************************************
// Funcion
//******************************************************************************

void putch(char data){
    while (TXIF == 0);      //Esperar a que se pueda enviar un nueva caracter
    TXREG = data;           //Transmitir un caracter
    return;
}

void display(void) {
    __delay_ms(100);    //Printf llama a la funcion Putch para enviar todos los
    printf("\rQue accion desea ejecutar?: \r"); //caracteres dentro de las comillas
    __delay_ms(100);    //y mostramos todas las opciones del menu
    printf("    (1) Desplegar cadena de caracteres \r");
    __delay_ms(100);
    printf("    (2) Cambiar PORTA \r");
    __delay_ms(100);
    printf("    (3) Cambiar PORTB \r");
    
    while (RCIF == 0);  //Esperar a que se ingrese un dato de la computadora
    
    if (RCREG == '1') { //Si presionamos 1 mandamos un cadena de caracteres
        __delay_ms(500);
        printf("\r\rLa cadena de caracteres es:");
        __delay_ms(500);
        printf(" HoLa JoSe y KuRt\r\r");
    }
    
    else if (RCREG == '2') {    //Si presionamos dos enviamos un caracter a PORTA
        __delay_ms(500);    //Preguntamos el caracter
        printf("\r\rPresione el caracter a colocar en PORTA\r\r");
        while (RCIF == 0);  //Esperamos a que el usuario ingrese un dato
        
        PORTA = RCREG;      //Colocamos el caracter en PORTA
    }
    
    else if (RCREG == '3') {    //Si presionamos dos enviamos un caracter a PORTB
        __delay_ms(500);    //Preguntamos el caracter
        printf("\r\rPresione el caracter a colocar en PORTB\r\r");
        while (RCIF == 0);  //Esperamos a que el usuario ingrese un dato
        
        PORTB = RCREG;      //Colocamos el caracter en PORTB
    } 
    
    else {  //Si el usuario presiona cualquier otro caracter no sucede nada
        NULL; 
    }
    return;
}
