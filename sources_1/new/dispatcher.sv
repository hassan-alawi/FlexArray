`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2025 11:48:51 AM
// Design Name: 
// Module Name: dispatcher
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Dispatches input data to systolic array and fills output buffer with final computation result
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "AXI_STREAM_IF.vh"
`include "FIFO_IF.vh"
`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

module dispatcher #(parameter M = 2, N = 3, K = 2, BW = 2)(
    input logic clk, nrst,
    FIFO_if.master in_fifo_if,
    input logic col_in_ready [0:K-1], row_in_ready [0:M-1],
    output logic done_dispatch,
    output word_t row_in_dat [0:M-1], col_in_dat [0:K-1], 
    output logic col_in_valid [0:K-1], row_in_valid [0:M-1]
    );
    
    // Assumptions 
    // Model : Interleaved (a_i_j)->(b_j_i)->(a_i+1_j)->(b_j_i+1)
    // Matrix shape : M = K, and M+K are multiples of BW (M = K/2 * BW, where K>0)
    // BW : Multiple of 2 * 32 bits (minimumn of BW=2)
    
    holding_reg [BW-1:0] dispatch_regs, n_dispatch_regs;
    logic [$clog2(M):0] inner_ctr,n_inner_ctr; // Counts which column of A and which row of B we are on 
    logic [$clog2(M):0] outer_ctr,n_outer_ctr; // Counts which row of A and which column of B we are on
    
    logic n_done_dispatch;
    logic row_ready, col_ready;
    logic valid; // Checks to see if valid signal is asserted
    logic fill_cond;
    
    logic outer_ctr_roll, inner_ctr_roll;
    
    always_ff @(posedge clk, negedge nrst) begin
        if(~nrst) begin
            dispatch_regs <= '0; // Hold data to be passed along to edge PEs
            inner_ctr    <= '0; // Counts which along the N dimension (which column of A and row of B we are on)
            outer_ctr    <= '0; // Counts which along the M dimension (which row of A and column of B we are on)
            done_dispatch <= '0; // Latches when all rows of A and columns of B are shifted into the systolic array
        end
        
        else begin
            dispatch_regs <= n_dispatch_regs;
            inner_ctr    <= n_inner_ctr;
            outer_ctr    <= n_outer_ctr;
            done_dispatch <= n_done_dispatch;
        end
    end
    
    // Condition to fill dispatch registers with fresh data
    // If Input FIFO has data and dispatcher is not done dispatching data
    /// If dispatch registers are empty or Systollic array accepted our current batch of data
    
    //// I don't know why but if we put these signals in the always_comb block, it breaks. So don't.
    assign fill_cond = (~dispatch_regs[0].dirty | (valid & row_ready & col_ready)) & (~in_fifo_if.is_empty & ~done_dispatch);
    assign valid = row_in_valid[outer_ctr]; // Checks to see if output valid signals for current batch of rows and columns are asserted
    
    always_comb begin
    // Default Values
        n_dispatch_regs     = dispatch_regs;
        in_fifo_if.pop      = 1'b0;
        n_done_dispatch     = done_dispatch;
        
        row_ready = 1'b1;
        col_ready = 1'b1;
        
        outer_ctr_roll = outer_ctr == M-BW/2; // Rollover flag for outer counter (We increment by BW/2 when draining the input buffer)
        inner_ctr_roll = inner_ctr == N-1; // Rollover flag for inner counter
        
        n_inner_ctr         = inner_ctr;
        n_outer_ctr         = outer_ctr;
        
        for(int i=0; i<M; i++) begin
            row_in_valid[i] = '0;
            row_in_dat[i]   = '0;
        end
        
        for(int i=0; i<K; i++) begin
            col_in_valid[i] = '0;
            col_in_dat[i]   = '0;
        end
        
        // Check that all row and column edge PEs are ready to recieve 
        // If any PE in the current batch is not then dispatcher halts 
        for(int i=0; i<BW/2; i++) begin      
           row_ready = row_ready & row_in_ready[outer_ctr+i];
           col_ready = col_ready & col_in_ready[outer_ctr+i];
        end
        
        // Filling dispatch registers
        if(fill_cond) begin
            in_fifo_if.pop = 1'b1;
            for(int i=0; i<BW; i++) begin
                n_dispatch_regs[i].data   = in_fifo_if.dat_out[i];
                n_dispatch_regs[i].dirty  = 1'b1; 
            end
        end
        
        // Dispatching operation
        if(dispatch_regs[0].dirty) begin
            if(row_ready & col_ready) begin
                // On every cycle where all the current selection of edge PEs are ready to receieve data
                // BW/2 rows, and BW/2 columns datums are passed to their associated edge PE
                for(int i=0; i<BW/2; i++) begin      
                   row_in_valid[outer_ctr+i]   = 1'b1;
                   row_in_dat[outer_ctr+i]     = dispatch_regs[i<<1].data; 
                   
                   col_in_valid[outer_ctr+i]            = 1'b1;
                   col_in_dat[outer_ctr+i]              = dispatch_regs[(i<<1)+1].data;
                end
               
                n_outer_ctr = outer_ctr_roll ? 'd0 : outer_ctr + BW/2;
                n_inner_ctr = inner_ctr_roll&outer_ctr_roll ? 'd0 : outer_ctr_roll ? inner_ctr + 'd1 : inner_ctr;
                
                if(in_fifo_if.is_empty) begin //Only clear when input fifo is empty
                    n_dispatch_regs[BW-1:0] = 'd0;
                    n_dispatch_regs[BW-1:0] = 'd0;
                end
                
                // Latching done dispatch signal to know that it is safe to start filling output buffer
                if((inner_ctr_roll) & (outer_ctr_roll)) begin
                    n_done_dispatch = 1'b1;
                end
            end
        end
   
    end

    
endmodule
