; --COPYRIGHT--,BSD_EX
;  Copyright (c) 2012, Texas Instruments Incorporated
;  All rights reserved.
; 
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
; 
;  *  Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
; 
;  *  Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
; 
;  *  Neither the name of Texas Instruments Incorporated nor the names of
;     its contributors may be used to endorse or promote products derived
;     from this software without specific prior written permission.
; 
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; 
; ******************************************************************************
;  
;                        MSP430 CODE EXAMPLE DISCLAIMER
; 
;  MSP430 code examples are self-contained low-level programs that typically
;  demonstrate a single peripheral function or device feature in a highly
;  concise manner. For this the code may rely on the device's power-on default
;  register values and settings such as the clock configuration and care must
;  be taken when combining code from several examples to avoid potential side
;  effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
;  for an API functional library-approach to peripheral configuration.
; 
; --/COPYRIGHT--
;*******************************************************************************
;  MSP430F54xA Demo - RTC in Counter Mode toggles P1.0 every 1s
;
;  This program demonstrates RTC in counter mode configured to source from ACLK
;  to toggle P1.0 LED every 1s.
;
;                MSP430F5438
;             -----------------
;        /|\ |                 |
;         |  |                 |
;         ---|RST              |
;            |                 |
;            |             P1.0|-->LED
;
;   D. Dang
;   Texas Instruments Inc.
;   December 2009
;   Built with CCS Version: 4.0.2 
;******************************************************************************

    .cdecls C,LIST,"msp430.h"
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.

;-------------------------------------------------------------------------------
            .global _main 
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

            bis.b   #0x01,&P1OUT            ; P1.0 Set
            bis.b   #0x01,&P1DIR            ; P1.0 Output

            ; Setup RTC Timer
            mov.w   #RTCTEVIE + RTCSSEL_2 + RTCTEV_0,&RTCCTL01
                                            ; Counter Mode, RTC1PS, 8-bit ovf
                                            ; overflow interrupt enable
            mov.w   #RT0PSDIV_2,&RTCPS0CTL  ; ACLK, /8, start timer
            mov.w   #RT1SSEL_2 + RT1PSDIV_3,&RTCPS1CTL
                                            ; out from RT0PS, /16, start timer

            bis.b   #LPM3 + GIE,SR          ; Enter LPM3 w/ interrupt

;-------------------------------------------------------------------------------
RTC_ISR ;   RTC Interrupt Handler
;-------------------------------------------------------------------------------
            add     &RTCIV,PC
            reti                            ; No interrupts
            reti                            ; RTCRDYIFG
            jmp     RTCEVIFG_HND            ; RTCEVIFG
            reti                            ; RTCAIFG
            reti                            ; RT0PSIFG
            reti                            ; RT1PSIFG
            reti                            ; Reserved
            reti                            ; Reserved
            reti                            ; Reserved
            reti
RTCEVIFG_HND
            xor.b   #BIT0,&P1OUT            ; Toggle P1.0
            reti
;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".int41"                  ; RTC Vector
            .short  RTC_ISR
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
