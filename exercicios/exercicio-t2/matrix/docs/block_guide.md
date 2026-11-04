# 4.1 Matrix2x2: Block Guide

## Identificação

- **DUT**: `matrix2x2_mult` (arquivo `rtl/matrixmult.v`, não modificado).
- **Função**: multiplicação de duas matrizes 2x2, com elementos de 8 bits, empacotadas em barramentos de 32 bits.
- **Classe de circuito**: aritmético/datapath (mesma classe do Adder32, ver Seção 6.1 do caderno), registrado, sem pipeline.

## Portas (nomes preservados exatamente como no RTL)

| Porta   | Direção | Largura | Descrição |
|---|---|---|---|
| `clk`   | input  | 1 bit   | clock do sistema |
| `rstn`  | input  | 1 bit   | reset assíncrono, **ativo baixo** (nome do próprio DUT — não é `reset_n` como no Adder32) |
| `en`    | input  | 1 bit   | habilita o registro do resultado |
| `A`     | input  | 32 bits | matriz 2x2 de operandos, 4 elementos de 8 bits |
| `B`     | input  | 32 bits | matriz 2x2 de operandos, 4 elementos de 8 bits |
| `Res`   | output | 32 bits | matriz 2x2 resultado, 4 elementos de 8 bits |

## Empacotamento dos elementos (confirmado no RTL)

```verilog
{A1[0][0], A1[0][1], A1[1][0], A1[1][1]} = A;  // idem para B1/B
...
Res = {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]};
```

Ou seja, para A, B e Res, a ordem MSB→LSB é **[0][0], [0][1], [1][0], [1][1]** (linha 0 primeiro, depois linha 1 — row-major), cada elemento com 8 bits:

- `X[31:24]` = elemento `[0][0]`
- `X[23:16]` = elemento `[0][1]`
- `X[15:8]`  = elemento `[1][0]`
- `X[7:0]`   = elemento `[1][1]`

## Comportamento funcional

O DUT calcula o produto matricial padrão 2x2: `Res = A × B` (multiplicação de matrizes, não elemento-a-elemento), onde:

```
Res[0][0] = A[0][0]*B[0][0] + A[0][1]*B[1][0]
Res[0][1] = A[0][0]*B[0][1] + A[0][1]*B[1][1]
Res[1][0] = A[1][0]*B[0][0] + A[1][1]*B[1][0]
Res[1][1] = A[1][0]*B[0][1] + A[1][1]*B[1][1]
```

- **Registrado**: `always @(posedge clk or negedge rstn)`, mesma latência do Adder32 (**LATENCY = 1** ciclo: o resultado calculado a partir de A/B amostrados no ciclo N aparece em `Res` no ciclo N+1).
- **Enable**: só atualiza `Res`/`Res1` quando `en=1` (fora de reset). Com `en=0`, `Res` **retém** o último valor — mesmo padrão do Adder32.
- **Sem pipeline**: um único estágio de registro, sem estágios intermediários.

## Achado 1 (importante): overflow silencioso por elemento

Cada elemento de `Res1[x][y]` é um `reg [7:0]` (8 bits). A soma de dois produtos de 8 bits pode chegar a `255*255 + 255*255 = 130050`, que precisa de **17 bits** para ser representado sem perda. Como o RTL atribui esse valor a um registrador de 8 bits, **os bits acima do bit 7 são truncados silenciosamente** (semântica padrão de atribuição em Verilog: trunca para os bits menos significativos, sem saturação e sem sinalizar overflow). Não existe nenhum sinal de overflow/flag exposto pelo DUT.

Isso **não é um bug introduzido por nós** — é o comportamento real e não-modificado do RTL fornecido — mas é um achado relevante de verificação: se a especificação pretendida do bloco assume que "produto de matrizes de 8 bits" deveria saturar, alertar, ou usar uma largura maior de acumulador, isso precisaria ser levantado com o time de design (mesmo raciocínio da Seção 2.1 do caderno: a spec deixa isso em aberto). Como não podemos alterar o RTL, o ambiente de verificação **modela e testa exatamente esse comportamento de truncamento** (ver `dpi/refmod.c` e `tb/matrix_assertion.sv`), em vez de assumir saturação.

## Achado 2 (importante): `Res` NÃO é zerado durante o reset

Ao contrário do Adder32 (onde `adder_out` volta a `0` durante `!reset_n`, pois é uma saída combinacional derivada do próprio registrador que é limpo no reset), o RTL do `matrix2x2_mult` só limpa o registrador **interno** `Res1` durante `!rstn`:

```verilog
always @ (posedge clk or negedge rstn)
begin
    if (!rstn) begin
        {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]} = 32'd0;   // Res1 zerado
    end
    else if (en) begin
        ...
        Res = {Res1[0][0], Res1[0][1], Res1[1][0], Res1[1][1]};    // Res SO e escrito aqui
    end
end
```

`Res` (a saída de fato) só é escrita dentro do ramo `else if (en)`. Durante o reset, esse ramo nunca executa, então **`Res` retém o último valor amostrado antes do reset**, em vez de ir a zero. `Res1` é zerado "por baixo dos panos", mas isso só ficaria visível em `Res` na primeira vez que `en=1` acontecer depois do reset (nesse ciclo, `Res` seria escrito com o valor de `Res1`, que nesse momento é 0 — a menos que `A`/`B` também estejam com o mesmo valor amostrado, o que faria `Res1` ser recalculado antes de `Res` ser lido).

Isso é uma divergência real de comportamento em relação ao Adder32 e está documentada, testada por assertion (`tb/matrix_assertion.sv::p_reset_res_stable`) e coberta por cobertura funcional (`cx_reset_en`). Ver também `docs/definition_of_done.md`, seção "Lições Aprendidas", para a discussão de uma armadilha de amostragem SVA (*preponed sampling*) descoberta ao escrever essa assertion.

## Resumo para o Verification Plan

| Item | Valor |
|---|---|
| Latência | 1 ciclo |
| Pipeline | Não |
| Reset | Assíncrono, ativo baixo (`rstn`); zera só `Res1` internamente, `Res` retém |
| Enable | Retém `Res` quando `en=0` (fora de reset) |
| Overflow | Truncamento silencioso por elemento (8 bits), sem flag |
| Largura A/B/Res | 32 bits (4 elementos × 8 bits) |
