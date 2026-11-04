// equivalente UVM da task adder32_mon() (adder2p0/tb/adder32_mon.sv)
class adder32_monitor extends uvm_monitor;

  `uvm_component_utils(adder32_monitor)

  virtual adder32_if vif;

  // por onde o monitor "publica" a transacao observada (o scoreboard escuta aqui)
  uvm_analysis_port #(adder32_seq_item) ap;

  function new(string name = "adder32_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual adder32_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "virtual interface 'vif' nao encontrada no config_db")
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    adder32_seq_item tr;

    forever begin
      // -- mesmo corpo da task adder32_mon() original --
      @(posedge vif.clk);
      @(posedge vif.clk);
      #3ns;

      tr = adder32_seq_item::type_id::create("tr");
      // driver segura op_a/op_b estaveis (ver adder32_driver), entao da pra
      // capturar estimulo + resposta juntos, numa unica transacao completa
      tr.a         = vif.cb_mon.op_a;
      tr.b         = vif.cb_mon.op_b;
      tr.adder_out = vif.cb_mon.adder_out;
      tr.carry_out = vif.cb_mon.carry_out;

      `uvm_info("MON", $sformatf("captured adder_out=%0d carry_out=%0b", tr.adder_out, tr.carry_out), UVM_MEDIUM)

      ap.write(tr);
    end
  endtask: run_phase

endclass: adder32_monitor
