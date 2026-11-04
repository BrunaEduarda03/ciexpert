#==============================================================================
# MiniSoC AES - ambiente de verificacao UVM (Synopsys VCS)
#
#   make                      compila e roda o teste default (smoke)
#   make compile              so compila
#   make run TEST=<teste> SEED=<n> VERBOSITY=UVM_HIGH WAVES=fsdb|vcd
#   make verdi                abre o Verdi com as waves FSDB do ultimo run
#   make clean
#==============================================================================

VERIF_DIR := $(abspath .)
RTL_DIR   := $(abspath ../frontend/rtl)
TB_DIR    := $(VERIF_DIR)/tb
SIM_DIR   := $(VERIF_DIR)/sim
LOG_DIR   := $(SIM_DIR)/logs

TEST      ?= minisoc_smoke_test
SEED      ?= 1
VERBOSITY ?= UVM_MEDIUM
WAVES     ?= none

#------------------------------------------------------------------------------
# Fontes (ordem importa: interfaces -> pacotes -> RTL -> SVA -> top)
#------------------------------------------------------------------------------
RTL_SRCS := \
	$(RTL_DIR)/minisoc_aes/minisoc_aes_key_exp.sv \
	$(RTL_DIR)/minisoc_aes/minisoc_aes_dp.sv \
	$(RTL_DIR)/minisoc_aes/minisoc_aes_top.sv \
	$(RTL_DIR)/minisoc_mem/minisoc_memory.sv \
	$(RTL_DIR)/minisoc_pll/minisoc_pll_mock.sv \
	$(RTL_DIR)/minisoc_spi/minisoc_spi.sv \
	$(RTL_DIR)/minisoc_top.sv

TB_INCDIRS := \
	+incdir+$(TB_DIR)/agents/clk \
	+incdir+$(TB_DIR)/agents/rst \
	+incdir+$(TB_DIR)/env \
	+incdir+$(TB_DIR)/tests

TB_SRCS := \
	$(TB_DIR)/agents/clk/clk_if.sv \
	$(TB_DIR)/agents/rst/rst_if.sv \
	$(TB_DIR)/minisoc_probe_if.sv \
	$(TB_DIR)/agents/clk/clk_pkg.sv \
	$(TB_DIR)/agents/rst/rst_pkg.sv \
	$(TB_DIR)/env/minisoc_env_pkg.sv \
	$(TB_DIR)/tests/minisoc_test_pkg.sv

TOP_SRCS := \
	$(TB_DIR)/top_assertions.sv \
	$(TB_DIR)/top_tb.sv

#------------------------------------------------------------------------------
# Opcoes do VCS
#------------------------------------------------------------------------------
VCS_FLAGS := -full64 -sverilog -ntb_opts uvm-1.2 \
	-timescale=1ns/1ps \
	-debug_access+all -kdb \
	+lint=TFIPC-L \
	-top top_tb \
	-l $(LOG_DIR)/compile.log

RUN_FLAGS := +UVM_TESTNAME=$(TEST) \
	+ntb_random_seed=$(SEED) \
	+UVM_VERBOSITY=$(VERBOSITY) \
	+UVM_NO_RELNOTES

ifeq ($(WAVES),fsdb)
RUN_FLAGS += +FSDB
endif
ifeq ($(WAVES),vcd)
RUN_FLAGS += +VCD
endif

RUN_LOG := $(LOG_DIR)/$(TEST)_$(SEED).log

#------------------------------------------------------------------------------
.PHONY: all compile run verdi clean help

all: compile run

$(LOG_DIR):
	mkdir -p $(LOG_DIR)

compile: | $(LOG_DIR)
	cd $(SIM_DIR) && vcs $(VCS_FLAGS) $(TB_INCDIRS) $(TB_SRCS) $(RTL_SRCS) $(TOP_SRCS) -o simv

run: | $(LOG_DIR)
	cd $(SIM_DIR) && ./simv $(RUN_FLAGS) -l $(RUN_LOG)
	@if grep -q "TEST PASSED" $(RUN_LOG); then \
		echo "==> PASS: $(TEST) seed=$(SEED)  log: $(RUN_LOG)"; \
	else \
		echo "==> FAIL: $(TEST) seed=$(SEED)  log: $(RUN_LOG)"; exit 1; \
	fi

verdi:
	cd $(SIM_DIR) && verdi -dbdir simv.daidir -ssf waves.fsdb &

clean:
	rm -rf $(SIM_DIR)

help:
	@sed -n '2,9p' Makefile
