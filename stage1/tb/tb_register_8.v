`timescale 1ns/1ps

module tb_register_8;

    reg clk;
    reg rst;
    reg en;
    reg signed [7:0] d;
    wire signed [7:0] q;

    register_8 dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(d),
        .q(q)
    );

    // 生成10ns周期的时钟
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_register_8);

        rst = 1;
        en = 0;
        d = 0;

        // 测试1：同步复位
        @(posedge clk);
        #1;

        if (q !== 8'sd0)
            $fatal(1, "Reset failed!");

        // 测试2：写入数据
        @(negedge clk);
        rst = 0;
        en = 1;
        d = 8'sd42;

        @(posedge clk);
        #1;

        if (q !== 8'sd42)
            $fatal(1, "Write failed!");

        // 测试3：状态保持
        @(negedge clk);
        rst = 0;
        en = 0;
        d = 8'sd100;
        
        @(posedge clk);
        #1;

        if(q !== 8'sd42)
            $fatal(1, "Keep failed!");

        //测试4：复位优先
        @(negedge clk);
        rst = 1;
        en = 1;
        d = 8'sd80;

        @(posedge clk);
        #1;

        if(q !== 8'sd0)
            $fatal(1, "Reset failed!");

        //测试5：恢复写入
        @(negedge clk);
        rst = 0;
        en = 1;
        d = -8'sd50;

        @(posedge clk);
        #1;

        if(q !== -8'sd50)
            $fatal(1, "Recover failed!");

        $display("All register tests passed!");
        $finish;
    end

endmodule