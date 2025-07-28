`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2025 03:37:15 PM
// Design Name: 
// Module Name: dsp_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Using 1xDSP58 slices for FP32 Multiply-Accumulate Units. Handles operand passing between PEs, and manages control of PE AXI interface
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
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

module dsp_wrapper #(parameter IN_STG_1 = 1, IN_STG_2 = 0, MUL_PIP = 1, MUL_OUT_STG = 1, ADD_OUT_STG = 1, FPOPMODE_STG = 3, FPINMODE_STG = 1, MODE = 0)(
    input logic clk, nrst,
    input logic col_in_valid, row_in_valid, col_out_ready, row_out_ready,
    input word_t row_in_dat, col_in_dat, 
    output logic col_in_ready, row_in_ready, error_bit, col_out_valid, row_out_valid, comp_done,
    output error user, 
    output word_t out, row_out_dat, col_out_dat
    );
    
    // DSP Primimitve Signals
    logic a_valid, a_ready, b_ready, b_valid, a_read, b_read, n_a_read, n_b_read, processing;
    word_t a_dat, b_dat, latched_a_dat, latched_b_dat, n_latched_a_dat, n_latched_b_dat;
    error t_user;
  
    word_t out_dat;
    logic out_valid, out_ready,n_comp_done;
    
    // Stationary Output Registers
    always_ff @(posedge clk, negedge nrst) begin
    
        if(~nrst) begin
            out <= 'B0;
            comp_done <= 'B0;
            user <= 'b0;
        end
        
        else begin
            user       <= t_user | user; // So that any indication of an error is perserved
            comp_done  <= n_comp_done;
            
            if(out_valid) begin
                out <= out_dat;
            end
            
            else begin
                out <= out;
            end
        end
    end 
    

    dsp_prim #(
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
    DSPFP(
    .aclk(clk),
    .aresetn(nrst),
    .s_axis_a_tvalid(a_valid),
    .s_axis_a_tready(a_ready),
    .s_axis_a_tdata(a_dat),
    .s_axis_b_tvalid(b_valid),
    .s_axis_b_tready(b_ready),
    .s_axis_b_tdata(b_dat),
    .m_axis_result_tvalid(out_valid),
    .processing(processing),
    .m_axis_result_tready(out_ready),
    .m_axis_result_tdata(out_dat),
    .m_axis_result_tuser(t_user));
    
    assign a_dat = row_in_dat;
    assign b_dat = col_in_dat;
    
    assign row_out_dat = latched_a_dat;
    assign col_out_dat = latched_b_dat;
    
    assign error_bit = |user; // Expresses whether there has been overflow, bit 1, or underflow, bit 0
    
    always_ff @(posedge clk, negedge nrst) begin
        if(~nrst) begin
            latched_a_dat <= 'B0; // Latched Row Operand
            latched_b_dat <= 'B0; // Latched column operand
            a_read        <= 'B1; // Tracks whether row operand has been read by row neighbour
            b_read        <= 'B1; // Tracks whether column operand has been read by column neighbour
        end
        
        else begin
            latched_a_dat <= n_latched_a_dat;
            latched_b_dat <= n_latched_b_dat;
            a_read        <= n_a_read;
            b_read        <= n_b_read;
        end
    end
    
    // Each operand latch operates independently and passes along the operand as long as respective input buffer is not 
    // full so as to avoid WaR hazard where input buffer doesnt get to see input since it was already written to latch 
    // and potentially passed on to neighbor
    
    // Latch A Logic
    always_comb begin
    n_a_read = a_read;
    n_latched_a_dat = latched_a_dat;
    row_in_ready = 1'b1 & a_read & a_ready; // Input ready signal is idle high unless DSP primitive is not ready or we have unread latched data
    a_valid = 1'B0;
  
    row_out_valid = ~a_read; // x_read signal can be seen as ~dirty bit, so as long as register is not read, then output is valid
    
    // If A latch has been read (or is empty) and DSP Primitive is ready, pass in new valid data to A latch and DSP Primitive 
    if(row_in_valid & a_ready & a_read) begin
        n_latched_a_dat = row_in_dat;
        n_a_read = 1'B0;
        a_valid =  1'B1;
    end
    
    // If neighbor is ready to accept valid output data, then we clear set the read bit and clear the latched data
    else if (row_out_valid & row_out_ready) begin
        n_a_read = 1'B1;
        n_latched_a_dat = 'b0;
    end
    
    end
    
    // Latch B Logic
    always_comb begin
    n_b_read = b_read;
    n_latched_b_dat = latched_b_dat;
    col_in_ready = 1'b1 & b_read & b_ready;
    b_valid = 1'B0;

    col_out_valid = ~b_read;
    
    if(col_in_valid & b_ready & b_read) begin
        n_latched_b_dat = col_in_dat;
        n_b_read = 1'B0;
        b_valid = 1'B1;
    end
    
    else if (col_out_valid & col_out_ready) begin
        n_b_read = 1'B1;
        n_latched_b_dat = 'b0;
    end
    
    end  
    
     // Result Logic 
    always_comb begin
    out_ready   = 1'B0;
    n_comp_done = comp_done;
    
    // If data is valid, assert ready signal to clear DSP output latch and set comp_done
    if(out_valid) begin
        out_ready = 1'B1;
        n_comp_done = 1'b1;
    end
    
    // If accepting new data, or DSP primitive is still waiting on data to pass onto pipeline, 
    // or DSP is still processing its output, comp_done is reset
    else if (row_in_valid | col_in_valid | ~a_ready | ~b_ready | processing) begin
        n_comp_done = 1'b0;
    end
    
    end  
       
endmodule
