;******************************************************************************
;  MSP430F54xA Demo - XT2 sources MCLK & SMCLK
;
;  Description: This program demonstrates using XT2 to source MCLK. XT1 is not
;  connected in this case.
;
;  By default, LFXT1 is requested by the following modules:
;     - FLL
;     - ACLK
;  If LFXT1 is NOT used and if the user does not change the source modules,
;  it causes the XT1xxOFIFG flag to be set because it is constantly looking
;  for LFXT1. OFIFG, global oscillator fault flag, will always be set if LFXT1
;  is set. Hence, it is important to ensure LFXT1 is no longer being sourced
;  if LFXT1 is NOT used.
;  MCLK = XT2
;  PMMCOREV = 2 to support up to 20MHz clock
;
;  NOTE: if the SMCLK/HF XTAL frequency exceeds 8MHz, VCore must be set
;  accordingly to support the system speed. Refer to MSP430x5xx Family User's Guide
;  Section 2.2 for more information.

;               MSP430F5438A
;             -----------------
;        /|\ |                 |
;         |  |                 |
;         ---|RST              |
;            |            XT2IN|-
;            |                 | HF XTAL (455kHz - 16MHz)
;            |           XT2OUT|-
;            |                 |
;            |            P11.1|--> MCLK = XT2
;            |                 |
;
;  	Note: 
;      	In order to run the system at up to 20MHz, VCore must be set at 1.8V 
;		or higher. This is done by invoking function SetVCore(), which requires 
;		2 files, hal_pmm.asm and hal_pmm.h, to be included in the project.
;      	hal_pmm.asm and hal_pmm.h are located in the same folder as the code 
;		example. 
;
;   D. Dang
;   Texas Instruments Inc.
;   December 2009
;   Built with CCS Version: 4.0.2 
;******************************************************************************

    .cdecls C,LIST,"msp430x54xA.h"
	.cdecls C,LIST,"hal_pmm.h"
	
count    .equ    R4 
;-------------------------------------------------------------------------------
            .global _main 
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #0x5C00,SP              ; Initialize stackpointer
            mov.w   #WDTPW + WDTHOLD,&WDTCTL; Stop WDT
            mov.w	#PMMCOREV_2,R12			; Set VCore to 1.8V to support up to 20MHz clock
            calla	#SetVCore				; call SetVCore subroutine from hal_pmm.c
            
            mov.b   #BIT1 + BIT2,&P11DIR    ; P11.1-2 to output direction
            bis.b   #BIT1 + BIT2,&P11SEL    ; P11.1-2 to output SMCLK,MCLK
            bis.b   #0x0C,&P5SEL            ; Port select XT2

            bic.w   #XT2OFF,&UCSCTL6        ; Clear XT2OFF bit
            bis.w   #SELREF_2,&UCSCTL3      ; FLLref = REFO
                                            ; Since LFXT1 is not used,
                                            ; sourcing FLL with LFXT1 can cause
                                            ; XT1OFFG flag to set
            bis.w   #SELA_2,&UCSCTL4        ; ACLK=REFO,SMCLK=DCO,MCLK=DCO

            ; Loop until XT1,XT2 & DCO stabilizes
do_while    bic.w   #XT2OFFG + XT1LFOFFG + XT1HFOFFG + DCOFFG,&UCSCTL7
                                            ; Clear XT2,XT1,DCO fault flags
            bic.w   #OFIFG,&SFRIFG1         ; Clear fault flags
            bit.w   #OFIFG,&SFRIFG1         ; Test oscillator fault flag
            jc      do_while

            bic.w   #XT2DRIVE0,&UCSCTL6     ; Decrease XT2 Drive according to
                                            ; expected frequency
            bis.w  #SELS_5 + SELM_5,&UCSCTL4; SMCLK=MCLK=XT2

while_loop  jmp     while_loop

;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
            
            