`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2025 04:57:18 PM
// Design Name: 
// Module Name: tb_fifo
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
`include "FIFO_IF.vh"
`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

module tb_fifo;

parameter PERIOD = 1.5;
parameter SIZE = 16;

logic CLK = 0, nRST;

// Test Bench Signals
integer testcase_num;
string testcase;
string testphase;

integer total_testcases;
integer total_failed_testcases;

logic ex_is_full, ex_is_empty;
logic [$clog2(SIZE):0] ex_ocp;
word_t ex_dat_out;

int inter;
word_t test;
int test_vector [0:2*SIZE];

always #(PERIOD/2) CLK++;

FIFO_if #(.SIZE(SIZE)) fifoif();

fifo #(.SIZE(SIZE)) DUT (CLK,nRST,fifoif);

task init_tb();
    {fifoif.dat_in, fifoif.push, fifoif.pop} = '0;
    nRST = 1'b1;  
endtask

task check_outputs(
    input logic is_full, is_empty,
    input logic [$clog2(SIZE):0] ocp,
    input word_t dat_out
  );

    total_testcases += 4;
		
	// Input Neighbor Ports 
    if(fifoif.is_full != is_full) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect is_full signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, is_full, fifoif.is_full);
    end
    
    if(fifoif.is_empty != is_empty) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect is_empty signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, is_empty, fifoif.is_empty);
    end

    if(fifoif.ocp != ocp) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Occupancy signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, ocp, fifoif.ocp);
    end
    
    if(fifoif.dat_out != dat_out) begin
      total_failed_testcases += 1;
      $display("At %d, Incorrect Data Out signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, dat_out, fifoif.dat_out);
    end

	endtask

task reset_dut();
    @(posedge CLK);
    @(negedge CLK);
    
    nRST = 1'b0;
    
    repeat (2) @(negedge CLK);
    
    nRST = 1'b1;
    
endtask 

task push(input word_t dat_in);
@(negedge CLK);
fifoif.push = 1'b1;
fifoif.dat_in = dat_in;

@(negedge CLK);
fifoif.push = 1'b0;
fifoif.dat_in = '0;
endtask

task pop();
@(negedge CLK);
fifoif.pop = 1'b1;

@(negedge CLK);
fifoif.pop = 1'b0;
endtask 

task push_pop(input word_t dat_in);
@(negedge CLK);
fifoif.push = 1'b1;
fifoif.pop = 1'b1;
fifoif.dat_in = dat_in;

@(negedge CLK);
fifoif.push = 1'b0;
fifoif.pop = 1'b0;
fifoif.dat_in = '0;
endtask


initial begin
testcase_num = 0;
testcase = "Initialization";
testphase = "Inititization";

total_testcases = 0;
total_failed_testcases = 0;

test = 0;

for(int i=0; i<2*SIZE; i++) begin
    test_vector[i] = i+1;
end

init_tb();
reset_dut();

testphase   = "Basic Operation";
testcase    = "Single Push and Pop";

ex_is_full  = 1'b0;
ex_is_empty = 1'b1;
ex_ocp      = 'd0;
ex_dat_out  = 'b0;

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

test = test_vector[0];
push(test);

ex_is_full  = 1'b0;
ex_is_empty = 1'b0;
ex_ocp      = 'd1;
ex_dat_out  = test_vector[0];

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

pop();

ex_is_full  = 1'b0;
ex_is_empty = 1'b1;
ex_ocp      = 'd0;
ex_dat_out  = 'd0;

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

reset_dut();
testphase = "Burst Operation";
testcase = "Stream till full";

for(int i=0; i<SIZE; i++)begin
    ex_is_full  = 1'b0;
    ex_is_empty = i==0 ? 1'b1 : 1'b0;
    ex_ocp      = i;
    ex_dat_out  = i == 0 ? '0 : test_vector[0];
    
    check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);
    
    test = test_vector[i];
    push(test);
    
    ex_is_full  = i == SIZE-1 ? 1'b1 : 1'b0;
    ex_is_empty = 1'b0;
    ex_ocp      = i+1;
    ex_dat_out  = test_vector[0];
    
    check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);
end

testcase = "Drain till empty";

for(int i=SIZE-1; i>=0; i--)begin
    ex_is_full  = i == SIZE-1 ? 1'b1 : 1'b0;
    ex_is_empty = 1'b0;
    ex_ocp      = i+1;
    ex_dat_out  = i == SIZE-1 ? test_vector[0] : test_vector[SIZE-1-i];
    
    check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);
    
    pop();
    
    ex_is_full  = 1'b0;
    ex_is_empty = i == 0 ? 1'b1 :1'b0;
    ex_ocp      = i;
    ex_dat_out  = i == 0 ? 'd0 : test_vector[SIZE-i];
    
    check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);
end

reset_dut();
testphase = "Error Checking";
testcase = "Simultaneous Push and Pop when empty";

ex_is_full  = 1'b0;
ex_is_empty = 1'b1;
ex_ocp      = 'd0;
ex_dat_out  = 'd0;

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

test = test_vector[0];
push_pop(test);

ex_is_full  = 1'b0;
ex_is_empty = 1'b0;
ex_ocp      = 'd1;
ex_dat_out  = test_vector[0];

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);


reset_dut();
testcase = "Simultaneous Push and Pop when full";
for(int i=0; i<SIZE; i++)begin
    test = test_vector[i];
    push(test);
end

ex_is_full  = 1'b1;
ex_is_empty = 1'b0;
ex_ocp      = SIZE;
ex_dat_out  = test_vector[0];

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

test = test_vector[SIZE];
push_pop(test);

ex_is_full  = 1'b1;
ex_is_empty = 1'b0;
ex_ocp      = SIZE;
ex_dat_out  = test_vector[1];

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

for(int i=0; i<SIZE-1; i++)begin
    pop();
end

ex_is_full  = 1'b0;
ex_is_empty = 1'b0;
ex_ocp      = 'd1;
ex_dat_out  = test_vector[SIZE];

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

pop();

ex_is_full  = 1'b0;
ex_is_empty = 1'b1;
ex_ocp      = 'd0;
ex_dat_out  = 'd0;

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

reset_dut();
testcase = "Push when FIFO full";
for(int i=0; i<SIZE; i++)begin
    test = test_vector[i];
    push(test);
end
//
ex_is_full  = 1'b1;
ex_is_empty = 1'b0;
ex_ocp      = SIZE;
ex_dat_out  = test_vector[0];

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

test = test_vector[SIZE];
push(test);

ex_is_full  = 1'b1;
ex_is_empty = 1'b0;
ex_ocp      = SIZE;
ex_dat_out  = test_vector[0];

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

reset_dut();
testcase = "Pop when FIFO empty";

ex_is_full  = 1'b0;
ex_is_empty = 1'b1;
ex_ocp      = 'd0;
ex_dat_out  = 'd0;

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

pop();

ex_is_full  = 1'b0;
ex_is_empty = 1'b1;
ex_ocp      = 'd0;
ex_dat_out  = 'd0;

check_outputs(ex_is_full, ex_is_empty, ex_ocp, ex_dat_out);

         
$display("Testcases Failed/Total Testcases: %d/%d",total_failed_testcases, total_testcases);
$finish();

end
endmodule
