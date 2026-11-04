BLOCK    ?= adder32


# RTL
RTL_FILES = rtl/$(BLOCK).v

# PACKAGE FILE
PKG_FILES = tb/$(BLOCK)_datatypes.sv

# DPI
C_FILES   = dpi/refmod.c

# Interface
IF_FILES  = tb/$(BLOCK)_if.sv

# TB
TB_FILES  = \
	tb/$(BLOCK)_scb.sv       \
	tb/$(BLOCK)_seqr.sv      \
	tb/$(BLOCK)_drv.sv       \
	tb/$(BLOCK)_mon.sv       \
	tb/tb_$(BLOCK).sv

ASSERT_FILES = tb/adder32_assertion.sv

# Functional coverage (Atividade 13)
COV_FILES = tb/adder32_coverage.sv

# VCS
FSDB_FILE = $(BLOCK)
VCS_KDB   = -kdb
VCS_DEBUG = -debug_access+all +ntb_random_seed=random
VCS_FLAGS = -full64 -sverilog -l ./vcs_logger.log $(VCS_KDB) $(VCS_DEBUG) -timescale=1ns/1ps

# Atividade 12: cobertura de codigo (line/toggle/branch/condition/fsm).
# Atividade 13: cobertura funcional (covergroup) e coletada automaticamente
# pelo VCS sempre que -cm esta ativo (nao ha uma keyword "cvg" separada
# nesta versao do VCS -- as flags validas sao: line cond fsm tgl branch
# obc path assert sdc property_path).
# Sem -cm_dir: usa o default do VCS (./simv.vdb), que o vcs_clean abaixo ja limpava.
VCS_COV_METRICS = line+cond+fsm+branch+tgl
VCS_COV_FLAGS   = -cm $(VCS_COV_METRICS)

all: vcs run

vcs:
	vcs $(VCS_FLAGS) $(VCS_COV_FLAGS) $(PKG_FILES) $(C_FILES) $(IF_FILES) $(RTL_FILES) $(ASSERT_FILES) $(COV_FILES) $(TB_FILES)

run:
	./simv +FSDB=$(BLOCK).fsdb $(VCS_COV_FLAGS)

gui:
	./simv -gui

verdi_wf:
	verdi -play cmd/$(BLOCK).cmd

verdi_wf_easy:
	verdi -nologo -ssf $(BLOCK).fsdb

verdi_sc:
	verdi -play schematic-top.cmd

# Atividade 12: gera o relatorio textual/HTML de cobertura (Unified Report Generator)
cov:
	urg -dir simv.vdb -report urgReport

# Atividade 12: abre o banco de cobertura (simv.vdb) na GUI de cobertura do Verdi
verdi_cov:
	verdi -cov -covdir simv.vdb

clean: vcs_clean

vcs_clean:
	rm -rf csrc *.daidir simv *.log *.key *.conf *.rc *.fsdb verdiLog/ simv.vdb vdCovLog urgReport vc_hdrs.h sysBusyPLog
