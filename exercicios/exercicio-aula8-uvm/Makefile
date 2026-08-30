BLOCKNAME = blockname

#
# RTL
#
RTL_DIR   ?= ./rtl
DUT_FILES := $(wildcard $(RTL_DIR)/*.sv)

#
# Verification
#

# top
TB_TOP_FILE = tb/$(BLOCKNAME)_tb_top.sv

# packages
PKG_FILES   = \
	tb/$(BLOCKNAME)_pkg.sv

# uvm
UVM_VERSION  = uvm-1.2
UVM_SEED     = 1
UVM_DEFINES  = UVM_NO_DEPRECATED+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
UVM_PLUSARGS =
UVM_TESTNAME = baseline # options: ...

#
# VCS Setup/Config
#

# compile flags
SIM            = vcs
OUT_DIR        = build/$(SIM)
LOG_DIR        = $(OUT_DIR)/logs
SRC_BUNDLE     = $(PKG_FILES) $(DUT_FILES) $(TB_TOP_FILE)
VCS_FLAGS_BASE = -sverilog -full64 -l $(LOG_DIR)/vcs_comp.log -kdb -debug_access+all +incdir+tb/ -timescale=1ns/1ps
VCS_UVM_FLAGS  = -ntb_opts $(UVM_VERSION)
VCS_SEED_FLAG  = +ntb_random_seed=$(UVM_SEED)
VCS_RUN_FLAGS  = $(VCS_FLAGS_BASE) $(VCS_UVM_FLAGS)	$(VCS_SEED_FLAG)

# compiling
vcs_compil:
	@echo "[VCS] Compiling "
	@mkdir -p $(OUT_DIR)
	@mkdir -p $(LOG_DIR)
	$(SIM) 						\
	$(VCS_RUN_FLAGS)  \
	$(SRC_BUNDLE) -o $(BLOCKNAME)

# run
vcs_run:
	@echo "[VCS] Running"
	./$(BLOCKNAME) $(VCS_RUN_FLAGS) 

# +UVM_TESTNAME=

# all
vcs_all: vcs_compil vcs_run

# full all
vcs_fall: vcs_clean vcs_compil vcs_run

# help
vcs_help:
	vcs -help > vcs_help.txt

# clean artifacts
vcs_clean:
	rm -rf build/ $(BLOCKNAME).daidir *.key $(BLOCKNAME) csrc vc_hdrs.h vcs_help.txt

#
# Verdi Setup/Config
#

# gui:
verdi_gui:
	@echo "[VCS] Launching Verdi"
	verdi -play $(BLOCKNAME).cmd	

#
# common
#
# ...