/**
 * Matrix2x2 datatypes package
 *
 * @brief : espelha a filosofia de adder32_datatypes_pkg (adder2p0), adaptada
 *          para o DUT matrix2x2_mult (rtl/matrixmult.v).
 */
package matrix_datatypes_pkg;

  // Transacao: par de matrizes 2x2 empacotadas em 32 bits (4 elementos de 8
  // bits cada), exatamente como o DUT espera em A/B (rtl/matrixmult.v):
  //   A[31:24]=A00 A[23:16]=A01 A[15:8]=A10 A[7:0]=A11 (idem para B)
  typedef struct packed {
    logic [31:0] a;
    logic [31:0] b;
  } matrix_seq_item_t;

  // Modos de estimulo controlaveis no sequencer (mesmo espirito da
  // Atividade 9 do Adder32, adaptado para a semantica de matriz 2x2 de
  // elementos de 8 bits em vez de um unico operando de 32 bits).
  typedef enum {
    BASIC,       // valores fixos, conferiveis a mao
    ZERO,        // A=0 ou B=0 (matriz nula em um dos operandos)
    MAX,         // todos os elementos de A e B = 8'hFF (overflow garantido)
    OVERFLOW,    // combinacao dirigida que garante estouro de 8 bits em ao menos 1 elemento
    NO_OVERFLOW, // elementos pequenos o suficiente para nunca estourar 8 bits
    PATTERN,     // padrao alternado por elemento
    SMALL,       // elementos na faixa baixa (apoio a cobertura)
    BIG,         // elementos na faixa alta (apoio a cobertura)
    MINMAX,      // cruzamento zero/maximo entre A e B
    RANDOM       // elementos totalmente aleatorios
  } stimulus_mode_t;

  // Modos de controle do sinal en no driver (mesmo espirito da Atividade 10
  // do Adder32).
  typedef enum {
    EN_RANDOM,
    EN_BURST,
    EN_DISABLE
  } en_mode_t;

endpackage: matrix_datatypes_pkg
