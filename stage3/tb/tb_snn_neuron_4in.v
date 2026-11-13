
`timescale 1ns/1ps

module tb_snn_neuron_4in;

    reg clk = 0;
    reg rst = 0;
    reg en = 0;

    reg [3:0] spike_in;
    reg signed [7:0] w_0, w_1, w_2, w_3;

    wire signed [15:0] u;
    wire spike_out;

    integer ref_u = 0;
    integer ref_spike = 0;
    integer ref_current;
    integer ref_leak;
    integer ref_v;
    integer ref_raw;

    integer test_count = 0;
    integer i;

    snn_neuron_4in dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .spike_in(spike_in),
        .w_0(w_0),
        .w_1(w_1),
        .w_2(w_2),
        .w_3(w_3),
        .u(u),
        .spike_out(spike_out)
    );

    always #5 clk = ~clk;

    task automatic check_step;
        input r;
        input e;
        input [3:0] s;
        input signed [7:0] a, b, c, d;

        begin
            @(negedge clk);

            rst = r;
            en = e;
            spike_in = s;
            w_0 = a;
            w_1 = b;
            w_2 = c;
            w_3 = d;

            // 软件参考模型
            ref_current = 0;

            if (r) begin
                ref_u = 0;
                ref_spike = 0;
            end
            else if (e) begin

                // 突触求和
                if (s[0]) ref_current = ref_current + a;
                if (s[1]) ref_current = ref_current + b;
                if (s[2]) ref_current = ref_current + c;
                if (s[3]) ref_current = ref_current + d;

                // 膜电位泄漏（负数向下取整）
                ref_leak = ref_u / 2;
                if (ref_u < 0 && ref_u % 2 != 0)
                    ref_leak = ref_leak - 1;

                // 膜电位积分
                ref_v = ref_leak + ref_current;

                // Spike 判断
                ref_spike = (ref_v > 15);

                // 减阈值重置
                ref_raw = ref_v;
                if (ref_spike)
                    ref_raw = ref_raw - 15;

                // INT16 饱和
                if (ref_raw > 32767)
                    ref_u = 32767;
                else if (ref_raw < -32768)
                    ref_u = -32768;
                else
                    ref_u = ref_raw;
            end

            @(posedge clk);
            #1;

            test_count = test_count + 1;

            if (u !== ref_u[15:0] ||
                spike_out !== ref_spike[0]) begin

                $display("FAIL: test %0d", test_count);
                $display("spike_in=%b", spike_in);
                $display("weights=%0d,%0d,%0d,%0d",
                         w_0, w_1, w_2, w_3);
                $display("Expected: u=%0d spike=%0d",
                         ref_u, ref_spike);
                $display("Actual:   u=%0d spike=%0d",
                         u, spike_out);

                $fatal(1, "Mismatch");
            end
        end
    endtask

    initial begin
        $dumpfile("snn_neuron_wave.vcd");
        $dumpvars(0, tb_snn_neuron_4in);

        // 基础功能：电流为70，连续发放
        check_step(1, 0, 4'b0000, 0, 0, 0, 0);
        check_step(0, 1, 4'b0101, -30, 50, 100, -80);
        check_step(0, 1, 4'b0101, -30, 50, 100, -80);

        // en=0，保持状态
        check_step(0, 0, 4'b1111, 127, 127, 127, 127);

        // 全部Spike为0，验证泄漏
        check_step(0, 1, 4'b0000, 127, 127, 127, 127);

        // 复位优先
        check_step(1, 1, 4'b1111, 127, 127, 127, 127);

        // 阈值等于15：不发放
        check_step(0, 1, 4'b0001, 15, 0, 0, 0);

        // 阈值大于15：发放
        check_step(1, 0, 4'b0000, 0, 0, 0, 0);
        check_step(0, 1, 4'b0001, 16, 0, 0, 0);

        // 负权重与负膜电位
        check_step(1, 0, 4'b0000, 0, 0, 0, 0);
        check_step(0, 1, 4'b1111,
                   8'sh80, 8'sh80, 8'sh80, 8'sh80);
        check_step(0, 1, 4'b1111,
                   8'sh80, 8'sh80, 8'sh80, 8'sh80);

        // 遍历全部16种Spike组合
        for (i = 0; i < 16; i = i + 1)
            check_step(0, 1, i, -30, 50, 100, -80);

        // 1000组随机输入、使能和复位测试
        for (i = 0; i < 1000; i = i + 1) begin
            check_step(
                (i % 97) == 0,
                (i % 7) != 0,
                $random,
                $random,
                $random,
                $random,
                $random
            );
        end

        $display("PASS: All %0d tests passed", test_count);
        $finish;
    end

endmodule
