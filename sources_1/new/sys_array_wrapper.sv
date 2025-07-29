`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2025 01:11:13 PM
// Design Name: 
// Module Name: sys_array_wrapper
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


module sys_array_wrapper #(parameter M = 2, N = 2, K = 2, BW = 2, SYS_MODE = 1, IN_STG_1 = 1, IN_STG_2 = 0, MUL_PIP = 1, 
MUL_OUT_STG = 1, ADD_OUT_STG = 1, FPOPMODE_STG = 1, FPINMODE_STG = 1, MODE = 0,  C_S_AXI_CONTROL_ADDR_WIDTH = 12 , C_S_AXI_CONTROL_DATA_WIDTH = 32)
(input logic clk, nrst,
// Input AXI-Stream slave interface
input logic in_valid,
input logic [BW-1:0] [31:0] in_stream,
output logic in_ready,

// Output AXI-Stream master interface
input logic out_ready,
output logic out_valid,
output [BW-1:0] [31:0] out_stream,

// AXI4-Lite slave interface
input  wire                                    s_axi_control_awvalid,
output wire                                    s_axi_control_awready,
input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr ,
input  wire                                    s_axi_control_wvalid ,
output wire                                    s_axi_control_wready ,
input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata  ,
input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb  ,
input  wire                                    s_axi_control_arvalid,
output wire                                    s_axi_control_arready,
input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr ,
output wire                                    s_axi_control_rvalid ,
input  wire                                    s_axi_control_rready ,
output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata  ,
output wire [2-1:0]                            s_axi_control_rresp  ,
output wire                                    s_axi_control_bvalid ,
input  wire                                    s_axi_control_bready ,
output wire [2-1:0]                            s_axi_control_bresp  ,
output wire                                    interrupt);


logic ap_done, ap_err;

assign in_str_if.in_valid   = in_valid;
assign in_str_if.in_stream  = in_stream;
assign in_ready             = in_str_if.in_ready;

assign out_str_if.out_ready = out_ready;
assign out_stream           = out_str_if.out_stream;
assign out_valid            = out_str_if.out_valid;

AXI_STREAM_if #(.BW(BW)) in_str_if();
AXI_STREAM_if #(.BW(BW)) out_str_if();

sys_array #(
    .M(M),
    .N(N),
    .K(K),
    .BW(BW),
    .SYS_MODE(SYS_MODE),
    .IN_STG_1(IN_STG_1),
    .IN_STG_2(IN_STG_2),
    .MUL_PIP(MUL_PIP),
    .MUL_OUT_STG(MUL_OUT_STG),
    .ADD_OUT_STG(ADD_OUT_STG),
    .FPOPMODE_STG(FPOPMODE_STG),
    .FPINMODE_STG(FPINMODE_STG),
    .MODE(MODE)
    )
sa(clk,nrst,ap_done,ap_err,in_str_if,out_str_if);

control_s_axi #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .ACLK      ( clk                ),
  .ARESET    ( 1'b0                  ),
  .ACLK_EN   ( 1'b1                  ),
  .AWVALID   ( s_axi_control_awvalid ),
  .AWREADY   ( s_axi_control_awready ),
  .AWADDR    ( s_axi_control_awaddr  ),
  .WVALID    ( s_axi_control_wvalid  ),
  .WREADY    ( s_axi_control_wready  ),
  .WDATA     ( s_axi_control_wdata   ),
  .WSTRB     ( s_axi_control_wstrb   ),
  .ARVALID   ( s_axi_control_arvalid ),
  .ARREADY   ( s_axi_control_arready ),
  .ARADDR    ( s_axi_control_araddr  ),
  .RVALID    ( s_axi_control_rvalid  ),
  .RREADY    ( s_axi_control_rready  ),
  .RDATA     ( s_axi_control_rdata   ),
  .RRESP     ( s_axi_control_rresp   ),
  .BVALID    ( s_axi_control_bvalid  ),
  .BREADY    ( s_axi_control_bready  ),
  .BRESP     ( s_axi_control_bresp   ),
  .interrupt ( interrupt             ),
  .ap_start  ( ap_start              ),
  .ap_done   ( ap_done               ),
  .ap_idle   ( ap_idle               ),
  .ap_ready(ap_ready),
  .scalar00  ( scalar00              ),
  .A         ( A                     ),
  .B         ( B                     )
);

endmodule
