
`timescale 1ns/1ps

module tb_lif_neuron;

    reg clk = 0;
    reg rst = 0;
    reg step_en = 0;
    reg signed [15:0] current = 0;

    wire signed [15:0] u;
    wire spike;

    integer ref_u = 0;
    integer ref_spike = 0;
    integer ref_leak;
    integer ref_v;
    integer ref_raw;
    integer count = 0;
    integer i;
    reg signed [15:0] random_current;

    lif_neuron dut (
        .clk(clk),
        .rst(rst),
        .step_en(step_en),
        .current(current),
        .u(u),
        .spike(spike)
    );

    always #5 clk = ~clk;

    task automatic check_step;
        input r;
        input e;
        input signed [15:0] c;
        begin
            @(negedge clk);
            rst = r;
            step_en = e;
            current = c;

            if (r) begin
                ref_u = 0;
                ref_spike = 0;
            end
            else if (e) begin
                // 有符号除法向零截断，额外修正负奇数
                ref_leak = ref_u / 2;
                if (ref_u < 0 && ref_u % 2 != 0)
                    ref_leak = ref_leak - 1;

                ref_v = ref_leak + c;
                ref_spike = (ref_v > 15);

                ref_raw = ref_v;
                if (ref_spike)
                    ref_raw = ref_raw - 15;

                if (ref_raw > 32767)
                    ref_u = 32767;
                else if (ref_raw < -32768)
                    ref_u = -32768;
                else
                    ref_u = ref_raw;
            end

            @(posedge clk);
            #1;

            count = count + 1;

            if (u !== ref_u[15:0] ||
                spike !== ref_spike[0]) begin

                $display("FAIL: test=%0d", count);
                $display("rst=%b en=%b current=%0d",
                         rst, step_en, current);
                $display("Expected: u=%0d spike=%0d",
                         ref_u, ref_spike);
                $display("Actual:   u=%0d spike=%0d",
                         u, spike);
                $fatal(1, "LIF mismatch");
            end
        end
    endtask

    initial begin
        $dumpfile("lif_wave.vcd");
        $dumpvars(0, tb_lif_neuron);

        // 基础测试和连续时间步
        check_step(1, 0, 0);
        check_step(0, 1, 10);
        check_step(0, 1, 10);
        check_step(0, 1, 10);
        check_step(0, 0, 30000);
        check_step(0, 1, -11);

        // 复位优先级
        check_step(1, 1, 32767);

        // 正向饱和
        check_step(0, 1, 32767);
        check_step(0, 1, 32767);

        // 负向饱和
        check_step(1, 0, 0);
        check_step(0, 1, -32768);
        check_step(0, 1, -32768);

        // 阈值边界和负数舍入
        check_step(1, 0, 0);
        check_step(0, 1, 15);
        check_step(0, 1, 8);
        check_step(0, 1, 9);
        check_step(0, 1, -1);
        check_step(0, 1, 0);

        // 随机测试
        for (i = 0; i < 1000; i = i + 1) begin
            random_current = $random;
            check_step(
                (i % 113) == 0,
                (i % 7) != 0,
                random_current
            );
        end

        $display("PASS: All %0d tests passed!", count);
        $finish;
    end

endmodule
