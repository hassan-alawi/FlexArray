`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/01/2025 04:57:40 PM
// Design Name: 
// Module Name: sys_array
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Systolic Array that multiplies A MxN by B NxK matrix to produce C MxK
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

module sys_array #(parameter M = 2, N = 3, K = 2, IN_STG_1 = 1, IN_STG_2 = 0, MUL_PIP = 1, MUL_OUT_STG = 1, ADD_OUT_STG = 1, FPOPMODE_STG = 1, FPINMODE_STG = 1, MODE = 0)(
input logic clk, nrst,
output logic comp_done, error,
output single_float r1c1_out, r1c2_out, r2c1_out, r2c2_out);

PE_if peifr1c1();
PE_if peifr2c1();
PE_if peifr1c2();
PE_if peifr2c2();

single_float [N-1:0] a_r1, a_r2, b_c1, b_c2, n_a_r1, n_a_r2, n_b_c1, n_b_c2;

logic ar1_strt, bc1_strt, n_ar1_strt, n_bc1_strt;
logic [3:0] r1c1_ctr, n_r1c1_ctr, r2c2_ctr, n_r2c2_ctr;

assign r1c1_out = peifr1c1.accum_sum;
assign r1c2_out = peifr1c2.accum_sum;
assign r2c1_out = peifr2c1.accum_sum;
assign r2c2_out = peifr2c2.accum_sum;


//dsp_wrapper r1c1(clk, nrst, peifr1c1);
//dsp_wrapper r1c2(clk, nrst, peifr1c2);
//dsp_wrapper r2c1(clk, nrst, peifr2c1);
//dsp_wrapper r2c2(clk, nrst, peifr2c2); 

mult_accum_wrapper #(
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
    r1c1(clk, nrst, peifr1c1);
    
mult_accum_wrapper #(
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
    r1c2(clk, nrst, peifr1c2);
    
mult_accum_wrapper #(
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
    r2c1(clk, nrst, peifr2c1);
    
mult_accum_wrapper #(
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
    r2c2(clk, nrst, peifr2c2); 

always_ff @(posedge clk, negedge nrst) begin

    if(~nrst) begin
//        for (logic i=0; i<N; i++) begin
//            a_r1[i] <= $shortrealtobits(1.0 + i);
//            a_r2[i] <= $shortrealtobits(1.0*N + i + 1);
//            b_c1[i] <= $shortrealtobits(1.0 + i*2);;
//            b_c2[i] <= $shortrealtobits(2 + i*2);
//        end
        a_r1 <= {$shortrealtobits(1.0),$shortrealtobits(2.0),$shortrealtobits(3.0)};
        a_r2 <= {$shortrealtobits(4.0),$shortrealtobits(5.0),$shortrealtobits(6.0)};
        b_c1 <= {$shortrealtobits(1.0),$shortrealtobits(2.0),$shortrealtobits(3.0)};
        b_c2 <= {$shortrealtobits(4.0),$shortrealtobits(5.0),$shortrealtobits(6.0)};
        
        ar1_strt <= 1'b1;
        bc1_strt <= 1'b1;
        
        r1c1_ctr <= '0;
        r2c2_ctr <= '0;
    end
    
    else begin
        a_r1 <= n_a_r1;
        a_r2 <= n_a_r2;
        b_c1 <= n_b_c1;
        b_c2 <= n_b_c2;
        
        ar1_strt <= n_ar1_strt;
        bc1_strt <= n_bc1_strt;
        
        r1c1_ctr <= n_r1c1_ctr;
        r2c2_ctr <= n_r2c2_ctr;
    end

end

// Interface Logic
always_comb begin
    // Edge PE connections
    peifr1c1.row_in_valid = 1'b0;
    peifr1c1.col_in_valid = 1'b0;
    peifr1c2.col_in_valid = 1'b0;
    peifr2c1.row_in_valid = 1'b0;
    
    // Edge PEs are have output port ready signals that are connected to any PEs tied to 1
    peifr1c2.row_out_ready = 1'b1;
    peifr2c2.row_out_ready = 1'b1;
    peifr2c2.col_out_ready = 1'b1;
    peifr2c1.col_out_ready = 1'b1;
    
    // Edge PEs whos data inputs are not connected to any PEs are tied to wrapper regs
    peifr1c1.row_in_dat = a_r1[0];
    peifr1c1.col_in_dat = b_c1[0];
    peifr2c1.row_in_dat = a_r2[0];
    peifr1c2.col_in_dat = b_c2[0];
    
    comp_done = peifr1c1.comp_done & peifr1c2.comp_done & peifr2c1.comp_done & peifr2c2.comp_done;
    error = peifr1c1.error_bit & peifr1c2.error_bit & peifr2c1.error_bit & peifr2c2.error_bit;
    
    if(r1c1_ctr != N) begin
        peifr1c1.row_in_valid = 1'b1;
        peifr1c1.col_in_valid = 1'b1;
    end
    
    if(r2c2_ctr != N) begin
        peifr2c1.row_in_valid = ar1_strt;
        peifr1c2.col_in_valid = bc1_strt;
    end
    
    // Internal PE connections
    // R1C1<->R1C2
    peifr1c2.row_in_dat     = peifr1c1.row_out_dat;
    peifr1c2.row_in_valid   = peifr1c1.row_out_valid;
    peifr1c1.row_out_ready  = peifr1c2.row_in_ready;
    
    // R1C1<->R2C1 
    peifr2c1.col_in_dat     = peifr1c1.col_out_dat;
    peifr2c1.col_in_valid   = peifr1c1.col_out_valid;
    peifr1c1.col_out_ready  = peifr2c1.col_in_ready;
    
    // R2C2<->R1C2
    peifr2c2.col_in_dat     = peifr1c2.col_out_dat;
    peifr2c2.col_in_valid   = peifr1c2.col_out_valid;
    peifr1c2.col_out_ready  = peifr2c2.col_in_ready;
    
    // R2C2<->R2C1
    peifr2c2.row_in_dat     = peifr2c1.row_out_dat;
    peifr2c2.row_in_valid   = peifr2c1.row_out_valid;
    peifr2c1.row_out_ready  = peifr2c2.row_in_ready;
end

// Shift Register and Counter Logic Logic
always_comb begin
    n_a_r1 = a_r1;
    n_a_r2 = a_r2;
    n_b_c1 = b_c1;
    n_b_c2 = b_c2;
    
    n_ar1_strt = ar1_strt;
    n_bc1_strt = bc1_strt;
    
    // Counter used so that shift register stops shifting in data after all its operands are in the systolic array
    // Essential so that valid signal goes low and comp_done reg doesnt get inccorectly cleared.
    n_r1c1_ctr = r1c1_ctr;
    n_r2c2_ctr = r2c2_ctr;
    
    // Logic to control when subsequent rows begin shifting in their inputs
//    if(n_r1c1_ctr == 1'd1) begin
//        n_ar1_strt = 1'b1;
//        n_bc1_strt = 1'b1;
//    end
    
    if(peifr1c1.row_in_valid & peifr1c1.row_in_ready & peifr1c1.col_in_valid & peifr1c1.col_in_ready)  begin
        n_a_r1 = a_r1 >> SNGL_FLT_SIZE;
        n_b_c1 = b_c1 >> SNGL_FLT_SIZE;
        n_r1c1_ctr = r1c1_ctr + 'd1;
    end    
    
    if(peifr2c1.row_in_valid & peifr2c1.row_in_ready & peifr1c2.col_in_valid & peifr1c2.col_in_ready)  begin
        n_a_r2 = a_r2 >> SNGL_FLT_SIZE;
        n_b_c2 = b_c2 >> SNGL_FLT_SIZE;
        n_r2c2_ctr = r2c2_ctr + 'd1;
    end  
end
   
endmodule
