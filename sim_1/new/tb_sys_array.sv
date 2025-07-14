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

parameter M = 2;
parameter N = 3;
parameter K = 4;

parameter IN_STG_1 = 1;
parameter IN_STG_2 = 0;
parameter MUL_PIP = 1;
parameter MUL_OUT_STG = 1;
parameter ADD_OUT_STG = 1;
parameter FPOPMODE_STG = 1;
parameter FPINMODE_STG = 1;
parameter MODE = 0;

logic CLK = 0, nRST;

//Testbench Signals
logic done, error;
single_float out [0:(M*K)-1];

integer num_cycles, en_count, begin_sim;

always #(PERIOD/2) CLK++;

sys_array #(
    .M(M),
    .N(N),
    .K(K),
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
sa(CLK,nRST,done,error,out);

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

task check_mat();

shortreal A [0:M*N];
shortreal B [0:N*K];
shortreal C [0:M*K];

$display("Matrix A %2dx%2d\n",M,N);
for (int i=0; i<M; i++) begin
    for(int j=0; j<N; j++) begin
        A[i*N + j] =  shortreal'(i*N +j+1);
        $write("%f ",A[i*N+j]);
    end
    $display("\n");
end 

$display("Matrix B %2dx%2d\n",N,K);
for (int j=0; j<K; j++) begin
    for(int i=0; i<N; i++) begin
        B[i*K + j] = shortreal'(j*N +i+1);
    end
end 

for (int i=0; i<N; i++) begin
    for(int j=0; j<K; j++) begin
        $write("%f  ",B[i*K + j]);
    end
    $display("\n");
end 

$display("Matrix C %2dx%2d\n",M,K);
for (int i=0; i<M; i++) begin
    for(int j=0; j<K; j++) begin
        C[i*K + j] = dot_product(i,j,A,B);
        $write("%f ",C[i*K+j]);
    end
    $display("\n");
end 


for (int i=0; i<M; i++) begin
    for(int j=0; j<K; j++) begin
        if(out[i*K+j] != $shortrealtobits(C[i*K + j])) begin
            $display("At %d, Incorrect computed value at row %d, column %d. \n Expected %f and got %f\n", $realtime,i+1,j+1,C[i*K + j],$bitstoshortreal(out[i*K+j]));
        end
    end
end

endtask

function shortreal dot_product(
input int a_row,
input int b_col,
input shortreal A [0:M*N],
input shortreal B [0:N*K]
);

automatic shortreal result = 0;
for (int i=0; i<N; i++) begin
    result += A[a_row*N + i] * B[i*K + b_col];
end

return result;
endfunction

function disp_out();
    $display("Systolic Array Out %2dx%2d\n",M,K);
    for (int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            $write("%f ",$bitstoshortreal(out[i*K+j]));
        end
        $display("\n");
    end 
endfunction 

initial begin
    begin_sim = 0;
    #(100 * 1ns);
    begin_sim = 1;
end
    

initial begin
    init_tb();
    wait(begin_sim);
    reset_dut();
    num_cycles = 0;
    en_count = 1;
    
    wait(done);
    
    $display("Finished Computation in %d cycles", num_cycles);  
    check_mat();
    disp_out();
    
    $finish;

end
endmodule
