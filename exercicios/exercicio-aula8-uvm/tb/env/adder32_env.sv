// junta agent (sequencer+driver+monitor) + scoreboard
class adder32_env extends uvm_env;

  `uvm_component_utils(adder32_env)

  adder32_agent      agent;
  adder32_scoreboard scoreboard;

  function new(string name = "adder32_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = adder32_agent::type_id::create("agent", this);
    scoreboard = adder32_scoreboard::type_id::create("scoreboard", this);
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // toda transacao que o monitor publica vai direto pro scoreboard
    agent.monitor.ap.connect(scoreboard.item_export);
  endfunction: connect_phase

endclass: adder32_env
