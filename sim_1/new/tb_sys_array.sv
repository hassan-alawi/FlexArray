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

parameter BW = 256; // Must be power of 2 (min 2)
parameter NUM_STRM_IN = 1; // Represents how many stream inputs of width BW needed to pass in whole column of A + row of B

//`ifndef BW
//    `define BW 50
//`endif

//`ifndef NUM_STRM_IN
//    `define NUM_STRM_IN 1
//`endif

//localparam int BW = `BW;
//localparam int NUM_STRM_IN = `NUM_STRM_IN;

parameter BW_SCALE = shortreal'(NUM_STRM_IN)/2;

parameter M = int'(BW*BW_SCALE);
parameter N = 4;
parameter K = M;

parameter NO_MEM    = 1;
parameter MEM_LAT   = 0;

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
shortreal A [0:M*N-1];
shortreal B [0:N*K-1];
shortreal C [0:M*K-1];
single_float OUT [0:M*K-1];

word_t [BW-1:0] test_in;
int outer_ctr, inner_ctr;
int passed_all_input;


integer num_cycles, en_count, begin_sim;

always #(PERIOD/2) CLK++;

AXI_STREAM_if #(.BW(BW)) axi_str_if();

sys_array #(
    .M(M),
    .N(N),
    .K(K),
    .BW(BW),
    .NO_MEM(NO_MEM),
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
sa(CLK,nRST,axi_str_if);

task init_tb();
    nRST = 1'b1;
    
    {axi_str_if.in_stream,axi_str_if.in_valid,axi_str_if.out_ready} = '0;
    test_in = 'd0;
endtask


always begin
    @(posedge CLK);
    if(en_count) num_cycles++;
end

task reset_dut();
    @(posedge CLK);
    @(negedge CLK);
    
    nRST = 1'b0;
    
    repeat (2) @(negedge CLK);
    
    nRST = 1'b1;
    
endtask




function void setup_mat();

$display("Matrix A %2dx%2d\n",M,N);
for (int i=0; i<M; i++) begin
    for(int j=0; j<N; j++) begin
        A[i*N + j] = (i*N +j+1);
        $write("%f ",A[i*N+j]);
    end
    $display("\n");
end 

$display("Matrix B %2dx%2d\n",N,K);
for (int j=0; j<K; j++) begin
    for(int i=0; i<N; i++) begin
        B[i*K + j] = (j*N +i+1);
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
endfunction







function int check_mat();
automatic int passed = 1;

for (int i=0; i<M; i++) begin
    for(int j=0; j<K; j++) begin
        if(NO_MEM) begin
            if(sa.out[i*K+j] != $shortrealtobits(C[i*K + j])) begin
                $display("At %d, Incorrect computed value at row %d, column %d. \n Expected %f and got %f\n", $realtime,i+1,j+1,C[i*K + j],$bitstoshortreal(sa.out[i*K+j]));
                passed = 0;
            end
        end
        
        else begin 
            if(OUT[i*K+j] != $shortrealtobits(C[i*K + j])) begin
                $display("At %d, Incorrect computed value at row %d, column %d. \n Expected %f and got %f\n", $realtime,i+1,j+1,C[i*K + j],$bitstoshortreal(OUT[i*K+j]));
                passed = 0;
            end
        end
    end
end

return passed;
endfunction

function shortreal dot_product(
input int a_row,
input int b_col,
input shortreal A [0:M*N-1],
input shortreal B [0:N*K-1]
);

automatic shortreal result = 0;
for (int i=0; i<N; i++) begin
    result += A[a_row*N + i] * B[i*K + b_col];
end

return result;
endfunction

function void disp_out();
    $display("Systolic Array Out %2dx%2d\n",M,K);
    for (int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            if(NO_MEM) begin
                $write("%f ",$bitstoshortreal(sa.out[i*K+j]));
            end
            
            else begin
                $write("%f ",$bitstoshortreal(OUT[i*K+j]));
            end
        end
        $display("\n");
    end 
endfunction 


task stream_push();
    // Begin of stream computation
    for(int j=0; j<NUM_STRM_IN*N; j++) begin
        
        for(int i=0; i<BW/2; i++) begin
            test_in[i*2]   = $shortrealtobits(A[(i+outer_ctr)*N + (N-inner_ctr-1)]);
            test_in[(2*i)+1] = $shortrealtobits(B[((N-inner_ctr-1)*K) + i+outer_ctr]); 
        end
       
        axi_str_if.in_valid = 1'b1;
        axi_str_if.in_stream = test_in;
       
        outer_ctr += BW/2;
    
        if(outer_ctr == M) begin 
            outer_ctr = 0;
            inner_ctr += 1;
        end
        
        if(inner_ctr == N) begin
            passed_all_input = 1;
        end
        
        @(negedge CLK);
        
        if(MEM_LAT) begin
            axi_str_if.in_valid = 1'b0;
            axi_str_if.in_stream = 'd0;
            
            repeat(MEM_LAT) @(negedge CLK);
        end
    end
    
    // Finish Streaming Input 
    axi_str_if.in_valid = 1'b0;
    axi_str_if.in_stream = 'd0;
endtask 


task stream_pop(input int comp_done = 1);
    
    for (int j=0; j<K; j+=2) begin
        for(int i=0; i<M; i+=BW/2) begin 
            
            for(int l=0; l<BW/2; l++) begin
                OUT[(i+l)*K + j] = axi_str_if.out_stream[l];
                OUT[(i+l)*K + (j+1)] = axi_str_if.out_stream[l+BW/2];
            end
            
            axi_str_if.out_ready = 1'b1;
            
            @(negedge CLK);
        end
    end
    
    axi_str_if.out_ready = 1'b0;
endtask 

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
    
    
    setup_mat();
    if(!NO_MEM) begin
        stream_push();
        wait(axi_str_if.out_valid);
        @(negedge CLK);
        stream_pop(); 
    end  
    
    else begin
        wait(sa.done);
    end
    
    $display("\n\n\n\n/////////////////////////////////////////////////////////");
    $display("Computation Results");
    $display("/////////////////////////////////////////////////////////");
    $display("Succesfull Computation: %s",check_mat() ? "True" : "False");
    $display("Finished Computation in %d cycles", num_cycles);
    $display("Floating Point Operations done: %d", M*K*N);
    $display("System Throughput (Assuming period of %.2f ns): %.2f GFLOPS", PERIOD, (shortreal'(M*K*N)/(PERIOD*num_cycles)));    
    $display("\n");
    disp_out();
    
    $finish;

end
endmodule
