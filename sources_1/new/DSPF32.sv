
//   DSPFP32   : In order to incorporate this function into the design,
//   Verilog   : the following instance declaration needs to be placed
//  instance   : in the body of the design code.  The instance name
// declaration : (DSPFP32_inst) and/or the port declarations within the
//    code     : parenthesis may be changed to properly reference and
//             : connect this function to the design.  All inputs
//             : and outputs must be connected.

//  <-----Cut code below this line---->

   // DSPFP32: The DSPFP32 consists of a floating-point multiplier and a floating-point adder  with separate outputs.
   //          Versal AI Core series
   // Xilinx HDL Language Template, version 2022.1
module dsp_prim();
   DSPFP32 #(
      // Feature Control Attributes: Data Path Selection
      .A_FPTYPE("B32"),                  // B16, B32
      .A_INPUT("DIRECT"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      .BCASCSEL("B"),                    // Selects B cascade out data (B, D).
      .B_D_FPTYPE("B32"),                // B16, B32
      .B_INPUT("DIRECT"),                // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      .PCOUTSEL("FPA"),                  // Select PCOUT output cascade of DSPFP32 (FPA, FPM)
      .USE_MULT("MULTIPLY"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
      // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
      .IS_CLK_INVERTED(1'b0),            // Optional inversion for CLK
      .IS_FPINMODE_INVERTED(1'b0),       // Optional inversion for FPINMODE
      .IS_FPOPMODE_INVERTED(7'b0000000), // Optional inversion for FPOPMODE
      .IS_RSTA_INVERTED(1'b0),           // Optional inversion for RSTA
      .IS_RSTB_INVERTED(1'b0),           // Optional inversion for RSTB
      .IS_RSTC_INVERTED(1'b0),           // Optional inversion for RSTC
      .IS_RSTD_INVERTED(1'b0),           // Optional inversion for RSTD
      .IS_RSTFPA_INVERTED(1'b0),         // Optional inversion for RSTFPA
      .IS_RSTFPINMODE_INVERTED(1'b0),    // Optional inversion for RSTFPINMODE
      .IS_RSTFPMPIPE_INVERTED(1'b0),     // Optional inversion for RSTFPMPIPE
      .IS_RSTFPM_INVERTED(1'b0),         // Optional inversion for RSTFPM
      .IS_RSTFPOPMODE_INVERTED(1'b0),    // Optional inversion for RSTFPOPMODE
      // Register Control Attributes: Pipeline Register Configuration
      .ACASCREG(1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .AREG(1),                          // Pipeline stages for A (0-2)
      .FPA_PREG(1),                      // Pipeline stages for FPA output (0-1)
      .FPBREG(1),                        // Pipeline stages for B inputs (0-1)
      .FPCREG(3),                        // Pipeline stages for C input (0-3)
      .FPDREG(1),                        // Pipeline stages for D inputs (0-1)
      .FPMPIPEREG(1),                    // Selects the number of FPMPIPE registers (0-1)
      .FPM_PREG(1),                      // Pipeline stages for FPM output (0-1)
      .FPOPMREG(3),                      // Selects the length of the FPOPMODE pipeline (0-3)
      .INMODEREG(1),                     // Selects the number of FPINMODE registers (0-1)
      .RESET_MODE("SYNC")                // Selection of synchronous or asynchronous reset. (ASYNC, SYNC).
   )
   DSPFP32_inst (
      // Cascade outputs: Cascade Ports
      .ACOUT_EXP(ACOUT_EXP),         // 8-bit output: A exponent cascade data
      .ACOUT_MAN(ACOUT_MAN),         // 23-bit output: A mantissa cascade data
      .ACOUT_SIGN(ACOUT_SIGN),       // 1-bit output: A sign cascade data
      .BCOUT_EXP(BCOUT_EXP),         // 8-bit output: B exponent cascade data
      .BCOUT_MAN(BCOUT_MAN),         // 23-bit output: B mantissa cascade data
      .BCOUT_SIGN(BCOUT_SIGN),       // 1-bit output: B sign cascade data
      .PCOUT(PCOUT),                 // 32-bit output: Cascade output
      // Data outputs: Data Ports
      .FPA_INVALID(FPA_INVALID),     // 1-bit output: Invalid flag for FPA output
      .FPA_OUT(FPA_OUT),             // 32-bit output: Adder/accumlator data output in Binary32 format.
      .FPA_OVERFLOW(FPA_OVERFLOW),   // 1-bit output: Overflow signal for adder/accumlator data output
      .FPA_UNDERFLOW(FPA_UNDERFLOW), // 1-bit output: Underflow signal for adder/accumlator data output
      .FPM_INVALID(FPM_INVALID),     // 1-bit output: Invalid flag for FPM output
      .FPM_OUT(FPM_OUT),             // 32-bit output: Multiplier data output in Binary32 format.
      .FPM_OVERFLOW(FPM_OVERFLOW),   // 1-bit output: Overflow signal for multiplier data output
      .FPM_UNDERFLOW(FPM_UNDERFLOW), // 1-bit output: Underflow signal for multiplier data output
      // Cascade inputs: Cascade Ports
      .ACIN_EXP(ACIN_EXP),           // 8-bit input: A exponent cascade data
      .ACIN_MAN(ACIN_MAN),           // 23-bit input: A mantissa cascade data
      .ACIN_SIGN(ACIN_SIGN),         // 1-bit input: A sign cascade data
      .BCIN_EXP(BCIN_EXP),           // 8-bit input: B exponent cascade data
      .BCIN_MAN(BCIN_MAN),           // 23-bit input: B mantissa cascade data
      .BCIN_SIGN(BCIN_SIGN),         // 1-bit input: B sign cascade data
      .PCIN(PCIN),                   // 32-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .CLK(CLK),                     // 1-bit input: Clock
      .FPINMODE(FPINMODE),           // 1-bit input: Controls select for B/D input data mux.
      .FPOPMODE(FPOPMODE),           // 7-bit input: Selects input signals to floating-point adder and input
                                     // negation.

      // Data inputs: Data Ports
      .A_EXP(A_EXP),                 // 8-bit input: A data exponent
      .A_MAN(A_MAN),                 // 23-bit input: A data mantissa
      .A_SIGN(A_SIGN),               // 1-bit input: A data sign bit
      .B_EXP(B_EXP),                 // 8-bit input: B data exponent
      .B_MAN(B_MAN),                 // 23-bit input: B data mantissa
      .B_SIGN(B_SIGN),               // 1-bit input: B data sign bit
      .C(C),                         // 32-bit input: C data input in Binary32 format.
      .D_EXP(D_EXP),                 // 8-bit input: D data exponent
      .D_MAN(D_MAN),                 // 23-bit input: D data mantissa
      .D_SIGN(D_SIGN),               // 1-bit input: D data sign bit
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .ASYNC_RST(ASYNC_RST),         // 1-bit input: Asynchronous reset for all registers.
      .CEA1(CEA1),                   // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(CEA2),                   // 1-bit input: Clock enable for 2nd stage AREG
      .CEB(CEB),                     // 1-bit input: Clock enable BREG
      .CEC(CEC),                     // 1-bit input: Clock enable for CREG
      .CED(CED),                     // 1-bit input: Clock enable for DREG
      .CEFPA(CEFPA),                 // 1-bit input: Clock enable for FPA_PREG
      .CEFPINMODE(CEFPINMODE),       // 1-bit input: Clock enable for FPINMODE register
      .CEFPM(CEFPM),                 // 1-bit input: Clock enable for FPM output register.
      .CEFPMPIPE(CEFPMPIPE),         // 1-bit input: Clock enable for FPMPIPE post multiplier register.
      .CEFPOPMODE(CEFPOPMODE),       // 1-bit input: Clock enable for FPOPMODE post multiplier register.
      .RSTA(RSTA),                   // 1-bit input: Reset for AREG
      .RSTB(RSTB),                   // 1-bit input: Reset for BREG
      .RSTC(RSTC),                   // 1-bit input: Reset for CREG
      .RSTD(RSTD),                   // 1-bit input: Reset for DREG
      .RSTFPA(RSTFPA),               // 1-bit input: Reset for FPA output register
      .RSTFPINMODE(RSTFPINMODE),     // 1-bit input: Reset for FPINMODE register
      .RSTFPM(RSTFPM),               // 1-bit input: Reset for FPM output register
      .RSTFPMPIPE(RSTFPMPIPE),       // 1-bit input: Reset for FPMPIPE register
      .RSTFPOPMODE(RSTFPOPMODE)      // 1-bit input: Reset for FPOPMODE registers
   );

   // End of DSPFP32_inst instantiation
					
endmodule				