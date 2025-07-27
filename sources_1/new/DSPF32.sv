
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
  
// Using the DSP58 FP32 Primitive as a paramertizable stage and operating mode floating point PE unit, that supports blocking mode AXI-Stream operation

// Parameters:
// IN_STG_1: Input Pipeline Stage infront of A and B Port (0-1)
// IN_STG_2: Second Input Pipeline Stage infront of A (0-1)
// MUL_PIP:  Additional Multiplier Pipeline Stage (0-1)
// MUL_OUT_STG: Register to latch Multiplier output (0-1)
// ADD_OUT_STG: Register to latch Adder output (0-1)
// FPOPMODE_STG: Set of pipeline registers for FPOPMODE Adder Input selection (0-3)
// FPINMODE_STG: Pipeline register infront of FPINMODE input (0-1)

// Modes of Operation 
// 0: Multiply Accumulate 
// 1: Multiply 
// TBD

`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

module dsp_prim #(parameter IN_STG_1 = 1, IN_STG_2 = 0, MUL_PIP = 1, MUL_OUT_STG = 1, ADD_OUT_STG = 1, FPOPMODE_STG = 3, FPINMODE_STG = 1, MODE = 0)(
// CLK and nRST PINS
input logic aclk, aresetn,

// A Port Signals 
input logic s_axis_a_tvalid,
input single_float s_axis_a_tdata,
output logic s_axis_a_tready,

// B Port Signals 
input logic s_axis_b_tvalid,
input single_float s_axis_b_tdata,
output logic s_axis_b_tready,

// Output Port Signals
input logic m_axis_result_tready,
output logic m_axis_result_tvalid,
output logic processing,
output single_float m_axis_result_tdata,
output error m_axis_result_tuser);

   parameter LAT = IN_STG_1 + IN_STG_2 + MUL_PIP + MUL_OUT_STG + ADD_OUT_STG; // Baseline Latency is 0 (Can do single cycle operation according to behavioral sim)
   
   // Internal wrapper signals
   logic add_overflow, add_underflow, add_invalid, mul_overflow, mul_underflow, mul_invalid, comp_ready, is_add, comp_done;
   single_float add_out, mul_out, a_dat, b_dat, n_a_dat, n_b_dat;
   dsp_add_conf fpopmode;
   error add_user, mul_user, n_add_user, n_mul_user;
   float_reg a_in, b_in, n_a_in, n_b_in, mul_out_latch, add_out_latch, n_mul_out_latch, n_add_out_latch;
   float_reg b_dat_2;
   logic [LAT:0] pip_stg_ocp, n_pip_stg_ocp;
   
   // Configuring DSP Primitive
   // Can expand functionality of the dsp primitive wrapper by adding more cases to the case statement 
   // To add more FPOPMODE configurations, modify the dsp_add_conf enum type in dsp_sys_arr_pkg
   always_comb begin
    fpopmode = NA;
    is_add = 0;
    
    case(MODE)
    'd0: begin
        fpopmode = MAC;
        is_add = 1'b1;
    end
    
    'd1: begin
        is_add = 1'b0;
    end
    
    default: begin
        fpopmode = MAC;
        is_add = 1'b1;
    end
    endcase
    
   end

   
   always_ff @(posedge aclk, negedge aresetn) begin
    if(~aresetn) begin
        mul_out_latch   <= '0; // Latches multiply output
        add_out_latch   <= '0; // Latches adder stage output
        a_in            <= '0; // Holds A data input until B data arrives to load into DSP (This is how blocking mode behaviour is implemented)
        b_in            <= '0; // Holds B data input until B data arrives to load into DSP 
        a_dat           <= '0; // A Data register that feeds into DSP. Loaded after all operands ready
        b_dat           <= '0; // B Data register that feeds into DSP. Loaded after all operands ready
        b_dat_2         <= '0; // Second B data register, only used if there is second A input stage to match timing of A input into multiplier
        add_user        <= '0; // Latches add output error signals (more details on format of user signal is in dsp_sys_arr_pkg)
        mul_user        <= '0; // Latches multiply out error signals
        pip_stg_ocp     <= '0; // Tracks if a particular stage of the pipeline is occupied
    end
    
    else begin
        a_in            <= n_a_in;
        if(IN_STG_2) begin
        b_dat            <= b_dat_2;
        b_dat_2          <= n_b_dat;
        end
        else begin
        b_dat           <= n_b_dat;
        end
        b_in            <= n_b_in;
        a_dat           <= n_a_dat;
        mul_out_latch   <= n_mul_out_latch;
        add_out_latch   <= n_add_out_latch;
        add_user        <= n_add_user;
        mul_user        <= n_mul_user;
        pip_stg_ocp     <= n_pip_stg_ocp;
    end
   end
   
   // Input Port AXI Logic (Implements Blocking mode as described in the User Guide)
   always_comb begin
    s_axis_a_tready = ~a_in.dirty; // Only accept input if holding registers are not full  
    s_axis_b_tready = ~b_in.dirty;
    
    // Indicates whether data is ready to be loaded into DSP Primitive
    // Checks if data is ready for both A and B port either from occupation of holding registers or availaibility on AXI IN lines
    comp_ready      = (a_in.dirty & b_in.dirty) | (a_in.dirty & s_axis_b_tvalid & s_axis_b_tready) | (b_in.dirty & s_axis_a_tvalid & s_axis_a_tready) | (s_axis_a_tvalid & s_axis_b_tvalid & s_axis_a_tready & s_axis_b_tready);
    
    n_a_in = a_in;
    n_b_in = b_in;
    n_a_dat = a_dat;
    n_b_dat = IN_STG_2 ? b_dat_2 : b_dat;
    
    n_pip_stg_ocp = pip_stg_ocp >> 1; 
    
    // In the case of simultaneous or sequential input passing, inputs must be passed into the pipeline in the same cycle and 
    // the holding registers must be cleared s.t. on the next cycle they are ready to receive data
    
    // Simulataneous input passing allows for bypassing the a/b_in holding registers and going straight to the DSP primitive
    // Allows for streaming mode input into PE, where ready signal is never low
    if(comp_ready) begin
        n_b_in  = '0;
        n_a_in  = '0;
        
        n_a_dat   = s_axis_a_tready ? s_axis_a_tdata : a_in.data;
        n_b_dat   = s_axis_b_tready ? s_axis_b_tdata : b_in.data; 
        n_pip_stg_ocp = (pip_stg_ocp >> 1) | (1'd1 << LAT); 
    end
    
    // Logic to fill holding registers in case of sequential input passing
    else begin
        if(s_axis_a_tvalid & s_axis_a_tready) begin
            n_a_in.dirty    = 1'b1;
            n_a_in.data     = s_axis_a_tdata;
        end
        
        if(s_axis_b_tvalid & s_axis_b_tready) begin
            n_b_in.dirty    = 1'b1;
            n_b_in.data     = s_axis_b_tdata;
        end
    end
    
    // If data has been passed into first stage of pipeline, input registers should be cleared to avoid duplicate inputs, and incorrect accumulation
    if(pip_stg_ocp[LAT]) begin
        n_a_dat = '0;
        n_b_dat = '0;
    end
   
   end
   
   // Output Port Logic
   always_comb begin
    n_add_out_latch         = add_out_latch;
    n_mul_out_latch         = mul_out_latch;
    
    m_axis_result_tvalid    = comp_done;
    processing              = |pip_stg_ocp; // If any stage of pipeline is occupied then, data is being processed
    
    n_mul_user              = mul_user;
    n_add_user              = add_user;
   
    // If PE saw our output, we can clear the output latches
    if(m_axis_result_tready & m_axis_result_tvalid) begin
        n_add_out_latch = '0;
        n_mul_out_latch = '0;
        n_mul_user      = '0;
        n_add_user      = '0;
    end
    
    
    if(ADD_OUT_STG) begin
        // If there is an accumulator stage, we need to latch multiplier and adder output seperatley, because there is a one cycle delay between them
        if(pip_stg_ocp[0]) begin
         
            n_add_out_latch.dirty   = 1'b1;
            n_add_out_latch.data    = add_out;
            
            n_add_user.overflow     = add_overflow;
            n_add_user.underflow    = add_underflow;
        end
        
        if(pip_stg_ocp[1]) begin
            n_mul_out_latch.dirty   = 1'b1;
            n_mul_out_latch.data    = mul_out;
            
            n_mul_user.overflow     = mul_overflow;
            n_mul_user.underflow    = mul_underflow;
        end 
    end
    
    else begin
        if(pip_stg_ocp[0]) begin
         
            n_add_out_latch.dirty   = 1'b1;
            n_add_out_latch.data    = add_out;
            
            n_mul_out_latch.dirty   = 1'b1;
            n_mul_out_latch.data    = mul_out;
            
            n_add_user.overflow     = add_overflow;
            n_add_user.underflow    = add_underflow;
            
            n_mul_user.overflow     = mul_overflow;
            n_mul_user.underflow    = mul_underflow;
        end
    end
   end
   
   // Can make it parametrizable so that it acts as a Multiply-Accumulate, Multiply, or Add unit
   // Only allowing latched data as output to implement the blocking behaviour
   assign m_axis_result_tuser   = add_user | mul_user;
   assign comp_done             = is_add ? add_out_latch.dirty : mul_out_latch.dirty;
   assign m_axis_result_tdata   = is_add ? add_out_latch.data : mul_out_latch.data;
   
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
      .IS_RSTA_INVERTED(1'b1),           // Optional inversion for RSTA
      .IS_RSTB_INVERTED(1'b1),           // Optional inversion for RSTB
      .IS_RSTC_INVERTED(1'b1),           // Optional inversion for RSTC
      .IS_RSTD_INVERTED(1'b1),           // Optional inversion for RSTD
      .IS_RSTFPA_INVERTED(1'b1),         // Optional inversion for RSTFPA
      .IS_RSTFPINMODE_INVERTED(1'b1),    // Optional inversion for RSTFPINMODE
      .IS_RSTFPMPIPE_INVERTED(1'b1),     // Optional inversion for RSTFPMPIPE
      .IS_RSTFPM_INVERTED(1'b1),         // Optional inversion for RSTFPM
      .IS_RSTFPOPMODE_INVERTED(1'b1),    // Optional inversion for RSTFPOPMODE
      .IS_ASYNC_RST_INVERTED(1'b1),      // Optional Inversion of ASYNC_RST
      // Register Control Attributes: Pipeline Register Configuration
      .ACASCREG(IN_STG_1|IN_STG_2),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .AREG(IN_STG_1+IN_STG_2),          // Pipeline stages for A (0-2)
      .FPA_PREG(ADD_OUT_STG),                      // Pipeline stages for FPA output (0-1)
      .FPBREG(IN_STG_1),                        // Pipeline stages for B inputs (0-1)
      .FPCREG(IN_STG_1),                        // Pipeline stages for C input (0-3)
      .FPDREG(IN_STG_1),                        // Pipeline stages for D inputs (0-1)
      .FPMPIPEREG(MUL_PIP),                    // Selects the number of FPMPIPE registers (0-1)
      .FPM_PREG(MUL_OUT_STG),                      // Pipeline stages for FPM output (0-1)
      .FPOPMREG(FPOPMODE_STG),                      // Selects the length of the FPOPMODE pipeline (0-3)
      .INMODEREG(FPINMODE_STG),                     // Selects the number of FPINMODE registers (0-1)
      .RESET_MODE("ASYNC")                // Selection of synchronous or asynchronous reset. (ASYNC, SYNC).
   )
   DSPFP32_inst (
      // Cascade outputs: Cascade Ports
      .ACOUT_EXP(),         // 8-bit output: A exponent cascade data
      .ACOUT_MAN(),         // 23-bit output: A mantissa cascade data
      .ACOUT_SIGN(),       // 1-bit output: A sign cascade data
      .BCOUT_EXP(),         // 8-bit output: B exponent cascade data
      .BCOUT_MAN(),         // 23-bit output: B mantissa cascade data
      .BCOUT_SIGN(),       // 1-bit output: B sign cascade data
      .PCOUT(),                 // 32-bit output: Cascade output
      // Data outputs: Data Ports
      .FPA_INVALID(add_invalid),     // 1-bit output: Invalid flag for FPA output
      .FPA_OUT(add_out),             // 32-bit output: Adder/accumlator data output in Binary32 format.
      .FPA_OVERFLOW(add_overflow),   // 1-bit output: Overflow signal for adder/accumlator data output
      .FPA_UNDERFLOW(add_underflow), // 1-bit output: Underflow signal for adder/accumlator data output
      .FPM_INVALID(mul_invalid),     // 1-bit output: Invalid flag for FPM output
      .FPM_OUT(mul_out),             // 32-bit output: Multiplier data output in Binary32 format.
      .FPM_OVERFLOW(mul_overflow),   // 1-bit output: Overflow signal for multiplier data output
      .FPM_UNDERFLOW(mul_underflow), // 1-bit output: Underflow signal for multiplier data output
      // Cascade inputs: Cascade Ports
      .ACIN_EXP('b0),           // 8-bit input: A exponent cascade data
      .ACIN_MAN('b0),           // 23-bit input: A mantissa cascade data
      .ACIN_SIGN('b0),         // 1-bit input: A sign cascade data
      .BCIN_EXP('b0),           // 8-bit input: B exponent cascade data
      .BCIN_MAN('b0),           // 23-bit input: B mantissa cascade data
      .BCIN_SIGN('b0),         // 1-bit input: B sign cascade data
      .PCIN('b0),                   // 32-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .CLK(aclk),                     // 1-bit input: Clock
      .FPINMODE(1'b1),           // 1-bit input: Controls select for B/D input data mux.
      .FPOPMODE(fpopmode),           // 7-bit input: Selects input signals to floating-point adder and input
                                     // negation.

      // Data inputs: Data Ports
      .A_EXP(a_dat.exp),                 // 8-bit input: A data exponent
      .A_MAN(a_dat.mantissa),                 // 23-bit input: A data mantissa
      .A_SIGN(a_dat.sign),               // 1-bit input: A data sign bit
      .B_EXP(b_dat.exp),                 // 8-bit input: B data exponent
      .B_MAN(b_dat.mantissa),                 // 23-bit input: B data mantissa
      .B_SIGN(b_dat.sign),               // 1-bit input: B data sign bit
      .C('b0),                         // 32-bit input: C data input in Binary32 format.
      .D_EXP('b0),                 // 8-bit input: D data exponent
      .D_MAN('b0),                 // 23-bit input: D data mantissa
      .D_SIGN('b0),               // 1-bit input: D data sign bit
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .ASYNC_RST(aresetn),         // 1-bit input: Asynchronous reset for all registers.
      .CEA1(1'b1),                   // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(1'b1),                   // 1-bit input: Clock enable for 2nd stage AREG
      .CEB(1'b1),                     // 1-bit input: Clock enable BREG
      .CEC(1'b1),                     // 1-bit input: Clock enable for CREG
      .CED(1'b1),                     // 1-bit input: Clock enable for DREG
      .CEFPA(1'b1),                 // 1-bit input: Clock enable for FPA_PREG
      .CEFPINMODE(1'b1),       // 1-bit input: Clock enable for FPINMODE register
      .CEFPM(1'b1),                 // 1-bit input: Clock enable for FPM output register.
      .CEFPMPIPE(1'b1),         // 1-bit input: Clock enable for FPMPIPE post multiplier register.
      .CEFPOPMODE(1'b1),       // 1-bit input: Clock enable for FPOPMODE post multiplier register.
      .RSTA(aresetn),                   // 1-bit input: Reset for AREG
      .RSTB(aresetn),                   // 1-bit input: Reset for BREG
      .RSTC(aresetn),                   // 1-bit input: Reset for CREG
      .RSTD(aresetn),                   // 1-bit input: Reset for DREG
      .RSTFPA(aresetn),               // 1-bit input: Reset for FPA output register
      .RSTFPINMODE(aresetn),     // 1-bit input: Reset for FPINMODE register
      .RSTFPM(aresetn),               // 1-bit input: Reset for FPM output register
      .RSTFPMPIPE(aresetn),       // 1-bit input: Reset for FPMPIPE register
      .RSTFPOPMODE(aresetn)      // 1-bit input: Reset for FPOPMODE registers
   );

   // End of DSPFP32_inst instantiation
					
endmodule				