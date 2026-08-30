/**
 * Adder
 *
 * @brief : example of a more organized adder32-tb
 * @author: gvillanovanm
 */

//
// imports
//
import adder32_datatypes_pkg::*;

module adder_tb;
  //
  // localparams
  //
  localparam int ADDER32_NBW = 32;

  // 
  // clk/rst gen
  //
  localparam int CLK_PERIOD = 10ns;
  logic clk = 0;
  logic reset_n;

  always #(CLK_PERIOD/2) clk = ~clk;

  //
  // interfaces
  //
  adder32_if #(
    .NBW    (ADDER32_NBW )
  ) uu_adder32_if (
    .clk    (clk         ),
    .reset_n(reset_n     )
  );

  // this is not a instance, it is a "pointer" for real obj
  virtual adder32_if adder32_vif;

  //
  // DUT Instanciation
  //
  adder uu_adder (
    .clk       (clk                    ),
    .reset_n   (reset_n                ),

    // in
    .en        (uu_adder32_if.en       ),
    .op_a      (uu_adder32_if.op_a     ),
    .op_b      (uu_adder32_if.op_b     ),

    // out
    .adder_out (uu_adder32_if.adder_out),
    .carry_out (uu_adder32_if.carry_out)
  );

  //
  // assert module
  //
  adder32_assertion uu_adder32_assertion(
    .clk       (clk                    ),
    .reset_n   (reset_n                ),

    // out
    .adder_out (uu_adder32_if.adder_out),
    .carry_out (uu_adder32_if.carry_out)
  );

  
  //
  // tb variables AND control panel of tesbench
  //
  
  // sequence item
  adder32_seq_item_t adder32_seq_item;

  // rfm
  longint unsigned rfm_r;
  logic [32:0] dut_r;

  // TB control variables
  localparam int NUM_OF_SEQUENCES = 2;
  string testname = "baseline";
  // ... 

  //
  // DPI
  // ref: https://www.consulting.amiq.com/2019/01/30/how-to-call-c-functions-from-systemverilog-using-dpi-c/
  import "DPI-C" function longint unsigned refmod(
    input longint unsigned a,
    input longint unsigned b,
    input bit en_log
  );

  //
  // main sequence
  //
  initial begin
    $display("Test started...");

    // vif
    adder32_vif = uu_adder32_if;

    // reset sequence
    reset_n = 1'bx;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    reset_n = 1'b0;
    #(CLK_PERIOD + $urandom_range(3, 0)*1ns);
    reset_n = 1'b1;

    // "sync" with clock
    @(posedge clk);

      case (testname)
        "baseline": begin
          $display("");
          $display("# --------------------------");
          $display("#");
          $display("# Baseline Test");
          $display("#");
          $display("# --------------------------");
          $display("# NUM_OF_SEQUENCES: %0d", NUM_OF_SEQUENCES);
          repeat(NUM_OF_SEQUENCES) begin
            // seqr
            adder32_seq_item = adder32_seqr(0);
          
            // driver+monitor
            adder32_drv(adder32_vif, adder32_seq_item, 0);
            adder32_mon(adder32_vif, dut_r, 0);

            // rfm
            rfm_r = refmod(adder32_seq_item.a, adder32_seq_item.b, 0);
          
            // scoreboard
            adder32_scb(dut_r, unsigned'(rfm_r), 1);
          end
        end

        "other_case": begin
          $display("other_case");
        end
      endcase

    #10ns;
    $finish;
  end

  reg [8*200:1] fsdb_name;
  initial begin
    if (!$value$plusargs("FSDB=%s", fsdb_name))
      fsdb_name = "adder32.fsdb";

    $display("[TB] FSDB file = %0s", fsdb_name);
    $fsdbDumpfile(fsdb_name);
    $fsdbDumpvars();
  end
endmodule
