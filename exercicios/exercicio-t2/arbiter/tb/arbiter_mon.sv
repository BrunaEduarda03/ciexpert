/**
 * Arbiter Monitor
 *
 * @ref: espelha adder2p0/tb/adder32_mon.sv, mas adaptado para amostragem
 *       CICLO A CICLO (nao espera N ciclos por uma "operacao completa"),
 *       pois o checker do arbiter roda em background, comparando o DUT
 *       contra o modelo de referencia a cada borda de clock.
 *
 * ACHADO (clockvar do cb_mon atrasada 1 ciclo): tentei ler vif.cb_mon.o_grant1
 * apos esperar mais do que o skew do clocking block (#3ns > #1ns, para nao
 * competir com a amostra automatica do proprio clocking block em
 * posedge+1ns). Mesmo assim, o valor lido continuava sendo o do CICLO
 * ANTERIOR -- confirmado comparando com transicoes reais extraidas do
 * .fsdb via fsdbreport (curr_state/o_grant1 mudam exatamente na borda,
 * mas a clockvar cb_mon.o_grant1 so refletia isso 1 ciclo depois, em
 * QUALQUER instante que eu lesse dentro do mesmo ciclo). Ou seja, o
 * problema nao era race de tempo (ja tinha descartado isso com a margem de
 * 3ns) -- e sim que a clockvar de um clocking block so fica disponivel
 * para leitura do testbench a partir do PROXIMO clocking event, nao no
 * mesmo ciclo em que foi amostrada (semantica de "amostra pipeline" do
 * clocking block). Isso nao aparecia no Adder32/Matrix2x2 porque eles so
 * liam a clockvar depois de esperar 2 bordas de clock inteiras + margem --
 * tempo de sobra para esse "1 ciclo de atraso" nao importar. Aqui, como o
 * checker precisa comparar CICLO A CICLO, esse atraso quebra tudo.
 * Corrigido lendo o sinal fisico da interface diretamente (vif.o_grant1),
 * sem passar pela clockvar -- e um pino de saida continuo do DUT, entao o
 * valor ja esta estavel poucos ns depois da borda.
 */
task arbiter_mon(
  virtual arbiter_if vif,
  output logic o_grant1,
  output logic o_grant2
);
  #1ns;
  o_grant1 = vif.o_grant1;
  o_grant2 = vif.o_grant2;
endtask: arbiter_mon
