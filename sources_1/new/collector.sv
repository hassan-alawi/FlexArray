`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2025 01:52:32 PM
// Design Name: 
// Module Name: collector
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


module collector #(parameter M = 2, K = 2, BW = 2)(
    input logic clk, nrst,
    FIFO_if.master out_fifo_if,
    input logic [31:0] out [0:M*K-1],
    input logic done_dispatch, done, err,
    output logic sys_comp_done, sys_comp_err
    );
    
    logic [$clog2(K):0] inner_ctr,n_inner_ctr; 
    logic [$clog2(M):0] outer_ctr,n_outer_ctr; 
    
    logic outer_ctr_roll, inner_ctr_roll;
    
    logic n_fill_done, n_error, fill_done,n_done;
    
    always_ff @(posedge clk, negedge nrst) begin
        if(~nrst) begin
            inner_ctr       <= '0; // Counts which along the K dimension (which column of C)
            outer_ctr       <= '0; // Counts which along the M dimension (which row of C)
            sys_comp_done   <= '0; // Latched when done signal from systolic array is active
            sys_comp_err    <= '0; // Latched when err signal from systolic array is active
            fill_done       <= '0; // Latched when all data from the systolic array output has been put into the output buffer
        end
        
        else begin
            inner_ctr       <= n_inner_ctr;
            outer_ctr       <= n_outer_ctr;
            sys_comp_done   <= n_done;
            sys_comp_err    <= n_error;
            fill_done       <= n_fill_done;
        end
    end
    
    always_comb begin
    n_done              = done ? 1'b1 : sys_comp_done;
    n_error             = err ? 1'b1 : sys_comp_err;
    
    out_fifo_if.push    = 1'b0;
    out_fifo_if.dat_in  = '0;
    
    outer_ctr_roll = outer_ctr == M-BW/2;
    inner_ctr_roll = inner_ctr == K-2;
    
    n_inner_ctr = inner_ctr;
    n_outer_ctr = outer_ctr;
    
    n_fill_done = fill_done;
    
    // Output Collection operation 
    // Start collecting data when done signal is latched, we are done dispatching, and if we have not finished filling the output buffer
    if(done_dispatch & sys_comp_done & ~fill_done) begin       
        out_fifo_if.push = 1'b1;
        
        // On every cycle, BW/2 datums from 2 adajacent columns, selected by inner counter, are pushed to the output FIFO
        for(int i=0; i<BW/2; i++) begin
            out_fifo_if.dat_in[i]       = out[((i+outer_ctr)*K) + inner_ctr];
            out_fifo_if.dat_in[i+BW/2]  = out[((i+outer_ctr)*K) + (inner_ctr+1)];
        end
     
        
        n_outer_ctr = outer_ctr_roll ? 'd0 : outer_ctr + BW/2;
        n_inner_ctr = inner_ctr_roll&outer_ctr_roll ? 'd0 : outer_ctr_roll ? inner_ctr + 'd2 : inner_ctr;
        
        // Fill is done once the counters both rollover
        if(inner_ctr_roll & outer_ctr_roll) begin
            n_fill_done = 1'b1;
        end
    end 
    end 
endmodule
