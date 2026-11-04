package adder32_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // modelo de referencia em C (mesmo usado em adder2p0/dpi/refmod.c)
  import "DPI-C" function longint unsigned refmod(
    input longint unsigned a,
    input longint unsigned b,
    input bit en_log
  );

  // as classes vao entrando aqui, na ordem de dependencia:
  // seq_item -> sequencer -> driver -> monitor -> agent -> scoreboard -> env -> sequence -> test
  `include "agent/adder32_seq_item.sv"
  `include "agent/adder32_sequencer.sv"
  `include "agent/adder32_driver.sv"
  `include "agent/adder32_monitor.sv"
  `include "agent/adder32_agent.sv"
  `include "env/adder32_scoreboard.sv"
  `include "env/adder32_env.sv"
  `include "tests/adder32_baseline_seq.sv"
  `include "tests/baseline.sv"

endpackage: adder32_pkg
