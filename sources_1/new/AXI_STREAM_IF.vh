`ifndef AXI_STREAM_IF_VH
`define AXI_STREAM_IF_VH

`include "dsp_sys_arr_pkg.vh"

`timescale 1ns / 1ps
interface AXI_STREAM_if #(parameter BW=2);
  // import types
  import dsp_sys_arr_pkg::*;
  
  // Interface Signals
  logic                 in_valid, in_ready, out_valid, out_ready;
  logic                 done, err;
  word_t [BW-1:0]       in_stream, out_stream;

  // AXI_STREAM Input ports
  modport in (
    input in_valid,
    input in_stream,
    output in_ready
  );
  
  // AXI_STREAM Output ports
  modport out (
    input out_ready,
    output out_valid,
    output out_stream
  );

  // AXI_STREAM Master ports
  modport master (
    input out_valid, in_ready,
    input out_stream,
    input done, err,
    output in_valid, out_ready,
    output in_stream
  );
endinterface

`endif //AXI_STREAM_IF_VH