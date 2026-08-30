// Function: The design arbiter monitors the requests from client 1 and client 2
// and grants the access by setting high corresponding grant 1 and grant 2 signals
// to the requested clients (master) based on priority. If priority selection is
// high, the request is granted to client 1even if client 2 is requesting, which is
// granted only after request from client 1 is serviced.
// Design file: arbiter.v

// ∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗
//
// Module grants request to the respective clients. If both the clients request at the same 
// time based on the priority the request is granted to client 1 followed by client 2.
// This is sequential block which require clock and reset
//
// User can refer to any Verilog HDL language book to understand the syntax of
// commands.
//
// ∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗∗

// arbiter design
module arbiter (
  //-----------------input_data----------------------//
  clk,
  reset_n,

  //---------------Input_interface---------------------//
  priority_sel, //1- client1 0- client2
  client1_req,
  client2_req,
  
  //-----------------Output_interface------------------//
  o_grant1,
  o_grant2
);

  //-----------------input_data----------------------//
  input clk, reset_n;
  
  //---------------Input_interface---------------------//
  input priority_sel, //0- client1 1- client2
        client1_req,
        client2_req;
  
  //-----------------Output_interface------------------//
  output o_grant1, o_grant2 ;
  
  
  // internals
  reg [1:0] curr_state, next_state;
  reg client1_req_d, client2_req_d;
  
  parameter 
    IDLE    = 2'd0 ,
    CLINET1 = 2'd1 ,
    CLINET2 = 2'd2 ;
  
  always@(client1_req_d, client2_req_d, curr_state, priority_sel) begin
    case (curr_state)
      // IDLE
      IDLE: begin
        if (priority_sel && client1_req_d)
              next_state = CLINET1 ;
        else if (client2_req_d)
          next_state = CLINET2 ;
        else
          next_state = IDLE ;
      end

      // CLINET1
      CLINET1: begin
        if (client2_req_d)
          next_state = CLINET2 ;
        else
          next_state = IDLE ;
      end

      // CLINET2
      CLINET2 : begin
        if (client1_req_d)
          next_state = CLINET1 ;
        else
          next_state = IDLE ;
      end
      
      default : next_state = IDLE ;
    endcase
  end

  always@(posedge clk or negedge reset_n) begin
    if (!reset_n ) begin
      curr_state<=2'd0;
    end else begin
      curr_state <= next_state ;
    end
  end

  assign o_grant1 = (curr_state == CLINET1);
  assign o_grant2 = (curr_state == CLINET2);
  
  always@(posedge clk or negedge reset_n) begin
    if (!reset_n ) begin
      client1_req_d<=1'd0;
      client2_req_d<=1'd0;
    end else begin
      if (o_grant1)
        client1_req_d<=1'd0;
      else if (client1_req)
        client1_req_d <=1'd1;
      
      if (o_grant2)
        client2_req_d<=1'd0;
      else if (client2_req)
        client2_req_d <=1'd1;
    end
  end
endmodule
