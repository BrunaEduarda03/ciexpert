# select a single block
# include Makefile.aes
# include Makefile.spi
# include Makefile.pll
# include Makefile.mem
include Makefile.top

# opens the included select to run the test

vcs_run:
	./simv

vcs_gui:
	./simv -gui

help:
	@echo 'type make vcs_comp to compile'
	@echo 'type make vcs_run to run'

clean:
	rm -rf csrc simv.daidir *.log
	rm -rf simv ucli.key *.vpd verdiLog *.fsdb novas.*