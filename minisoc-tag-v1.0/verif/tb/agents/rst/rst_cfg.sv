//-----------------------------------------------------------------------------
// rst_cfg.sv
// Configuracao do VIP de RESET. A duracao do reset inicial e randomizada
// dentro da faixa do VPLAN (ST-RST-01: >= 10 ciclos de clk).
//-----------------------------------------------------------------------------
class rst_cfg extends uvm_object;

  virtual rst_if vif;

  rand int unsigned assert_cycles;   // ciclos de clk com rst_n = 0 no reset inicial

  constraint c_assert_cycles { assert_cycles inside {[10:50]}; }

  `uvm_object_utils_begin(rst_cfg)
    `uvm_field_int(assert_cycles, UVM_DEFAULT | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "rst_cfg");
    super.new(name);
    assert_cycles = 10;
  endfunction

endclass : rst_cfg
