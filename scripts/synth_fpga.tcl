# ==============================================================================
# AMD Vivado Physical Implementation & Comprehensive Environmental Sign-off Suite
# Target Device: AMD Zybo Z7-10 (xc7z010clg400-1)
# Project: CNN MNIST Hardware Accelerator
# Author: Conquerors - NGUYEN VAN THUC (MSSV: 24161421)
# ==============================================================================

set_param general.maxThreads 2

set report_dir "reports"
file mkdir $report_dir

puts "\n=================================================================="
puts ">>> PROFILING CNN ACCELERATOR: top_cnn on xc7z010clg400-1"
puts ">>> Comprehensive Environmental, Thermal & Physical Sign-Off"
puts ">>> Output Directory: $report_dir"
puts "=================================================================="

create_project -in_memory -part xc7z010clg400-1

# Read all RTL files
set rtl_files [glob -nocomplain rtl/*.v]
read_verilog $rtl_files

# Read constraints (50 MHz sys_clk_pin)
read_xdc constrs/constr.xdc

# Allow unconstrained virtual pads during placement
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

# ------------------------------------------------------------------------------
# 1. Synthesis
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 1\] Synthesizing top_cnn..."
synth_design -top top_cnn -part xc7z010clg400-1

# ------------------------------------------------------------------------------
# 2. Place & Route (Physical Implementation)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 2\] Place & Route Implementation..."
opt_design
place_design
route_design

# ------------------------------------------------------------------------------
# 3. Post-Route Utilization & Baseline Timing (50 MHz)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 3\] Utilization & Physical Timing Sign-Off (50 MHz)..."
report_utilization -file "${report_dir}/pnr_util.rpt"
report_utilization -hierarchical -file "${report_dir}/utilization_hierarchical.rpt"
report_timing_summary -delay_type min_max -max_paths 10 -file "${report_dir}/pnr_timing.rpt"
report_timing -nworst 1 -max_paths 1 -file "${report_dir}/critical_path.rpt"
report_timing -delay_type max -max_paths 10 -file "${report_dir}/timing_paths_detailed.rpt"

# ------------------------------------------------------------------------------
# 4. Baseline Power Analysis (50 MHz, Nominal PVT: 25C, 1.00V, 12.5% toggle)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 4\] Power Analysis at 50 MHz Nominal..."
report_power -file "${report_dir}/pnr_power.rpt"

# ------------------------------------------------------------------------------
# 5. Environmental & Thermal Sign-Off Sweep (-40C to 100C, Still Air)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 5\] Thermal Ambient Sweep (-40C to 100C)..."
set ambient_temps {-40 0 25 50 85 100}
set thermal_csv [open "${report_dir}/thermal_ambient_sweep.csv" "w"]
puts $thermal_csv "ambient_c,junction_tj_c,thermal_margin_c,static_power_w,dynamic_power_w,total_power_w"

foreach amb $ambient_temps {
    set_operating_conditions -ambient_temp $amb
    report_power -file "${report_dir}/power_thermal_${amb}C.rpt"
    
    set pwr_rpt [open "${report_dir}/power_thermal_${amb}C.rpt" "r"]
    set rpt_data [read $pwr_rpt]
    close $pwr_rpt
    
    set tot_w "N/A"
    set dyn_w "N/A"
    set dev_static_w "N/A"
    set junction_tj "N/A"
    set margin_tj "N/A"
    
    regexp {Total On-Chip Power \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match tot_w
    regexp {Dynamic \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match dyn_w
    regexp {Device Static \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match dev_static_w
    regexp {Junction Temperature \(C\)\s+\|\s+([0-9\.]+)} $rpt_data match junction_tj
    regexp {Thermal Margin \(C\)\s+\|\s+([0-9\.]+)} $rpt_data match margin_tj
    
    puts $thermal_csv "${amb},${junction_tj},${margin_tj},${dev_static_w},${dyn_w},${tot_w}"
}
close $thermal_csv

# Reset operating conditions back to nominal 25C
set_operating_conditions -ambient_temp 25

# ------------------------------------------------------------------------------
# 6. Supply Voltage Corner Sweep (+/-5% Vccint: 0.95V, 1.00V, 1.05V)
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 6\] Supply Voltage Corner Sweep (Vccint +/-5%)..."
set voltages {0.95 1.00 1.05}
set volt_csv [open "${report_dir}/voltage_corner_power.csv" "w"]
puts $volt_csv "vccint_v,total_power_w,dynamic_power_w,static_power_w"

foreach v $voltages {
    set_operating_conditions -voltage [list Vccint $v]
    report_power -file "${report_dir}/power_vccint_${v}V.rpt"
    
    set pwr_rpt [open "${report_dir}/power_vccint_${v}V.rpt" "r"]
    set rpt_data [read $pwr_rpt]
    close $pwr_rpt
    
    set tot_w "N/A"
    set dyn_w "N/A"
    set dev_static_w "N/A"
    
    regexp {Total On-Chip Power \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match tot_w
    regexp {Dynamic \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match dyn_w
    regexp {Device Static \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match dev_static_w
    
    puts $volt_csv "${v},${tot_w},${dyn_w},${dev_static_w}"
}
close $volt_csv

# Reset voltage back to nominal 1.00V
set_operating_conditions -voltage [list Vccint 1.00]

# ------------------------------------------------------------------------------
# 7. Switching Activity & Toggle Rate Sensitivity Sweep
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 7\] Switching Activity / Toggle Rate Sweep..."
set toggle_rates {5.0 12.5 25.0 50.0}
set switch_csv [open "${report_dir}/switching_activity_sweep.csv" "w"]
puts $switch_csv "toggle_rate_pct,dynamic_power_w,logic_power_w,signals_power_w"

foreach tr $toggle_rates {
    set_switching_activity -default_toggle_rate $tr -default_static_probability 0.5
    report_power -file "${report_dir}/power_toggle_${tr}pct.rpt"
    
    set pwr_rpt [open "${report_dir}/power_toggle_${tr}pct.rpt" "r"]
    set rpt_data [read $pwr_rpt]
    close $pwr_rpt
    
    set dyn_w "N/A"
    set logic_w "N/A"
    set sig_w "N/A"
    
    regexp {Dynamic \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match dyn_w
    regexp {Logic \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match logic_w
    regexp {Signals \(W\)\s+\|\s+([0-9\.]+)} $rpt_data match sig_w
    
    puts $switch_csv "${tr},${dyn_w},${logic_w},${sig_w}"
}
close $switch_csv

# Reset switching activity to default
set_switching_activity -default_toggle_rate 12.5 -default_static_probability 0.5

# ------------------------------------------------------------------------------
# 8. Deep Netlist & Physical Complexity Analysis
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 8\] Deep Netlist & Physical Complexity Analysis..."
catch { report_design_analysis -timing -setup -hold -max_paths 5 -file "${report_dir}/design_timing_paths.rpt" }
catch { report_design_analysis -logic_level_distribution -file "${report_dir}/logic_level_distribution.rpt" }
catch { report_design_analysis -congestion -file "${report_dir}/routing_congestion.rpt" }
catch { report_high_fanout_nets -fanout_greater_than 10 -max_nets 20 -file "${report_dir}/high_fanout_nets.rpt" }
catch { report_datasheet -file "${report_dir}/datasheet.rpt" }

# ------------------------------------------------------------------------------
# 9. Consolidated Deep Sign-Off Summary Report Generation
# ------------------------------------------------------------------------------
puts "\n>>> \[STAGE 9\] Generating Consolidated Deep Sign-Off Report..."
set signoff_rpt [open "${report_dir}/deep_fpga_signoff_summary.rpt" "w"]
puts $signoff_rpt "================================================================================"
puts $signoff_rpt " AMD ZYNQ-7000 FPGA DEEP PHYSICAL SIGN-OFF & ENVIRONMENTAL REPORT"
puts $signoff_rpt " Target Device : AMD Zybo Z7-10 (xc7z010clg400-1)"
puts $signoff_rpt " Design Module : top_cnn"
puts $signoff_rpt " Generated On  : [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
puts $signoff_rpt "================================================================================\n"

puts $signoff_rpt "1. ENVIRONMENTAL & THERMAL CHARACTERIZATION (STILL AIR, NO HEATSINK):"
puts $signoff_rpt "--------------------------------------------------------------------------------"
puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s | %-12s" "Ambient (C)" "Junction Tj (C)" "Thermal Margin" "Static Pwr" "Total Pwr"]
puts $signoff_rpt "--------------------------------------------------------------------------------"
if {[file exists "${report_dir}/thermal_ambient_sweep.csv"]} {
    set fp [open "${report_dir}/thermal_ambient_sweep.csv" "r"]
    gets $fp line ; # header
    while {[gets $fp line] >= 0} {
        set cols [split $line ","]
        puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s | %-12s" \
            [lindex $cols 0] [lindex $cols 1] [lindex $cols 2] [lindex $cols 3] [lindex $cols 5]]
    }
    close $fp
}

puts $signoff_rpt "\n2. SUPPLY VOLTAGE CORNER SENSITIVITY (VCCINT VARIATION +/-5%):"
puts $signoff_rpt "--------------------------------------------------------------------------------"
puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s" "Vccint (V)" "Total Power (W)" "Dynamic (W)" "Static (W)"]
puts $signoff_rpt "--------------------------------------------------------------------------------"
if {[file exists "${report_dir}/voltage_corner_power.csv"]} {
    set fp [open "${report_dir}/voltage_corner_power.csv" "r"]
    gets $fp line ; # header
    while {[gets $fp line] >= 0} {
        set cols [split $line ","]
        puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-12s" \
            [lindex $cols 0] [lindex $cols 1] [lindex $cols 2] [lindex $cols 3]]
    }
    close $fp
}

puts $signoff_rpt "\n3. SWITCHING ACTIVITY / TOGGLE RATE SENSITIVITY:"
puts $signoff_rpt "--------------------------------------------------------------------------------"
puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-16s" "Toggle Rate (%)" "Dynamic Pwr (W)" "Logic Pwr (W)" "Signals Pwr (W)"]
puts $signoff_rpt "--------------------------------------------------------------------------------"
if {[file exists "${report_dir}/switching_activity_sweep.csv"]} {
    set fp [open "${report_dir}/switching_activity_sweep.csv" "r"]
    gets $fp line ; # header
    while {[gets $fp line] >= 0} {
        set cols [split $line ","]
        puts $signoff_rpt [format "%-14s | %-16s | %-16s | %-16s" \
            [lindex $cols 0] [lindex $cols 1] [lindex $cols 2] [lindex $cols 3]]
    }
    close $fp
}
puts $signoff_rpt "================================================================================"
close $signoff_rpt

close_project
puts "\n>>> FPGA Physical Implementation & Deep Characterization Completed: top_cnn"
exit
