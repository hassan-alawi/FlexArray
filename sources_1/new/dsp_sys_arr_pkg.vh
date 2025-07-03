`ifndef DSP_SYS_ARR_PKG_VH
`define DSP_SYS_ARR_PKG_VH

package dsp_sys_arr_pkg;

  // word width and size
  parameter WORD_W          = 32;
  parameter WBYTES          = WORD_W/8;
  
  parameter EXP_W           = 8;
  parameter MNTSA_W         = 24-1; // Top bit ommited and assumed to be constant 1 i.e. 1.xxxxxxx
  
  parameter SNGL_FLT_SIZE   = MNTSA_W + EXP_W + 1;

// word_t
  typedef logic [WORD_W-1:0] word_t;

// FP-32 format types
  typedef struct packed {
	logic sign;
	logic [EXP_W - 1:0] exp;
	logic [MNTSA_W - 1:0] mantissa;
  } single_float;
  
// IP Error Format
  typedef struct packed {
	logic overflow;
	logic underflow;
  } error;

endpackage
`endif //DSP_SYS_ARR_PKG_VH