`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/02/2025 03:37:44 PM
// Design Name: 
// Module Name: tb_sys_array
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

module tb_sys_array;

parameter PERIOD = 1.5;

logic CLK = 0, nRST;

//Testbench Signals
logic comp_done, error;
single_float r1c1_out, r1c2_out, r2c1_out, r2c2_out;

integer num_cycles, en_count;

always #(PERIOD/2) CLK++;

sys_array sa(CLK,nRST,comp_done,error,r1c1_out, r1c2_out, r2c1_out, r2c2_out);

task init_tb();
    nRST = 1'b1;  
endtask

always begin
    @(CLK);
    if(en_count) num_cycles++;
end

task reset_dut();
    @(posedge CLK);
    @(negedge CLK);
    
    nRST = 1'b0;
    
    repeat (2) @(negedge CLK);
    
    nRST = 1'b1;
    
endtask

initial begin
    init_tb();
    reset_dut();
    num_cycles = 0;
    en_count = 1;
    
    wait(comp_done);
    
    $display("Finished Computation in %d cycles", num_cycles);
    $display("Output Array:\n %f   %f\n %f   %f",$bitstoshortreal(r1c1_out), $bitstoshortreal(r1c2_out), $bitstoshortreal(r2c1_out), $bitstoshortreal(r2c2_out));
    
    $finish;

end
endmodule
