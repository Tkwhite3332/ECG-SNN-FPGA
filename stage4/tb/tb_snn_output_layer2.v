
`timescale 1ns/1ps

module tb_snn_output_layer2;

    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    reg [3:0] spike_in;
    reg [63:0] weights;

    wire [1:0] spike_out;
    wire [31:0] u_out;

    integer ref_u [0:1];
    integer ref_spike [0:1];

    integer test_count = 0;
    integer i, j;

    // 神经元0: w0 = 20
    // 神经元1: w0 = -10
    localparam [63:0] W_DEMO = {
        32'h000000F6,
        32'h00000014
    };

    snn_output_layer2 dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .spike_in(spike_in),
        .weights(weights),
        .spike_out(spike_out),
        .u_out(u_out)
    );

    always #5 clk = ~clk;

    task automatic check_step;
        input r;
        input e;
        input [3:0] s;
        input [63:0] w;

        integer n, k;
        integer ref_current;
        integer leak;
        integer v;
        integer raw;

        begin
            @(negedge clk);

            rst = r;
            en = e;
            spike_in = s;
            weights = w;

            // 两个神经元分别计算参考值
            for (n = 0; n < 2; n = n + 1) begin

                if (r) begin
                    ref_u[n] = 0;
                    ref_spike[n] = 0;
                end
                else if (e) begin

                    ref_current = 0;

                    // 读取第n个神经元的独立权重
                    for (k = 0; k < 4; k = k + 1) begin
                        if (s[k])
                            ref_current = ref_current
                                + $signed(w[n*32 + k*8 +: 8]);
                    end

                    // 泄漏：向下取整
                    leak = ref_u[n] / 2;

                    if (ref_u[n] < 0 &&
                        ref_u[n] % 2 != 0)
                        leak = leak - 1;

                    // 积分及发放
                    v = leak + ref_current;
                    ref_spike[n] = (v > 15);

                    // 减阈值重置
                    raw = v;

                    if (ref_spike[n])
                        raw = raw - 15;

                    // INT16饱和
                    if (raw > 32767)
                        ref_u[n] = 32767;
                    else if (raw < -32768)
                        ref_u[n] = -32768;
                    else
                        ref_u[n] = raw;
                end
            end

            @(posedge clk);
            #1;

            test_count = test_count + 1;

            for (n = 0; n < 2; n = n + 1) begin
                if (u_out[n*16 +: 16] !== ref_u[n][15:0] ||
                    spike_out[n] !== (ref_spike[n] != 0)) begin

                    $display("FAIL: test=%0d neuron=%0d",
                             test_count, n);
                    $display("rst=%b en=%b spike_in=%b",
                             rst, en, spike_in);
                    $display("Expected: u=%0d spike=%0d",
                             ref_u[n], ref_spike[n]);
                    $display("Actual:   u=%0d spike=%0d",
                             $signed(u_out[n*16 +: 16]),
                             spike_out[n]);

                    $fatal(1, "Output layer mismatch");
                end
            end
        end
    endtask

    initial begin
        $dumpfile("output_wave.vcd");
        $dumpvars(0, tb_snn_output_layer2);

        for (j = 0; j < 2; j = j + 1) begin
            ref_u[j] = 0;
            ref_spike[j] = 0;
        end

        // 1. 复位
        check_step(1, 0, 4'b0000, 64'd0);

        // 2. 两个神经元使用不同权重
        check_step(0, 1, 4'b0001, W_DEMO);

        $display("Demo: spike_out=%b", spike_out);
        $display("Neuron0 u=%0d, Neuron1 u=%0d",
                 $signed(u_out[15:0]),
                 $signed(u_out[31:16]));

        // 3. 连续时间步
        check_step(0, 1, 4'b0001, W_DEMO);

        // 4. 使能关闭
        check_step(0, 0, 4'b1111, {8{8'h7F}});

        // 5. 复位优先
        check_step(1, 1, 4'b1111, {8{8'h7F}});

        // 6. 最大正权重
        check_step(0, 1, 4'b1111, {8{8'h7F}});

        // 7. 重置后测试最小负权重
        check_step(1, 0, 4'b0000, 64'd0);
        check_step(0, 1, 4'b1111, {8{8'h80}});

        // 8. 遍历16种输入Spike组合
        for (i = 0; i < 16; i = i + 1) begin
            check_step(
                0, 1, i[3:0],
                {2{32'hD26432E2}}
            );
        end

        // 9. 1000组随机测试
        for (i = 0; i < 1000; i = i + 1) begin
            check_step(
                (i % 97) == 0,
                (i % 7) != 0,
                $random,
                {$random, $random}
            );
        end

        $display("--------------------------------");
        $display("PASS: All %0d tests passed!", test_count);
        $display("2 output neurons verified.");
        $display("--------------------------------");

        $finish;
    end

endmodule
