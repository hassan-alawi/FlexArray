`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/01/2025 04:57:40 PM
// Design Name: 
// Module Name: sys_array
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Systolic Array that multiplies A MxN by B NxK matrix to produce C MxK
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

// Parameters:
// M : Number of rows for input matrix A 
// N : Number of columns for input matrix A and rows for input matrix B
// K : Number of columns for input matrix B 
// BW : Stream channel bus width in terms of 32 bit words
// IN_STG_1: Input Pipeline Stage infront of A and B Port (0-1)
// IN_STG_2: Second Input Pipeline Stage infront of A (0-1)
// MUL_PIP:  Additional Multiplier Pipeline Stage (0-1)
// MUL_OUT_STG: Register to latch Multiplier output (0-1)
// ADD_OUT_STG: Register to latch Adder output (0-1)
// FPOPMODE_STG: Set of pipeline registers for FPOPMODE Adder Input selection (0-3)
// FPINMODE_STG: Pipeline register infront of FPINMODE input (0-1)

// System Mode of operations: (SYS_MODE)
// AXI_NO_BUFF (0): Systolic array with AXI stream I/O but dispatcher directly interfaces with PEs
// AXI_BUFF(1): Systolic array AXI stream I/O and dispatcher interfaces to input buffers which connect to PEs
// NO_MEM (2): Ideal model of systolic array computation that is purely compute bound (Disables AXI-Stream Interface)

// Modes of Operation 
// 0: Multiply Accumulate 
// 1: Multiply 
// TBD 

module sys_array #(parameter M = 8, N = 2, K = 8, BW = 16, SYS_MODE = 1, IN_STG_1 = 1, IN_STG_2 = 0, MUL_PIP = 1, MUL_OUT_STG = 1, ADD_OUT_STG = 1, FPOPMODE_STG = 1, FPINMODE_STG = 1, MODE = 0)(
input logic clk, nrst,
output logic sys_comp_done,sys_comp_err,
AXI_STREAM_if.slave in_str_if,
AXI_STREAM_if.master out_str_if);

// PE Signals
logic col_in_valid [0:M*K-1], row_in_valid [0:M*K-1], col_out_ready [0:M*K-1], row_out_ready                                            [0:M*K-1];
logic [31:0] row_in_dat [0:M*K-1], col_in_dat                                                                                           [0:M*K-1]; 
logic col_in_ready [0:M*K-1], row_in_ready [0:M*K-1], error_bit [0:M*K-1], col_out_valid [0:M*K-1], row_out_valid [0:M*K-1], comp_done  [0:M*K-1];
error user                                                                                                                              [0:M*K-1];
logic [31:0] row_out_dat [0:M*K-1], col_out_dat                                                                                         [0:M*K-1];
logic [31:0] out                                                                                                                        [0:M*K-1];

// Dispatcher and Collector I/O signals
logic done, err, done_dispatch;
logic edge_col_in_valid [0:K-1], edge_row_in_valid [0:M-1], edge_row_in_ready [0:M-1], edge_col_in_ready [0:K-1];
logic [31:0] edge_col_in_dat[0:K-1], edge_row_in_dat [0:M-1];

/// NO_MEM Model signals and registers
// Matrices Data Registers
logic [N-1:0][31:0] a_r [0:M-1];
logic [N-1:0][31:0] n_a_r [0:M-1];
logic [N-1:0][31:0] b_c [0:K-1];
logic [N-1:0][31:0] n_b_c [0:K-1];

// Per row/column Counters
logic [$clog2(N):0] ctr [0:M+K-1], n_ctr [0:M+K-1]; 


// AXI Stream Interface Buffers and controller
FIFO_if #(.SIZE(M*N + K*N), .BW(BW))   in_fifo_if();
FIFO_if #(.SIZE(M*K), .BW(BW))         out_fifo_if();

fifo #(.SIZE((M*N + K*N)/BW), .BW(BW)) fifo_in(clk, nrst, in_fifo_if);
fifo #(.SIZE((M*K)/BW), .BW(BW)) fifo_out(clk, nrst, out_fifo_if);

assign in_str_if.in_ready    = ~in_fifo_if.is_full & ~done_dispatch; // Only accept data if input FIFO has space and the dispatcher hasn't already passed all of A and B
assign in_fifo_if.push       = in_str_if.in_valid; // Push into Input fifo if valid signal is asserted (if full, FIFO logic prevents it from updating its state)
assign in_fifo_if.dat_in     = in_str_if.in_stream; 

assign out_str_if.out_valid     = ~out_fifo_if.is_empty & sys_comp_done; // Valid is output if the systolic array has finished its computation and output fifo has data to pass on)
assign out_fifo_if.pop          = out_str_if.out_ready & out_str_if.out_valid; // Pop data if recepeint is ready to accept data and if we are ready to give it
assign out_str_if.out_stream    = out_fifo_if.dat_out;

dispatcher #(.M(M), .N(N), .K(K), .BW(BW)) dispatch (clk,nrst,in_fifo_if,edge_col_in_ready,edge_row_in_ready,done_dispatch,
edge_row_in_dat,edge_col_in_dat,edge_col_in_valid,edge_row_in_valid);

collector #(.M(M), .K(K), .BW(BW)) collect (clk,nrst,out_fifo_if,out,done_dispatch,done,err,sys_comp_done,sys_comp_err);

// Systolic Array Buffers
logic push [0:M+K-1], pop [0:M+K-1], is_full [0:M+K-1], is_empty [0:M+K-1];
logic [31:0] dat_in [0:M+K-1], dat_out [0:M+K-1];
logic [$clog2(N):0] ocp [0:M+K-1];

generate 
    for(genvar i = 0; i < M+K; i++) begin
        fifo_wrapper #(.N(N)) sys_buff(
        .clk(clk),
        .nrst(nrst),
        .push(push[i]),
        .pop(pop[i]),
        .dat_in(dat_in[i]),
        .is_full(is_full[i]),
        .is_empty(is_empty[i]),
        .dat_out(dat_out[i]),
        .ocp(ocp[i])
        );
    end
endgenerate

// If we are in AXI_NO_BUFF mode, connect dispatcher I/O signals to systolic array
if (SYS_MODE == 0) begin
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
end

// If we are in AXI_BUFF mode, connect dispatcher I/O signals to buffers, and buffers to systolic array
if(SYS_MODE == 1) begin   
    // Connect Dispatcher to FIFOs
    always_comb begin 
        for(int i=0; i<K; i++) begin
            push[i] = edge_col_in_valid[i];
            dat_in[i] = edge_col_in_dat[i];
            edge_col_in_ready[i] = ~is_full[i]; 
        end
        
        for(int j=0; j<M; j++) begin
            push[j+K] = edge_row_in_valid[j];
            dat_in[j+K] = edge_row_in_dat[j];
            edge_row_in_ready[j] = ~is_full[j+K];  
        end
    end
    
    // Connect FIFOs to systolic array
    always_comb begin 
        for(int i=0; i<K; i++) begin
            col_in_valid[i] = ~is_empty[i];
            col_in_dat[i] = dat_out[i];
            pop[i] = col_in_ready[i]; 
        end
        
        for(int j=0; j<M; j++) begin
            row_in_valid[j*K] = ~is_empty[j+K];
            row_in_dat[j*K] = dat_out[j+K];
            pop[j+K] = row_in_ready[j*K];  
        end
    end
end


generate 

for(genvar i = 0; i < M; i++) begin 
    for(genvar j = 0; j < K; j++) begin 
        dsp_wrapper #(
        .IN_STG_1(IN_STG_1),
        .IN_STG_2(IN_STG_2),
        .MUL_PIP(MUL_PIP),
        .MUL_OUT_STG(MUL_OUT_STG),
        .ADD_OUT_STG(ADD_OUT_STG),
        .FPOPMODE_STG(FPOPMODE_STG),
        .FPINMODE_STG(FPINMODE_STG),
        .MODE(MODE)
        )
        PE (
        .clk(clk), 
        .nrst(nrst), 
        .col_in_valid(col_in_valid[i*K + j]),
        .row_in_valid(row_in_valid[i*K + j]),
        .col_out_ready(col_out_ready[i*K + j]),
        .row_out_ready(row_out_ready[i*K + j]),
        .row_in_dat(row_in_dat[i*K + j]),
        .col_in_dat(col_in_dat[i*K + j]),
        .col_in_ready(col_in_ready[i*K + j]),
        .row_in_ready(row_in_ready[i*K + j]),
        .error_bit(error_bit[i*K + j]),
        .col_out_valid(col_out_valid[i*K + j]),
        .row_out_valid(row_out_valid[i*K + j]),
        .comp_done(comp_done[i*K + j]),
        .out(out[i*K + j]),
        .row_out_dat(row_out_dat[i*K + j]),
        .col_out_dat(col_out_dat[i*K + j]));
    end
end
    
endgenerate

// Register state for NO_MEM model signals and shift registers
if(SYS_MODE == 2) begin
    always_ff @(posedge clk, negedge nrst) begin
    
        if(~nrst) begin
            for(int i=0; i<M; i++) begin
                for(int l=0; l<N; l++) begin
                    a_r[i][l] <= $shortrealtobits(shortreal'(i*N +l+1)); 
                end
            end
            
            for(int i=0; i<K; i++) begin
                for(int l=0; l<N; l++) begin
                    b_c[i][l] <= $shortrealtobits(shortreal'(i*N +l+1)); 
                end
            end
            
            for(int i=0; i<M+K; i++) begin
                ctr[i] <= 'd0;
            end 
        end
        
        else begin
            for(int i=0; i<M; i++) begin
                a_r[i] <= n_a_r[i]; 
            end
            
            for(int i=0; i<K; i++) begin
                b_c[i] <= n_b_c[i];
            end        
            
            for(int i=0; i<M+K; i++) begin
                ctr[i] <= n_ctr[i];
            end 
        end
    
    end
end 

// Interface Logic
always_comb begin
    // Edge PE connections
    // If NO MEM, hook up shift registers to systolic array edge PEs
    if(SYS_MODE==2) begin
        // Row 0 column inputs
        for(int i=0; i<K; i++) begin
            col_in_valid[i] = (ctr[i] == N) ? 1'b0 : 1'b1;
            col_in_dat[i]   = b_c[i][0];
        end
        // Column 0 row inputs
        for(int i=0; i<M; i++) begin
            row_in_valid[i*K]   = (ctr[i+K] == N) ? 1'b0 : 1'b1;
            row_in_dat[i*K]     = a_r[i][0];
        end
    end
    
    // Edge PEs are have output port ready signals that are connected to any PEs tied to 1
    // Column K Row Output Ready 
    for(int i=0; i<M; i++) begin
        row_out_ready[i*K + K-1] = 1'b1;
    end
    
    // Row M Col Output Ready
    for(int i=0; i<K; i++) begin
        col_out_ready[(M-1)*K + i] = 1'b1;
    end
    
    done = 1'b1;
    err = 1'b0;
    
    // Done signal asserted if every PE is done 
    // Err signal asserted if any PE has an error
    for(int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            done   &= comp_done[i*K +j];
            err         |= error_bit[i*K + j];
        end
    end
    
    // Internal PE connections
    for(int i=0; i<M; i++) begin
        for(int j=0; j<K; j++) begin
            if(i==0) begin // Row 0 PEs
                if(~(j == 0)) begin // Ensures Row 0 PEs, that aren't at row 0 col 0, have their row inputs connected to the previous PEs row output
                    row_in_dat[i*K+j]       = row_out_dat[i*K+j-1];
                    row_in_valid[i*K+j]     = row_out_valid[i*K+j-1];
                    row_out_ready[i*K+j-1]  = row_in_ready[i*K+j];
                end
            end
            
            else if(j==0) begin // Col 0 PEs
                if(~(i==0)) begin // Ensures Col 0 PEs, that aren't at row 0 col 0, have their col inputs connected to the previous PEs col output
                    col_in_dat[i*K+j]           = col_out_dat[(i-1)*K+j];
                    col_in_valid[i*K+j]         = col_out_valid[(i-1)*K+j];
                    col_out_ready[(i-1)*K+j]    = col_in_ready[i*K+j];
                end
            end
            
            else begin // Every other PE
                row_in_dat[i*K+j]       = row_out_dat[i*K+j-1];
                row_in_valid[i*K+j]     = row_out_valid[i*K+j-1];
                row_out_ready[i*K+j-1]  = row_in_ready[i*K+j];
                
                col_in_dat[i*K+j]           = col_out_dat[(i-1)*K+j];
                col_in_valid[i*K+j]         = col_out_valid[(i-1)*K+j];
                col_out_ready[(i-1)*K+j]    = col_in_ready[i*K+j];
            end
        end
    end
    
end

if(SYS_MODE==2) begin
// Shift Register and Counter Logic Logic
always_comb begin
    // Counter used so that shift register stops shifting in data after all its operands are in the systolic array
    // Essential so that valid signal goes low and comp_done reg doesnt get inccorectly cleared. 
    for(int i=0; i<M+K; i++) begin
        n_ctr[i] = ctr[i];
    end 
    
    for(int i=0; i<M; i++) begin // Only on rows along column 0
        n_a_r[i] = a_r[i]; 
        if(row_in_valid[i*K+0] & row_in_ready[i*K+0]) begin
            n_a_r[i] = a_r[i] >> SNGL_FLT_SIZE;
            n_ctr[i+K] = ctr[i+K] + 'd1;
        end
    end
    
    for(int i=0; i<K; i++) begin // Only on columns along row 0
        n_b_c[i] = b_c[i];
        if(col_in_valid[i] & col_in_ready[i]) begin
            n_b_c[i] = b_c[i] >> SNGL_FLT_SIZE;
            n_ctr[i] = ctr[i] + 'd1;
        end
    end 
end
end 
 
endmodule
