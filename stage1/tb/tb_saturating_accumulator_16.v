
`timescale 1ns/1ps

module tb_saturating_accumulator_16;

    reg clk;
    reg rst;
    reg en;
    reg signed [15:0] d;
    wire signed [15:0] q;

    integer expected;
    integer test_count;
    integer i;
    reg signed [15:0] random_d;

    saturating_accumulator_16 dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .d(d),
        .q(q)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // 自动执行一次输入和结果检查
    task automatic apply_and_check;
        input rst_value;
        input en_value;
        input signed [15:0] data_value;
        begin
            @(negedge clk);

            rst = rst_value;
            en  = en_value;
            d   = data_value;

            // 软件参考模型
            if (rst_value)
                expected = 0;
            else if (en_value) begin
                expected = expected + data_value;

                if (expected > 32767)
                    expected = 32767;
                else if (expected < -32768)
                    expected = -32768;
            end

            @(posedge clk);
            #1;

            test_count = test_count + 1;

            if (q !== expected[15:0]) begin
                $display("Test %0d failed!", test_count);
                $display("rst=%b en=%b d=%0d",
                         rst, en, d);
                $display("Actual=%0d Expected=%0d",
                         q, expected);
                $fatal(1, "Mismatch");
            end
        end
    endtask

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_saturating_accumulator_16);

        rst = 1;
        en  = 0;
        d   = 0;
        expected = 0;
        test_count = 0;

        // 基础功能
        apply_and_check(1, 0, 0);
        apply_and_check(0, 1, 100);
        apply_and_check(0, 1, 20);
        apply_and_check(0, 1, -170);

        // 正向饱和与恢复
        apply_and_check(1, 0, 0);
        apply_and_check(0, 1, 32760);
        apply_and_check(0, 1, 20);
        apply_and_check(0, 1, -100);

        // 负向饱和与恢复
        apply_and_check(1, 0, 0);
        apply_and_check(0, 1, -32760);
        apply_and_check(0, 1, -20);
        apply_and_check(0, 1, 100);

        // 最大正数累加
        apply_and_check(1, 0, 0);
        apply_and_check(0, 1, 32767);
        apply_and_check(0, 1, 32767);

        // 使能保持及复位优先
        apply_and_check(0, 0, -12345);
        apply_and_check(1, 1, 200);

        // 1000组随机测试
        for (i = 0; i < 1000; i = i + 1) begin
            random_d = $random;

            apply_and_check(
                (i % 73) == 0,
                (i % 11) != 0,
                random_d
            );
        end

        $display("All %0d tests passed!", test_count);
        $finish;
    end

endmodule
