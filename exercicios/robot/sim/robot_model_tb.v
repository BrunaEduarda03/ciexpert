/*************************************************************************

Testbench for ROBOT Design
Moore machine Design with Two process Blocks.

*************************************************************************/

module robot_model_tb;

reg clock;
reg reset_n;

//clock generation
initial  begin
   clock = 1'b0;
   forever #10 clock = ~clock;
end

// reset_n generation
initial begin
   #0 reset_n = 1'b1;
   #2 reset_n = 1'b0;
   #5 reset_n = 1'b1;
end

reg  s0_req, s1_req,s2_req,s3_req;
wire s0_unloadstart,s1_unloadstart,s2_unloadstart,s3_unloadstart;
reg  s0_unload_done, s1_unload_done,s2_unload_done,s3_unload_done;
wire load_start;
// reg load_done;

// module instantiation
robot_model u_robot_model(
   .clock           (clock  ),
   .reset_n         (reset_n),  

   .s0_req          (s0_req ),
   .s1_req          (s1_req ),
   .s2_req          (s2_req ),
   .s3_req          (s3_req ),

   .s0_unloadstart  (s0_unloadstart), 
   .s1_unloadstart  (s1_unloadstart), 
   .s2_unloadstart  (s2_unloadstart), 
   .s3_unloadstart  (s3_unloadstart), 

   .s0_unload_done  (s0_unload_done),
   .s1_unload_done  (s1_unload_done),
   .s2_unload_done  (s2_unload_done),
   .s3_unload_done  (s3_unload_done),

   .load_start      (load_start    )
);

// generate station unload requests
initial begin
   $display("\n");
   $display("================================================");
   $display("Starting simulation...");
   $display("================================================\n\n");

   // individual request generation (no req)
   s0_req = 1'b0;
   s1_req = 1'b0;
   s2_req = 1'b1;
   s3_req = 1'b0;
   #100;

   // all done?
   s0_unload_done = 1'b0;
   s1_unload_done = 1'b0;
   s2_unload_done = 1'b0;
   s3_unload_done = 1'b0;

   #500;


   // #15;
   // s0_req = 1'b1;
   // #15;
   // s0_req = 1'b0;
   // #50;
   // s1_req = 1'b1;
   // #50;
   // s1_req = 1'b0;
       
   // s2_req = 1'b1;
   // #50;
   // s2_req = 1'b0;
   // s3_req = 1'b1;
   // #50;
   // s3_req = 1'b0;
end

initial begin
   $fsdbDumpfile("robot.fsdb");
   $fsdbDumpvars(2,robot_model_tb);  
   #300;
   $finish;
end

endmodule
