transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/QuartusCode/HW4 {D:/QuartusCode/HW4/AM2302_master.v}
vlog -vlog01compat -work work +incdir+D:/QuartusCode/HW4 {D:/QuartusCode/HW4/edge_detect.v}

