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
`include "PE_IF.vh"
`include "dsp_sys_arr_pkg.vh"
import dsp_sys_arr_pkg::*;

module sys_array #(parameter M = 2, N = 3, K = 2, IN_STG_1 = 1, IN_STG_2 = 0, MUL_PIP = 1, MUL_OUT_STG = 1, ADD_OUT_STG = 1, FPOPMODE_STG = 1, FPINMODE_STG = 1, MODE = 0)(
input logic clk, nrst,
output logic done, err,
output single_float out [0:(M*K)-1]);

// PE Signals
logic col_in_valid [0:M*K-1], row_in_valid [0:M*K-1], col_out_ready [0:M*K-1], row_out_ready                                           [0:M*K-1];
single_float row_in_dat [0:M*K-1], col_in_dat                                                                                          [0:M*K-1]; 
logic col_in_ready [0:M*K-1], row_in_ready [0:M*K-1], error_bit [0:M*K-1], col_out_valid [0:M*K-1], row_out_valid [0:M*K-1], comp_done [0:M*K-1];
error user                                                                                                                             [0:M*K-1];
single_float accum_sum [0:M*K-1], row_out_dat [0:M*K-1], col_out_dat                                                                   [0:M*K-1];

// Matrices Data Registers
single_float [N-1:0] a_r [0:M-1],n_a_r [0:M-1];
single_float [N-1:0] b_c [0:K-1],n_b_c [0:K-1];

// Per row/column Counters
logic [$clog2(N)-1:0] ctr [0:M+K-1], n_ctr [0:M+K-1];

always_comb begin
    for(int i=0; i<M; i++) begin 
        for(int j=0; j<K; j++) begin
            out[i*K +j] = accum_sum[i*K +j]; 
        end
    end
end

generate 

for(genvar i = 0; i < M; i++) begin 
    for(genvar j = 0; j < K; j++) begin 
        mult_accum_wrapper #(
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
        .accum_sum(accum_sum[i*K + j]),
        .row_out_dat(row_out_dat[i*K + j]),
        .col_out_dat(col_out_dat[i*K + j]));
    end
end
    
endgenerate

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

// Interface Logic
always_comb begin
    // Edge PE connections
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
                if(~(j == 0)) begin
                    row_in_dat[i*K+j]       = row_out_dat[i*K+j-1];
                    row_in_valid[i*K+j]     = row_out_valid[i*K+j-1];
                    row_out_ready[i*K+j-1]  = row_in_ready[i*K+j];
                end
            end
            
            else if(j==0) begin // Col 0 PEs
                if(~(i==0)) begin
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
        if(row_in_valid[i] & row_in_ready[i]) begin
            n_b_c[i] = b_c[i] >> SNGL_FLT_SIZE;
            n_ctr[i] = ctr[i] + 'd1;
        end
    end 
end
   
endmodule
