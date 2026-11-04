// equivalente UVM da function adder32_scb() (adder2p0/tb/adder32_scb.sv),
// so que acionada por TLM (write()) toda vez que o monitor publica uma transacao
class adder32_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(adder32_scoreboard)

  // "porta de entrada" que o monitor.ap vai conectar (feito no env, passo 10)
  uvm_analysis_imp #(adder32_seq_item, adder32_scoreboard) item_export;

  int num_passed;
  int num_failed;

  function new(string name = "adder32_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    item_export = new("item_export", this);
  endfunction: new

  // chamado automaticamente pelo TLM sempre que o monitor faz ap.write(tr)
  function void write(adder32_seq_item tr);
    logic [32:0] dut_r;
    logic [32:0] rfm_r;

    dut_r = {tr.carry_out, tr.adder_out};
    rfm_r = refmod(tr.a, tr.b, 0);

    if (dut_r != rfm_r) begin
      num_failed++;
      `uvm_error("SCB", $sformatf("MISMATCH a=%0d b=%0d dut=%0d rfm=%0d", tr.a, tr.b, dut_r, rfm_r))
    end else begin
      num_passed++;
      `uvm_info("SCB", $sformatf("PASS a=%0d b=%0d dut=%0d rfm=%0d", tr.a, tr.b, dut_r, rfm_r), UVM_LOW)
    end
  endfunction: write

  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("RESUMO: passed=%0d failed=%0d", num_passed, num_failed), UVM_NONE)
  endfunction: report_phase

endclass: adder32_scoreboard
