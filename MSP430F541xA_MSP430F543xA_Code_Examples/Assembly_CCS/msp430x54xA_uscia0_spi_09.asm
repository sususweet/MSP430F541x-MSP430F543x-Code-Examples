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
;******************************************************************************
;   MSP430F54xA Demo - USCI_A0, SPI 3-Wire Master Incremented Data
;
;   Description: SPI master talks to SPI slave using 3-wire mode. Incrementing
;   data is sent by the master starting at 0x01. Received data is expected to
;   be same as the previous transmission.  USCI RX ISR is used to handle
;   communication with the CPU, normally in LPM0. If high, P1.0 indicates
;   valid data reception.  Because all execution after LPM0 is in ISRs,
;   initialization waits for DCO to stabilize against ACLK.
;   ACLK = ~32.768kHz, MCLK = SMCLK = DCO ~ 1048kHz.  BRCLK = SMCLK/2
;
;   Use with SPI Slave Data Echo code example.  If slave is in debug mode, P1.1
;   slave reset signal conflicts with slave's JTAG; to work around, use IAR's
;   "Release JTAG on Go" on slave device.  If breakpoints are set in
;   slave RX ISR, master must stopped also to avoid overrunning slave
;   RXBUF.
;
;                   MSP430F5438A
;                 -----------------
;             /|\|                 |
;              | |                 |
;              --|RST          P1.0|-> LED
;                |                 |
;                |             P3.4|-> Data Out (UCA0SIMO)
;                |                 |
;                |             P3.5|<- Data In (UCA0SOMI)
;                |                 |
;  Slave reset <-|P1.1         P3.0|-> Serial Clock Out (UCA0CLK)
;
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

count    .equ    R4 
MST_Data    .equ    R5 
SLV_Data    .equ    R6 

;-------------------------------------------------------------------------------
            .global _main 
            .text                           ; Assemble to Flash memory
;-------------------------------------------------------------------------------
_main
RESET       mov.w   #0x5C00,SP              ; Initialize stackpointer
            mov.w   #WDTPW + WDTHOLD,&WDTCTL; Stop WDT

            bis.b   #0x02,&P1OUT            ; Set P1.0 for LED
                                            ; Set P1.1 for slave reset
            bis.b   #0x03,&P1DIR            ; Set P1.0-2 to output direction
            bis.b   #0x31,&P3SEL            ; P3.5,4,0 option select

            bis.b   #UCSWRST,&UCA0CTL1      ; **Reset USCI state machine**
            bis.b   #UCMST + UCSYNC + UCCKPL + UCMSB,&UCA0CTL0
                                            ; 3-pin, 8-bit SPI master
                                            ; Clock polarity high, MSB
            bis.b   #UCSSEL_2,&UCA0CTL1     ; SMCLK
            mov.b   #0x02,&UCA0BR0          ; /2
            mov.b   #0x00,&UCA0BR1
            mov.b   #0x00,&UCA0MCTL         ; No modulation
            bic.b   #UCSWRST,&UCA0CTL1      ;**Initialize USCI state machine**
            bis.b   #UCRXIE,&UCA0IE         ; Enable USCI_A0 RX interrupt

            bic.b   #BIT1,&P1OUT            ; Now with SPI signals initialized,
            bis.b   #BIT1,&P1OUT            ;  reset slave

            mov.b   #50,count               ; Load delay counter
slave_init_delay
            dec.b   count                   ; Wait for slave to initialize
            jne     slave_init_delay

            mov.b   #0x01,MST_Data          ; Initialize data values
            mov.b   #0x00,SLV_Data          ;

check_Tx_buf
            bit.b   #UCTXIFG,&UCA0IFG       ; USCI_A0 TX buffer ready?
            jnc     check_Tx_buf            ; no -> check again
            mov.b   MST_Data,&UCA0TXBUF     ; yes -> Transmit first character

            bis.w   #LPM0 + GIE,SR          ; Enter LPM0, enable interrupts
            nop                             ; For debugger

;-------------------------------------------------------------------------------
USCI_A0_ISR
;-------------------------------------------------------------------------------
            add.w   &UCA0IV,PC              ; Vector to interrupt handler
            reti                            ; Vector 0: No interrupt
            jmp     RXIFG_HND               ; Vector 2: RXIFG
            reti                            ; Vector 4: TXIFG

RXIFG_HND
check_TX_rdy
            bit.b   #UCTXIFG,&UCA0IFG       ; USCI_A0 TX buffer ready?
            jnc     check_TX_rdy

            cmp.b   SLV_Data,&UCA0RXBUF     ; Test for correct character RX'd
            jne     clear_led
set_led     bis.b   #BIT0,&P1OUT            ; If correct, light LED
            jmp     correct_LED
clear_led   bic.b   #BIT0,&P1OUT            ; If incorrect, clear LED

correct_LED inc.b   MST_Data                ; Increment data
            inc.b   SLV_Data

            mov.b   MST_Data,&UCA0TXBUF     ; Send next value

            mov.b   #30,count               ; Load delay counter
tx_delay    dec.b   count                   ; Add time between transmissions to
            jne     tx_delay                ;   make sure slave can keep up

            reti                            ; Return from interrupt

;-------------------------------------------------------------------------------
                  ; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".int57"    
            .short  USCI_A0_ISR
            .sect   ".reset"                ; POR, ext. Reset
            .short  RESET
            .end
