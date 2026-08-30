/**
 * Adder32 datatypes package
 */
package adder32_datatypes_pkg;

  typedef struct packed {
    logic [31:0] a;
    logic [31:0] b;
    // missing outputs? or it's better to create another seq-item?
  } adder32_seq_item_t;

endpackage: adder32_datatypes_pkg