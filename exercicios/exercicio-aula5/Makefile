BLOCK    ?= adder32

# RTL
RTL_FILES = rtl/$(BLOCK).v

# TB
TB_FILES  = tb/tb_$(BLOCK).v

# ─── Fluxo: Icarus Verilog + Surfer ───────────────────────────
# Uso:
#   make sim BLOCK=adder32      → compila + roda + mostra resultado no terminal
#   make wave BLOCK=adder32     → compila + roda + abre waveform no Surfer
#   make sim_clean              → remove artefatos do Icarus

SIM_DIR   = sim
SIM_RTL   = rtl/$(BLOCK).v
SIM_TB    = $(SIM_DIR)/sim_$(BLOCK).v
SIM_OUT   = $(SIM_DIR)/$(BLOCK).out
SIM_VCD   = $(SIM_DIR)/$(BLOCK).vcd

# Mapeia BLOCK para o testbench na pasta  sim
SIM_TB_adder32        = $(SIM_DIR)/adder32/sim_adder32.v
SIM_TB_multiplier16x16= $(SIM_DIR)/multiplier16x16/sim_multiplier16x16.v
SIM_TB_matrixmult     = $(SIM_DIR)/matrixmult/sim_matrixmult.v
SIM_TB_counter32bit   = $(SIM_DIR)/counter32bit/sim_counter32bit.v
SIM_TB_updown_counter = $(SIM_DIR)/updown_counter/sim_updown_counter.v
SIM_TB_1x8demux       = $(SIM_DIR)/demux1x8/sim_demux1x8.v
SIM_TB_8x1mux         = $(SIM_DIR)/mux8x1/sim_mux8x1.v
SIM_TB_decoder2x4     = $(SIM_DIR)/decoder2x4/sim_decoder2x4.v
SIM_TB_encoder4x2     = $(SIM_DIR)/encoder4x2/sim_encoder4x2.v
SIM_TB_arbiter        = $(SIM_DIR)/arbiter/sim_arbiter.v

# VCDs gerados dentro de cada subpasta sim
SIM_VCD_adder32           = $(SIM_DIR)/adder32/sim.vcd
SIM_VCD_multiplier16x16   = $(SIM_DIR)/multiplier16x16/sim.vcd
SIM_VCD_matrixmult        = $(SIM_DIR)/matrixmult/sim.vcd
SIM_VCD_counter32bit      = $(SIM_DIR)/counter32bit/sim.vcd
SIM_VCD_updown_counter    = $(SIM_DIR)/updown_counter/sim.vcd
SIM_VCD_1x8demux          = $(SIM_DIR)/demux1x8/sim.vcd
SIM_VCD_8x1mux            = $(SIM_DIR)/mux8x1/sim.vcd
SIM_VCD_decoder2x4        = $(SIM_DIR)/decoder2x4/sim.vcd
SIM_VCD_encoder4x2        = $(SIM_DIR)/encoder4x2/sim.vcd
SIM_VCD_arbiter           = $(SIM_DIR)/arbiter/sim.vcd

SIM_TB_FILE  = $(or $(SIM_TB_$(BLOCK)),$(SIM_TB))
SIM_OUT_FILE = $(SIM_DIR)/$(BLOCK).out
SIM_VCD_FILE = $(or $(SIM_VCD_$(BLOCK)),$(SIM_DIR)/$(BLOCK).vcd)

.PHONY: sim wave sim_clean

sim:
	@echo "=== Compilando $(BLOCK) com Icarus Verilog ==="
	iverilog -o $(SIM_OUT_FILE) $(SIM_RTL) $(SIM_TB_FILE)
	@echo "=== Rodando simulacao ==="
	vvp $(SIM_OUT_FILE)

wave:
	@echo "=== Compilando $(BLOCK) ==="
	iverilog -o $(SIM_OUT_FILE) $(SIM_RTL) $(SIM_TB_FILE)
	@echo "=== Rodando simulacao e gerando VCD ==="
	vvp $(SIM_OUT_FILE)
	@echo "=== Abrindo waveform no Surfer ==="
	surfer $(SIM_VCD_FILE) &

sim_clean:
	rm -f $(SIM_DIR)/*.out $(SIM_DIR)/*.vcd

# ─── Fluxo VCS + Verdi (requer licenca Synopsys) ──────────────────────────
VCS_KDB   = -kdb
VCS_DEBUG = -debug_access+all
VCS_FLAGS = -full64 -l ./vcs_logger.log $(VCS_KDB) $(VCS_DEBUG) -timescale=1ns/1ps

vcs:
	vcs $(VCS_FLAGS) $(RTL_FILES) $(TB_FILES)

run:
	./simv +FSDB=$(BLOCK).fsdb

gui:
	./simv -gui

verdi_wf:
	verdi -play cmd/$(BLOCK).cmd

verdi_wf_easy:
	verdi -nologo -ssf $(BLOCK).fsdb

verdi_sc:
	verdi -play schematic-top.cmd

vcs_clean:
	rm -rf csrc *.daidir simv *.log *.key *.conf *.rc *.fsdb verdiLog/
