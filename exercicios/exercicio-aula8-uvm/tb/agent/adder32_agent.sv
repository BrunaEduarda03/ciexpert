// embala sequencer + driver + monitor num unico componente reutilizavel
class adder32_agent extends uvm_agent;

  `uvm_component_utils(adder32_agent)

  adder32_sequencer sequencer;
  adder32_driver     driver;
  adder32_monitor     monitor;

  function new(string name = "adder32_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = adder32_sequencer::type_id::create("sequencer", this);
    driver    = adder32_driver::type_id::create("driver", this);
    monitor   = adder32_monitor::type_id::create("monitor", this);
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // liga o "pedir proximo item" do driver a fila do sequencer
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction: connect_phase

endclass: adder32_agent
