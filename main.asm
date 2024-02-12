//***************************************************
;
; Universidad del Valle de Guatemala
; IE2023: Programación de Microcontroladores
; Autor: Angel Velásquez
; Descripción: Pre laboratorio 2, contador binario de 4 bits, donde cada 1s hay un incremento y un contador 
; controlado por botones, cuando ambos son el mismo número se alterna el estado de una led de alerta.
; Hardware: atmega328p
; Proyecto: AssemblerApplication1.asm
; Created: 4/2/2024 
;
//**************************************************


//**************************************************
; ENCABEZADO
//**************************************************
.include "M328PDEF.inc"
.cseg								//Indica inicio del código
.org 0x00							//Indica en que dirección va a estar el vector RESET


//**************************************************
; Configuración de pila
//**************************************************
LDI R16, LOW(RAMEND)              //STACKPOINTER, PARTE BAJA
OUT SPL, R16
LDI R16, HIGH(RAMEND)             //STACKPOINTER, PARTE DE ARRIBA
OUT SPH, R16


//**************************************************
; CONFIGURACIÓN MCU
//**************************************************
SETUP:
LDI R16, 0b1000_0000		  // 
STS CLKPR,R16				  // Habilitar el prescaler (STS GUARDA R16 EN UN LUGAR FUERA DE I/O)
LDI R16, 0b0000_0100
STS CLKPR,R16				  // Definir el prescaler de 16 Fcpu = 1MHz

LDI R16, 0b0000_1111	  //PUERTO B LED DE SALIDA
OUT DDRB, R16				  //SETEO DE PUERTO

LDI R16, 0b0001_0000		  //PUERTO C
OUT DDRC, R16
LDI R16, 0b0000_0011	  //PULL-UPS de los pines
OUT PORTC, R16

LDI R16, 0b0000_1111	  //PUERTO D
OUT DDRD, R16

CALL TIMER_SET

SEI			//Habilito las banderas globales

LDI R17, 0b0000_0000  //Registro contador por timer
LDI R19, 0b0000_0000  //Registro contador por botones
LDI R21, 0b0000_0000



	
LOOP:	//LOOP INFINITO DEL PROGRAMA


COMPARACION:
CP R17, R19 //SI SON IGUALES
BRNE SIGUIENTE
RJMP ALERTA


//PARTE MANEJADA POR BOTONES
SIGUIENTE:

IN R18, PINC				//LEER ESTADO DE LOS BOTONES

Boton_1: 
SBRS R18, PC0  // SALTA SI ESL PINC 0, ESTA EN 1, ES DECIR NO PRESIONADO
RJMP DelayBounce1

Boton_2: 
SBRS R18, PC1  // SALTA SI ESL PINC 0, ESTA EN 1, ES DECIR NO PRESIONADO
RJMP DelayBounce2

RJMP TIMER








//**************************************************
; SUBRUTINAS
//**************************************************

TIMER:
IN R16, TIFR0		//CARGO A R16 LOS DATOS DE TIFR0, DONDE ESTA ALMACENADO LA BANDERA DE OVERFLOW
SBRS R16, TOV0		//SI LA BANDERA DE OVERFLOW ESTA PRENDIDA SE SALTA LA SIGUIENTE INSTRUCCIÓN	
RJMP LOOP

LDI R16, 60				//CARGO EL VALOR DONDE DEBERIA EMPEZAR A CONTAR
OUT TCNT0, R16
SBI TIFR0, TOV0			//APAGA LA BANDERA DE DESBORDE
RJMP VECES

CONTADOR_UP:
CPI R16, 0b0000_1111 //SI EL CONTADOR DE 4 BITS SE LLENA SE SALTA LA SIGUIENTE LINEA
BRNE INC_C
RJMP RESET_C

VECES:
CPI R21, 5
BRNE INC_T
RJMP RESET_T

INC_T:
INC R21
RJMP LOOP

RESET_T:
LDI R21, 0b0000_0000
RJMP CONTADOR_UP


TIMER_SET:
LDI R16, 0b0000_0000
OUT TCCR0A, R16			// El temporizador en modo normal

LDI R16, (1 << CS02) | (1 << CS00)
OUT TCCR0B,  R16		// Prescaler a 1024

LDI R16, 60 //CARGO EL VALOR DONDE DEBERIA EMPEZAR A CONTAR
OUT TCNT0, R16
RET

RESET_C:
LDI R17, 0b0000_0000	//REINICIA EL CONTADOR
RJMP LED_UPDATE

INC_C:				//INCREMENTAR 1 AL CONTADOR
INC R17
RJMP LED_UPDATE





LED_UPDATE: //PUERTO DE LAS LEDS B PIN 0-3, REGISTRO DEL NUMERO R17
OUT PORTB, R17
OUT PORTD, R19
RJMP COMPARACION

////////////////////////////////////7

DelayBounce1:
LDI R16, 200
delay1:
DEC R16
BRNE delay1
IN R18, PINC
SBRS R18, PC0 // SALTA SI ESL PINC 0, ESTA EN 1, ES DECIR YA SOLTO EL BOTÓN
RJMP DelayBounce1

CPI R19, 0b0000_1111
BRNE N1_add
RJMP LOOP

DelayBounce2:
LDI R16, 200
delay2:
DEC R16
BRNE delay2
IN R18, PINC
SBRS R18, PC1 // SALTA SI ESL PINC 1, ESTA EN 1, ES DECIR YA SOLTO EL BOTÓN
RJMP DelayBounce2

CPI R19, 0b0000_0000
BRNE N1_res
RJMP LOOP

N1_res:
DEC R19
RJMP LED_UPDATE

N1_add:
INC R19
RJMP LED_UPDATE

ALERTA:
SBIC PINC, PC4
RJMP ENCENDIDA
RJMP APAGADA





ENCENDIDA:
LDI R23, 0b0000_0011
OUT PORTC, R23
RJMP SIGUIENTE

APAGADA:
LDI R23, 0b0001_0011
OUT PORTC, R23
RJMP SIGUIENTE