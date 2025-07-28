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
// Description: Circular Pointer based FIFO for simple hardware
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

module fifo #(parameter SIZE=16, BW = 2)(
input logic clk, nRST,
FIFO_if.slave fifoif
    );
    
    word_t [SIZE-1:0] [BW-1:0]  fifo, n_fifo;
    logic [$clog2(SIZE)-1:0] w_ptr, n_w_ptr, r_ptr, n_r_ptr;
    logic written, n_written;
    logic [$clog2(SIZE):0] n_ocp;
    
    assign fifoif.dat_out = fifoif.is_empty ? 'd0 : fifo[r_ptr];
    assign fifoif.is_full = fifoif.ocp == SIZE;
    assign fifoif.is_empty = fifoif.ocp == '0;
    
    always_ff @(posedge clk, negedge nRST) begin
        
        if(~nRST) begin
            fifo <= '0; // Register array with BW * WORD_W size registers
            w_ptr <= '0; // Write pointer to indicate where next write should be
            r_ptr <= '0; // Read pointer to indicate which is next in que to be read
            fifoif.ocp <= '0; // Indicates FIFO occupancy
        end
        
        else begin
            fifo <= n_fifo;
            w_ptr <= n_w_ptr;
            r_ptr <= n_r_ptr;
            fifoif.ocp <= n_ocp;
        end
    
    end
    
    always_comb begin
        n_w_ptr = w_ptr;
        n_r_ptr = r_ptr;
        n_fifo = fifo;
        n_ocp = fifoif.ocp;
        
        // Simultaneous Push and Pop
        if(fifoif.push & fifoif.pop) begin
           n_fifo[w_ptr] = fifoif.dat_in;
           
           if(fifoif.is_empty) begin
               n_ocp = fifoif.ocp + 'd1;
               n_w_ptr = (w_ptr + 'd1) % SIZE; // Wrap around logic for ptr
           
           end
           
           else begin
                 n_w_ptr = (w_ptr + 'd1) % SIZE;
                 n_r_ptr = (r_ptr + 'd1) % SIZE;
           end
        end
        
        else if(fifoif.push & ~fifoif.is_full) begin
           n_fifo[w_ptr] = fifoif.dat_in;
           n_ocp = fifoif.ocp + 'd1;
           n_w_ptr = (w_ptr + 'd1) % SIZE;
        end
        
        else if(fifoif.pop & ~fifoif.is_empty) begin 
            n_ocp = fifoif.ocp - 'd1;
            n_fifo[r_ptr] = 'd0;
            n_r_ptr = (r_ptr + 'd1) % SIZE;
        end
    end
    
endmodule
