create_clock -period 1.75 -name clk [get_ports clk]

set_property IOSTANDARD LVCMOS18 [get_ports nrst]

