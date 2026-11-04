BLOCK    ?= matrix2x2

# RTL (nome do arquivo/modulo preservado: rtl/matrixmult.v, modulo matrix2x2_mult)
RTL_FILES = rtl/matrixmult.v

# PACKAGE FILE
PKG_FILES = tb/matrix_datatypes.sv

# DPI
C_FILES   = dpi/refmod.c

# Interface
IF_FILES  = tb/matrix_if.sv

# TB
TB_FILES  = \
	tb/matrix_scb.sv  \
	tb/matrix_seqr.sv \
	tb/matrix_drv.sv  \
	tb/matrix_mon.sv  \
	tb/tb_matrix.sv

ASSERT_FILES = tb/matrix_assertion.sv

# Functional coverage
COV_FILES = tb/matrix_coverage.sv

# VCS
FSDB_FILE = $(BLOCK)
VCS_KDB   = -kdb
VCS_DEBUG = -debug_access+all +ntb_random_seed=random
VCS_FLAGS = -full64 -sverilog -l ./vcs_logger.log $(VCS_KDB) $(VCS_DEBUG) -timescale=1ns/1ps

# Cobertura de codigo (line/toggle/branch/condition/fsm) + cobertura
# funcional (covergroup), coletadas automaticamente pelo VCS com -cm ativo
# (mesma convencao usada em adder2p0/Makefile).
VCS_COV_METRICS = line+cond+fsm+branch+tgl
VCS_COV_FLAGS   = -cm $(VCS_COV_METRICS)

all: vcs run

vcs:
	vcs $(VCS_FLAGS) $(VCS_COV_FLAGS) $(PKG_FILES) $(C_FILES) $(IF_FILES) $(RTL_FILES) $(ASSERT_FILES) $(COV_FILES) $(TB_FILES)

run:
	./simv +FSDB=$(BLOCK).fsdb $(VCS_COV_FLAGS)
	@mkdir -p sim
	@cp -f $(BLOCK).fsdb sim/ 2>/dev/null || true
	@cp -f vcs_logger.log sim/ 2>/dev/null || true

gui:
	./simv -gui

verdi_wf:
	verdi -play cmd/$(BLOCK).cmd

verdi_wf_easy:
	verdi -nologo -ssf $(BLOCK).fsdb

verdi_sc:
	verdi -play schematic-top.cmd

# gera o relatorio textual/HTML de cobertura (Unified Report Generator)
cov:
	urg -dir simv.vdb -report urgReport

# abre o banco de cobertura (simv.vdb) na GUI de cobertura do Verdi
verdi_cov:
	verdi -cov -covdir simv.vdb

clean: vcs_clean

vcs_clean:
	rm -rf csrc *.daidir simv *.log *.key *.conf *.rc *.fsdb verdiLog/ simv.vdb vdCovLog urgReport vc_hdrs.h sysBusyPLog
