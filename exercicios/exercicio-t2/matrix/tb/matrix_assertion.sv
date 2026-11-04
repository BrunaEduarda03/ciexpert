/**
 * Matrix2x2 Assertions
 *
 * @ref: espelha adder2p0/tb/adder32_assertion.sv (Atividade 15: reset /
 *       latencia / retencao). Nao ha carry_out neste DUT, entao nao existe
 *       equivalente a p_carry_causality.
 *
 * ACHADO IMPORTANTE (ver docs/block_guide.md, secao "Comportamento no
 * reset"): ao contrario do Adder32 (onde adder_out volta a 0 durante o
 * reset), o RTL do matrix2x2_mult (rtl/matrixmult.v) SO zera o registrador
 * interno Res1 durante !rstn; o registrador de saida Res, em si, NAO e
 * tocado no ramo de reset (so e escrito no ramo "else if (en)"). Ou seja,
 * Res RETEM o ultimo valor amostrado durante o reset, em vez de ir a zero.
 * Isso NAO foi alterado (regra: nao modificar o RTL) -- a property abaixo
 * documenta e verifica o comportamento REAL observado, nao o que se
 * assumiria por analogia com o Adder32.
 */
module matrix_assertion #(
  parameter int NBW = 32
)(
  input logic           clk,
  input logic           rstn,

  input logic           en,
  input logic [NBW-1:0] A,
  input logic [NBW-1:0] B,

  input logic [NBW-1:0] Res
);

  // Modelo de referencia local (SVA-only) para a multiplicacao 2x2 de
  // elementos de 8 bits, com a MESMA semantica de truncamento do RTL
  // (reg [7:0] Res1[x][y] <= produto_a + produto_b -- os bits acima do
  // bit 7 sao descartados na atribuicao, exatamente como em Verilog).
  function automatic logic [NBW-1:0] f_expected_res(logic [NBW-1:0] a, logic [NBW-1:0] b);
    byte unsigned a00, a01, a10, a11;
    byte unsigned b00, b01, b10, b11;
    int unsigned  p00, p01, p10, p11;
    byte unsigned r00, r01, r10, r11;

    a00 = a[31:24]; a01 = a[23:16]; a10 = a[15:8]; a11 = a[7:0];
    b00 = b[31:24]; b01 = b[23:16]; b10 = b[15:8]; b11 = b[7:0];

    p00 = (a00 * b00) + (a01 * b10);
    p01 = (a00 * b01) + (a01 * b11);
    p10 = (a10 * b00) + (a11 * b10);
    p11 = (a10 * b01) + (a11 * b11);

    r00 = p00[7:0]; r01 = p01[7:0]; r10 = p10[7:0]; r11 = p11[7:0];

    return {r00, r01, r10, r11};
  endfunction: f_expected_res

  // Durante o reset, Res RETEM o ultimo valor (nao vai a zero -- ver nota
  // no cabecalho deste arquivo). Property documenta/verifica o comportamento
  // real do RTL.
  //
  // ACHADO (amostragem preponed / borda de entrada no reset): a checagem so
  // pode comparar dois ciclos que já estejam AMBOS em reset
  // ($past(!rstn) && !rstn), e nao simplesmente "!rstn |-> $stable(Res)".
  // Motivo: SVA usa amostragem "preponed" -- o valor de Res no ciclo em que
  // uma escrita legitima acontece (en=1, rstn=1) so passa a ser o valor
  // "corrente" a partir do PROXIMO tick. Se o ultimo ciclo antes do reset
  // entrar foi um ciclo de escrita valida, o primeiro tick DENTRO do reset
  // consegue ver um "$stable" comparando o valor novo (deste tick) com o
  // valor antigo (do tick anterior, ainda pre-escrita) -- um falso positivo
  // na fronteira, nao uma mudanca real de Res durante o reset. Confirmado
  // experimentalmente: sem o $past(!rstn) extra, a assertion disparava
  // exatamente no primeiro ciclo apos uma escrita valida seguida de reset
  // (ver docs/definition_of_done.md, "Licoes Aprendidas").
  property p_reset_res_stable;
    @(posedge clk)
      ($past(!rstn) && !rstn) |-> $stable(Res);
  endproperty

  a_reset_res_stable: assert property (p_reset_res_stable)
    else begin
      $error("[ASSERTION] Reset behavior changed: Res mudou durante rstn=0 (Res=%0h). Comportamento esperado deste RTL e RETENCAO, nao zero.", Res);
    end

  cov_reset_res_stable: cover property (p_reset_res_stable);

  // Latencia: 1 ciclo depois de en=1 amostrado (com rstn=1) junto com A/B,
  // Res deve refletir exatamente o produto matricial truncado a 8 bits por
  // elemento (LATENCY=1, mesmo padrao do Adder32).
  property p_latency_mult;
    @(posedge clk) disable iff (!rstn)
      ($past(en) && $past(rstn)) |->
        (Res == f_expected_res($past(A), $past(B)));
  endproperty

  a_latency_mult: assert property (p_latency_mult)
    else begin
      $error("[ASSERTION] Latency failure: esperado Res=32'h%08h, obtido Res=32'h%08h",
             f_expected_res($past(A), $past(B)),
             Res);
    end

  cov_latency_mult: cover property (p_latency_mult);

  // Retencao: se en=0 (fora de reset) no ciclo N, Res no ciclo N+1 deve
  // permanecer identico ao do ciclo N.
  property p_retention;
    @(posedge clk) disable iff (!rstn)
      (!en) |=> $stable(Res);
  endproperty

  a_retention: assert property (p_retention)
    else begin
      $error("[ASSERTION] Retention failure: Res mudou com en=0 (Res=%0h)", Res);
    end

  cov_retention: cover property (p_retention);

endmodule: matrix_assertion
