# ==============================================================================
# AMD Vivado Physical Implementation script for CNN Accelerator (Zybo Z7-10)
# ==============================================================================

set_param general.maxThreads 2

create_project -in_memory -part xc7z010clg400-1

# Read all RTL files
read_verilog [glob rtl/*.v]

# Read constraints
read_xdc constrs/constr.xdc

# 1. Synthesis
synth_design -top top_cnn -part xc7z010clg400-1

# Allow unconstrained virtual pads during placement
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

# 2. Place & Route
opt_design
place_design
route_design

# 3. Reports
file mkdir reports
report_utilization -file reports/pnr_util.rpt
report_timing_summary -file reports/pnr_timing.rpt
report_power -file reports/pnr_power.rpt

puts "\n\[PASS\] FPGA Implementation Complete: reports/pnr_util.rpt"
exit
