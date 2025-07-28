# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_OUT_FIFO_IF_BW" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_OUT_FIFO_IF_SIZE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "K" -parent ${Page_0}
  ipgui::add_param $IPINST -name "M" -parent ${Page_0}


}

proc update_PARAM_VALUE.BW { PARAM_VALUE.BW } {
	# Procedure called to update BW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BW { PARAM_VALUE.BW } {
	# Procedure called to validate BW
	return true
}

proc update_PARAM_VALUE.C_OUT_FIFO_IF_BW { PARAM_VALUE.C_OUT_FIFO_IF_BW } {
	# Procedure called to update C_OUT_FIFO_IF_BW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_OUT_FIFO_IF_BW { PARAM_VALUE.C_OUT_FIFO_IF_BW } {
	# Procedure called to validate C_OUT_FIFO_IF_BW
	return true
}

proc update_PARAM_VALUE.C_OUT_FIFO_IF_SIZE { PARAM_VALUE.C_OUT_FIFO_IF_SIZE } {
	# Procedure called to update C_OUT_FIFO_IF_SIZE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_OUT_FIFO_IF_SIZE { PARAM_VALUE.C_OUT_FIFO_IF_SIZE } {
	# Procedure called to validate C_OUT_FIFO_IF_SIZE
	return true
}

proc update_PARAM_VALUE.K { PARAM_VALUE.K } {
	# Procedure called to update K when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.K { PARAM_VALUE.K } {
	# Procedure called to validate K
	return true
}

proc update_PARAM_VALUE.M { PARAM_VALUE.M } {
	# Procedure called to update M when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.M { PARAM_VALUE.M } {
	# Procedure called to validate M
	return true
}


proc update_MODELPARAM_VALUE.M { MODELPARAM_VALUE.M PARAM_VALUE.M } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.M}] ${MODELPARAM_VALUE.M}
}

proc update_MODELPARAM_VALUE.K { MODELPARAM_VALUE.K PARAM_VALUE.K } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.K}] ${MODELPARAM_VALUE.K}
}

proc update_MODELPARAM_VALUE.BW { MODELPARAM_VALUE.BW PARAM_VALUE.BW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BW}] ${MODELPARAM_VALUE.BW}
}

proc update_MODELPARAM_VALUE.C_OUT_FIFO_IF_SIZE { MODELPARAM_VALUE.C_OUT_FIFO_IF_SIZE PARAM_VALUE.C_OUT_FIFO_IF_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_OUT_FIFO_IF_SIZE}] ${MODELPARAM_VALUE.C_OUT_FIFO_IF_SIZE}
}

proc update_MODELPARAM_VALUE.C_OUT_FIFO_IF_BW { MODELPARAM_VALUE.C_OUT_FIFO_IF_BW PARAM_VALUE.C_OUT_FIFO_IF_BW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_OUT_FIFO_IF_BW}] ${MODELPARAM_VALUE.C_OUT_FIFO_IF_BW}
}

