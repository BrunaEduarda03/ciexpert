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

# VCS
FSDB_FILE = $(BLOCK)
VCS_KDB   = -kdb 
VCS_DEBUG = -debug_access+all +ntb_random_seed=random
VCS_FLAGS = -full64 -sverilog -l ./vcs_logger.log $(VCS_KDB) $(VCS_DEBUG) -timescale=1ns/1ps

all: vcs run

vcs:
	vcs $(VCS_FLAGS) $(PKG_FILES) $(C_FILES) $(IF_FILES) $(RTL_FILES) $(ASSERT_FILES) $(TB_FILES) 

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
	rm -rf csrc *.daidir simv *.log *.key *.conf *.rc *.fsdb verdiLog/ simv.vdb vdCovLog vc_hdrs.h sysBusyPLog
