`ifndef FIFO_IF_VH
`define FIFO_IF_VH

`include "dsp_sys_arr_pkg.vh"
`timescale 1ns / 1ps

interface FIFO_if #(parameter SIZE = 16, BW=1);
  // import types
  import dsp_sys_arr_pkg::*;
  
  // Interface Signals
  logic push, pop, is_full, is_empty;
  logic [BW-1:0] [31:0] dat_in, dat_out;
  logic [$clog2(SIZE):0] ocp;

  // FIFO ports
  modport slave (
    input push, pop, dat_in,
    output is_full, is_empty, dat_out, ocp
  );

  // FIFO master
  modport master (
    output push, pop, dat_in,
    input is_full, is_empty, dat_out, ocp
  );
endinterface

`endif //FIFO_IF_VH