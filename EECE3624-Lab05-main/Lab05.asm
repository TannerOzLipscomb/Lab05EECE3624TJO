/**************************************************************************
 *	    File: Lab05.asm
 *  Lab Name: Pardon the Interruption...
 *    Author: Dr. Greg Nordstrom
 *   Created: 02/19/2021
 * Processor: ATmega128A (on the ReadyAVR board)
 *
 * Modified by: <Tanner Ozanich>
 * Modified on: <09/22/26>
 *
 * This program turns on the boot LED at a rate of 1-15Hz adjustable. The blink rate is displayed on LED 0-3 in binary. 
 *
 *************************************************************************/

 /*********
 * Interrupt Jump Table
 *********/
.org 0x0000                 ; next instruction address is 0x0000
                            ; (the location of the reset vector)
.def BlinkFreq = R20
.equ BlinkFreqMin = 1
.equ BlinkFreqMax = 15
.equ InitialBlinkFreq = BlinkFreqMin
.equ PullUp1and3 = 0x0A
.equ Output0to3 = 0x0F
.equ INT1andINT3 = 0xCC

rjmp main					; allow reset to run this program

.org 0x0004
rjmp int1_isr

.org 0x0008
rjmp int3_isr

/**********
* Main code
**********/
.org 0x0020					; Move the "main" to 0x0020 to make room for ISRs
main:                       ; jump here on reset
    ldi R16, HIGH(RAMEND)   ; initialize stack (default RAMEND = 0x10FF)
    out SPH, R16
    ldi R16, low(RAMEND)
    out SPL, R16

	/* Additional Setup before Main Loop */

    LDI  R16, (1<<DDA7)		; Set the mask to make Port A.7 an output
    OUT  DDRA, R16		; Load bitmask to PORTA register

	LDI  R16, Output0to3 ; setup of Port C 0-3 as output
	OUT  DDRC, R16
   
    LDI R16, 0x00     ; setup Port B and Port D as input ports
	OUT DDRB, R16
	OUT DDRD, R16

	LDI R16, PullUp1and3 ; hold the pins 1 and 3 high when no other input
	OUT PORTB, R16

	LDI R16, INT1andINT3
	STS EICRA, R16

	LDI R16, (1<<INT1) | (1<<INT3)
	OUT EIMSK, R16

	SEI

    LDI BlinkFreq, InitialBlinkFreq
	COM BlinkFreq
	OUT PORTC, BlinkFreq
	COM BlinkFreq

mainLoop:
    CBI  PORTA, PORTA7       ; turn BOOT LED on (active low) by clearing PORTA.7

    ; kill some time
    ldi R16, 16            ; R16 is outer loop counter
	sub R16, BlinkFreq
outer_loop1:
    ldi R24, low(0xFFFF)     ; load low and high parts of R25:R24 pair with
    ldi R25, high(0xFFFF)    ; loop count by loading registers separately
    inner_loop1:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop1    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop1        ; loop back if R16 isn't zero

    sbi PORTA, PORTA7       ; turn BOOT LED off (active low) by setting PORTA.7

    ; kill some more time
    ldi R16, 16            ; R16 is outer loop counter
	sub R16, BlinkFreq
outer_loop2:
    ldi R24, low(0xFFFF)     ; load low and high parts of R25:R24 pair with
    ldi R25, high(0xFFFF)    ; loop count by loading registers separately
    inner_loop2:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop2    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop2        ; loop back if R16 isn't zero

    rjmp mainLoop           ; play it again, Sam...

/**********
* ISR code
**********/
.org 0x0200							; Load the ISR code higher than main code

int1_isr:
PUSH R16
LDS R16, SREG
PUSH R16
CPI BlinkFreq, BlinkFreqMin
BREQ done2
DEC BlinkFreq
COM BlinkFreq
OUT PORTC, BlinkFreq
COM BlinkFreq

done2:
POP R16
STS SREG, R16
POP R16
reti

int3_isr:

PUSH R16
LDS R16, SREG
PUSH R16
CPI BlinkFreq, BlinkFreqMax
BREQ done1
INC BlinkFreq
COM BlinkFreq
OUT PORTC, BlinkFreq
COM BlinkFreq

done1:
POP R16
STS SREG, R16
POP R16
reti