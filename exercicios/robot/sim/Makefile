# VCS
FSDB_FILE = $(BLOCK)

KDB       = ./simv.daidir
FSDB      = robot.fsdb
VCS_KDB   = -kdb 
VCS_DEBUG = -debug_access+all
VCS_TIMES = # -timescale=1ns/1ps
VCS_FLAGS = -full64 -l ./vcs_logger.log $(VCS_KDB) $(VCS_DEBUG) $(VCS_TIMES)

robot: robot_comp robot_sim robot_wav

robot_comp:
	vcs $(VCS_FLAGS) -f rtl_file_list.f

robot_sim:
	./simv -no_save -l simv.log	

robot_gui:
	./simv -gui=verdi -l simv.log -sml=verdi

robot_wav:
	verdi -play robot-wave.cmd -l simv.log

robot_verdi: robot_comp robot_sim
	verdi -dbdir ./simv.daidir -ssf robot.fsdb -sswr robot-signals.rc

robot_restart: robot_comp robot_sim






### 
### to rec:
###

SOC_Verification: comp sim

SOC_Interactive_Debug: clean ana comp_interactive_debug sim_debug_interactive

SOC_PP_Debug: clean comp_pp_debug sim debug

clean:
	rm -rf simv* csrc* *.log  verdiLog novas.fsdb novas.rc novas.conf *.key *.fsdb

ana_core:
	vlogan  -l an_top.log -f rtl_file_list.f
	vlogan  -l an_tb.log -kdb -work tb -ntb_opts -f tb_robot 

ana: ana_core

ana_pp: ana_core
	vlogan -l an_tb.log -sverilog -kdb -work tb -ntb_opts uvm -f tb.f +define+DUMP

ana_xprop: ana_core
	vlogan -l  an_ethmac.log -sverilog -kdb -work  ethmac -f ethmac.f +define+MEM_INITIALIZE_FIX

comp:
	vcs -f rtl_file_list.f -l comp.log

comp_pp_debug:
	vcs -f rtl_file_list.f -debug_access -kdb -l comp.log

comp_interactive_debug:
	vcs robot_tb_top test -debug_access+all -kdb l comp.log

comp_cov:
	vcs  robot_tb_top test -kdb -l comp.log -cm line+cond+tgl+fsm+branch+assert

sim:
	./simv  -l simv.log	

sim_debug_interactive:
	./simv  -gui=verdi -l simv.log	

sim_cov:
	./simv  -l simv.log -cm line+cond+tgl+fsm+branch+assert +enable_coverage=1

debug:
	verdi -nologo -ssf robot_model.fsdb &


report_cov:
	verdi -cov -covdir simv.vdb


