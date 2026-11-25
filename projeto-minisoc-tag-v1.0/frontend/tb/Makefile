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

# abre o Verdi com o design compilado (e as waves .fsdb, se existirem)
verdi:
	verdi -dbdir simv.daidir $(if $(wildcard *.fsdb),-ssf $(firstword $(wildcard *.fsdb))) &

# roda a simulacao interativa ja dentro do Verdi
verdi_run:
	./simv -gui=verdi &

help:
	@echo 'type make vcs_comp to compile'
	@echo 'type make vcs_run to run'
	@echo 'type make verdi to open Verdi'
	@echo 'type make verdi_run to simulate inside Verdi'

clean:
	rm -rf csrc simv.daidir *.log
	rm -rf simv ucli.key *.vpd verdiLog *.fsdb novas.*