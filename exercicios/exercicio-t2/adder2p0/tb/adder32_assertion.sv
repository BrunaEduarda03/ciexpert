module adder32_assertion #(
  parameter int NBW = 32
)(
  input logic           clk,
  input logic           reset_n,

  input logic           en,
  input logic [NBW-1:0] op_a,
  input logic [NBW-1:0] op_b,

  input logic [NBW-1:0] adder_out,
  input logic           carry_out
);

  // During reset, DUT outputs must be zero.
  property p_reset_outputs_zero;
    @(posedge clk)
      (!reset_n) |-> (adder_out == '0 && carry_out == 1'b0);
  endproperty

  a_reset_outputs_zero: assert property (p_reset_outputs_zero)
    else begin
      $error("[ASSERTION] Reset failure: adder_out=%0h carry_out=%0b while reset_n=0",
             adder_out,
             carry_out);
    end

  cov_reset_outputs_zero: cover property (p_reset_outputs_zero);

  //
  // Atividade 15: assertions temporais alem do reset
  //

  // Latencia: 1 ciclo depois de en=1 amostrado (com reset_n=1) junto com
  // op_a/op_b, a saida {carry_out, adder_out} deve refletir exatamente a
  // soma de 33 bits desses operandos (LATENCY=1, Figura 2 do caderno).
  property p_latency_sum;
    @(posedge clk) disable iff (!reset_n)
      ($past(en) && $past(reset_n)) |->
        ({carry_out, adder_out} == ($past(op_a) + $past(op_b)));
  endproperty

  a_latency_sum: assert property (p_latency_sum)
    else begin
      $error("[ASSERTION] Latency failure: esperado {carry,adder_out}=%0h, obtido {%0b,%0h}",
             $past(op_a) + $past(op_b),
             carry_out,
             adder_out);
    end

  cov_latency_sum: cover property (p_latency_sum);

  // Retencao: se en=0 (fora de reset) no ciclo N, a saida {adder_out,
  // carry_out} no ciclo N+1 deve permanecer identica a do ciclo N.
  property p_retention;
    @(posedge clk) disable iff (!reset_n)
      (!en) |=> $stable({adder_out, carry_out});
  endproperty

  a_retention: assert property (p_retention)
    else begin
      $error("[ASSERTION] Retention failure: adder_out/carry_out mudaram com en=0");
    end

  cov_retention: cover property (p_retention);

  // Causalidade do carry: carry_out deve ser exatamente o bit mais
  // significativo (bit NBW) da soma de 33 bits de op_a+op_b amostrados no
  // ciclo em que a soma foi registrada (en=1 no ciclo anterior). Isolada da
  // checagem geral de latencia (p_latency_sum), serve como segunda fonte de
  // evidencia independente especificamente sobre o carry_out.
  property p_carry_causality;
    logic [NBW:0] sum33;
    @(posedge clk) disable iff (!reset_n)
      ($past(en) && $past(reset_n), sum33 = {1'b0, $past(op_a)} + {1'b0, $past(op_b)})
        |-> (carry_out == sum33[NBW]);
  endproperty

  a_carry_causality: assert property (p_carry_causality)
    else begin
      $error("[ASSERTION] Carry causality failure: carry_out=%0b nao bate com o MSB da soma registrada", carry_out);
    end

  cov_carry_causality: cover property (p_carry_causality);

endmodule: adder32_assertion
