// equivalente UVM da task adder32_drv() (adder2p0/tb/adder32_drv.sv)
class adder32_driver extends uvm_driver #(adder32_seq_item);

  `uvm_component_utils(adder32_driver)

  virtual adder32_if vif;

  function new(string name = "adder32_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // mesma vif que o tb_top vai publicar no config_db (passo 13)
    if (!uvm_config_db#(virtual adder32_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "virtual interface 'vif' nao encontrada no config_db")
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);

      // -- mesmo corpo da task adder32_drv() original --
      @(posedge vif.clk);
      vif.cb_drv.en   <= 1'b1;
      vif.cb_drv.op_a <= req.a;
      vif.cb_drv.op_b <= req.b;

      `uvm_info("DRV", $sformatf("driving a=%0d b=%0d", req.a, req.b), UVM_MEDIUM)

      seq_item_port.item_done();

      // driver e monitor agora sao processos independentes (nao mais uma
      // chamada sequencial drv()->mon() como no adder2p0): esperamos aqui o
      // mesmo numero de ciclos que o monitor espera pra amostrar, senao o
      // proximo item sobrescreve op_a/op_b antes do monitor ler o atual.
      @(posedge vif.clk);
      @(posedge vif.clk);
    end
  endtask: run_phase

endclass: adder32_driver
