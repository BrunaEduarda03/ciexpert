// teste default (+UVM_TESTNAME=baseline no Makefile aponta pra essa classe)
class baseline extends uvm_test;

  `uvm_component_utils(baseline)

  adder32_env env;

  function new(string name = "baseline", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = adder32_env::type_id::create("env", this);
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    adder32_baseline_seq seq;

    phase.raise_objection(this);

    seq = adder32_baseline_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    // folga pro monitor terminar de amostrar o ultimo item antes de fechar
    #100ns;

    phase.drop_objection(this);
  endtask: run_phase

endclass: baseline
