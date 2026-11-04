//-----------------------------------------------------------------------------
// minisoc_env_cfg.sv
// Configuracao do ambiente: agrupa as configuracoes de cada agente e as
// virtual interfaces. Os valores default seguem o VPLAN (ST-CLK-01/02).
//-----------------------------------------------------------------------------
class minisoc_env_cfg extends uvm_object;
  `uvm_object_utils(minisoc_env_cfg)

  clk_cfg ref_clk;    // clk: referencia 2 GHz (500 ps)
  clk_cfg mem_clk;    // mem_clk: MEMORY DATA, 100 MHz nominal
  rst_cfg rst;        // rst_n

  virtual minisoc_probe_if probe_vif;

  function new(string name = "minisoc_env_cfg");
    super.new(name);
    ref_clk           = clk_cfg::type_id::create("ref_clk");
    ref_clk.period_ps = 500;
    mem_clk           = clk_cfg::type_id::create("mem_clk");
    mem_clk.period_ps = 10000;
    rst               = rst_cfg::type_id::create("rst");
  endfunction

  function string convert2string();
    return $sformatf("ref_clk=%0d ps | mem_clk=%0d ps | reset inicial=%0d ciclos",
                     ref_clk.period_ps, mem_clk.period_ps, rst.assert_cycles);
  endfunction

endclass : minisoc_env_cfg
