# ==============================================================================
# INDUSTRIAL MAKEFILE: CNN MNIST ACCELERATOR ON AMD ZYBO Z7 (xc7z010clg400-1)
# Author: Conquerors - NGUYEN VAN THUC (24161421)
# ==============================================================================

SHELL := /bin/bash

NUM_IMAGES ?= 10

.PHONY: sim sim-full eval fpga clean help

help:
	@echo "================================================================================"
	@echo " CNN MNIST ACCELERATOR BENCHMARK SUITE"
	@echo "================================================================================"
	@echo " Execution Commands:"
	@echo "   make sim NUM_IMAGES=10     Run Vivado xsim simulation (default: 10 images)"
	@echo "   make sim-full              Run Vivado xsim simulation for all 1000 images"
	@echo "   make eval                  Evaluate prediction accuracy vs ground truth"
	@echo "   make fpga                  Run AMD Vivado Physical Implementation (P&R)"
	@echo "   make clean                 Clean simulation and build artifacts"
	@echo "================================================================================"

sim:
	@mkdir -p sim results
	@echo ">>> [1/2] Compiling and Elaborating Simulation with Vivado xvlog/xelab..."
	@xvlog -nolog rtl/*.v sim/tb_test.v
	@xelab -nolog -top tb_test -s sim_snapshot
	@echo ">>> [2/2] Running Simulation (+NUM_IMAGES=$(NUM_IMAGES))..."
	@xsim sim_snapshot -nolog -R --testplusarg NUM_IMAGES=$(NUM_IMAGES) --testplusarg OUT_CSV=results/predict_output.csv
	@python3 scripts/eval_accuracy.py results/predict_output.csv data/ground_truth_labels.csv

sim-full:
	@$(MAKE) sim NUM_IMAGES=1000

eval:
	@python3 scripts/eval_accuracy.py results/predict_output.csv data/ground_truth_labels.csv

fpga:
	@mkdir -p reports
	@echo ">>> Running AMD Vivado FPGA Implementation (top_cnn on xc7z010)..."
	@vivado -mode batch -notrace -source scripts/synth_fpga.tcl > reports/vivado_pnr.log 2>&1
	@grep -A 10 "1. Slice Logic" reports/pnr_util.rpt
	@grep -A 8 "Design Timing Summary" reports/pnr_timing.rpt || true

clean:
	@rm -rf xsim.dir .Xil reports results *.jou *.log *.pb clockInfo.txt
