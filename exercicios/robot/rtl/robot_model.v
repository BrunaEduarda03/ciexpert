
module robot_model(clock,
   reset_n,
   s0_req,
   s1_req,
   s2_req,
   s3_req,

   s0_unloadstart,
   s1_unloadstart,
   s2_unloadstart,
   s3_unloadstart,

   s0_unload_done,
   s1_unload_done,
   s2_unload_done,
   s3_unload_done,

   load_start
);

input clock, reset_n;

//sensor request
input s0_req;
input s1_req;
input s2_req;
input s3_req;

//station unload start
output s0_unloadstart;
output s1_unloadstart;
output s2_unloadstart;
output s3_unloadstart;

//station unload req served
input s0_unload_done;
input s1_unload_done;
input s2_unload_done;
input s3_unload_done;

//Robot load req 
output load_start;

reg [1:0] curr_state, next_state;
reg [1:0] load_cstate, load_nstate;
reg [1:0] unload_cstate,unload_nstate;

parameter IDLE       = 2'b00;
parameter WRIST_HOR  = 2'b01;
parameter LOAD_ITEM  = 2'b10;
parameter WRIST_VERT = 2'b11;

// logic starts here
assign load_done_int = (load_cstate == WRIST_VERT);

// next state logic of main control state machine
always @(posedge clock or negedge reset_n) begin
   if (~reset_n) begin
      curr_state    <= 2'b00;
      load_cstate   <= 2'b00;
      unload_cstate <= 2'b00;
   end
   else begin
      curr_state    <= next_state;
      load_cstate   <= load_nstate;
      unload_cstate <= unload_nstate;
   end
end

// Main Control state machine
wire unload_done; 
assign unload_done = s0_unload_done | s1_unload_done | s2_unload_done | s3_unload_done;

always @(reset_n or curr_state or unload_done or s0_req or s1_req or s2_req or s3_req) begin
   if (~reset_n)begin
      next_state <= 2'b00;
   end else begin
      case (curr_state )
         IDLE: begin
            if (s0_req || s1_req)
               next_state <= 2'b01;
            else if (s2_req || s3_req)
               next_state <= 2'b10;
            else
               next_state <= IDLE;  
         end
         
         2'b01: begin
            if (unload_done)
               next_state <= IDLE;
         end
         
         2'b10: begin
            if (unload_done)
               next_state <= IDLE;
         end
   
         default: next_state <= IDLE; 
      endcase
   end
end

wire s0ors2_req, s1ors3_req;

// output generation
wire s0_unloadstart;
wire s1_unloadstart;
wire s2_unloadstart;
wire s3_unloadstart;

assign s0ors2_req = s0_req | s2_req;
assign s1ors3_req = s1_req | s3_req; 

// load state machine
always @(reset_n or load_cstate or s0ors2_req or load_done_int or s1ors3_req) begin
   if (~reset_n)
      load_nstate <= IDLE;
   else begin
      case (load_cstate )
         IDLE: begin
            if (s0ors2_req || s1ors3_req)
               load_nstate <= WRIST_HOR;
            else
               load_nstate <= IDLE;  
         end

         WRIST_HOR : load_nstate <= LOAD_ITEM;
         LOAD_ITEM : load_nstate <= WRIST_VERT;
         WRIST_VERT: load_nstate <= IDLE; 
      endcase
   end
end

// output generation
assign load_start = (load_cstate == WRIST_HOR);

// unload state machine
parameter JOINTA_RIGHT = 3'b001;
parameter JOINTC_DOWN = 3'b010;
parameter JOINTC_UP = 3'b011;
parameter RELEASE_CLAWE = 3'b100;
parameter JOINTA_LEFT = 3'b110;

always @(reset_n or unload_cstate or s0ors2_req or s1ors3_req or s0_unload_done or s1_unload_done or s2_unload_done or s3_unload_done) begin
   if (~reset_n)
      unload_nstate <= IDLE;
   else begin
      case (unload_cstate)
         IDLE: begin
            if(s0ors2_req || s1ors3_req)
               unload_nstate <= JOINTA_RIGHT;
            else
               unload_nstate <= IDLE;  
         end

         JOINTA_RIGHT: begin
            if (s1ors3_req)
               unload_nstate <= JOINTC_DOWN;
            else
               unload_nstate <= RELEASE_CLAWE;
         end

         JOINTC_DOWN: unload_nstate <= RELEASE_CLAWE;
         JOINTA_LEFT: unload_nstate <= IDLE;

         RELEASE_CLAWE: begin
            if (s1ors3_req)
               unload_nstate<= JOINTC_UP;
            else if(s0_unload_done | s2_unload_done)
               unload_nstate<= JOINTA_LEFT;
         end

         JOINTC_UP: begin
            if (s1_unload_done | s3_unload_done)
               unload_nstate<= JOINTA_LEFT;
         end
         
         default: unload_nstate<= IDLE;
      endcase
   end
end

// Output generation

// assign s0_unloadstart =( unload_cstate == JOINTA_RIGHT | RELEASE_CLAWE |JOINTA_LEFT);
assign s0_unloadstart = load_done_int;
assign s1_unloadstart = load_done_int;
// assign s1_unloadstart =( unload_cstate == JOINTA_RIGHT | JOINTC_DOWN |JOINTC_UP | RELEASE_CLAWE |JOINTA_LEFT) ;
assign s2_unloadstart = (unload_cstate == JOINTA_RIGHT | RELEASE_CLAWE |JOINTA_LEFT) ;
assign s3_unloadstart = (unload_cstate == JOINTA_RIGHT | JOINTC_DOWN |JOINTC_UP | RELEASE_CLAWE |JOINTA_LEFT) ;

endmodule
