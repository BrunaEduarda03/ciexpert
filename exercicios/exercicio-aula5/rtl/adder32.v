//Inputs: two 32-bit operands in op_a, op_b
//Output: adder_out,carry_out
//Function: The design adds two operands of 32-bit binary numbers stored in 32-bit
//registers op_a, op_b representing the operands. The result is stored in bit adderout
//and carry_out.
//Design file: 32bit_adder.v
// 32-Bit Adder Design
module adder (
  //------------------clock_reset-----------------//
  clk ,
  reset_n ,
  //----------------Input--------------------------//
  en ,
  op_a ,
  op_b ,
  //--------------output--------------------------//
  adder_out,
  carry_out
);

  input clk , reset_n ;
  //----------------Input---------------------//
  input en ;
  input [31:0] op_a ;
  input [31:0] op_b ;
  //--------------output-----------------------//
  output [31:0] adder_out ;
  output carry_out ;

  reg [32:0] adder_reg ;
  assign adder_out = adder_reg[31:0] ;
  assign carry_out = adder_reg[32] ;

  always@(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      adder_reg<=33'd0;
    end else begin
      if (en) begin
        adder_reg <=op_a + op_b ; // en is the enable to carry the addition of two numbers.
      end
    end
  end
endmodule
