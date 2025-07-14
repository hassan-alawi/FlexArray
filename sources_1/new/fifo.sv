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

module fifo #(parameter SIZE=16)(
input logic clk, nRST,
FIFO_if.fifo fifoif
    );
    
    word_t [SIZE-1:0] fifo, n_fifo;
    logic [$clog2(SIZE)-1:0] w_ptr, n_w_ptr, r_ptr, n_r_ptr;
    logic written, n_written;
    logic [$clog2(SIZE):0] n_ocp;
    
    assign fifoif.dat_out = fifoif.is_empty ? 'd0 : fifo[r_ptr];
    assign fifoif.is_full = fifoif.ocp == SIZE;
    assign fifoif.is_empty = fifoif.ocp == '0;
    
    always_ff @(posedge clk, negedge nRST) begin
        
        if(~nRST) begin
            fifo <= '0;
            w_ptr <= '0;
            r_ptr <= '0;
            fifoif.ocp <= '0;
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
        
        if(fifoif.push & fifoif.pop) begin
           n_fifo[w_ptr] = fifoif.dat_in;
           
           if(fifoif.is_empty) begin
               n_ocp = fifoif.ocp + 'd1;
                
//               if({1'b0,w_ptr} +'d1 == SIZE) begin
//                n_w_ptr = 'd0;
//               end
//               else begin
               n_w_ptr = (w_ptr + 'd1) % SIZE;
//               end
           
           end
           
           else begin
//               if({1'b0,w_ptr} +'d1 == SIZE) begin
//                    n_w_ptr = 'd0;
//               end
//               else begin
                 n_w_ptr = (w_ptr + 'd1) % SIZE;
//               end
               
//               if({1'b0,r_ptr} +'d1 == SIZE) begin
//                    n_r_ptr = 'd0;
//               end
//               else begin
                n_r_ptr = (r_ptr + 'd1) % SIZE;
//               end
           end
        end
        
        else if(fifoif.push & ~fifoif.is_full) begin
           n_fifo[w_ptr] = fifoif.dat_in;
           n_ocp = fifoif.ocp + 'd1;
           
//           if({1'b0,w_ptr} +'d1 == SIZE) begin
//            n_w_ptr = 'd0;
//           end
           
//           else begin
            n_w_ptr = (w_ptr + 'd1) % SIZE;
//           end
        end
        
        else if(fifoif.pop & ~fifoif.is_empty) begin 
            n_ocp = fifoif.ocp - 'd1;
            n_fifo[r_ptr] = 'd0;
            
//           if({1'b0,r_ptr} +'d1 == SIZE) begin
//            n_r_ptr = 'd0;
//           end
           
//           else begin
            n_r_ptr = (r_ptr + 'd1) % SIZE;
//           end
        end
    end
    
endmodule
