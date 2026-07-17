# Design and Simulation of a Low-Pass FIR Filter for ECG Signal Processing on FPGA

**Capstone Project 2 – Computer Engineering Technology**
Ho Chi Minh City University of Technology (HUTECH)
Faculty of Electrical – Electronics Engineering | Department of Electronics & Telecommunications Engineering

- **Student:** Le Phong Vu – Student ID: 22119157
- **Supervisor:** Assoc. Prof. Dr. Truong Ngoc Son
- **Date:** July 2026

---

## 📌 Introduction

Electrocardiogram (ECG) signals have very low amplitude (100 μV – 5 mV), making them highly susceptible to noise such as power-line interference (50/60 Hz), muscle noise (EMG), and baseline wander. This project designs a **low-pass FIR digital filter** using the Hamming window method to remove high-frequency noise while preserving the ECG waveform shape, thanks to the linear-phase property of FIR filters. The algorithm is first verified in MATLAB, then implemented in **Verilog HDL** and simulated on **Xilinx ISE**, taking advantage of FPGA's real-time parallel processing capability.

## 🎯 Objectives

- Study ECG signal characteristics and common noise sources.
- Design a low-pass FIR filter using the Window Method.
- Build a reference model in MATLAB (fixed-point, bit-true).
- Implement the filter in hardware using Verilog HDL, ensuring bit-true accuracy against the MATLAB model.
- Quantitatively evaluate results using RMSE/MAE and FFT spectral analysis.

## ⚠️ Project Scope & Limitations

- Limited to **software simulation** (MATLAB + Xilinx ISE); not deployed on a physical FPGA board (no synthesis/timing analysis).
- Uses a **simulated** ECG signal (1 Hz sine wave + 20 Hz structured noise + Gaussian noise), not real patient data.
- Input data format: **Q1.7 signed 8-bit**; filter coefficients: **Q1.15**.
- Fixed low-pass filter with a **fixed 3 Hz cutoff frequency**; no adaptive filtering based on changing noise conditions.

## 🧠 Theoretical Background

| Component | Key Content |
|---|---|
| ECG Signal | P wave, QRS complex, T wave; useful frequency band 0.05–100 Hz |
| Noise Sources | PLI (50/60 Hz), EMG (5–500 Hz), Baseline Wander (0.15–0.3 Hz) |
| FIR Filter | `y(n) = Σ h(k)·x(n−k)`, linear phase, unconditionally stable |
| Design Method | Hamming window (stopband attenuation ~ −53 dB) |
| Quantization | `h_q(n) = round(h_ideal(n) × 2^Q)`, Q = 15 (Q1.15 format) |

## 🏗️ System Architecture

```
Simulated ECG Signal → ADC → FIR Filter (FPGA) → Filtered Digital Signal → DAC → Analog Output
```

**Selected filter parameters:**
- Sampling frequency Fs = 200 Hz
- Cutoff frequency fc = 3 Hz
- Number of taps N = 29 (chosen as optimal after testing 3–39 taps)
- Group delay = 14 samples (70 ms)
- Format: 16-bit Q1.15 coefficients, 8-bit Q1.7 input data, 32-bit accumulator to prevent overflow

**Verilog hardware blocks:**
- Shift Register storing the 29 most recent samples
- Multiply-Accumulate (MAC) Unit – computes all taps in parallel within one clock cycle
- Saturation & Scaling block – normalizes output back to Q1.15 and prevents overflow
- Reset control block to bring the system to a clean initial state

## 🔄 Design Flow

1. **MATLAB**: generate the simulated ECG signal, design the filter (Hamming window), quantize coefficients, export data as hex files.
2. **Verilog HDL**: implement the FIR core (shift register + MAC + saturation), run bit-true simulation via a Testbench.
3. **Comparison & Evaluation**: compare Verilog output against MATLAB and the clean original signal using RMSE/MAE and FFT spectral analysis.

## 📊 Key Results

| Comparison | RMSE | MAE |
|---|---|---|
| Verilog vs MATLAB | 0.0124 | 0.0110 |
| Verilog vs Clean Original Signal | 0.0236 | 0.0182 |

- Measured phase delay: **14 samples**, matching the theoretical value `(N−1)/2`.
- High-frequency noise components are clearly suppressed in the post-filter FFT spectrum.

**Tap-count study:**

| Taps | RMSE (vs Clean) | MAE (vs Clean) | Delay | Observation |
|---|---|---|---|---|
| 3 | 0.2004 | 0.1683 | 5 ms | Noise still very high |
| 5 | 0.1744 | 0.1475 | 10 ms | Sawtooth noise still present |
| 7 | 0.0848 | 0.0733 | 15 ms | Good basic filtering |
| **29** | **0.0802** | **0.0700** | **70 ms** | **Optimal point** |
| 35 | 0.0856 | 0.0777 | 85 ms | Error increases due to phase delay |
| 39 | 0.0875 | 0.0795 | 95 ms | Large phase delay distorts signal |

→ **29 taps** was chosen as it offers the best trade-off between filtering quality and hardware resource cost.

## 🛠️ Technologies Used

- MATLAB (filter design, reference model, RMSE/MAE evaluation, FFT analysis)
- Verilog HDL (hardware implementation of the FIR filter)
- Xilinx ISE (functional simulation, waveform inspection)

## 📁 Source Code / Appendix Structure

```
├── Compare/
│   ├── DAC.m                    # Compares Verilog vs MATLAB vs original signal (RMSE/MAE, plots)
│   ├── Output_Reference.txt     # MATLAB reference filter output (Q1.15 hex)
│   ├── Output_V.txt             # Verilog simulation output (Q1.15 hex)
│   └── Lưu ý.txt                # Notes
│
├── Input/
│   ├── generate_input.m         # Generates simulated ECG signal + noise
│   └── ECG_Input.txt            # Simulated input signal (Q1.7 hex)
│
├── Matlab_out/
│   ├── fir_filter_reference.m   # Reference FIR filter design (Hamming window, bit-true)
│   ├── ECG_Input.txt            # Input signal used by the MATLAB filter
│   ├── Output_Reference.txt     # Filtered output from MATLAB
│   ├── filter_analysis.mat      # Saved workspace (Fs, coefficients, samples, etc.)
│   └── Lưu ý.txt                # Notes
│
└── Verilog_out/
    ├── fir_filter.v             # FIR module: shift register + MAC + saturation
    ├── fir_tb.v                 # Testbench: reads ECG_Input.txt, writes Output_V.txt
    ├── fir_tb.vvp                # Compiled simulation executable (Icarus Verilog)
    ├── fir_wave.vcd              # Waveform dump for viewing in GTKWave
    ├── ECG_Input.txt             # Input signal used by the Verilog testbench
    ├── Output_V.txt              # Filtered output from Verilog simulation
    ├── run.bat                   # Script to compile & run the simulation
    └── Lưu ý.txt                 # Notes
```

## 🚀 Future Development

- Apply **multiplier-less FIR** architectures (Distributed Arithmetic / CSD) to save hardware resources.
- Develop an **adaptive filter** (LMS/RLS) to handle time-varying noise.
- Integrate into a **System-on-Chip (SoC)** (Zynq/MicroBlaze) combined with QRS detection and real-time arrhythmia alerting.
- Deploy and validate on a **physical FPGA board** using real patient ECG data.

## 📚 References

A list of 11 references (textbooks, scientific papers, and Xilinx/MathWorks technical documentation) is provided in detail in the full report.

---

*This is a summary of the Capstone Project 2 report. Refer to the full report (PDF) for detailed formulas, data tables, and source code.*