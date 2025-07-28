`ifndef AXI_STREAM_IF_VH
`define AXI_STREAM_IF_VH

`include "dsp_sys_arr_pkg.vh"

`timescale 1ns / 1ps
interface AXI_STREAM_if #(parameter BW=2);
  // import types
  import dsp_sys_arr_pkg::*;
  
  // Interface Signals
  logic                 in_valid, in_ready, out_valid, out_ready;
  logic [BW-1:0] [31:0]      in_stream, out_stream;

  // AXI_STREAM Input ports
  modport slave (
    input in_valid,
    input in_stream,
    output in_ready
  );
  
  // AXI_STREAM Output ports
  modport master (
    input out_ready,
    output out_valid,
    output out_stream
  );
endinterface

`endif //AXI_STREAM_IF_VH