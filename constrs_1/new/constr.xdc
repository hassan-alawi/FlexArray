create_clock -period 1.7 -name clk [get_ports clk]

set_property IOSTANDARD LVCMOS18 [get_ports nrst]
set_property PACKAGE_PIN G37 [get_ports nrst]