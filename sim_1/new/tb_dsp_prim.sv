`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2025 02:22:12 PM
// Design Name: 
// Module Name: tb_dsp_prim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "PE_IF.vh"
`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

`timescale 1ns / 100ps
module tb_dsp_prim;

    parameter PERIOD = 1.5;
    parameter VEC_SIZE = 16;
    parameter INPUT_BUFF = 1; // Number of 32 bit FP words that can be buffered at the input buffers before being processed
                              // Would only need to support deeper queues if there is a lot of bursty behaviour in the system
                              // Since compute latency per PE is uniform as confirmed from simulations, we expect equal rate Fetch and Store Requests
                              
    parameter IN_STG_1 = 1;
    parameter IN_STG_2 = 0;
    parameter MUL_PIP = 0;
    parameter MUL_OUT_STG = 0;
    parameter ADD_OUT_STG = 1;
    parameter FPOPMODE_STG = 2;
    parameter FPINMODE_STG = 1;
    parameter MODE = 0;
   
//   parameter LAT = 59 + IN_STG_1 + IN_STG_2 + MUL_PIP + MUL_OUT_STG + ADD_OUT_STG;
//   parameter LAT = 42 + IN_STG_1 + IN_STG_2 + MUL_PIP + MUL_OUT_STG + ADD_OUT_STG; // Baseline Latency is 3 (2 for multiply and 1 for addition with register in between them)
//   parameter CLR_LAT = LAT - ((IN_STG_1 || IN_STG_2) + MUL_PIP + MUL_OUT_STG + ADD_OUT_STG);
//   parameter COLD_START_LAT = 63 + IN_STG_2;
   parameter PIP_LAT = IN_STG_1 + MUL_PIP + MUL_OUT_STG + ADD_OUT_STG;
    
    logic CLK = 0, nRST;
    
    // Test Bench Signals
    integer testcase_num;
    string testcase;
    string testphase;
    
    integer total_testcases;
    integer total_failed_testcases;
    
    logic ex_col_in_ready,ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, ex_comp_done;
    error ex_user;
    single_float ex_accum_sum, ex_row_out_dat, ex_col_out_dat;
    
    single_float test;
    shortreal inter;
    shortreal test_row, test_col, test_sum;
    shortreal test_vector [0:VEC_SIZE];
    error test_user;
    int begin_sim;
    
    logic add_overflow, add_underflow, add_invalid, mul_overflow, mul_underflow, mul_invalid, comp_ready, is_add, comp_done;
    single_float add_out, mul_out, a_dat, b_dat, n_a_dat, n_b_dat;
    dsp_add_conf fpopmode;
    error add_user, mul_user, n_add_user, n_mul_user;
    float_reg a_in, b_in, n_a_in, n_b_in, mul_out_latch, add_out_latch, n_mul_out_latch, n_add_out_latch;
    
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
    
    // clock
    always #(PERIOD/2) CLK++;

    PE_if peif();
    
    assign a_dat = peif.row_in_dat;
    assign b_dat = peif.col_in_dat;

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
      .ACASCREG(IN_STG_1),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
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
      .CLK(CLK),                     // 1-bit input: Clock
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
      .ASYNC_RST(nRST),         // 1-bit input: Asynchronous reset for all registers.
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
      .RSTA(nRST),                   // 1-bit input: Reset for AREG
      .RSTB(nRST),                   // 1-bit input: Reset for BREG
      .RSTC(nRST),                   // 1-bit input: Reset for CREG
      .RSTD(nRST),                   // 1-bit input: Reset for DREG
      .RSTFPA(nRST),               // 1-bit input: Reset for FPA output register
      .RSTFPINMODE(nRST),     // 1-bit input: Reset for FPINMODE register
      .RSTFPM(nRST),               // 1-bit input: Reset for FPM output register
      .RSTFPMPIPE(nRST),       // 1-bit input: Reset for FPMPIPE register
      .RSTFPOPMODE(nRST)      // 1-bit input: Reset for FPOPMODE registers
   );
     
    task init_tb();
        // Initializing Interface Input Signals
        {peif.col_in_valid, peif.row_in_valid, peif.col_out_ready, peif.row_out_ready, peif.row_in_dat, peif.col_in_dat} = 'B0;  
        nRST = 1'b1;  
        
        // Initializing TB Signals
        {ex_col_in_ready,ex_row_in_ready, ex_error_bit, ex_col_out_valid, ex_row_out_valid, ex_accum_sum, ex_row_out_dat, ex_col_out_dat, ex_user, ex_comp_done} = 'B0;
    endtask
    
    task reset_dut();
        @(posedge CLK);
        @(negedge CLK);
        
        nRST = 1'b0;
        
        repeat (2) @(negedge CLK);
        
        nRST = 1'b1;
        
    endtask
    
    task check_outputs(
    input single_float accum_sum
  );

    total_testcases += 1;

	// PE outputs
	if(add_out != accum_sum) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Accumulated Sum during %s testcase in the %s test phase. \n Expected %x and got %x\n", $realtime,testcase, testphase, accum_sum, add_out);
    end

	endtask
    
    function automatic single_float create_single_float(
    input shortreal frac
    );
    
    single_float flt;
    int bits;
   
    bits = $shortrealtobits(frac);
    flt.sign = bits[31];
    flt.exp = bits[30:23];
    flt.mantissa = bits[22:0];
 
    return flt;
    endfunction
    
    initial begin
    begin_sim = 0;
    #(100 * 1ns);
    begin_sim = 1;
    end
    
    
    initial begin
        testcase_num = 0;
        testcase = "Initialization";
        testphase = "Inititization";
        
        total_testcases = 0;
        total_failed_testcases = 0;
        
        test_row = 0;
        test_col = 0;
        test_sum = 0;
        
        test_user = 'b0;
        
        init_tb();
        reset_dut();
        
        // DUT ready to process
        // Inputs port valid
        // Output ports ready
        wait(begin_sim);
        testphase = "Basic Operation";
        
//        // First pass inputs to both ports
//        testcase = "Passing Operands on for all CLR_LAT";
//        test_sum = 0;
//        test_row = 2.0;
//        test_col = 2.5;
        
//        @(posedge CLK);
//        peif.row_in_dat = create_single_float(test_row);
//        peif.col_in_dat = create_single_float(test_col);
        
//        repeat(CLR_LAT) @(posedge CLK);
//        peif.row_in_dat = '0;
//        peif.col_in_dat = '0;
        
//        repeat(LAT - CLR_LAT) @(posedge CLK);
//        #(PERIOD * 0.1);
//        test = (test_row) * (test_col);
//        check_outputs(create_single_float(test));
        
        
//        reset_dut();
//        repeat (5) @(posedge CLK);
        
//        testcase = "Passing Operands on for only first cycle and last 2 cycles of operation";
//        test_sum = 0;
//        test_row = 2.0;
//        test_col = 2.5;
        
//        @(posedge CLK);
//        peif.row_in_dat = create_single_float(test_row);
//        peif.col_in_dat = create_single_float(test_col);
        
//        @(posedge CLK);
//        peif.row_in_dat = '0;
//        peif.col_in_dat = '0;
        
//        repeat(CLR_LAT - 3) @(posedge CLK);
//        peif.row_in_dat = create_single_float(test_row);
//        peif.col_in_dat = create_single_float(test_col);
        
//        repeat(2) @(posedge CLK);
//        peif.row_in_dat = '0;
//        peif.col_in_dat = '0;
        
//        repeat(LAT - CLR_LAT) @(posedge CLK);
//        #(PERIOD * 0.1);
//        test = (test_row) * (test_col);
//        check_outputs(create_single_float(test));
        
        
//        reset_dut();
//        repeat (5) @(posedge CLK);
        
//        testcase = "Passing Operands on for all but one cycle in the middle of operation";
//        test_sum = 0;
//        test_row = 2.0;
//        test_col = 2.5;
        
//        @(posedge CLK);
//        peif.row_in_dat = create_single_float(test_row);
//        peif.col_in_dat = create_single_float(test_col);
        
//        repeat(CLR_LAT/2) @(posedge CLK);
//        peif.row_in_dat = '0;
//        peif.col_in_dat = '0;
        
//        @(posedge CLK);
//        peif.row_in_dat = create_single_float(test_row);
//        peif.col_in_dat = create_single_float(test_col);
        
//        repeat(CLR_LAT/2) @(posedge CLK);
        
//        peif.row_in_dat = '0;
//        peif.col_in_dat = '0;
        
//        repeat(LAT - CLR_LAT) @(posedge CLK);
//        #(PERIOD * 0.1);
//        test = (test_row) * (test_col);
//        check_outputs(create_single_float(test));
        
        
        // First pass inputs to both ports
//        repeat(COLD_START_LAT) @(posedge CLK);
        
        testcase = "Passing Operands on for all CLR_LAT after LAT wait period";
        test_sum = 0;
        test_row = 2.0;
        test_col = 2.5;
        test_sum +=  test_col * test_row;
        test_vector[0] = test_sum;
        
        @(posedge CLK);
        peif.row_in_dat = create_single_float(test_row);
        peif.col_in_dat = create_single_float(test_col);
        
        if(PIP_LAT == 0) begin 
            #(PERIOD * 0.1);
            ex_accum_sum = create_single_float(test_vector[0]);
            check_outputs(ex_accum_sum);
        end
        
        @(posedge CLK);
        test_row = 5.0;
        test_col = 6.5;
        test_sum +=  test_col * test_row;
        
        test_vector[1] = test_sum;
        
        peif.row_in_dat = create_single_float(test_row);
        peif.col_in_dat = create_single_float(test_col);
        
        if(PIP_LAT == 0) begin 
            #(PERIOD * 0.1);
            ex_accum_sum = create_single_float(test_vector[1]-test_vector[0]);
            check_outputs(ex_accum_sum);
        end
        
        if(PIP_LAT == 1 && ADD_OUT_STG == 0) begin 
            #(PERIOD * 0.1);
            ex_accum_sum = create_single_float(test_vector[0]);
            check_outputs(ex_accum_sum);
        end
        
        @(posedge CLK);
        peif.row_in_dat = '0;
        peif.col_in_dat = '0;
        
        if(PIP_LAT == 1 && ADD_OUT_STG == 0) begin 
            #(PERIOD * 0.1);
            ex_accum_sum = create_single_float(test_vector[1]-test_vector[0]);
            check_outputs(ex_accum_sum);
        end
        
        if(PIP_LAT == 2 && ADD_OUT_STG == 0) begin 
            #(PERIOD * 0.1);
            ex_accum_sum = create_single_float(test_vector[0]);
            check_outputs(ex_accum_sum);
        end
        
        
        if(PIP_LAT == 3) begin 
            @(posedge CLK);
        end
        
        else begin
            repeat(PIP_LAT-2) @(posedge CLK);
        end
        
        if(PIP_LAT != 0 && PIP_LAT != 1) begin
            if(PIP_LAT == 2 && ADD_OUT_STG == 0) begin
                #(PERIOD * 0.1);
                ex_accum_sum = create_single_float(test_vector[1]-test_vector[0]);
                check_outputs(ex_accum_sum);
            end
            
            else begin
                #(PERIOD * 0.1);
                ex_accum_sum = create_single_float(test_vector[0]);
                check_outputs(ex_accum_sum);
                
                @(posedge CLK);
                #(PERIOD * 0.1);
                if(ADD_OUT_STG == 0) begin 
                    ex_accum_sum = create_single_float(test_vector[1] - test_vector[0]);
                end
                else begin
                    ex_accum_sum = create_single_float(test_vector[1]);
                end
                check_outputs(ex_accum_sum);
            end
        end
        
        
        repeat(5) @(posedge CLK);
       
                 
        $display("Testcases Failed/Total Testcases: %d/%d",total_failed_testcases, total_testcases);
        $finish();
    
    end

endmodule
