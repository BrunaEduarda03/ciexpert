//-----------------------------------------------------------------------------
// clk_cfg.sv
// Configuracao do VIP de CLOCK. Os tempos sao inteiros em picossegundos para
// nao depender do timescale de cada arquivo.
//-----------------------------------------------------------------------------
class clk_cfg extends uvm_object;

  virtual clk_if vif;                  // interface dirigida por este clock

  int unsigned period_ps      = 500;   // 500 ps = 2 GHz (REQ-CLK-01)
  int unsigned duty_pct       = 50;    // ciclo de trabalho em %
  int unsigned start_delay_ps = 0;     // atraso antes da primeira borda
  bit          enable         = 1'b1;  // 0 = clock parado em 0

  `uvm_object_utils_begin(clk_cfg)
    `uvm_field_int(period_ps,      UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(duty_pct,       UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(start_delay_ps, UVM_DEFAULT | UVM_DEC)
    `uvm_field_int(enable,         UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "clk_cfg");
    super.new(name);
  endfunction

  function int unsigned high_ps();
    return (period_ps * duty_pct) / 100;
  endfunction

  function int unsigned low_ps();
    return period_ps - high_ps();
  endfunction

  function real freq_mhz();
    return 1.0e6 / real'(period_ps);
  endfunction

  // Retorna 0 e uma mensagem quando a configuracao e invalida.
  function bit is_valid(output string msg);
    msg = "";
    if (period_ps < 2) begin
      msg = $sformatf("period_ps=%0d invalido (minimo 2)", period_ps);
      return 0;
    end
    if (duty_pct == 0 || duty_pct >= 100) begin
      msg = $sformatf("duty_pct=%0d invalido (1..99)", duty_pct);
      return 0;
    end
    if (high_ps() == 0 || low_ps() == 0) begin
      msg = "periodo/duty resultam em fase alta ou baixa nula";
      return 0;
    end
    return 1;
  endfunction

endclass : clk_cfg
