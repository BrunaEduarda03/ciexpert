import adder32_datatypes_pkg::*;

function automatic adder32_seq_item_t adder32_seqr(
  input stimulus_mode_t mode,
  input bit             en_log
);
  // data
  logic [31:0] a;
  logic [31:0] b;
  int          zero_case;
  int          minmax_case;

  adder32_seq_item_t item;

  case (mode)

    BASIC: begin
      // T1: soma simples (Atividade 3)
      a = 32'd10;
      b = 32'd20;
    end

    ZERO: begin
      // T2: A=0/B=0, A=0/B!=0, A!=0/B=0
      zero_case = $urandom_range(2, 0);
      case (zero_case)
        0: begin
          a = 32'd0;
          if (!randomize(b)) $fatal(1, "Randomization failed in adder32_seqr() [ZERO/b]");
        end
        1: begin
          if (!randomize(a)) $fatal(1, "Randomization failed in adder32_seqr() [ZERO/a]");
          b = 32'd0;
        end
        default: begin
          a = 32'd0;
          b = 32'd0;
        end
      endcase
    end

    MAX: begin
      // T3: A=B=32'hFFFFFFFF
      a = 32'hFFFFFFFF;
      b = 32'hFFFFFFFF;
    end

    CARRY: begin
      // T4: combinacoes que garantidamente geram carry (A+B > 32'hFFFFFFFF)
      a = $urandom_range(32'hFFFFFFFF, 32'h8000_0000);
      b = $urandom_range(32'hFFFFFFFF, (32'hFFFFFFFF - a) + 32'd1);
    end

    NO_CARRY: begin
      // T5: combinacoes que garantidamente NAO geram carry (A+B <= 32'hFFFFFFFF)
      a = $urandom_range(32'h7FFFFFFF, 32'd0);
      b = $urandom_range(32'hFFFFFFFF - a, 32'd0);
    end

    PATTERN: begin
      // T6: padroes alternados
      a = 32'hAAAAAAAA;
      b = 32'h55555555;
    end

    SMALL: begin
      // apoio a cobertura CP9 (value_range: baixo)
      a = $urandom_range(32'h0000_00FF, 32'd0);
      b = $urandom_range(32'h0000_00FF, 32'd0);
    end

    BIG: begin
      // apoio a cobertura CP9 (value_range: alto)
      a = $urandom_range(32'hFFFFFFFF, 32'hF000_0000);
      b = $urandom_range(32'hFFFFFFFF, 32'hF000_0000);
    end

    MINMAX: begin
      // apoio a cobertura CP1-CP4 (cruzamento entre zero e valor maximo)
      minmax_case = $urandom_range(3, 0);
      case (minmax_case)
        0: begin a = 32'd0;        b = 32'd0;        end
        1: begin a = 32'd0;        b = 32'hFFFFFFFF; end
        2: begin a = 32'hFFFFFFFF; b = 32'd0;         end
        default: begin a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; end
      endcase
    end

    RANDOM: begin
      // T11: operandos totalmente aleatorios
      if (!randomize(a, b)) begin
        $fatal(1, "Randomization failed in adder32_seqr() [RANDOM]");
      end
    end

    default: begin
      $fatal(1, "adder32_seqr(): modo de estimulo desconhecido");
    end

  endcase

  if(en_log) begin
    $display("# ---------------------------");
    $display("# sequence generated (mode=%s)", mode.name());
    $display("# ---------------------------");
  end

  item.a = a;
  item.b = b;

  return item;

endfunction: adder32_seqr
