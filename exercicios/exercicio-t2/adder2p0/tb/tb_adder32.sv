/**
 * Adder
 *
 * @brief : example of a more organized adder32-tb
 * @author: gvillanovanm
 */

//
// imports
//
import adder32_datatypes_pkg::*;

module adder_tb;
  //
  // localparams
  //
  localparam int ADDER32_NBW = 32;

  // 
  // clk/rst gen
  //
  localparam int CLK_PERIOD = 10ns;
  logic clk = 0;
  logic reset_n;

  always #(CLK_PERIOD/2) clk = ~clk;

  //
  // interfaces
  //
  adder32_if #(
    .NBW    (ADDER32_NBW )
  ) uu_adder32_if (
    .clk    (clk         ),
    .reset_n(reset_n     )
  );

  // this is not a instance, it is a "pointer" for real obj
  virtual adder32_if adder32_vif;

  //
  // DUT Instanciation
  //
  adder uu_adder (
    .clk       (clk                    ),
    .reset_n   (reset_n                ),

    // in
    .en        (uu_adder32_if.en       ),
    .op_a      (uu_adder32_if.op_a     ),
    .op_b      (uu_adder32_if.op_b     ),

    // out
    .adder_out (uu_adder32_if.adder_out),
    .carry_out (uu_adder32_if.carry_out)
  );

  //
  // assert module
  //
  adder32_assertion uu_adder32_assertion(
    .clk       (clk                    ),
    .reset_n   (reset_n                ),

    // in (Atividade 15: latencia/retencao/causalidade do carry)
    .en        (uu_adder32_if.en       ),
    .op_a      (uu_adder32_if.op_a     ),
    .op_b      (uu_adder32_if.op_b     ),

    // out
    .adder_out (uu_adder32_if.adder_out),
    .carry_out (uu_adder32_if.carry_out)
  );

  //
  // functional coverage (Atividade 13)
  //
  adder32_coverage uu_adder32_coverage(
    .clk       (clk                    ),
    .reset_n   (reset_n                ),
    .en        (uu_adder32_if.en       ),

    // in
    .op_a      (uu_adder32_if.op_a     ),
    .op_b      (uu_adder32_if.op_b     ),

    // out
    .carry_out (uu_adder32_if.carry_out)
  );


  //
  // tb variables AND control panel of tesbench
  //
  
  // sequence item
  adder32_seq_item_t adder32_seq_item;

  // rfm
  longint unsigned rfm_r;
  logic [32:0] dut_r;

  // TB control variables
  localparam int NUM_OF_SEQUENCES = 100; // Atividade 11: 100 sequencias self-checking
  localparam int NUM_RANDOM_SEQUENCES = 5; // Atividade 9: transacoes do modo RANDOM
  localparam int NUM_BURST_SEQUENCES   = 3; // Atividade 10: transacoes com EN_BURST
  localparam int NUM_DISABLE_SEQUENCES = 3; // Atividade 10: transacoes com EN_DISABLE
  localparam int NUM_ENRANDOM_SEQUENCES = 6; // Atividade 10: transacoes com EN_RANDOM
  string testname = "stimulus_modes"; // Atividade 14 (etapa 2): estimulo dirigido fecha os bins que RANDOM nao fecha
  // ...

  //
  // DPI
  // ref: https://www.consulting.amiq.com/2019/01/30/how-to-call-c-functions-from-systemverilog-using-dpi-c/
  import "DPI-C" function longint unsigned refmod(
    input longint unsigned a,
    input longint unsigned b,
    input bit en_log
  );

  //
  // main sequence
  //
  initial begin
    $display("Test started...");

    // vif
    adder32_vif = uu_adder32_if;

    // reset sequence
    reset_n = 1'bx;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    reset_n = 1'b0;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    reset_n = 1'b1;

    // "sync" with clock
    @(posedge clk);

      case (testname)
        "baseline": begin
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# Baseline Test");
          $display("#");
          $display("# --------------------------");
          $display("# NUM_OF_SEQUENCES: %0d", NUM_OF_SEQUENCES);
          repeat(NUM_OF_SEQUENCES) begin
            // seqr (modo RANDOM preserva o comportamento original deste teste)
            adder32_seq_item = adder32_seqr(RANDOM, 0);

            // driver+monitor (EN_BURST preserva o comportamento original: en sempre 1)
            adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
            adder32_mon(adder32_vif, dut_r, 0);

            // rfm
            rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);

            // scoreboard
            adder32_scb(dut_r, unsigned'(rfm_r), 1);
          end

          // Atividade 11: resumo final de matches/mismatches
          adder32_scb_report();
        end

        "stimulus_modes": begin
          // Atividade 9: coletanea de estimulos controlaveis no sequencer,
          // um modo por vez, cada um com sua propria janela na waveform.
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# Atividade 9 - Stimulus Modes");
          $display("#");
          $display("# --------------------------");

          // BASIC -> T1
          $display("# ---- mode: BASIC @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(BASIC, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "BASIC", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // ZERO -> T2
          $display("# ---- mode: ZERO @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(ZERO, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "ZERO", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // MAX -> T3
          $display("# ---- mode: MAX @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(MAX, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "MAX", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // CARRY -> T4
          $display("# ---- mode: CARRY @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(CARRY, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "CARRY", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // NO_CARRY -> T5
          $display("# ---- mode: NO_CARRY @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(NO_CARRY, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "NO_CARRY", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // PATTERN -> T6
          $display("# ---- mode: PATTERN @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(PATTERN, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "PATTERN", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // SMALL -> apoio CP9 (value_range: baixo)
          $display("# ---- mode: SMALL @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(SMALL, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "SMALL", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // BIG -> apoio CP9 (value_range: alto)
          $display("# ---- mode: BIG @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(BIG, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "BIG", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // MINMAX -> apoio CP1-CP4
          $display("# ---- mode: MINMAX @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(MINMAX, 1);
          $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "MINMAX", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // RANDOM -> T11 (varias transacoes)
          $display("# ---- mode: RANDOM (%0d transacoes) @ t=%0t ----", NUM_RANDOM_SEQUENCES, $time);
          repeat (NUM_RANDOM_SEQUENCES) begin
            adder32_seq_item = adder32_seqr(RANDOM, 1);
            $display("[STIMULUS] mode=%s op_a=32'h%08h op_b=32'h%08h", "RANDOM", adder32_seq_item.a, adder32_seq_item.b);
            adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
            adder32_mon(adder32_vif, dut_r, 0);
            rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
            adder32_scb(dut_r, unsigned'(rfm_r), 1);
          end

          // Atividade 14: estimulos dirigidos para fechar os bins que RANDOM
          // puro nao fecha isoladamente (op_b=zero, en=disabled, e os
          // cruzamentos com reset). cp_carry/cx_carry_en amostram carry_out
          // (saida do DUT), que so atualiza quando en=1; por isso, para
          // cobrir cada combinacao "x disabled", primeiro fixamos o valor de
          // carry_out desejado com en=1 e so depois mantemos en=0 (retencao).
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# Atividade 14 - Directed Coverage Closure");
          $display("#");
          $display("# --------------------------");

          // D1: op_b=0 (op_a != 0), en=1 -> fecha cp_op_b bin "zero"
          $display("# ---- directed D1: op_b=0 @ t=%0t ----", $time);
          adder32_seq_item.a = 32'hDEAD_BEEF;
          adder32_seq_item.b = 32'h0000_0000;
          $display("[DIRECTED] op_a=32'h%08h op_b=32'h%08h en_mode=EN_BURST", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // D2: latch carry_out=1 com en=1 (a=b=max garante overflow)
          $display("# ---- directed D2: latch carry=1 (en=1) @ t=%0t ----", $time);
          adder32_seq_item.a = 32'hFFFF_FFFF;
          adder32_seq_item.b = 32'hFFFF_FFFF;
          $display("[DIRECTED] op_a=32'h%08h op_b=32'h%08h en_mode=EN_BURST", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // D3: en=0 logo em seguida -> carry_out retem 1, fecha cx_carry_en
          //     "carry x disabled" e cp_en bin "disabled"
          $display("# ---- directed D3: en=0 retendo carry=1 @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(RANDOM, 0);
          adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 0); // mismatch esperado: dut_r retem valor antigo (en=0), rfm_r calcula o par novo

          // D4: latch carry_out=0 com en=1 (a=b=0 garante ausencia de overflow)
          $display("# ---- directed D4: latch carry=0 (en=1) @ t=%0t ----", $time);
          adder32_seq_item.a = 32'h0000_0000;
          adder32_seq_item.b = 32'h0000_0000;
          $display("[DIRECTED] op_a=32'h%08h op_b=32'h%08h en_mode=EN_BURST", adder32_seq_item.a, adder32_seq_item.b);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 1);

          // D5: en=0 logo em seguida -> carry_out retem 0, fecha cx_carry_en "no_carry x disabled"
          $display("# ---- directed D5: en=0 retendo carry=0 @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(RANDOM, 0);
          adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 0);
          adder32_mon(adder32_vif, dut_r, 0);
          rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          adder32_scb(dut_r, unsigned'(rfm_r), 0); // mismatch esperado: retencao (en=0)

          // D6: manter en=0 durante um 2o pulso de reset -> fecha cx_reset_en "in_reset x disabled"
          $display("# ---- directed D6: en=0 durante reset (2o pulso) @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(RANDOM, 0);
          adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 0);
          @(posedge clk);
          reset_n = 1'b0;
          @(posedge clk);
          @(posedge clk);
          reset_n = 1'b1;
          @(posedge clk);

          // D7: manter en=1 durante um 3o pulso de reset -> fecha cx_reset_en "in_reset x enabled"
          $display("# ---- directed D7: en=1 durante reset (3o pulso) @ t=%0t ----", $time);
          adder32_seq_item = adder32_seqr(RANDOM, 0);
          adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 0);
          @(posedge clk);
          reset_n = 1'b0;
          @(posedge clk);
          @(posedge clk);
          reset_n = 1'b1;
          @(posedge clk);
        end

        "en_modes": begin
          // Atividade 10: controle do sinal en no driver (RANDOM / BURST / DISABLE).
          // Usa os estimulos da Atividade 9 (adder32_seqr em modo RANDOM) para variar op_a/op_b
          // em cada transacao, isolando assim o efeito do en_mode sobre adder_out/carry_out.
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# Atividade 10 - EN Modes");
          $display("#");
          $display("# --------------------------");

          // BURST -> T7, F4, F6 (en=1 constante, DUT atualiza a cada transacao)
          $display("# ---- en_mode: EN_BURST (%0d transacoes) @ t=%0t ----", NUM_BURST_SEQUENCES, $time);
          repeat (NUM_BURST_SEQUENCES) begin
            adder32_seq_item = adder32_seqr(RANDOM, 0);
            adder32_drv(adder32_vif, adder32_seq_item, EN_BURST, 1);
            adder32_mon(adder32_vif, dut_r, 0);
            rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
            adder32_scb(dut_r, unsigned'(rfm_r), 0);
          end

          // DISABLE -> T8, F5 (en=0 constante, saida deve reter o ultimo valor do bloco BURST)
          $display("# ---- en_mode: EN_DISABLE (%0d transacoes) @ t=%0t ----", NUM_DISABLE_SEQUENCES, $time);
          repeat (NUM_DISABLE_SEQUENCES) begin
            adder32_seq_item = adder32_seqr(RANDOM, 0);
            adder32_drv(adder32_vif, adder32_seq_item, EN_DISABLE, 1);
            adder32_mon(adder32_vif, dut_r, 0);
            rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
            adder32_scb(dut_r, unsigned'(rfm_r), 0);
          end

          // RANDOM -> T11, F4, F5 (en alterna 0/1 aleatoriamente a cada transacao)
          $display("# ---- en_mode: EN_RANDOM (%0d transacoes) @ t=%0t ----", NUM_ENRANDOM_SEQUENCES, $time);
          repeat (NUM_ENRANDOM_SEQUENCES) begin
            adder32_seq_item = adder32_seqr(RANDOM, 0);
            adder32_drv(adder32_vif, adder32_seq_item, EN_RANDOM, 1);
            adder32_mon(adder32_vif, dut_r, 0);
            rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
            adder32_scb(dut_r, unsigned'(rfm_r), 0);
          end
        end

        "other_case": begin
          $display("other_case");
        end
      endcase

    #10ns;
    $finish;
  end

  reg [8*200:1] fsdb_name;
  initial begin
    if (!$value$plusargs("FSDB=%s", fsdb_name))
      fsdb_name = "adder32.fsdb";

    $display("[TB] FSDB file = %0s", fsdb_name);
    $fsdbDumpfile(fsdb_name);
    $fsdbDumpvars();
  end
endmodule
