// Archivo:  Lab07.c
// Dispositivo:	PIC16F887
// Autor:    Fernando Arribas
// Compilador:	pic-as (v2.31), MPLABX V5.45
// 
// Programa: Contador con botones desplegado en decimal en displays 7 seg 
// Hardware: 7 displays 7 segmentos en PORTD con los controladores en PORTB,
//           2 pushbotons en PORTB y leds en PORTC
//
// Creado: 13 abr, 2021
// Ultima modificacion: 18 abr, 2021

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

//******************************************************************************
// Directivas del Compilador
//******************************************************************************

#define _tmr0_value 217         //Definimos el valor del timer 0
//#define _XTAL_FREQ  8000000


//******************************************************************************
// Variables
//******************************************************************************
char tabla [10] = {0X3F, 0X06, 0X5B, 0X4F, 0X66, 0X6D, 0X7D, 0X07, 0X7F, 0X67};
 //Definimos la tabla para mostrar los valores en el 7 segmentos

int flags;      //Variables de conversion a decimal
int unidad;
int decena;
int centena;
int variable;
int residuo;

//******************************************************************************
// Prototipos de funciones
//******************************************************************************
void setup(void);           //Definimos las funciones que vamos a utilizar 
int decimal(void);          //dentro del código

//******************************************************************************
// Interupción
//******************************************************************************
void __interrupt() isr(void)
{
//Interupcion del Timer 0 (Multiplexado)
    if (T0IF == 1)                  //Multiplexado
    {
        PORTBbits.RB2 = 0;          //Limpiamos los puertos a utilizar
        PORTBbits.RB3 = 0;
        PORTBbits.RB4 = 0;
        
        INTCONbits.T0IF  = 0;       //Reinicio del timer 0
        TMR0 = _tmr0_value;  
        
        if (flags == 0) {           //Por medio de banderas verificamos que 
           PORTBbits.RB4 = 0;       //display es el que toca encender
           PORTBbits.RB2 = 1;       //al terminar el if cambiamos de bandera
           PORTD = tabla[centena];
           flags = 1; 
        }
        
        else if (flags == 1) {
           PORTBbits.RB2 = 0;
           PORTBbits.RB3 = 1;
           PORTD = tabla[decena];
           flags = 2;  
        }
        
        else if (flags == 2) {
           PORTBbits.RB3 = 0;
           PORTBbits.RB4 = 1;
           PORTD = tabla[unidad];
           flags = 0;  
        }
    }
    
    //Interupcion on change del puerto B
    if (RBIF == 1){                 //Contador
        if (RB0 == 1){              //Verificamos cual boton se presiona
            PORTC++;                //Si es RB0 incrementamos
        }
        
        if (RB1 == 1){              //Si es RB1 decrementamos
            PORTC--;
        }
        
        INTCONbits.RBIF = 0;        //Reiniciamos la interupción
    }
    
}

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
        variable = PORTC;   //Preparamos el contador par ser convertido a decimal
        decimal();          //luego llamamod a la funcion de conversion       
    }

    return;
}

//******************************************************************************
// Configuracion
//******************************************************************************

void setup(void) {
    //Configuracion de los puertos
    ANSEL   = 0X00;             //Colocamos RB0 y RB1 como entradas y el resto del
    ANSELH  = 0X00;             //PORTB, el PORTC y PORTD como salidas
    
    TRISB   = 0X03;
    TRISC   = 0X00;
    TRISD   = 0X00;
    
    PORTB   = 0X00;
    PORTC   = 0X00;
    PORTD   = 0X00;
    
    //Configuracion del Oscilador
    OSCCONbits.IRCF2 = 1;       //Reloj interno de 8MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 1;
    OSCCONbits.SCS   = 1;
            
    //Configuracion Interupciones
    INTCONbits.GIE   = 1;       //Activamos las interupciones on change y del TMR0
    INTCONbits.T0IE  = 1;
    INTCONbits.RBIE  = 1;
    INTCONbits.T0IF  = 0;
    INTCONbits.RBIF  = 0;
    
    //Configuracion Puerto B
    IOCBbits.IOCB0   = 1;       //Activamos en RB0 y RB1 la interupcion on change
    IOCBbits.IOCB1   = 1;
    
    //Configuracion TMR0
    OPTION_REGbits.PSA  = 0;    //Le indicamos que el timer 0 utiliza un 
    OPTION_REGbits.T0CS = 0;    //prescaler de 1:256 y que utilze reloj interno
    OPTION_REGbits.PS2  = 1;
    OPTION_REGbits.PS1  = 1;
    OPTION_REGbits.PS0  = 1;
    TMR0 = _tmr0_value;
    
    //Valor inicial del multiplexado
    flags = 0X00;               //Colocamos valor inical a la bandera
    
}

//******************************************************************************
//Conversion a decimal
//******************************************************************************
int decimal(void) {
    centena = variable/100;     //Convertimos el valor del contador a decimal
    residuo = variable%100;     //por medio de divisiones y residuos
    decena  = residuo/10;
    unidad  = residuo%10;   
}