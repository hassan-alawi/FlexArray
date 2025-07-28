`ifndef PE_IF_VH
`define PE_IF_VH

`include "dsp_sys_arr_pkg.vh"

`timescale 1ns / 1ps
interface PE_if;
  // import types
  import dsp_sys_arr_pkg::*;
  
  // Interface Signals
  logic         col_in_ready, row_in_ready, col_in_valid, row_in_valid, error_bit;
  logic         col_out_ready, row_out_ready, col_out_valid, row_out_valid, comp_done;
  logic [1:0]   user;
  logic [31:0]  row_in_dat, col_in_dat, accum_sum, row_out_dat, col_out_dat;

  // PE ports
  modport slave (
    input   col_in_valid, row_in_valid, col_out_ready, row_out_ready,
    input   row_in_dat, col_in_dat, 
    output  col_in_ready, row_in_ready, error_bit, col_out_valid, row_out_valid, comp_done,
    output  user, accum_sum, row_out_dat, col_out_dat
  );

  // PE tb
  modport master (
    input   col_in_ready, row_in_ready, error_bit, col_out_valid, row_out_valid, comp_done,
    input   user, accum_sum, row_out_dat, col_out_dat,
    output  col_in_valid, row_in_valid, col_out_ready, row_out_ready, 
    output  row_in_dat, col_in_dat
  );
endinterface

`endif //PE_IF_VH