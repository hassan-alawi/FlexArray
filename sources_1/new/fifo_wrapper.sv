`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2025 05:29:25 PM
// Design Name: 
// Module Name: fifo_wrapper
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


module fifo_wrapper #(parameter N=2)(
    input logic clk, nrst,
    input logic push, pop, 
    input logic [31:0] dat_in,
    output logic is_full, is_empty, 
    output logic [31:0] dat_out,
    output logic [$clog2(N):0] ocp
    );
    
    FIFO_if #(.SIZE(N), .BW(1))         fifo_if();
    
    assign fifo_if.push = push;
    assign fifo_if.pop = pop;
    assign is_full = fifo_if.is_full;
    assign is_empty = fifo_if.is_empty;
    assign fifo_if.dat_in = dat_in;
    assign dat_out = fifo_if.dat_out;
    assign ocp = fifo_if.ocp;
    
    fifo #(.SIZE((N)), .BW(1)) fifo_in(clk, nrst, fifo_if);
endmodule
