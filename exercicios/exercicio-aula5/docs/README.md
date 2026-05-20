# 📘 Verilog Circuits Collection – README

This repository contains a set of **basic digital design modules and their testbenches**, written in Verilog. The designs include combinational and sequential logic blocks commonly used in digital systems.

---

## 🔹 1. Demultiplexer (1×8) – `demux1x8`

**What it does:**
Routes a single input (`din`) to one of 8 outputs (`dout`) based on a 3-bit select signal.

**Special notes:**

* Only one output bit is high at a time.
* Output is **clocked (latched)** even though demux is normally combinational.
* Uses **enable (`en`)** and **active-low reset (`rstn`)**.

---

## 🔹 2. Multiplexer (8×1) – `mux8x1`

**What it does:**
Selects one of 8 input bits and forwards it to a single output.

**Special notes:**

* Controlled by a 3-bit select signal.
* Output is **registered (clocked)** instead of purely combinational.
* Includes **enable and reset**.

---

## 🔹 3. Decoder (2×4) – `decoder2x4`

**What it does:**
Converts a 2-bit input into a one-hot 4-bit output.

**Special notes:**

* Only one output is HIGH at a time.
* Implemented with **clocked output**, not purely combinational.
* Includes **enable + reset**.

---

## 🔹 4. Encoder (4×2) – `encoder4x2`

**What it does:**
Encodes a one-hot 4-bit input into a 2-bit binary output.

**Special notes:**

* Assumes valid one-hot input (no priority handling).
* Output is **latched on clock edge**.
* Includes **enable and reset**.

---

## 🔹 5. 2×2 Matrix Multiplier – `matrix2x2_mult`

**What it does:**
Multiplies two 2×2 matrices packed into 32-bit inputs.

**How it works:**

* Each matrix is split into four 8-bit elements.
* Performs matrix multiplication:

  ```
  [a b]   [e f]
  [c d] x [g h]
  ```

**Special notes:**

* Uses **internal 2D arrays** (interesting Verilog feature).
* Mixed behavior:

  * Input unpacking → combinational
  * Computation → clocked
* Output packed back into 32-bit.

---

## 🔹 6. 16×16 Multiplier – `multiplier`

**What it does:**
Multiplies two 16-bit numbers and produces a 32-bit result.

**Special notes:**

* Sequential (clocked), not purely combinational.
* Uses **register to store result**.
* Controlled by **enable and reset**.

---

## 🔹 7. Counter with Overflow – `counter_overflow`

**What it does:**
A 32-bit counter with an additional overflow bit.

**Special notes:**

* Internally uses a **33-bit register**:

  * Lower 32 bits → count
  * MSB → overflow
* Has a **load feature**:

  * Loads a predefined value (`33'hfffffff8`)
* Supports:

  * Enable counting
  * Reset
  * Load operation

---

## 🔹 8. Up/Down Counter (4-bit) – `updowncounter`

**What it does:**
Counts up and down simultaneously:

* `up_counter`: increments
* `down_counter`: decrements

**Special notes:**

* Both counters run in parallel.
* Reset initializes:

  * Up → `0000`
  * Down → `1111`
* Controlled by enable signal.

---

## 🔹 9. Testbenches (TBs)

Each module has a corresponding testbench:

* `demux1x8_tb`
* `mux8x1_tb`
* `decoder2x4_tb`
* `encoder4x2_tb`
* `matrix2x2_mult_tb`
* `multiplier_tb`
* `counter_overflow_tb`
* `updown_counter_tb`

**What they do:**

* Generate clock signals
* Apply stimulus (input values)
* Dump waveform files (`.vcd` / `.fsdb`)

**Special notes:**

* Use `$dumpfile`, `$dumpvars`, or `$fsdbDumpvars`
* Help visualize behavior in waveform viewers (GTKWave, Verdi, etc.)

---

## ⚙️ General Observations

* Many designs are **clocked even when typically combinational**
  → Good for learning sequential design behavior.

* Consistent use of:

  * `en` (enable)
  * `rstn` / `resetn` (active-low reset)

* Good mix of:

  * **Combinational logic** (mux, demux, encoder, decoder)
  * **Sequential logic** (counters, multiplier, matrix mult)

---

## 📊 Summary Table

| Module           | Type       | Key Feature          |
| ---------------- | ---------- | -------------------- |
| demux1x8         | Sequential | One-hot output       |
| mux8x1           | Sequential | Selects 1 of 8       |
| decoder2x4       | Sequential | Binary → one-hot     |
| encoder4x2       | Sequential | One-hot → binary     |
| matrix2x2_mult   | Hybrid     | Uses 2D arrays       |
| multiplier       | Sequential | 16×16 multiply       |
| counter_overflow | Sequential | 33-bit with overflow |
| updowncounter    | Sequential | Dual counter         |
| Testbenches      | Simulation | Stimulus + waveform  |

