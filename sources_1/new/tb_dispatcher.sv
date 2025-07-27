`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/16/2025 03:58:17 PM
// Design Name: 
// Module Name: tb_dispatcher
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
`include "AXI_STREAM_IF.vh"
`include "FIFO_IF.vh"
`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

module tb_dispatcher;

parameter PERIOD = 1.5;

parameter BW = 4; // Must be power of 2 (min 2)
parameter NUM_STRM_IN = 2; // Represents how many stream inputs of width BW needed to pass in whole column of A and row of B
parameter BW_SCALE = shortreal'(NUM_STRM_IN)/2;

parameter M = int'(BW*BW_SCALE);
parameter N = 3;
parameter K = M;

logic CLK = 0, nRST;

// Test Bench Signals
integer testcase_num;
string testcase;
string testphase;


integer total_testcases;
integer total_failed_testcases;

logic ex_in_ready, ex_out_valid, ex_done, ex_err;
word_t [BW-1:0] ex_out_stream; 

logic ex_row_in_valid [0:M*K-1], ex_col_in_valid[0:M*K-1];
single_float ex_row_in_dat [0:M*K-1], ex_col_in_dat [0:M*K-1];

int outer_ctr, inner_ctr;
int passed_all_input;

word_t [1:0] outer_ctr_hist = '1;
word_t [1:0] [BW-1:0] in_dat_hist = '1;

word_t [BW-1:0] test_in;

int A [0:M*N-1];
int B [0:N*K-1];
int C [0:M*K-1];

// System Signals
logic done,err;
logic col_in_ready [0:M*K-1], row_in_ready [0:M*K-1], col_in_valid [0:M*K-1], row_in_valid [0:M*K-1];
word_t row_in_dat [0:M*K-1], col_in_dat [0:M*K-1], out [0:M*K-1];

logic edge_col_in_valid [0:K-1], edge_row_in_valid [0:M-1], edge_row_in_ready [0:M-1], edge_col_in_ready [0:K-1];
single_float edge_col_in_dat[0:K-1], edge_row_in_dat [0:M-1];

always_comb begin 
    for(int i=0; i<K; i++) begin
        col_in_valid[i] = edge_col_in_valid[i];
        col_in_dat[i] = edge_col_in_dat[i];
        edge_col_in_ready[i] = col_in_ready[i]; 
    end
    
    for(int j=0; j<M; j++) begin
        row_in_valid[j*K] = edge_row_in_valid[j];
        row_in_dat[j*K] = edge_row_in_dat[j];
        edge_row_in_ready[j] = row_in_ready[j*K];  
    end
end

AXI_STREAM_if #(.BW(BW)) axi_str_if();

FIFO_if #(.SIZE(M*N + K*N), .BW(BW))   in_fifo_if();
FIFO_if #(.SIZE(M*K), .BW(BW))         out_fifo_if();

fifo #(.SIZE((M*N + K*N)/BW), .BW(BW)) fifo_in(CLK, nRST, in_fifo_if);
fifo #(.SIZE((M*K)/BW), .BW(BW)) fifo_out(CLK, nRST, out_fifo_if);

dispatcher #(.M(M), .N(N), .K(K), .BW(BW)) dispatch (CLK,nRST,axi_str_if,in_fifo_if,out_fifo_if,
done,err,edge_col_in_ready,edge_row_in_ready,out,edge_row_in_dat,edge_col_in_dat,edge_col_in_valid,edge_row_in_valid);

always #(PERIOD/2) CLK++;

task check_outputs(
    input logic in_ready, out_valid,
    input word_t [BW-1:0] out_stream,
    input logic ex_row_in_valid [0:M*K-1], ex_col_in_valid [0:M*K-1],
    input single_float ex_row_in_dat [0:M*K-1], ex_col_in_dat [0:M*K-1],
    input logic ex_done,ex_err, 
    input int check_in_ready = 1
  );

    total_testcases += 2 + BW + 4*M*K;
		
	// AXI-Interface
    if((axi_str_if.in_ready != in_ready) && check_in_ready) begin
      total_failed_testcases += 1;
      $display("At %f, Incorrect AXI in_ready signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, in_ready, axi_str_if.in_ready);
    end
    
    if(axi_str_if.out_valid != out_valid) begin
      total_failed_testcases += 1;
      $display("At %f, Incorrect AXI out_valid signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, out_valid, axi_str_if.out_valid);
    end
    
    if(axi_str_if.done != ex_done) begin
      total_failed_testcases += 1;
      $display("At %f, Incorrect AXI done signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, ex_done, axi_str_if.done);
    end
    
    if(axi_str_if.err != ex_err) begin
      total_failed_testcases += 1;
      $display("At %f, Incorrect AXI err signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, testcase, testphase, ex_err, axi_str_if.err);
    end
   
    for(int k=0; k<BW; k++) begin
        if(axi_str_if.out_stream[k] != out_stream[k]) begin
          total_failed_testcases += 1;
          $display("At %f, Incorrect AXI Out stream bus at index %d signal during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, k, testcase, testphase, out_stream[k], axi_str_if.out_stream[k]);
        end
    end
    
    
    // Dispatcher Outputs
    
    for(int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            if(ex_row_in_valid[i*K+j] != row_in_valid[i*K+j]) begin
              total_failed_testcases += 1;
              $display("At %f, Incorrect row in valid signal at row %2d col %2d signal \n during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, i,j, testcase, testphase, ex_row_in_valid[i*K+j], row_in_valid[i*K+j]);
            end
            
            if(ex_col_in_valid[i*K+j] != col_in_valid[i*K+j]) begin
              total_failed_testcases += 1;
              $display("At %f, Incorrect col in valid signal at row %2d col %2d signal \n during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, i,j, testcase, testphase, ex_col_in_valid[i*K+j], col_in_valid[i*K+j]);
            end
            
            if(ex_row_in_dat[i*K+j] != row_in_dat[i*K+j]) begin
              total_failed_testcases += 1;
              $display("At %f, Incorrect row in dat signal at row %d2 col %2d signal \n during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, i,j, testcase, testphase, ex_row_in_dat[i*K+j], row_in_dat[i*K+j]);
            end
            
            if(ex_col_in_dat[i*K+j] != col_in_dat[i*K+j]) begin
              total_failed_testcases += 1;
              $display("At %f, Incorrect col in dat signal at row %2d col %2d signal \n during %s testcase in the %s test phase. \n Expected %d and got %d\n", $realtime, i,j, testcase, testphase, ex_col_in_dat[i*K+j], col_in_dat[i*K+j]);
            end
        end
    end

endtask






task init_tb();
    nRST = 1'b1;
    
    {axi_str_if.in_stream,axi_str_if.in_valid,axi_str_if.out_ready,done,err} = '0;
    test_in = 'd0;
    for(int i=0; i<M*K; i++) begin
        row_in_ready[i] = '0;
        col_in_ready[i] = '0;
        out[i]          = '0;
    end
endtask

task reset_dut();
    @(posedge CLK);
    @(negedge CLK);
    
    nRST = 1'b0;
    
    repeat (2) @(negedge CLK);
    
    nRST = 1'b1;
    
endtask







task setup_mat();

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

endtask

function int dot_product(
input int a_row,
input int b_col,
input int A [0:M*N],
input int B [0:N*K]
);

automatic int result = 0;
for (int i=0; i<N; i++) begin
    result += A[a_row*N + i] * B[i*K + b_col];
end

return result;
endfunction









task single_push(
input word_t [BW-1:0] in_dat,
input int ready = 1
);
    ex_in_ready = ~passed_all_input;
    ex_out_valid = 1'b0;
    ex_out_stream = '0;
    
    for(int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            ex_row_in_valid[i*K+j] = 1'b0;
            ex_col_in_valid[i*K+j] = 1'b0;
            ex_row_in_dat[i*K+j] = 'd0;
            ex_col_in_dat[i*K+j] = 'd0;
        end
    end
    
    check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
    ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,1'b0,1'b0);
    
    axi_str_if.in_valid = 1'b1;
    axi_str_if.in_stream = in_dat;
    
    @(negedge CLK); // Pushed into buffer
    
    axi_str_if.in_valid = 1'b0;
    axi_str_if.in_stream = 'd0;
    
    // Setup Ready signals 
    for(int i=0; i<BW/2; i++) begin   
       row_in_ready[(outer_ctr+i) * K]  = ready;
       col_in_ready[outer_ctr+i]        = ready;
    end
    
    @(negedge CLK); // Pushed into dispatch register
    
    if(!passed_all_input) begin
        // Set Expected values 
        for(int i=0; i<BW/2; i++) begin   
           ex_row_in_valid[(outer_ctr+i)*K]   = ready ? 1'b1 : '0;
           ex_row_in_dat[(outer_ctr+i)*K]     = ready ? in_dat[i*2] : '0; 
           
           ex_col_in_valid[outer_ctr+i]       = ready ? 1'b1 : '0;
           ex_col_in_dat[outer_ctr+i]         = ready ? in_dat[(i*2)+1] : '0;
        end
    end
    
    else begin
        for(int i=0; i<BW/2; i++) begin   
           ex_row_in_valid[(outer_ctr+i)*K]   = 1'b0;
           ex_row_in_dat[(outer_ctr+i)*K]     = 'd0; 
           
           ex_col_in_valid[outer_ctr+i]       = 1'b0;
           ex_col_in_dat[outer_ctr+i]         = 'd0;
        end
    end
    
    check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
    ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,1'b0,1'b0);
    
    @(negedge CLK); // Done dispatch
    
    // Disable inputs
    for(int i=0; i<BW/2; i++) begin   
       row_in_ready[(outer_ctr+i) * K]  = 1'b0;
       col_in_ready[outer_ctr+i]        = 1'b0;
    end 
       // Set Expected values 
    for(int i=0; i<BW/2; i++) begin   
       ex_row_in_valid[(outer_ctr+i)*K]   = 'b0;
       ex_row_in_dat[(outer_ctr+i)*K]     = 'd0; 
       
       ex_col_in_valid[outer_ctr+i]       = 'b0;
       ex_col_in_dat[outer_ctr+i]         = 'd0; 
    end
    
    outer_ctr += BW/2;
    
    if(outer_ctr == M) begin 
        outer_ctr = 0;
        inner_ctr += 1;
    end
    
    if(inner_ctr == N) begin
        passed_all_input = 1;
    end
    
    ex_in_ready = ~passed_all_input;
    
    check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
    ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,1'b0,1'b0);
    
endtask



task stream_push();
    ex_in_ready = 1'b1;
    ex_out_valid = 1'b0;
    ex_out_stream = '0;
    
    for(int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            ex_row_in_valid[i*K+j] = 1'b0;
            ex_col_in_valid[i*K+j] = 1'b0;
            ex_row_in_dat[i*K+j] = 'd0;
            ex_col_in_dat[i*K+j] = 'd0;
        end
    end
    
    check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
    ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,1'b0,1'b0);
    
    // Begin of stream computation
    for(int j=0; j<NUM_STRM_IN*N; j++) begin
        
        for(int i=0; i<BW/2; i++) begin
            test_in[i*2]   = A[(i+outer_ctr)*N + (N-inner_ctr-1)];
            test_in[(2*i)+1] = B[((N-inner_ctr-1)*K) + i+outer_ctr]; 
        end
        
        // Setup Ready signals 
        for(int i=0; i<BW/2; i++) begin   
           row_in_ready[(outer_ctr+i) * K]  = 1'b1;
           col_in_ready[outer_ctr+i]        = 1'b1;
        end
        
        axi_str_if.in_valid = 1'b1;
        axi_str_if.in_stream = test_in;
        
        if(outer_ctr_hist[1] != '1) begin // Input has reached end of pipeline and is at the dispatch register
            // Set Expected values 
            for(int i=0; i<BW/2; i++) begin   
               ex_row_in_valid[(outer_ctr_hist[1]+i)*K]   = 1'b1;
               ex_row_in_dat[(outer_ctr_hist[1]+i)*K]     = in_dat_hist[1][i*2]; 
               
               ex_col_in_valid[outer_ctr_hist[1]+i]       = 1'b1;
               ex_col_in_dat[outer_ctr_hist[1]+i]         = in_dat_hist[1][(i*2)+1];
            end
            
            check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
            ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,1'b0,1'b0);
            
            for(int i=0; i<BW/2; i++) begin   
               ex_row_in_valid[(outer_ctr_hist[1]+i)*K]   = 1'b0;
               ex_row_in_dat[(outer_ctr_hist[1]+i)*K]     = 'd0; 
               
               ex_col_in_valid[outer_ctr_hist[1]+i]       = 1'b0;
               ex_col_in_dat[outer_ctr_hist[1]+i]         = 'd0;
            end
        end
        
        outer_ctr_hist = {outer_ctr_hist[0],outer_ctr};
        in_dat_hist    = {in_dat_hist[0],test_in};
        
        outer_ctr += BW/2;
    
        if(outer_ctr == M) begin 
            outer_ctr = 0;
            inner_ctr += 1;
        end
        
        if(inner_ctr == N) begin
            passed_all_input = 1;
        end
        
        @(negedge CLK);
    end
    
    // Finish Streaming Input 
    axi_str_if.in_valid = 1'b0;
    axi_str_if.in_stream = 'd0;
    
    // Check remaining outputs 
    while(outer_ctr_hist[1] != '1) begin 
        for(int i=0; i<BW/2; i++) begin   
           ex_row_in_valid[(outer_ctr_hist[1]+i)*K]   = 1'b1;
           ex_row_in_dat[(outer_ctr_hist[1]+i)*K]     = in_dat_hist[1][i*2]; 
           
           ex_col_in_valid[outer_ctr_hist[1]+i]       = 1'b1;
           ex_col_in_dat[outer_ctr_hist[1]+i]         = in_dat_hist[1][(i*2)+1];
        end
        
        check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
        ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,1'b0,1'b0);
        
        for(int i=0; i<BW/2; i++) begin   
           ex_row_in_valid[(outer_ctr_hist[1]+i)*K]   = 1'b0;
           ex_row_in_dat[(outer_ctr_hist[1]+i)*K]     = 'd0; 
           
           ex_col_in_valid[outer_ctr_hist[1]+i]       = 1'b0;
           ex_col_in_dat[outer_ctr_hist[1]+i]         = 'd0;
        end
        
        outer_ctr_hist = {outer_ctr_hist[0],{WORD_W{1'b1}}};
        in_dat_hist    = {in_dat_hist[0],{BW*WORD_W{1'b1}}};
        
        @(negedge CLK);
    end
    
    // Disable inputs
    for(int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            row_in_ready[i*K +j]  = 1'b0;
            col_in_ready[i*K +j]  = 1'b0;
        end
    end
    
    // Set Expected values 
    for(int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            ex_row_in_valid[i*K+j] = 1'b0;
            ex_col_in_valid[i*K+j] = 1'b0;
            ex_row_in_dat[i*K+j] = 'd0;
            ex_col_in_dat[i*K+j] = 'd0;
        end
    end
    
    ex_in_ready = 1'b0;
    
    check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
    ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,1'b0,1'b0);
    
    
endtask






task done_comp();  
    done = 1'b1;
     
    @(negedge CLK);
    done = 1'b0;
     
    for (int i=0; i<M; i++) begin
       for(int j=0; j<K; j++) begin
           out[i*K + j] = C[i*K + j];
       end
    end 
    
    repeat (M*BW_SCALE) @(negedge CLK);
endtask 







task stream_pop(input int comp_done = 1);
    ex_done = comp_done;
    
    for (int j=0; j<K; j+=2) begin
        for(int i=0; i<M; i+=BW/2) begin 
            ex_out_valid = comp_done;
            
            for(int l=0; l<BW/2; l++) begin
                ex_out_stream[l] = comp_done ? C[(i+l)*K + j] : '0;
                ex_out_stream[l+BW/2] = comp_done ?  C[(i+l)*K + (j+1)] : '0;
            end
            
            axi_str_if.out_ready = 1'b1;
            
            check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
            ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,ex_done,1'b0);
            
            @(negedge CLK);
        end
    end
    
    ex_out_valid = 1'b0;
    ex_out_stream = '0;
    
    axi_str_if.out_ready = 1'b0;
    
    check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
    ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,ex_done,1'b0);
    
    ex_done = 1'b0;
endtask





task pulse_error();
    ex_err = 1'b1;
    
    err = 1'b1;
    
    @(negedge CLK);
    
    err = 1'b0;
    
    @(negedge CLK);
    
    check_outputs(ex_in_ready, ex_out_valid, ex_out_stream,
    ex_row_in_valid,ex_col_in_valid,ex_row_in_dat,ex_col_in_dat,ex_done,ex_err,0);
    
    ex_err = 1'b0;
endtask





initial begin
    testcase_num = 0;
    testcase = "Initialization";
    testphase = "Inititization";
    
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    
    total_testcases = 0;
    total_failed_testcases = 0;
    
    init_tb();
    setup_mat();
    reset_dut();
    
    repeat (5) @(posedge CLK);
    
    testphase = "Passing Inputs";
    // Pass Single Input 
    testcase = "Passing Single Input";
    for(int i=0; i<BW/2; i++) begin
        test_in[i*2]   = A[(i+outer_ctr)*N + (N-inner_ctr-1)];
        test_in[(2*i)+1] = B[((N-inner_ctr-1)*K) + i+outer_ctr]; 
    end
    
    @(negedge CLK);
    single_push(test_in);
    
    // Pass Multiple discontigous Inputs
    reset_dut();
    testcase = "Series of Single Inputs";
    
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    
    // Passing in whole A and B matrix
    @(negedge CLK);
    for(int j=0; j<NUM_STRM_IN*N; j++) begin
        for(int i=0; i<BW/2; i++) begin
            test_in[i*2]   = A[(i+outer_ctr)*N + (N-inner_ctr-1)];
            test_in[(2*i)+1] = B[((N-inner_ctr-1)*K) + i+outer_ctr]; 
        end
        
        single_push(test_in);
    end
    
    @(negedge CLK);
    // Pass Stream of Inputs 
    reset_dut();
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    testcase = "Stream of Inputs";
    
    @(negedge CLK);
    stream_push();
    
    // Push when and one PE not ready
    reset_dut();
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    testcase = "Push when PE not ready";
    
    @(negedge CLK);
    
    for(int i=0; i<BW/2; i++) begin
        test_in[i*2]   = A[(i+outer_ctr)*N + (N-inner_ctr-1)];
        test_in[(2*i)+1] = B[((N-inner_ctr-1)*K) + i+outer_ctr]; 
    end
    
    single_push(test_in,0);
    @(negedge CLK);
    
    // Pass Input after all data was passed
    reset_dut();
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    testcase = "Pass after Dispatch done";
    
    @(negedge CLK);
    stream_push();
    
    @(negedge CLK);
    inner_ctr = 0;
    outer_ctr = 0;
    for(int i=0; i<BW/2; i++) begin
        test_in[i*2]   = A[(i+outer_ctr)*N + (N-inner_ctr-1)];
        test_in[(2*i)+1] = B[((N-inner_ctr-1)*K) + i+outer_ctr]; 
    end
    
    single_push(test_in);
    
    
    // Pass Outputs
    testphase = "Reading Outputs"; 
    reset_dut();
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    testcase = "Passing Outputs to dispatch unit";
    
    @(negedge CLK);
    stream_push();
    
    @(negedge CLK);
    done_comp();
    
    // Read Outputs from Output Buffer
    testcase = "Reading Outputs from buffer";
    @(negedge CLK);
    stream_pop();
    
    // Read after input passed in but comp was not done
    reset_dut();
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    testcase = "Reading when comp not done";
    
    @(negedge CLK);
    stream_push();
    
    @(negedge CLK);
    stream_pop(0);
    
    // Check err signal
    reset_dut();
    inner_ctr = 0;
    outer_ctr = 0;
    passed_all_input = 0;
    testcase = "Checking Error Latch";
    
    @(negedge CLK);
    pulse_error();
    
    repeat (2) @(negedge CLK);
    
    $display("Testcases Failed/Total Testcases: %d/%d",total_failed_testcases, total_testcases);
    $finish();
end

endmodule
