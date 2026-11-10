# Hardware MNIST CNN Accelerator with Approximate Logarithmic Multipliers
**Author:** NGUYEN VAN THUC (Student ID: 24161421) - Lead of Team Conquerors  
**Affiliation:** Ho Chi Minh City University of Technology and Education (HCMUTE)  
**Target Platform:** Digilent Zybo Z7 (AMD Zynq-7000 `xc7z010clg400-1`)  
**Clock Frequency:** 50.0 MHz (Nominal Physical Sign-off)  

---

## 1. Executive Summary

This repository hosts the official physical implementation and sign-off verification suite for the **Energy-Efficient MNIST Convolutional Neural Network (CNN) Accelerator**. The architecture replaces power-hungry exact array multipliers with an ultra-compact **Look-Up Table Approximate Logarithmic Multiplier (LUT-ALM) Subsystem**.

### Core Technical Breakthroughs:
1. **Record-Setting Inference Accuracy (95.80%):** Outperforms the competition baseline (92.40%) by **+3.40%** across all 1,000 standard testbench images (958/1,000 correctly classified).
2. **Spatial Error Cancellation (Alternating Asymmetric Rounding):** Alternates antilog rounding bias between even convolution lanes (`4'b1111`) and odd convolution lanes (`4'b0000`), canceling arithmetic accumulation drift across spatial receptive fields.
3. **Ultra-Compact Multiplier Footprint (176 LUTs total):** 9 parallel convolution multipliers consume only **153 Slice LUTs (~17 LUTs/multiplier)**; Dense layer multiplier consumes only **23 LUTs**. Eliminates 1,074 LUTs compared to baseline array multipliers (-85.9%).
4. **Zero-LUT ROM Pre-Encoding:** All kernel weights and dense weights are pre-transformed to logarithmic codes during offline training, eliminating 10 runtime weight encoders.
5. **RTL Active Input Operand Isolation:** Zero-glitch bypass suppression gates internal transitions during padding and zero-activation cycles, reducing dynamic power to **23.0 mW**.

---

## 2. Repository Versioning & Branch Hierarchy

- **Branch `baseline` (Tag `v0.0.0`)**: Exact multiplier reference architecture (92.40% accuracy, 3,982 LUTs).
- **Branch `v2` (Tag `v0.2.3`)**: Log8-Nano Active Input Operand Isolation (3,502 LUTs, 95.10% accuracy, +5.119 ns WNS @ 50 MHz).
- **Branch `v4` / `main` (Tag `v0.4.0`)**: Spatial Error Cancellation & V10 Biasing Suite (**3,501 LUTs, 95.80% accuracy, 23.0 mW dynamic power, +5.577 ns WNS @ 50 MHz**).

---

## 3. Directory Structure

```
cnn_mnist/
├── Makefile                          # Unified build and automation interface
├── rtl/                              # Self-contained Verilog source files
│   ├── top_cnn.v                     # Top-level accelerator module
│   ├── convolution_unit.v            # 3x3 parallel convolution engine (9 Log8-Nano cores)
│   ├── log8_nano_mul_core.v          # Approximate logarithmic multiplier core
│   ├── active_log8_nano_encoder.v    # 6-LUT global active pixel encoder
│   ├── dense.v                       # Fully-connected classification layer
│   └── Controller.v                  # FSM sequencing and memory management
├── reports/                          # Complete 34-file EDA physical sign-off suite
│   ├── Bang_tinh_Accuracy.xlsx       # 1,000-image accuracy verification table (Vietnamese)
│   ├── Accuracy_Evaluation.xlsx      # Standardized IEEE English accuracy table
│   ├── pnr_util.rpt                  # Post-route FPGA resource utilization
│   ├── pnr_timing.rpt                # Setup/Hold STA timing sign-off (50 MHz)
│   ├── critical_path.rpt             # Worst-case timing path analysis
│   ├── deep_fpga_signoff_summary.rpt # Consolidated environmental & corner sign-off
│   └── simulation.log                # AMD Vivado xsim verification log
├── scripts/                          # Automated EDA scripts (Vivado PNR, sweeps, Excel gen)
├── constrs/                          # Pinout constraints (zybo_z7.xdc)
└── data/                             # Ground-truth labels and evaluation vectors
```

---

## 4. Physical Sign-Off Benchmarks (AMD Zybo Z-7010)

Measurements obtained from complete AMD Vivado 2024.2 Place & Route (PNR) at nominal $25^\circ\text{C}$, $1.00\text{V}$ $V_{\text{CCINT}}$:

| Architectural Metric | Baseline BTC | Release v0.2.3 (`v2`) | Release v0.4.0 (`v4` / `main`) | Improvement vs Baseline |
| :--- | :---: | :---: | :---: | :---: |
| **MNIST Test Accuracy** | 92.40% (924/1,000) | 95.10% (951/1,000) | **95.80% (958/1,000)** | **+3.40% Accuracy Gain** |
| **Slice LUTs** | 3,982 (22.6%) | 3,502 (19.9%) | **3,501 (19.89%)** | **-481 LUTs (-12.1%)** |
| **Slice Registers (FF)** | 3,454 (9.8%) | 3,454 (9.8%) | **3,454 (9.81%)** | Unchanged |
| **CARRY4 Primitives** | 221 | 221 | **221** | Unchanged |
| **DSP Blocks** | 0 | 0 | **0** | **100% DSP-Free** |
| **Worst Negative Slack (WNS)** | +4.950 ns | +5.119 ns | **+5.577 ns** | **+0.627 ns Timing Margin** |
| **Max Frequency ($F_{\max}$)** | 66.45 MHz | 67.20 MHz | **69.33 MHz** | **+2.88 MHz Throughput** |
| **Dynamic Power (@50MHz)** | 27.0 mW | 24.0 mW | **23.0 mW** | **-14.8% Dynamic Power** |
| **Multiplier Subsystem LUTs** | ~1,250 LUTs | 176 LUTs | **176 LUTs** | **-85.9% Footprint Drop** |

---

## 5. Execution Commands

```bash
# 1. Run full 1,000-image hardware simulation and generate Excel accuracy table
make sim

# 2. Run complete 9-stage Vivado FPGA Implementation (PNR, timing, power, thermal sweeps)
make fpga

# 3. Clean intermediate logs and build caches
make clean
```
