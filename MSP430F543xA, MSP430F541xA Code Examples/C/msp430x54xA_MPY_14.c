//******************************************************************************
//    MSP430F543xA Demo - Saturation mode underflow test
//
//   Description: The example illustrates a special case showing underflow.
//   Underflow occurs when adding 2 negative numbers yields a positive result.
//   By having the saturation mode enabled, the result if rounded off to the
//   highest negative number (0x8000.0000 for 16 bit). Results can be viewed
//   in the debugger window.
//
//   ACLK = 32.768kHz, MCLK = SMCLK = default DCO
//
//                MSP430F5438A
//             -----------------
//         /|\|                 |
//          | |                 |
//          --|RST              |
//            |                 |
//            |                 |
//
//   D. Dang
//   Texas Instruments Inc.
//   December 2009
//   Built with CCS Version: 4.0.2 and IAR Embedded Workbench Version: 4.21.8
//******************************************************************************

#include "msp430x54xA.h"

unsigned int Result_lower16;
unsigned int Result_upper16;

void main(void)
{
  WDTCTL = WDTPW+WDTHOLD;                   // Stop WDT

  MPY32CTL0 = MPYSAT+MPYC;                  // Saturation mode enable,
                                            // Carry bit set
  RES3 = 0;
  RES2 = 0;
  RES1 = 0x0000;                            // Pre-load first negative value
  RES0 = 0x8000;

  MACS = 0x8000;                            // Add to second negative value
  OP2 = 0x05;
  _nop();                                   // Wait for the result to become ready
  _nop();
  _nop();
  _nop();
  _nop();

  Result_upper16 = RESHI;                   // Result_upper15 = 0x8000
  Result_lower16 = RESLO;                   // Result_lower15 = 0x0000

  MPY32CTL0 &= ~MPYSAT;                     // Clear saturation mode
  
  __bis_SR_register(LPM4_bits);             // LPM4
  __no_operation();                         // For debugger
}
