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
// Description: Using 4xDSP58 slices for FP32 Multiply-Add Units.
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

module dsp_wrapper(
    input logic clk, nrst,
    PE_if.pe peif
    );
    
    // Accumulator Flip Flop
    single_float accumulator, c_dat, out_dat;
    logic c_valid, c_ready, out_valid, out_ready, c_read, n_c_read, n_comp_done;
   
    assign peif.accum_sum = accumulator;
    assign c_dat = accumulator;
    
    always_ff @(posedge clk, negedge nrst) begin
    
        if(~nrst) begin
            accumulator <= 'B0;
            peif.comp_done <= 'B0;
            peif.user <= 'b0;
            c_read <= 'b0;
        end
        
        else begin
            c_read          <= n_c_read;
            peif.user       <= t_user;
            peif.comp_done  <= n_comp_done;
            
            if(out_valid) begin
                accumulator <= out_dat;
            end
            
            else begin
                accumulator <= accumulator;
            end
        end
    end
    
    // FP-32 MAD Signals 
    logic a_valid, a_ready, b_ready, b_valid, a_read, b_read, n_a_read, n_b_read;
    single_float a_dat, b_dat, latched_a_dat, latched_b_dat, n_latched_a_dat, n_latched_b_dat;
    error t_user;
    
    floating_point_0 fp_mad(
    .aclk(clk),
    .aresetn(nrst),
    .s_axis_a_tvalid(a_valid),
    .s_axis_a_tready(a_ready),
    .s_axis_a_tdata(a_dat),
    .s_axis_b_tvalid(b_valid),
    .s_axis_b_tready(b_ready),
    .s_axis_b_tdata(b_dat),
    .s_axis_c_tvalid(c_valid),
    .s_axis_c_tready(c_ready),
    .s_axis_c_tdata(c_dat),
    .m_axis_result_tvalid(out_valid),
    .m_axis_result_tready(out_ready),
    .m_axis_result_tdata(out_dat),
    .m_axis_result_tuser(t_user));
    
    assign a_dat = peif.row_in_dat;
    assign b_dat = peif.col_in_dat;
    
    assign peif.row_out_dat = latched_a_dat;
    assign peif.col_out_dat = latched_b_dat;
    
    assign peif.error_bit = |peif.user; // Expresses whether there has been overflow, bit 1, or underflow, bit 0
    
    always_ff @(posedge clk, negedge nrst) begin
        if(~nrst) begin
            latched_a_dat <= 'B0; // Latched Row Operand
            latched_b_dat <= 'B0; // Latched column operand
            a_read        <= 'B1; // Tracks whether row operand has been read by neighbour
            b_read        <= 'B1; // Tracks whether column operand has been read by neighbour
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
    peif.row_in_ready = 1'B0;
    a_valid = 1'B0;
  
    peif.row_out_valid = ~a_read;
    
    if(peif.row_in_valid & a_ready & a_read) begin
        n_latched_a_dat = peif.row_in_dat;
        n_a_read = 1'B0;
        peif.row_in_ready = 1'B1;
        a_valid = 1'B1;
    end
    
    else if (peif.row_out_valid & peif.row_out_ready) begin
        n_a_read = 1'B1;
        n_latched_a_dat = 'b0;
    end
    
    end
    
    // Latch B Logic
    always_comb begin
    
    n_b_read = b_read;
    n_latched_b_dat = latched_b_dat;
    peif.col_in_ready = 1'B0;
    b_valid = 1'B0;

    peif.col_out_valid = ~b_read;
    
    if(peif.col_in_valid & b_ready & b_read) begin
        n_latched_b_dat = peif.col_in_dat;
        n_b_read = 1'B0;
        peif.col_in_ready = 1'B1;
        b_valid = 1'B1;
    end
    
    else if (peif.col_out_valid & peif.col_out_ready) begin
        n_b_read = 1'B1;
        n_latched_b_dat = 'b0;
    end
    
    end  
    
    // Port C and Result Logic 
    always_comb begin
    c_valid     = 1'B0;
    out_ready   = 1'B0;
    n_c_read    = c_read;
    n_comp_done = peif.comp_done;
    
    if(c_ready & ~c_read) begin // Only feed input into C port if computation has finished or upon startup where we can input a 0 into C port, since prev product is 0
        c_valid = 1'B1;         // As long as the port buffer is ready and we havent already passed an input in, then we can pass in the input
        n_c_read = 1'b1;        // Otherwise if we only depended on c_ready, we run the risk of passing multiple duplicate C operands into the buffer while computation is ongoing
    end
    
    if(out_valid) begin
        out_ready = 1'B1;
        n_c_read = 1'b0;
        n_comp_done = 1'b1;
    end
    
    else if (peif.row_in_valid | peif.col_in_valid | ~a_ready | ~b_ready) begin
        n_comp_done = 1'b0;
    end
    
    end  
       
endmodule
