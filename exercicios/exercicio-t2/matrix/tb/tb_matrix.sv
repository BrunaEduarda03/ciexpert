/**
 * Matrix2x2
 *
 * @brief : ambiente de verificacao do matrix2x2_mult (rtl/matrixmult.v),
 *          construido do zero reaproveitando exatamente a arquitetura do
 *          Adder32 (adder2p0/tb/tb_adder32.sv): sequencer -> driver ->
 *          monitor -> reference model (DPI-C) -> scoreboard, com assertions
 *          e cobertura funcional observando a interface diretamente.
 * @author: gerado a partir do caderno Fase 2 - PARTE I (Capitulo 4, Matrix2x2 Project)
 */

//
// imports
//
import matrix_datatypes_pkg::*;

module matrix_tb;
  //
  // localparams
  //
  localparam int MATRIX_NBW = 32;

  //
  // clk/rst gen
  //
  localparam int CLK_PERIOD = 10ns;
  logic clk = 0;
  logic rstn;

  always #(CLK_PERIOD/2) clk = ~clk;

  //
  // interfaces
  //
  matrix_if #(
    .NBW  (MATRIX_NBW)
  ) uu_matrix_if (
    .clk  (clk       ),
    .rstn (rstn      )
  );

  // this is not a instance, it is a "pointer" for real obj
  virtual matrix_if matrix_vif;

  //
  // DUT Instanciation (nomes de porta preservados: A, B, Res, clk, rstn, en)
  //
  matrix2x2_mult uu_matrix (
    .A    (uu_matrix_if.A  ),
    .B    (uu_matrix_if.B  ),
    .Res  (uu_matrix_if.Res),
    .clk  (clk             ),
    .rstn (rstn             ),
    .en   (uu_matrix_if.en )
  );

  //
  // assert module
  //
  matrix_assertion uu_matrix_assertion (
    .clk  (clk             ),
    .rstn (rstn             ),

    .en   (uu_matrix_if.en ),
    .A    (uu_matrix_if.A  ),
    .B    (uu_matrix_if.B  ),

    .Res  (uu_matrix_if.Res)
  );

  //
  // functional coverage
  //
  matrix_coverage uu_matrix_coverage (
    .clk  (clk             ),
    .rstn (rstn             ),
    .en   (uu_matrix_if.en ),

    .A    (uu_matrix_if.A  ),
    .B    (uu_matrix_if.B  )
  );

  //
  // tb variables AND control panel of testbench
  //

  // sequence item
  matrix_seq_item_t matrix_seq_item;

  // rfm
  longint unsigned rfm_r;
  logic [31:0]     dut_r;

  // TB control variables
  localparam int NUM_OF_SEQUENCES        = 100; // baseline: sequencias self-checking
  localparam int NUM_RANDOM_SEQUENCES    = 5;   // stimulus_modes: transacoes do modo RANDOM
  localparam int NUM_BURST_SEQUENCES     = 3;   // en_modes: transacoes com EN_BURST
  localparam int NUM_DISABLE_SEQUENCES   = 3;   // en_modes: transacoes com EN_DISABLE
  localparam int NUM_ENRANDOM_SEQUENCES  = 6;   // en_modes: transacoes com EN_RANDOM
  string testname = "stimulus_modes";
  // ...

  //
  // DPI
  // ref: https://www.consulting.amiq.com/2019/01/30/how-to-call-c-functions-from-systemverilog-using-dpi-c/
  import "DPI-C" function longint unsigned refmod_matrix(
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
    matrix_vif = uu_matrix_if;

    // reset sequence
    rstn = 1'bx;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    rstn = 1'b0;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    rstn = 1'b1;

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
          repeat (NUM_OF_SEQUENCES) begin
            matrix_seq_item = matrix_seqr(RANDOM, 0);

            matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
            matrix_mon(matrix_vif, dut_r, 0);

            rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);

            matrix_scb(dut_r, unsigned'(rfm_r), 1);
          end

          matrix_scb_report();
        end

        "stimulus_modes": begin
          // coletanea de estimulos controlaveis no sequencer, um modo por
          // vez, cada um com sua propria janela na waveform.
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# Stimulus Modes");
          $display("#");
          $display("# --------------------------");

          // BASIC -> T1 (conferivel a mao, ver docs/verification_plan.md)
          $display("# ---- mode: BASIC @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(BASIC, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "BASIC", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 1);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // ZERO -> T2
          $display("# ---- mode: ZERO @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(ZERO, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "ZERO", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // MAX -> T3 (overflow garantido em todo Res)
          $display("# ---- mode: MAX @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(MAX, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "MAX", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 1);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // OVERFLOW -> T4 (overflow dirigido, independente de aleatoriedade)
          $display("# ---- mode: OVERFLOW @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(OVERFLOW, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "OVERFLOW", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 1);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // NO_OVERFLOW -> T5
          $display("# ---- mode: NO_OVERFLOW @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(NO_OVERFLOW, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "NO_OVERFLOW", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 1);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // PATTERN -> T6
          $display("# ---- mode: PATTERN @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(PATTERN, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "PATTERN", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // SMALL -> apoio a cobertura (value_range: baixo)
          $display("# ---- mode: SMALL @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(SMALL, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "SMALL", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // BIG -> apoio a cobertura (value_range: alto)
          $display("# ---- mode: BIG @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(BIG, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "BIG", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // MINMAX -> cruzamento zero/maximo entre A e B
          $display("# ---- mode: MINMAX @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(MINMAX, 1);
          $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "MINMAX", matrix_seq_item.a, matrix_seq_item.b);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // RANDOM -> varias transacoes
          $display("# ---- mode: RANDOM (%0d transacoes) @ t=%0t ----", NUM_RANDOM_SEQUENCES, $time);
          repeat (NUM_RANDOM_SEQUENCES) begin
            matrix_seq_item = matrix_seqr(RANDOM, 1);
            $display("[STIMULUS] mode=%s A=32'h%08h B=32'h%08h", "RANDOM", matrix_seq_item.a, matrix_seq_item.b);
            matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
            matrix_mon(matrix_vif, dut_r, 0);
            rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
            matrix_scb(dut_r, unsigned'(rfm_r), 1);
          end

          // ---------------------------------------------------------------
          // Directed Coverage Closure (mesmo espirito da Atividade 14 do
          // Adder32): fecha bins/crosses que RANDOM puro nao fecha sozinho.
          // ---------------------------------------------------------------
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# Directed Coverage Closure");
          $display("#");
          $display("# --------------------------");

          // D1: overflow x disabled -> dirige valores de overflow (en=1,
          // fecha cp_overflow=overflow x cp_en=enabled). Em seguida, REPETE
          // os MESMOS A/B com en=0: cp_overflow(A,B) continua amostrando
          // overflow=1 (o coverpoint observa A/B correntes na interface, nao
          // Res), fechando cp_overflow=overflow x cp_en=disabled. Como A/B
          // nao mudaram, a checagem do scoreboard aqui e um MATCH legitimo
          // (retencao de um valor igual ao que o refmod recalcularia) --
          // a demonstracao de mismatch por retencao com dado NOVO ja e
          // coberta separadamente pelo teste "en_modes" (EN_DISABLE com
          // RANDOM a cada transacao).
          $display("# ---- directed D1: overflow held with en=0 @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(OVERFLOW, 0);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);
          matrix_drv(matrix_vif, matrix_seq_item, EN_DISABLE, 0); // mesmos A/B, so muda en
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1); // match esperado: A/B inalterados, retencao == recalculo

          // D1b: B=0 dirigido (A!=0) -> fecha cp_B bin "zero". ZERO e MINMAX
          // sozinhos so fecham esse bin por sorte ($urandom_range escolhe
          // entre 3/4 casos cada), exatamente a licao "random puro raramente
          // fecha cobertura" discutida no caderno (Secao 2.2.7 / Atividade 14).
          // Confirmado empiricamente: nesta mesma seed, cp_B "zero" ficou
          // descoberto ate este passo ser adicionado (ver docs/definition_of_done.md).
          $display("# ---- directed D1b: B=0 (A!=0) @ t=%0t ----", $time);
          matrix_seq_item.a = 32'hDEAD_BEEF;
          matrix_seq_item.b = 32'h0000_0000;
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 1);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);

          // D2: no_overflow x disabled (mesmo raciocinio do D1, mas para o
          // bin no_overflow: A/B mantidos entre as duas chamadas -> match
          // legitimo, fecha cp_overflow=no_overflow x cp_en=disabled)
          $display("# ---- directed D2: no_overflow held with en=0 @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(NO_OVERFLOW, 0);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1);
          matrix_drv(matrix_vif, matrix_seq_item, EN_DISABLE, 0); // mesmos A/B, so muda en
          matrix_mon(matrix_vif, dut_r, 0);
          rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
          matrix_scb(dut_r, unsigned'(rfm_r), 1); // match esperado: A/B inalterados, retencao == recalculo

          // D3: in_reset x disabled -> segundo pulso de reset com en=0
          // NOTA (achado de verificacao): rstn e trocado #1ns depois da
          // borda de posedge, nunca exatamente EM CIMA dela. Isso evita uma
          // race de amostragem SVA (preponed sampling) entre o instante em
          // que a assertion le rstn e o instante em que o RTL efetivamente
          // reage a transicao -- a mesma razao pela qual o reset inicial
          // deste testbench (acima) usa "+$urandom_range(3,0)*1ns" em vez de
          // trocar rstn exatamente na borda. No Adder32 essa race nao
          // aparecia porque adder_out E FORCADO a 0 durante o reset; aqui
          // Res NAO e tocado durante o reset (ver matrix_assertion.sv), o
          // que torna a property p_reset_res_stable mais sensivel a esse
          // alinhamento. Ver docs/definition_of_done.md, "Licoes Aprendidas".
          $display("# ---- directed D3: en=0 durante reset (2o pulso) @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(RANDOM, 0);
          matrix_drv(matrix_vif, matrix_seq_item, EN_DISABLE, 0);
          @(posedge clk);
          #1ns;
          rstn = 1'b0;
          @(posedge clk);
          @(posedge clk);
          #1ns;
          rstn = 1'b1;
          @(posedge clk);

          // D4: in_reset x enabled -> terceiro pulso de reset com en=1
          $display("# ---- directed D4: en=1 durante reset (3o pulso) @ t=%0t ----", $time);
          matrix_seq_item = matrix_seqr(RANDOM, 0);
          matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 0);
          @(posedge clk);
          #1ns;
          rstn = 1'b0;
          @(posedge clk);
          @(posedge clk);
          #1ns;
          rstn = 1'b1;
          @(posedge clk);

          matrix_scb_report();
        end

        "en_modes": begin
          // controle do sinal en no driver (RANDOM / BURST / DISABLE).
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# EN Modes");
          $display("#");
          $display("# --------------------------");

          // BURST (en=1 constante, DUT atualiza a cada transacao)
          $display("# ---- en_mode: EN_BURST (%0d transacoes) @ t=%0t ----", NUM_BURST_SEQUENCES, $time);
          repeat (NUM_BURST_SEQUENCES) begin
            matrix_seq_item = matrix_seqr(RANDOM, 0);
            matrix_drv(matrix_vif, matrix_seq_item, EN_BURST, 1);
            matrix_mon(matrix_vif, dut_r, 0);
            rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
            matrix_scb(dut_r, unsigned'(rfm_r), 0);
          end

          // DISABLE (en=0 constante, saida deve reter o ultimo valor do bloco BURST)
          $display("# ---- en_mode: EN_DISABLE (%0d transacoes) @ t=%0t ----", NUM_DISABLE_SEQUENCES, $time);
          repeat (NUM_DISABLE_SEQUENCES) begin
            matrix_seq_item = matrix_seqr(RANDOM, 0);
            matrix_drv(matrix_vif, matrix_seq_item, EN_DISABLE, 1);
            matrix_mon(matrix_vif, dut_r, 0);
            rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
            matrix_scb(dut_r, unsigned'(rfm_r), 0);
          end

          // RANDOM (en alterna 0/1 aleatoriamente a cada transacao)
          $display("# ---- en_mode: EN_RANDOM (%0d transacoes) @ t=%0t ----", NUM_ENRANDOM_SEQUENCES, $time);
          repeat (NUM_ENRANDOM_SEQUENCES) begin
            matrix_seq_item = matrix_seqr(RANDOM, 0);
            matrix_drv(matrix_vif, matrix_seq_item, EN_RANDOM, 1);
            matrix_mon(matrix_vif, dut_r, 0);
            rfm_r = refmod_matrix(matrix_seq_item.a, matrix_seq_item.b, 0);
            matrix_scb(dut_r, unsigned'(rfm_r), 0);
          end

          matrix_scb_report();
        end

        default: begin
          $display("unknown testname: %s", testname);
        end

      endcase

    #10ns;
    $finish;
  end

  reg [8*200:1] fsdb_name;
  initial begin
    if (!$value$plusargs("FSDB=%s", fsdb_name))
      fsdb_name = "matrix2x2.fsdb";

    $display("[TB] FSDB file = %0s", fsdb_name);
    $fsdbDumpfile(fsdb_name);
    $fsdbDumpvars();
  end
endmodule
