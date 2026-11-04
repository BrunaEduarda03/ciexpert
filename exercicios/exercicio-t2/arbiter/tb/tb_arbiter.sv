/**
 * Arbiter
 *
 * @brief : ambiente de verificacao do arbiter (rtl/arbiter.v), construido do
 *          zero reaproveitando a arquitetura do Adder32 (adder2p0), adaptada
 *          para um DUT de CONTROLE/FSM: o checker roda em background, CICLO
 *          A CICLO, comparando o DUT contra um modelo de referencia (DPI-C)
 *          que reproduz a mesma FSM + latch de requisicao do RTL.
 * @author: gerado a partir do caderno Fase 2 - PARTE I (Capitulo 5, Arbiter Project)
 */

import arbiter_datatypes_pkg::*;

module arbiter_tb;
  //
  // clk/rst gen
  //
  localparam int CLK_PERIOD = 10ns;
  logic clk = 0;
  logic reset_n;

  always #(CLK_PERIOD/2) clk = ~clk;

  //
  // interface
  //
  arbiter_if uu_arbiter_if (
    .clk    (clk    ),
    .reset_n(reset_n)
  );

  virtual arbiter_if arbiter_vif;

  //
  // DUT Instanciation (nomes de porta preservados: priority_sel, client1_req,
  // client2_req, o_grant1, o_grant2, clk, reset_n)
  //
  arbiter uu_arbiter (
    .clk         (clk                       ),
    .reset_n     (reset_n                   ),

    .priority_sel(uu_arbiter_if.priority_sel),
    .client1_req (uu_arbiter_if.client1_req ),
    .client2_req (uu_arbiter_if.client2_req ),

    .o_grant1    (uu_arbiter_if.o_grant1    ),
    .o_grant2    (uu_arbiter_if.o_grant2    )
  );

  //
  // assert module (referencia hierarquica whitebox: curr_state/req_d)
  //
  arbiter_assertion uu_arbiter_assertion (
    .clk          (clk                        ),
    .reset_n      (reset_n                    ),

    .priority_sel (uu_arbiter_if.priority_sel ),
    .client1_req  (uu_arbiter_if.client1_req  ),
    .client2_req  (uu_arbiter_if.client2_req  ),

    .o_grant1     (uu_arbiter_if.o_grant1     ),
    .o_grant2     (uu_arbiter_if.o_grant2     ),

    .curr_state    (uu_arbiter.curr_state     ),
    .client1_req_d (uu_arbiter.client1_req_d  ),
    .client2_req_d (uu_arbiter.client2_req_d  )
  );

  //
  // functional coverage
  //
  arbiter_coverage uu_arbiter_coverage (
    .clk         (clk                        ),
    .reset_n     (reset_n                    ),

    .priority_sel(uu_arbiter_if.priority_sel ),
    .client1_req (uu_arbiter_if.client1_req  ),
    .client2_req (uu_arbiter_if.client2_req  ),

    .curr_state  (uu_arbiter.curr_state      )
  );

  //
  // tb variables AND control panel of testbench
  //
  arbiter_seq_item_t arbiter_seq_item;
  string testname = "stimulus_modes";
  // ...

  //
  // DPI: modelo de referencia (FSM em C), passo-a-passo, 1 chamada por ciclo
  //
  import "DPI-C" function void refmod_arbiter_step(
    input  bit reset_n,
    input  bit priority_sel,
    input  bit client1_req,
    input  bit client2_req,
    output bit o_grant1,
    output bit o_grant2
  );

  //
  // checker em background: roda a cada borda de clock, independente da
  // sequencia de estimulo, comparando o DUT contra o modelo de referencia.
  //
  bit checker_en = 0;
  always @(posedge clk) begin
    if (checker_en) begin
      automatic bit p_sel, r1, r2;
      automatic bit g1_exp, g2_exp;
      automatic logic g1_dut, g2_dut;

      // valores estaveis vistos pelo DUT nesta borda (drive tem skew de
      // +2ns, entao o valor "cru" aqui e o que foi dirigido na borda
      // anterior, ja estavel ha varios ns)
      p_sel = uu_arbiter_if.priority_sel;
      r1    = uu_arbiter_if.client1_req;
      r2    = uu_arbiter_if.client2_req;

      refmod_arbiter_step(reset_n, p_sel, r1, r2, g1_exp, g2_exp);

      arbiter_mon(arbiter_vif, g1_dut, g2_dut);

      arbiter_scb(g1_dut, g2_dut, g1_exp, g2_exp, 0);
    end
  end

  //
  // main sequence
  //
  initial begin
    $display("Test started...");

    arbiter_vif = uu_arbiter_if;

    // reset sequence
    reset_n = 1'bx;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    reset_n = 1'b0;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    reset_n = 1'b1;

    @(posedge clk);
    checker_en = 1;

    case (testname)

      "baseline": begin
        $display("");
        $display("# --------------------------");
        $display("# Baseline Test (RANDOM)");
        $display("# --------------------------");
        repeat (300) begin
          arbiter_seq_item = arbiter_seqr(RANDOM, $urandom_range(1, 0), 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end
        repeat (5) @(posedge clk); // deixa o checker terminar de comparar o rabo da fila
        arbiter_scb_report();
      end

      "stimulus_modes": begin
        $display("");
        $display("# --------------------------");
        $display("# Stimulus Modes");
        $display("# --------------------------");

        // 1) nenhuma requisicao
        $display("# ---- NONE (nenhuma requisicao) @ t=%0t ----", $time);
        repeat (5) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 1);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 2) apenas uma requisicao (client1)
        $display("# ---- ONE_C1 (apenas client1) @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(ONE_C1, 1'b1, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (5) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 3) apenas uma requisicao (client2)
        $display("# ---- ONE_C2 (apenas client2) @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(ONE_C2, 1'b1, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (5) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 4) duas ou mais requisicoes (pulso unico, priority_sel=1 -> client1 primeiro)
        $display("# ---- BOTH (duas requisicoes, priority_sel=1) @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(BOTH, 1'b1, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (6) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 5) todas as requisicoes (sustentado -- os dois pedindo o tempo todo)
        $display("# ---- ALL (requisicoes sustentadas dos dois clientes) @ t=%0t ----", $time);
        repeat (10) begin
          arbiter_seq_item = arbiter_seqr(BOTH, 1'b1, 1);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end
        repeat (3) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 6) teste de prioridade
        $display("");
        $display("# --------------------------");
        $display("# Priority Test");
        $display("# --------------------------");

        // 6a) priority_sel=1, os dois pedindo -> client1 deve vencer
        $display("# ---- PRIORITY: priority_sel=1, both req @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(BOTH, 1'b1, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (6) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 6b) priority_sel=0, os dois pedindo -> client2 deve vencer
        $display("# ---- PRIORITY: priority_sel=0, both req @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(BOTH, 1'b0, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (6) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b0, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 6c) ACHADO do Block Guide: priority_sel=0 e SO client1 pedindo ->
        // client1 fica preso em IDLE (nunca e atendido). Confirmando com
        // simulacao real, nao so leitura do RTL.
        $display("# ---- PRIORITY: starvation (priority_sel=0, so client1) @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(ONE_C1, 1'b0, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (20) begin
          arbiter_seq_item = arbiter_seqr(ONE_C1, 1'b0, 0); // continua "pedindo" (nao importa, ja esta latched)
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
          if (uu_arbiter_if.o_grant1)
            $display("[UNEXPECTED] o_grant1 foi a 1 durante o teste de starvation, em t=%0t", $time);
        end
        $display("[CHECK] apos 20 ciclos com priority_sel=0 e so client1 pedindo: o_grant1=%0b (esperado 0)", uu_arbiter_if.o_grant1);

        // 6d) recuperacao: muda priority_sel para 1, client1 continua pedindo -> agora deve ser atendido
        $display("# ---- PRIORITY: recovery (priority_sel muda para 1) @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(ONE_C1, 1'b1, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (6) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 7) reset no meio da operacao
        $display("");
        $display("# --------------------------");
        $display("# Reset Test");
        $display("# --------------------------");
        $display("# ---- deixando client1 com grant, depois resetando @ t=%0t ----", $time);
        arbiter_seq_item = arbiter_seqr(ONE_C1, 1'b1, 1);
        arbiter_drv(arbiter_vif, arbiter_seq_item, 1);
        repeat (2) @(posedge clk);

        // NOTA (achado de verificacao): o checker NAO pode ser desligado
        // durante o reset. O modelo em C ja sabe tratar reset_n=0 (volta
        // pro estado IDLE sozinho, igual ao RTL), entao ele precisa continuar
        // rodando a cada ciclo para ficar sincronizado com o DUT. Na primeira
        // tentativa, desligar o checker aqui (checker_en=0) fazia o estado
        // interno do modelo em C "congelar" enquanto o DUT resetava de
        // verdade -- quando o checker voltava, os dois ficavam dessincronizados
        // e todos os ciclos seguintes davam mismatch (182 mismatches numa
        // rodada real). Ver docs/definition_of_done.md, "Licoes Aprendidas".
        // NOTA (achado de verificacao 2): trocar reset_n exatamente EM CIMA
        // de uma borda de clock (sem delay) cria uma race entre essa
        // atribuicao e a leitura de reset_n feita pelo checker no mesmo
        // instante -- mesma categoria de achado da Atividade 8 do Adder32 e
        // do Matrix2x2 (reset alinhado exatamente com a borda). Corrigido
        // com um pequeno delay (#1ns) antes de mudar reset_n.
        #1ns;
        reset_n = 1'b0;
        repeat (2) @(posedge clk);
        $display("[CHECK] durante reset: o_grant1=%0b o_grant2=%0b (esperado 0/0)", uu_arbiter_if.o_grant1, uu_arbiter_if.o_grant2);
        #1ns;
        reset_n = 1'b1;
        @(posedge clk);

        repeat (5) begin
          arbiter_seq_item = arbiter_seqr(NONE, 1'b1, 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        // 8) testes aleatorios
        $display("");
        $display("# --------------------------");
        $display("# Random Test");
        $display("# --------------------------");
        repeat (200) begin
          arbiter_seq_item = arbiter_seqr(RANDOM, $urandom_range(1, 0), 0);
          arbiter_drv(arbiter_vif, arbiter_seq_item, 0);
        end

        repeat (5) @(posedge clk);
        arbiter_scb_report();
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
      fsdb_name = "arbiter.fsdb";

    $display("[TB] FSDB file = %0s", fsdb_name);
    $fsdbDumpfile(fsdb_name);
    $fsdbDumpvars();
  end
endmodule
