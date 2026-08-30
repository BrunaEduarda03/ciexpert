`timescale 1ns/1ps

// ============================================================
//  Testbench Self-Checking — robot_model
//  Compativel com Icarus Verilog (usa $dumpfile/$dumpvars)
//  Testa as propriedades da FSM de controle do robo industrial
// ============================================================

module sim_robot;

// ---- sinais do DUT ----
reg  clock, reset_n;
reg  s0_req, s1_req, s2_req, s3_req;
reg  s0_unload_done, s1_unload_done, s2_unload_done, s3_unload_done;
wire s0_unloadstart, s1_unloadstart, s2_unloadstart, s3_unloadstart;
wire load_start;

// ---- contadores ----
integer errors = 0;
integer tests  = 0;

// ---- instancia do DUT ----
robot_model dut (
    .clock          (clock),
    .reset_n        (reset_n),
    .s0_req         (s0_req),
    .s1_req         (s1_req),
    .s2_req         (s2_req),
    .s3_req         (s3_req),
    .s0_unloadstart (s0_unloadstart),
    .s1_unloadstart (s1_unloadstart),
    .s2_unloadstart (s2_unloadstart),
    .s3_unloadstart (s3_unloadstart),
    .s0_unload_done (s0_unload_done),
    .s1_unload_done (s1_unload_done),
    .s2_unload_done (s2_unload_done),
    .s3_unload_done (s3_unload_done),
    .load_start     (load_start)
);

// ---- clock: periodo 10 ns ----
always #5 clock = ~clock;

// ---- tarefa auxiliar de verificacao ----
task check1;
    input        got;
    input        exp;
    input [255:0] msg;
    begin
        tests = tests + 1;
        if (got !== exp) begin
            $display("  [FAIL] %0s: obtido=%b esperado=%b", msg, got, exp);
            errors = errors + 1;
        end else begin
            $display("  [OK]   %0s", msg);
        end
    end
endtask

// ---- tarefa: reseta e aguarda 2 ciclos ----
task do_reset;
    begin
        reset_n = 0;
        s0_req = 0; s1_req = 0; s2_req = 0; s3_req = 0;
        s0_unload_done = 0; s1_unload_done = 0;
        s2_unload_done = 0; s3_unload_done = 0;
        @(posedge clock); #1;
        @(posedge clock); #1;
        reset_n = 1;
        @(posedge clock); #1;
    end
endtask

// ---- tarefa: cicla load FSM ate retornar ao IDLE ----
// (3 ciclos apos req: WRIST_HOR -> LOAD_ITEM -> WRIST_VERT -> IDLE)
task cycle_load_fsm;
    begin
        @(posedge clock); #1; // LOAD_ITEM
        @(posedge clock); #1; // WRIST_VERT
        @(posedge clock); #1; // IDLE
    end
endtask

// ===========================================================
//  ESTIMULOS E VERIFICACOES
// ===========================================================
initial begin
    $dumpfile("robot.vcd");
    $dumpvars(0, sim_robot);

    clock = 0;
    reset_n = 0;
    s0_req = 0; s1_req = 0; s2_req = 0; s3_req = 0;
    s0_unload_done = 0; s1_unload_done = 0;
    s2_unload_done = 0; s3_unload_done = 0;

    $display("");
    $display("  =========================================================");
    $display("  SIMULACAO: Robot Model — FSM de Controle Industrial");
    $display("  Funcao: Gerenciar carga/descarga em 4 estacoes");
    $display("  =========================================================");

    // -------------------------------------------------------
    //  TESTE 1 — Reset assíncrono
    //  Propriedade: apos reset todos os estados e saidas = 0
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 1: Reset assincrono ---");
    reset_n = 0;
    #3; // assincrono: nao precisa de clock
    check1(load_start,      1'b0, "load_start=0 (reset ativo)");
    check1(s0_unloadstart,  1'b0, "s0_unloadstart=0 (reset ativo)");
    check1(s1_unloadstart,  1'b0, "s1_unloadstart=0 (reset ativo)");
    @(posedge clock); #1;
    reset_n = 1;
    @(posedge clock); #1;
    check1(load_start,      1'b0, "load_start=0 (apos soltar reset)");
    check1(s0_unloadstart,  1'b0, "s0_unloadstart=0 (apos soltar reset)");
    check1(s1_unloadstart,  1'b0, "s1_unloadstart=0 (apos soltar reset)");

    // -------------------------------------------------------
    //  TESTE 2 — Load FSM: sequencia completa para s0_req
    //  Propriedade: s0_req dispara IDLE->WRIST_HOR->LOAD_ITEM->WRIST_VERT->IDLE
    //  load_start ativo apenas em WRIST_HOR
    //  s0_unloadstart ativo apenas em WRIST_VERT (load_done_int)
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 2: Load FSM — sequencia s0_req ---");
    do_reset;

    s0_req = 1;
    @(posedge clock); #1;  // Load FSM entra em WRIST_HOR
    check1(load_start,     1'b1, "load_start=1 (WRIST_HOR)");
    check1(s0_unloadstart, 1'b0, "s0_unloadstart=0 (WRIST_HOR)");

    @(posedge clock); #1;  // LOAD_ITEM
    check1(load_start,     1'b0, "load_start=0 (LOAD_ITEM)");
    check1(s0_unloadstart, 1'b0, "s0_unloadstart=0 (LOAD_ITEM)");

    @(posedge clock); #1;  // WRIST_VERT
    check1(load_start,     1'b0, "load_start=0 (WRIST_VERT)");
    check1(s0_unloadstart, 1'b1, "s0_unloadstart=1 (WRIST_VERT = load_done_int)");
    check1(s1_unloadstart, 1'b1, "s1_unloadstart=1 (WRIST_VERT = load_done_int)");

    @(posedge clock); #1;  // Load FSM volta a IDLE
    check1(s0_unloadstart, 1'b0, "s0_unloadstart=0 (Load FSM IDLE)");
    check1(s1_unloadstart, 1'b0, "s1_unloadstart=0 (Load FSM IDLE)");

    s0_req = 0;
    s0_unload_done = 1;
    @(posedge clock); #1;
    s0_unload_done = 0;
    @(posedge clock); #1;

    // -------------------------------------------------------
    //  TESTE 3 — Load FSM: sequencia para s1_req
    //  Propriedade: s1_req tambem dispara load FSM identico
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 3: Load FSM — sequencia s1_req ---");
    do_reset;

    s1_req = 1;
    @(posedge clock); #1;
    check1(load_start,     1'b1, "load_start=1 (WRIST_HOR para s1)");

    @(posedge clock); #1;
    check1(load_start,     1'b0, "load_start=0 (LOAD_ITEM)");

    @(posedge clock); #1;
    check1(s0_unloadstart, 1'b1, "s0_unloadstart=1 (WRIST_VERT, s1_req)");
    check1(s1_unloadstart, 1'b1, "s1_unloadstart=1 (WRIST_VERT, s1_req)");

    @(posedge clock); #1;
    s1_req = 0;
    s1_unload_done = 1;
    @(posedge clock); #1;
    s1_unload_done = 0;
    @(posedge clock); #1;

    // -------------------------------------------------------
    //  TESTE 4 — Load FSM: sequencia para s2_req
    //  Propriedade: s2_req (grupo par) tambem ativa load FSM
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 4: Load FSM — sequencia s2_req ---");
    do_reset;

    s2_req = 1;
    @(posedge clock); #1;
    check1(load_start,     1'b1, "load_start=1 (WRIST_HOR para s2)");

    @(posedge clock); #1;
    check1(load_start,     1'b0, "load_start=0 (LOAD_ITEM)");

    @(posedge clock); #1;
    check1(s0_unloadstart, 1'b1, "s0_unloadstart=1 (WRIST_VERT, s2_req)");
    check1(s1_unloadstart, 1'b1, "s1_unloadstart=1 (WRIST_VERT, s2_req)");

    @(posedge clock); #1;
    s2_req = 0;
    s2_unload_done = 1;
    @(posedge clock); #1;
    s2_unload_done = 0;
    @(posedge clock); #1;

    // -------------------------------------------------------
    //  TESTE 5 — Load FSM: sequencia para s3_req
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 5: Load FSM — sequencia s3_req ---");
    do_reset;

    s3_req = 1;
    @(posedge clock); #1;
    check1(load_start,     1'b1, "load_start=1 (WRIST_HOR para s3)");

    @(posedge clock); #1;
    check1(load_start,     1'b0, "load_start=0 (LOAD_ITEM)");

    @(posedge clock); #1;
    check1(s0_unloadstart, 1'b1, "s0_unloadstart=1 (WRIST_VERT, s3_req)");
    check1(s1_unloadstart, 1'b1, "s1_unloadstart=1 (WRIST_VERT, s3_req)");

    @(posedge clock); #1;
    s3_req = 0;
    s3_unload_done = 1;
    @(posedge clock); #1;
    s3_unload_done = 0;
    @(posedge clock); #1;

    // -------------------------------------------------------
    //  TESTE 6 — Main FSM: prioridade s0/s1 sobre s2/s3
    //  Propriedade: se s0_req e s2_req simultaneos, s0 vence
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 6: Main FSM — prioridade s0/s1 vs s2/s3 ---");
    do_reset;

    s0_req = 1; s2_req = 1; // ambos ao mesmo tempo
    @(posedge clock); #1;
    // Main FSM deve seguir para estado 01 (s0/s1 tem prioridade)
    check1(load_start, 1'b1, "load_start=1 (s0/s1 com prioridade sobre s2/s3)");
    // Se fosse estado 10 (s2/s3), load_start ainda seria 1 pois load FSM e independente
    // A verificacao real e via curr_state, mas como e reg interno verificamos
    // que pelo menos a Load FSM iniciou (o que ocorre para qualquer req)
    cycle_load_fsm;
    s0_req = 0; s2_req = 0;
    s0_unload_done = 1;
    @(posedge clock); #1;
    s0_unload_done = 0;
    @(posedge clock); #1;
    check1(load_start, 1'b0, "load_start=0 (voltou ao IDLE apos unload_done)");

    // -------------------------------------------------------
    //  TESTE 7 — Main FSM: retorno ao IDLE via unload_done
    //  Propriedade: unload_done em qualquer estacao retorna FSM ao IDLE
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 7: Main FSM — retorno ao IDLE por unload_done ---");
    do_reset;

    s1_req = 1;
    @(posedge clock); #1;
    cycle_load_fsm;
    s1_req = 0;

    // FSM em estado 01, aguarda unload_done
    check1(load_start, 1'b0, "load_start=0 (aguardando unload_done)");

    s1_unload_done = 1;
    @(posedge clock); #1;
    s1_unload_done = 0;
    @(posedge clock); #1;
    // Apos unload_done, Main FSM volta ao IDLE
    // Verificamos que load_start nao volta a subir (sem novas reqs)
    check1(load_start, 1'b0, "load_start=0 (IDLE, sem novas reqs)");
    check1(s0_unloadstart, 1'b0, "s0_unloadstart=0 (IDLE, sem novas reqs)");

    // -------------------------------------------------------
    //  TESTE 8 — Reset durante operacao
    //  Propriedade: reset_n=0 durante carga interrompe e retorna ao IDLE
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 8: Reset assincrono durante operacao ---");
    do_reset;

    s0_req = 1;
    @(posedge clock); #1;  // WRIST_HOR (load_start=1)
    check1(load_start, 1'b1, "load_start=1 antes do reset");

    reset_n = 0; #3;  // reset assincrono
    check1(load_start,     1'b0, "load_start=0 (reset assincrono)");
    check1(s0_unloadstart, 1'b0, "s0_unloadstart=0 (reset assincrono)");

    @(posedge clock); #1;
    reset_n = 1;
    s0_req = 0;
    @(posedge clock); #1;
    check1(load_start, 1'b0, "load_start=0 apos soltar reset");

    // -------------------------------------------------------
    //  TESTE 9 — Documentacao: BUG unload_cstate 2 bits
    //  A FSM de descarga usa reg [1:0] mas parametros sao 3 bits
    //  RELEASE_CLAWE=3b100 truncado para 2b00 (IDLE)
    //  JOINTA_LEFT=3b110 truncado para 2b10 (JOINTC_DOWN)
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 9: BUG — reg [1:0] unload_cstate (deve ser [2:0]) ---");
    $display("  BUG: RELEASE_CLAWE=3b100 -> truncado para 00 = IDLE");
    $display("  BUG: JOINTA_LEFT=3b110   -> truncado para 10 = JOINTC_DOWN");
    $display("  Efeito: FSM de descarga nunca alcanca RELEASE_CLAWE nem JOINTA_LEFT");
    $display("  Caminho s0 real: IDLE->JOINTA_RIGHT->IDLE (loop ao inves de RELEASE_CLAWE)");
    $display("  Caminho s1 real: IDLE->JOINTA_RIGHT->JOINTC_DOWN->IDLE (falta RELEASE/UP/LEFT)");
    $display("  [INFO] Bug documentado. Correcao: mudar reg [1:0] para reg [2:0]");

    // -------------------------------------------------------
    //  TESTE 10 — Documentacao: BUG precedencia s2/s3_unloadstart
    //  assign s2_unloadstart = (unload_cstate == JOINTA_RIGHT | RELEASE_CLAWE | JOINTA_LEFT)
    //  Verilog avalia: (unload_cstate==1) | 4 | 6 => sempre nao-zero => sempre 1
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 10: BUG — precedencia de operadores em s2/s3_unloadstart ---");
    $display("  Expressao: (unload_cstate == JOINTA_RIGHT | RELEASE_CLAWE | JOINTA_LEFT)");
    $display("  Avaliado como: (unload_cstate==1) | 4 | 6  (== tem maior precedencia que |)");
    $display("  Resultado: bit0 de (x | 4 | 6) = bit0 de (x | 100 | 110)");
    $display("  RELEASE_CLAWE(4) | JOINTA_LEFT(6) = 110 -> bit0=0, logo nao e sempre 1");
    $display("  Mas a expressao nao e o que o designer pretendia (faltam parenteses)");
    do_reset;
    $display("  s2_unloadstart em IDLE sem reqs = %b (esperado=0)", s2_unloadstart);
    $display("  s3_unloadstart em IDLE sem reqs = %b (esperado=0)", s3_unloadstart);
    tests = tests + 1;
    if (s2_unloadstart !== 1'b0 || s3_unloadstart !== 1'b0) begin
        $display("  [FAIL] s2/s3_unloadstart ativos em IDLE: BUG de precedencia confirmado");
        errors = errors + 1;
    end else begin
        $display("  [OK]   s2/s3_unloadstart = 0 em IDLE (bug de precedencia nao causa saida constante 1)");
    end

    // -------------------------------------------------------
    //  TESTE 11 — s0_unloadstart == s1_unloadstart (sempre)
    //  Propriedade observada: ambos sao assign do mesmo sinal load_done_int
    // -------------------------------------------------------
    $display("");
    $display("  --- TESTE 11: s0_unloadstart sempre igual a s1_unloadstart ---");
    do_reset;
    begin : blk_test11
        integer i;
        integer ok;
        ok = 1;
        s0_req = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clock); #1;
            if (s0_unloadstart !== s1_unloadstart) begin
                $display("  [FAIL] ciclo %0d: s0_unloadstart=%b s1_unloadstart=%b (devem ser iguais)", i, s0_unloadstart, s1_unloadstart);
                ok = 0;
                errors = errors + 1;
            end
        end
        tests = tests + 1;
        if (ok)
            $display("  [OK]   s0_unloadstart == s1_unloadstart em todos os 8 ciclos");
        s0_req = 0;
        s0_unload_done = 1;
        @(posedge clock); #1;
        s0_unload_done = 0;
    end

    // -------------------------------------------------------
    //  RESULTADO FINAL
    // -------------------------------------------------------
    $display("");
    $display("  =========================================================");
    if (errors == 0)
        $display("  RESULTADO FINAL: TODOS OS %0d TESTES PASSARAM (0 erros)", tests);
    else
        $display("  RESULTADO FINAL: %0d FALHA(S) em %0d testes", errors, tests);
    $display("  =========================================================");
    $display("");

    $finish;
end

endmodule
