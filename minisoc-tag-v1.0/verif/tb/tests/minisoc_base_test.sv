//-----------------------------------------------------------------------------
// minisoc_base_test.sv
// Teste base: monta minisoc_env_cfg (virtual interfaces + configuracoes),
// cria o ambiente, define timeout global e imprime PASS/FAIL no report_phase.
// Testes derivados ajustam a configuracao em configure_env().
//-----------------------------------------------------------------------------
class minisoc_base_test extends uvm_test;
  `uvm_component_utils(minisoc_base_test)

  minisoc_env     env;
  minisoc_env_cfg env_cfg;

  time test_timeout = 100us;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env_cfg = minisoc_env_cfg::type_id::create("env_cfg");

    if (!uvm_config_db#(virtual clk_if)::get(this, "", "ref_clk_vif", env_cfg.ref_clk.vif))
      `uvm_fatal("TEST_NOVIF", "ref_clk_vif nao encontrado no config_db")
    if (!uvm_config_db#(virtual clk_if)::get(this, "", "mem_clk_vif", env_cfg.mem_clk.vif))
      `uvm_fatal("TEST_NOVIF", "mem_clk_vif nao encontrado no config_db")
    if (!uvm_config_db#(virtual rst_if)::get(this, "", "rst_vif", env_cfg.rst.vif))
      `uvm_fatal("TEST_NOVIF", "rst_vif nao encontrado no config_db")
    if (!uvm_config_db#(virtual minisoc_probe_if)::get(this, "", "probe_vif", env_cfg.probe_vif))
      `uvm_fatal("TEST_NOVIF", "probe_vif nao encontrado no config_db")

    if (!env_cfg.rst.randomize())
      `uvm_fatal("TEST_RAND", "falha ao randomizar rst_cfg")

    configure_env();

    uvm_config_db#(minisoc_env_cfg)::set(this, "env", "cfg", env_cfg);
    env = minisoc_env::type_id::create("env", this);

    uvm_top.set_timeout(test_timeout, 1);
  endfunction

  // Gancho para testes derivados alterarem env_cfg antes do build do env.
  virtual function void configure_env();
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
    `uvm_info(get_type_name(), {"Configuracao: ", env_cfg.convert2string()}, UVM_LOW)
  endfunction

  function void report_phase(uvm_phase phase);
    uvm_report_server rs;
    int unsigned      n_err;
    super.report_phase(phase);

    rs    = uvm_report_server::get_server();
    n_err = rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL);

    if (n_err == 0)
      `uvm_info("RESULT", $sformatf("*** TEST PASSED: %s ***", get_type_name()), UVM_NONE)
    else
      `uvm_info("RESULT", $sformatf("*** TEST FAILED: %s (%0d erros) ***", get_type_name(), n_err), UVM_NONE)
  endfunction

endclass : minisoc_base_test
