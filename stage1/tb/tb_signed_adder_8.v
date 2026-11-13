`timescale 1ns/1ps

module tb_signed_adder_8;

    reg signed [7:0] a;
    reg signed [7:0] b;
    wire signed [8:0] sum;

    signed_adder_8 dut (
        .a(a),
        .b(b),
        .sum(sum)
    );

    initial begin

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_signed_adder_8);

        // 测试1：普通加法
        a = 8'sd5;
        b = 8'sd3;

        #10;

        $display("a=%0d, b=%0d, sum=%0d",
                  a, b, sum);

        if (sum !== 9'sd8)
            $fatal(1, "Test 1 Failed!");

        // 后面的测试由你完成
        a = 8'sd127;
        b = 8'sd127;

        #10;

        $display("a=%0d, b=%0d, sum=%0d",
                a, b, sum);

        if(sum !== 9'sd254)
            $fatal(1, "Test 2 Failed!");

        a = -8'sd128;
        b = -8'sd128;

        #10;

        $display("a=%0d, b=%0d, sum=%0d",
                a, b, sum);

        if(sum !== -9'sd256)
            $fatal(1, "Test 3 Failed!");

        a = -8'sd128;
        b = 8'sd127;

        #10;

        $display("a=%0d, b=%0d, sum=%0d",
                a, b, sum);

        if(sum !== -9'sd1)
            $fatal(1, "Test 4 Failed!");
        $finish;

    end

endmodule