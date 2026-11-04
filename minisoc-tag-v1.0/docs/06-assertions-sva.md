# 06 — `top_assertions.sv` (SVA ligadas por `bind`)

## Por que `bind` em vez de instanciar direto no RTL

```systemverilog
module minisoc_top_sva (input logic clk, rst_n, sys_clk, pll_locked, ...);
  ...
endmodule : minisoc_top_sva

bind minisoc_top minisoc_top_sva u_sva (.*);
```

`bind` injeta `minisoc_top_sva` dentro de toda instância de `minisoc_top`
**sem tocar no arquivo RTL do instrutor**. Isso é importante para a avaliação
de autoria: o RTL recebido na tag `minisoc-tag-v1.0` fica intocado; as
assertions são 100% do verificador, vivendo só no lado do testbench. A
conexão `.*` funciona porque os nomes das portas de `minisoc_top_sva`
coincidem com sinais internos de `minisoc_top` (conexão implícita por nome).

## As três properties (VPLAN seção 6.1)

**A-01 — defaults um ciclo após reset**
```systemverilog
property p_a01_reset_defaults;
  @(posedge clk)
    !rst_n |=> (!pll_locked && !spi_cfg_pll_enable && !spi_cfg_mem_sel_aes &&
                (spi_cfg_pll_div_sel == 2'b11) && !spi_cfg_start);
endproperty
```
Lê-se: "em toda borda de clock em que `rst_n` estiver baixo, **no próximo
ciclo** (`|=>`) essas 5 condições devem valer". É o equivalente formal, em
nível de assertion contínua, do que `check_defaults()` faz pontualmente no
teste — mas a assertion verifica em **toda** borda de clock durante o reset
inteiro, não só numa amostra isolada.

**A-02a — domínio AES em reset enquanto o PLL não trava**
```systemverilog
assert property (@(posedge clk) disable iff (!rst_n) !pll_locked |-> !sys_rst_n)
```
"Sempre que o PLL não estiver locked, `sys_rst_n` tem que estar em reset."
`disable iff (!rst_n)` desliga a assertion durante o reset externo — ali
`sys_rst_n` já é coberto pela A-01, e checar os dois ao mesmo tempo seria
redundante e potencialmente conflitante. O comentário no código já aponta que
essa property também vai pegar a hipótese **OPEN-01** (re-enable do PLL) a
partir de P2 — ela não precisa mudar quando esse teste for escrito, só vai
passar a ser exercitada por um cenário novo.

**A-03 — `sys_clk` só bate com PLL locked**
```systemverilog
assert property (@(posedge sys_clk) disable iff (!rst_n) pll_locked)
```
Dispara em toda borda de `sys_clk` — se existir uma borda de `sys_clk` com
`pll_locked == 0`, é falha. Isso é o tipo de bug que um teste dirigido
dificilmente pegaria por acidente (precisaria observar o instante exato de
uma borda espúria); como assertion contínua, é verificado o tempo todo de
graça.

## As duas `cover property`

```systemverilog
C01_reset_release:  cover property (@(posedge clk) !rst_n ##1 rst_n);
C01_reset_runtime:  cover property (@(posedge clk) rst_n ##1 !rst_n);
```
Não são checagens — são prova de que os **antecedentes** das assertions
acima realmente aconteceram na simulação. Uma assertion do tipo `A |-> B`
passa trivialmente se `A` nunca acontecer (vacuamente verdadeira) — o que
daria falsa confiança. As covers confirmam que houve pelo menos uma
transição `rst_n: 1→0` (entrada em reset) e uma `rst_n: 0→1` (saída de
reset) na simulação.

## Resultado real do log de 29/10

```
"top_assertions.sv", 48: top_tb.dut.u_sva.C01_reset_release, 185 attempts, 2 match
"top_assertions.sv", 49: top_tb.dut.u_sva.C01_reset_runtime, 185 attempts, 1 match
```
2 matches em `C01_reset_release` = as duas liberações de reset (inicial +
runtime) do T-SMOKE. 1 match em `C01_reset_runtime` = a única transição
`1→0` que não é a condição inicial (rst_n já nasce em 0, então não conta como
transição). Nenhuma falha de `A01`/`A02a`/`A03` apareceu no log — zero
`UVM_ERROR` confirma isso, já que as assertions reportam via `` `uvm_error ``.
