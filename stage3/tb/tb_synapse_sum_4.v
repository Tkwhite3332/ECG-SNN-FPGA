
`timescale 1ns/1ps

module tb_synapse_sum_4;

    reg [3:0] spike_in;
    reg signed [7:0] w_0, w_1, w_2, w_3;
    wire signed [15:0] current;

    integer expected;
    integer test_count;
    integer i;

    // 实例化待测模块
    synapse_sum_4 dut (
        .spike_in(spike_in),
        .w_0(w_0),
        .w_1(w_1),
        .w_2(w_2),
        .w_3(w_3),
        .current(current)
    );

    // 自动测试任务
    task automatic check;
        input [3:0] s;
        input signed [7:0] a, b, c, d;

        begin
            spike_in = s;
            w_0 = a;
            w_1 = b;
            w_2 = c;
            w_3 = d;

            // 独立计算期望结果
            expected = 0;

            if (s[0]) expected = expected + a;
            if (s[1]) expected = expected + b;
            if (s[2]) expected = expected + c;
            if (s[3]) expected = expected + d;

            // 等待组合逻辑稳定
            #1;

            test_count = test_count + 1;

            if (current !== expected[15:0]) begin
                $display("FAIL: Test %0d", test_count);
                $display("Spike = %b", spike_in);
                $display("Weights = %0d %0d %0d %0d",
                         w_0, w_1, w_2, w_3);
                $display("Expected = %0d", expected);
                $display("Actual   = %0d", current);
                $fatal(1, "Mismatch!");
            end
        end
    endtask

    initial begin

        $dumpfile("synapse_wave.vcd");
        $dumpvars(0, tb_synapse_sum_4);

        test_count = 0;

        // 1. 全部 Spike 为 0
        check(4'b0000, -30, 50, 100, -80);

        // 2. 部分 Spike 为 1，预期 -10
        check(4'b1101, -30, 50, 100, -80);

        // 3. 全部最大正权重，预期 508
        check(4'b1111, 127, 127, 127, 127);

        // 4. 全部最小负权重，预期 -512
        check(4'b1111, 8'sh80, 8'sh80,
                         8'sh80, 8'sh80);

        // 5. 单独选中最小负权重
        check(4'b0001, 8'sh80, 0, 0, 0);

        // 6. 正负权重混合
        check(4'b1010, 10, -20, 30, -40);

        // 7. 遍历全部16种Spike组合
        for (i = 0; i < 16; i = i + 1) begin
            check(i, -30, 50, 100, -80);
        end

        // 8. 随机测试1000组
        for (i = 0; i < 1000; i = i + 1) begin
            check(
                $random,
                $random,
                $random,
                $random,
                $random
            );
        end

        $display("--------------------------------");
        $display("PASS: All %0d tests passed!", test_count);
        $display("--------------------------------");

        $finish;
    end

endmodule
