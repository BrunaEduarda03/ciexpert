BLOCK    ?= adder32

# RTL
RTL_FILES = rtl/$(BLOCK).v

# TB
TB_FILES  = tb/tb_$(BLOCK).v

# VCS
FSDB_FILE = $(BLOCK)
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
