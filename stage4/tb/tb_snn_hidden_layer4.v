
`timescale 1ns/1ps

module tb_snn_hidden_layer4;

    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    reg [3:0] spike_in;
    reg [127:0] weights;

    wire [3:0] spike_out;
    wire [63:0] u_out;

    integer ref_u [0:3];
    integer ref_spike [0:3];
    integer ref_current [0:3];

    integer test_count = 0;
    integer i;
    integer j;

    // neuron 0: w0 =  20
    // neuron 1: w0 = -10
    // neuron 2: w0 =  40
    // neuron 3: w0 =   0
    localparam [127:0] W_DEMO = {
        32'h00000000,
        32'h00000028,
        32'h000000F6,
        32'h00000014
    };

    snn_hidden_layer4 dut (
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
        input [127:0] w;

        integer n;
        integer k;
        integer leak;
        integer v;
        integer raw;

        begin
            @(negedge clk);

            rst = r;
            en = e;
            spike_in = s;
            weights = w;

            // 4个神经元分别计算参考值
            for (n = 0; n < 4; n = n + 1) begin

                if (r) begin
                    ref_u[n] = 0;
                    ref_spike[n] = 0;
                    ref_current[n] = 0;
                end
                else if (e) begin

                    // 计算第n个神经元的突触电流
                    ref_current[n] = 0;

                    for (k = 0; k < 4; k = k + 1) begin
                        if (s[k]) begin
                            ref_current[n] =
                                ref_current[n] +
                                $signed(
                                    w[n*32 + k*8 +: 8]
                                );
                        end
                    end

                    // 泄漏：负数向下取整
                    leak = ref_u[n] / 2;

                    if (ref_u[n] < 0 &&
                        ref_u[n] % 2 != 0)
                        leak = leak - 1;

                    // 积分
                    v = leak + ref_current[n];

                    // Spike判断
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

            // 等待有效时钟上升沿
            @(posedge clk);
            #1;

            test_count = test_count + 1;

            // 检查全部4个神经元
            for (n = 0; n < 4; n = n + 1) begin

                if (
                    u_out[n*16 +: 16] !==
                        ref_u[n][15:0] ||

                    spike_out[n] !==
                        (ref_spike[n] != 0)
                ) begin

                    $display("FAIL: Test %0d", test_count);
                    $display("Neuron = %0d", n);

                    $display("rst=%b en=%b spike_in=%b",
                             rst, en, spike_in);

                    $display("Current = %0d",
                             ref_current[n]);

                    $display("Expected: u=%0d spike=%0d",
                             ref_u[n], ref_spike[n]);

                    $display("Actual: u=%0d spike=%0d",
                             $signed(u_out[n*16 +: 16]),
                             spike_out[n]);

                    $fatal(1, "Hidden layer mismatch");
                end
            end
        end
    endtask

    initial begin

        $dumpfile("hidden_wave.vcd");
        $dumpvars(0, tb_snn_hidden_layer4);

        for (j = 0; j < 4; j = j + 1) begin
            ref_u[j] = 0;
            ref_spike[j] = 0;
            ref_current[j] = 0;
        end

        // 1. 同步复位
        check_step(1, 0, 4'b0000, 128'd0);

        // 2. 四个神经元输入相同，但权重不同
        check_step(0, 1, 4'b0001, W_DEMO);

        $display("First step: spike_out=%b",
                 spike_out);

        // 3. 连续时间步，验证状态独立保持
        check_step(0, 1, 4'b0001, W_DEMO);

        // 4. en=0，改变输入但不更新寄存器
        check_step(0, 0, 4'b1111,
                   {4{32'h7F7F7F7F}});

        // 5. 复位优先级
        check_step(1, 1, 4'b1111,
                   {4{32'h7F7F7F7F}});

        // 6. 所有权重都是-128
        check_step(0, 1, 4'b1111,
                   {16{8'h80}});

        // 7. 再次复位
        check_step(1, 0, 4'b0000, 128'd0);

        // 8. 所有权重都是127
        check_step(0, 1, 4'b1111,
                   {16{8'h7F}});

        // 9. 遍历全部16种输入Spike组合
        for (i = 0; i < 16; i = i + 1) begin
            check_step(
                0,
                1,
                i[3:0],
                {4{32'hD26432E2}}
            );
        end

        // 10. 随机测试1000组
        for (i = 0; i < 1000; i = i + 1) begin

            check_step(
                (i % 97) == 0,
                (i % 7) != 0,
                $random,

                {
                    $random,
                    $random,
                    $random,
                    $random
                }
            );
        end

        $display("--------------------------------");
        $display("PASS: All %0d tests passed!", test_count);
        $display("4 hidden neurons verified.");
        $display("--------------------------------");

        $finish;
    end

endmodule
