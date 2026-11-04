import matrix_datatypes_pkg::*;

/**
 * Matrix2x2 Sequencer
 *
 * @ref: espelha adder2p0/tb/adder32_seqr.sv (Atividade 9), adaptado para a
 *       semantica de matriz 2x2 de elementos de 8 bits empacotados em A/B
 *       (rtl/matrixmult.v): A[31:24]=A00 A[23:16]=A01 A[15:8]=A10 A[7:0]=A11.
 *
 * NO_OVERFLOW usa elementos <= 8'hB (11 decimal), pois 2*11*11=242 <= 255:
 * a soma de dois produtos de 8 bits nunca estoura os 8 bits do acumulador
 * Res1[x][y] do RTL nesse caso (ver Block Guide, secao "overflow por elemento").
 */
function automatic matrix_seq_item_t matrix_seqr(
  input stimulus_mode_t mode,
  input bit             en_log
);
  logic [31:0] a;
  logic [31:0] b;
  int          zero_case;
  int          minmax_case;
  byte unsigned e0, e1, e2, e3, e4, e5, e6, e7;

  matrix_seq_item_t item;

  case (mode)

    BASIC: begin
      // T1: valores fixos, conferiveis a mao (ver Verification Plan/DoD)
      // A = [[1,2],[3,4]], B = [[5,6],[7,8]]
      a = {8'd1, 8'd2, 8'd3, 8'd4};
      b = {8'd5, 8'd6, 8'd7, 8'd8};
    end

    ZERO: begin
      // T2: A=0/B=random, A=random/B=0, A=0/B=0
      zero_case = $urandom_range(2, 0);
      case (zero_case)
        0: begin
          a = 32'd0;
          if (!randomize(b)) $fatal(1, "Randomization failed in matrix_seqr() [ZERO/b]");
        end
        1: begin
          if (!randomize(a)) $fatal(1, "Randomization failed in matrix_seqr() [ZERO/a]");
          b = 32'd0;
        end
        default: begin
          a = 32'd0;
          b = 32'd0;
        end
      endcase
    end

    MAX: begin
      // T3: todos os elementos de A e B = 8'hFF (overflow garantido em todo Res)
      a = 32'hFFFF_FFFF;
      b = 32'hFFFF_FFFF;
    end

    OVERFLOW: begin
      // T4: caso dirigido, overflow garantido independente de aleatoriedade:
      // A = [[0xFF,0xFF],[0x00,0x00]], B = [[0xFF,0x00],[0xFF,0x00]]
      // Res00 = 0xFF*0xFF + 0xFF*0xFF = 130050 (>255) -> trunca para 8 bits
      a = 32'hFFFF_0000;
      b = 32'hFF00_FF00;
    end

    NO_OVERFLOW: begin
      // T5: elementos <= 11 (0xB) garantem soma de produtos <= 255 (sem overflow)
      e0 = $urandom_range(8'hB, 8'h0); e1 = $urandom_range(8'hB, 8'h0);
      e2 = $urandom_range(8'hB, 8'h0); e3 = $urandom_range(8'hB, 8'h0);
      e4 = $urandom_range(8'hB, 8'h0); e5 = $urandom_range(8'hB, 8'h0);
      e6 = $urandom_range(8'hB, 8'h0); e7 = $urandom_range(8'hB, 8'h0);
      a = {e0, e1, e2, e3};
      b = {e4, e5, e6, e7};
    end

    PATTERN: begin
      // T6: padrao alternado por elemento
      a = 32'hAAAA_AAAA;
      b = 32'h5555_5555;
    end

    SMALL: begin
      // apoio a cobertura (value_range: baixo) -- mesma convencao do Adder32
      a = $urandom_range(32'h0000_00FF, 32'd0);
      b = $urandom_range(32'h0000_00FF, 32'd0);
    end

    BIG: begin
      // apoio a cobertura (value_range: alto) -- mesma convencao do Adder32
      a = $urandom_range(32'hFFFF_FFFF, 32'hF000_0000);
      b = $urandom_range(32'hFFFF_FFFF, 32'hF000_0000);
    end

    MINMAX: begin
      // cruzamento zero/maximo entre A e B
      minmax_case = $urandom_range(3, 0);
      case (minmax_case)
        0: begin a = 32'd0;        b = 32'd0;        end
        1: begin a = 32'd0;        b = 32'hFFFF_FFFF; end
        2: begin a = 32'hFFFF_FFFF; b = 32'd0;         end
        default: begin a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF; end
      endcase
    end

    RANDOM: begin
      // elementos totalmente aleatorios
      if (!randomize(a, b)) begin
        $fatal(1, "Randomization failed in matrix_seqr() [RANDOM]");
      end
    end

    default: begin
      $fatal(1, "matrix_seqr(): modo de estimulo desconhecido");
    end

  endcase

  if (en_log) begin
    $display("# ---------------------------");
    $display("# sequence generated (mode=%s)", mode.name());
    $display("# ---------------------------");
  end

  item.a = a;
  item.b = b;

  return item;

endfunction: matrix_seqr
