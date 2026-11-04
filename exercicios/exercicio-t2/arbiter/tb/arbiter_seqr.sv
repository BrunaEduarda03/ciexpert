import arbiter_datatypes_pkg::*;

/**
 * Arbiter Sequencer
 *
 * @ref: espelha adder2p0/tb/adder32_seqr.sv (Atividade 9), adaptado: aqui
 *       cada chamada gera o estimulo de UM ciclo de clock (nao uma operacao
 *       completa), pois o arbiter e um DUT sequencial/FSM cujo resultado
 *       depende do historico, nao so da transacao atual.
 */
function automatic arbiter_seq_item_t arbiter_seqr(
  input stimulus_mode_t mode,
  input bit             priority_sel,
  input bit             en_log
);
  arbiter_seq_item_t item;
  bit r1, r2;

  item.priority_sel = priority_sel;

  case (mode)
    NONE: begin
      item.client1_req = 1'b0;
      item.client2_req = 1'b0;
    end

    ONE_C1: begin
      item.client1_req = 1'b1;
      item.client2_req = 1'b0;
    end

    ONE_C2: begin
      item.client1_req = 1'b0;
      item.client2_req = 1'b1;
    end

    BOTH: begin
      item.client1_req = 1'b1;
      item.client2_req = 1'b1;
    end

    RANDOM: begin
      if (!randomize(r1, r2))
        $fatal(1, "Randomization failed in arbiter_seqr() [RANDOM]");
      item.client1_req = r1;
      item.client2_req = r2;
    end

    default: begin
      $fatal(1, "arbiter_seqr(): modo de estimulo desconhecido");
    end
  endcase

  if (en_log) begin
    $display("# ---------------------------");
    $display("# sequence generated (mode=%s, priority_sel=%0b)", mode.name(), priority_sel);
    $display("# ---------------------------");
  end

  return item;

endfunction: arbiter_seqr
