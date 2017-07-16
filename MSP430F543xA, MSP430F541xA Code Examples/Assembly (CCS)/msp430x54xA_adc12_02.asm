;******************************************************************************
;  MSP430F543xA Demo - ADC12_A, Using the Internal Reference
;
;  Description: This example shows how to use the shared reference for ADC12
;  sampling and performs a single conversion on channel A0. The conversion 
;  results are stored in ADC12MEM0. Test by applying a voltage to channel A0, 
;  then setting and running to a break point at the nop  
;  instruction. To view the conversion results, open an ADC12 register window 
;  in debugger and view the contents of ADC12MEM0
;
;                MSP430F543xA
;             -----------------
;         /|\|                 |
;          | |                 |
;          --|RST              |
;            |                 |
;     Vin -->|P6.0/A0          |
;            |                 |

;
;   D. Dang
;   Texas Instruments Inc.
;   December 2009
;   Built with CCS Version: 4.0.2 and IAR Embedded Workbench Version: 4.11B
;******************************************************************************

    .cdecls C,LIST,"msp430x54xA.h"

;-------------------------------------------------------------------------------
            .global _main 
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #0x5C00,SP              ; Initialize stackpointer
            mov.w   #WDTPW + WDTHOLD,&WDTCTL; Stop WDT    
            bis.b   #0x01,&P6SEL            ; Enable A/D channel A0
			            
            mov.w 	#REFMSTR + REFVSEL_2 + REFON + REFTCOFF, &REFCTL0
       																			; Initialize REF module 
																						; Enable 2.5V shared reference, disable temperature sensor to save power								; 									
            mov.w	#ADC12ON + ADC12SHT02, &ADC12CTL0
            																; Turn on ADC12, set sampling time  
            mov.w   #ADC12SHP,&ADC12CTL1    ; Use sampling timer
            mov.b   #ADC12SREF_1,&ADC12MCTL0; Vr+=Vref+ and Vr-=AVss
            
            mov.w   #75,R4                  ; Initialize delay loop counter
delay_loop  dec.w   R4                      ; Delay for reference startup
            jne     delay_loop               
            
            bis.w   #ADC12ENC,&ADC12CTL0    ; Enable conversions
while_loop  bis.w   #ADC12SC,&ADC12CTL0     ; Start conversion
poll_ifg    bit.w   #BIT0,&ADC12IFG
            jnc     poll_ifg
            nop                             ; SET BREAKPOINT HERE
            jmp     while_loop 
            
;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
