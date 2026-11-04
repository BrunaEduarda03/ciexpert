# 09 — Status das entregas de outubro, após a sessão de hoje (29/10, quinta)

Para cada item: o que estava pendente, o que foi feito hoje neste servidor,
e o que ainda depende de você.

## VPLAN v1 — ✅ pronto, versões preenchidas

**Estava faltando:** as versões de VCS/UVM na tabela 1.2.
**Feito hoje:** rodei `vcs -full64 -ID` neste servidor e extraí:
- VCS: `X-2025.06-SP2_Full64` (build `Dec 01 2025`)
- UVM: `UVM-1.2` (via `-ntb_opts uvm-1.2`, biblioteca embutida no VCS em `$VCS_HOME/etc/uvm-1.2`)
**Falta de você:** confirmar se quer essas strings literais na tabela 1.2 e
atualizar o campo de sumário no Word (seção 2.4 mudou).

## Arquitetura do TB — ✅ pronto (sem alteração hoje)

Diagrama e texto da seção 4.3 já estavam prontos; nenhuma mudança de
arquitetura foi necessária — só a correção de infraestrutura de waveform
(ver abaixo), que não afeta o diagrama.

## VIP de CLOCK — ✅ compilado e rodando no VCS

**Estava:** código escrito, nunca compilado no VCS real (só validado com
`slang`, que usa UVM IEEE 1800.2, diferente do UVM-1.2 do VCS).
**Feito hoje:** compilou de primeira no VCS X-2025.06-SP2, sem erros. Os dois
clocks (`ref_clk_agt` 2 GHz, `mem_clk_agt` 100 MHz) geraram período exato,
confirmado por `measure_clock()` no log (ver [08](08-evidencias-outubro.md)).

## VIP de RESET — ✅ compilado e rodando no VCS

**Feito hoje:** mesma compilação acima. Reset inicial (39 ciclos, seed=1) e
reset em runtime (27 ciclos) executados e logados corretamente, dentro da
constraint `[10:50]`/`[10:30]`.

## Baseline compilando/rodando — ✅ PASS confirmado

**Estava:** nunca tinha rodado no VCS real.
**Feito hoje:**
1. Localizei e carreguei o ambiente Synopsys deste servidor
   (`source /Tools/synopsys-scripts/snps.sh` — o caminho do seu
   `.bash_history` estava desatualizado, o real é
   `/Tools/synopsys-scripts/snps.sh`).
2. `make compile`: 0 erros.
3. `make run`: `*** TEST PASSED ***`, `UVM_ERROR: 0`, `UVM_FATAL: 0`.

**Falta de você:** nada — está rodando ponta a ponta.

## Smoke test — ✅ PASS confirmado

57 checagens executadas, 0 falhas. As duas `cover property` de reset
dispararam (prova de que A-01/A-02a/A-03 foram exercitadas de verdade).
Detalhe completo em [05](05-testes.md) e [08](08-evidencias-outubro.md).

## Evidências — 🟡 log pronto, waveform pendente de você

**Feito hoje:**
- Log oficial com `TEST PASSED` salvo em
  `verif/doc/evidencias/outubro/minisoc_smoke_test_1.log`.
- **Bug encontrado e corrigido**: `make run WAVES=fsdb` não gerava arquivo
  `.fsdb` nenhum (plusarg de auto-dump não funciona nesta instalação do
  VCS). Corrigi `top_tb.sv` (chamada explícita de `$fsdbDumpvars`) e
  `Makefile` (plusarg `+FSDB`, alvo `verdi` apontando para `waves.fsdb`).
  Testado isoladamente e depois end-to-end: `waves.fsdb` gerado (17958
  bytes), salvo em `verif/doc/evidencias/outubro/waves.fsdb`.
- Confirmei que o Verdi abre normalmente com a licença deste servidor
  (`27020@melicense.embedded.ufcg.edu.br`), sem erro.

**Falta de você:** abrir o Verdi de verdade e tirar o print com `clk`,
`mem_clk` e `rst_n` visíveis (comando exato em
[08-evidencias-outubro.md](08-evidencias-outubro.md#o-que-ainda-falta-seu-lado)).
Isso eu não consigo fazer por você — precisa escolher os sinais e dar zoom
interativamente na GUI.

## Versionamento — ✅ pronto, commit da correção pendente de aprovação

Repositório com 2 commits + tag `minisoc-tag-v1.0`, sem push, sem remote —
exatamente como estava. A correção de `top_tb.sv`/`Makefile` feita hoje
**ainda não foi commitada** — ver próxima seção sobre a pendência das linhas
`Co-Authored-By`.

**Pendência em aberto desde ontem, ainda sem resposta sua:** manter ou
remover as linhas `Co-Authored-By: Claude` / `Claude-Session` dos commits
existentes. Avisa qual prefere antes de eu criar o commit da correção de
hoje, para eu já seguir o mesmo padrão.

## Apresentação — ❌ não feita

Só faz sentido montar depois que você tiver o print da waveform — aí eu
monto os 6–8 slides com diagrama, resumo do VPLAN, execução do baseline e as
duas evidências (log + waveform).

---

## Resumindo o que falta, em ordem

1. **Você decide:** manter ou remover `Co-Authored-By` nos commits (pendência de ontem).
2. **Eu faço:** commito a correção de `top_tb.sv` + `Makefile` (sem push).
3. **Você faz:** `make verdi`, tira o print de `clk`/`mem_clk`/`rst_n`.
4. **Eu faço:** monto os slides com log + print.
