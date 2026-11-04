/**
 * Adder32 datatypes package
 */
package adder32_datatypes_pkg;

  typedef struct packed {
    logic [31:0] a;
    logic [31:0] b;
    // missing outputs? or it's better to create another seq-item?
  } adder32_seq_item_t;

  // Atividade 9: modos de estimulo controlaveis no sequencer (ver mini-VP da Atividade 3)
  typedef enum {
    BASIC,
    ZERO,
    MAX,
    CARRY,
    NO_CARRY,
    PATTERN,
    SMALL,
    BIG,
    MINMAX,
    RANDOM
  } stimulus_mode_t;

  // Atividade 10: modos de controle do sinal en no driver
  typedef enum {
    EN_RANDOM,
    EN_BURST,
    EN_DISABLE
  } en_mode_t;

endpackage: adder32_datatypes_pkg