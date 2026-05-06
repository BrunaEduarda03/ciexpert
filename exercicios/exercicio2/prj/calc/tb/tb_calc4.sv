module tb_calc4();

    logic [7:0] a;
    logic [7:0] b;
    logic [1:0] op;
    logic [7:0] result;

    calc4 uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result)
    );

    initial begin
        $fsdbDumpfile("waveform.fsdb");
        $fsdbDumpvars(0, tb_calc4);
    end

    initial begin
        a = 8'd10; b = 8'd5; op = 2'b00; #10;
        $display("ADD | a=%0d b=%0d op=%0b result=%0d", a, b, op, result);

        a = 8'd10; b = 8'd5; op = 2'b01; #10;
        $display("SUB | a=%0d b=%0d op=%0b result=%0d", a, b, op, result);

        a = 8'd6; b = 8'd4; op = 2'b10; #10;
        $display("MUL | a=%0d b=%0d op=%0b result=%0d", a, b, op, result);

        a = 8'd20; b = 8'd4; op = 2'b11; #10;
        $display("DIV | a=%0d b=%0d op=%0b result=%0d", a, b, op, result);

        a = 8'd15; b = 8'd0; op = 2'b11; #10;
        $display("DIV | a=%0d b=%0d op=%0b result=%0d", a, b, op, result);

        $display("-------------------------------");
        $finish;
    end

endmodule