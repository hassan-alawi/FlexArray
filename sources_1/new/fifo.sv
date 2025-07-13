`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2025 04:11:20 PM
// Design Name: 
// Module Name: fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Moving head fixed tail implementation for simple hardware
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "FIFO_IF.vh"
`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

module fifo #(parameter SIZE=16)(
input logic clk, nRST,
FIFO_if.fifo fifoif
    );
    
    word_t [SIZE-1:0] fifo, n_fifo;
    logic [$clog2(SIZE)-1:0] ptr, n_ptr;
    logic written, n_written;
    
    assign fifoif.ocp = ({1'b0,ptr}+'d1) & {($clog2(SIZE)+1){written}}; // Need to add signal that checks if write has occured if ptr is at position 0
    assign fifoif.dat_out = fifo[ptr];
    assign fifoif.is_full = fifoif.ocp == SIZE;
    assign fifoif.is_empty = fifoif.ocp == '0;
    
    always_ff @(posedge clk, negedge nRST) begin
        
        if(~nRST) begin
            fifo <= '0;
            ptr <= '0;
            written <= '0;
        end
        
        else begin
            fifo <= n_fifo;
            ptr <= n_ptr;
            written <= n_written;
        end
    
    end
    
    always_comb begin
        n_ptr = ptr;
        n_fifo = fifo;
        n_written = written;
        
        if(fifoif.push & fifoif.pop) begin
           n_written = 1'b1;
           n_fifo[SIZE-1:0] = {fifo[SIZE-2:0],fifoif.dat_in}; 
        end
        
        else if(fifoif.push & ~fifoif.is_full) begin
            n_ptr = fifoif.is_empty ? 'd0 : ptr + 'd1;
            n_written = 1'b1;
            n_fifo[SIZE-1:0] = {fifo[SIZE-2:0],fifoif.dat_in};
        end
        
        else if(fifoif.pop & ~fifoif.is_empty) begin 
            if(fifoif.ocp == 'd1) begin
                n_ptr = 'd0;
                n_written = 1'b0;
                n_fifo[0] = 'd0;
            end
            
            else begin
                n_ptr = ptr -'d1;
            end
        end
    end
    
endmodule
