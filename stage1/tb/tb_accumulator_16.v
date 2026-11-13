`timescale 1ns/1ps

module tb_accumulator_16;
    reg clk;
    reg rst;
    reg en;
    reg signed [15:0] d;
    wire signed [15:0] q;

    accumulator_16 dut(.clk(clk), .rst(rst), .en(en), .d(d), .q(q));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_accumulator_16);

        //Test 1
        rst = 1;
        en = 0;

        @(posedge clk);
        #1;

        if(q !== 16'sd0)
            $fatal(1, "Test 1 failed.");

        //Test 2
        @(negedge clk);
        rst = 0;
        en = 1;
        d = 16'sd100;
        
        @(posedge clk);
        #1;

        if(q !== 16'sd100)
            $fatal(1, "Test 2 failed.");

        //Test 3
        @(negedge clk);
        rst = 0;
        en = 1;
        d = -16'sd40;
        
        @(posedge clk);
        #1;

        if(q !== 16'sd60)
            $fatal(1, "Test 3 failed.");

        //Test 4
        @(negedge clk);
        rst = 0;
        en = 0;
        d = 16'sd500;
        
        @(posedge clk);
        #1;

        if(q !== 16'sd60)
            $fatal(1, "Test 4 failed.");

        //Test 5
        @(negedge clk);
        rst = 1;
        en = 1;
        d = 16'sd200;

        @(posedge clk);
        #1;

        if(q !== 16'sd0)
            $fatal(1, "Test 5 failed.");

        //Test 6
        @(negedge clk);
        rst = 0;
        en = 1;
        d = 16'sd32760;
        
        @(posedge clk);
        #1;

        @(negedge clk);
        rst = 0;
        en = 1;
        d = 16'sd20;
        
        @(posedge clk);
        #1;

        if(q !== -16'sd32756)
            $fatal(1, "Test 6 failed.");

        $display("All tests finished.");
        $finish;
    end

endmodule