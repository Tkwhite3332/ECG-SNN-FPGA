
`timescale 1ns/1ps

module tb_snn_network_442;

    reg clk = 0;
    reg rst = 0;
    reg hidden_en = 0;
    reg output_en = 0;

    reg [3:0] spike_in = 0;
    reg [127:0] hidden_weights = 0;
    reg [63:0] output_weights = 0;

    wire [1:0] spike_out;

    integer hu [0:3];
    integer hs [0:3];
    integer ou [0:1];
    integer os [0:1];

    integer n, k, i, current_sum;
    integer step_count = 0;

    snn_network_442 dut (
        .clk(clk),
        .rst(rst),
        .hidden_en(hidden_en),
        .output_en(output_en),
        .spike_in(spike_in),
        .hidden_weights(hidden_weights),
        .output_weights(output_weights),
        .spike_out(spike_out)
    );

    always #5 clk = ~clk;

    // 参考模型：负数除以2时向下取整
    function integer floor_half;
        input integer x;
        begin
            floor_half = x / 2;
            if (x < 0 && x % 2 != 0)
                floor_half = floor_half - 1;
        end
    endfunction

    function integer next_spike;
        input integer old_u, cur;
        begin
            next_spike = (floor_half(old_u) + cur > 15);
        end
    endfunction

    function integer next_u;
        input integer old_u, cur;
        integer v, raw;
        begin
            v = floor_half(old_u) + cur;
            raw = v - ((v > 15) ? 15 : 0);

            if (raw > 32767)
                next_u = 32767;
            else if (raw < -32768)
                next_u = -32768;
            else
                next_u = raw;
        end
    endfunction

    // 检查全部6个神经元
    task automatic check_all;
        integer j;
        begin
            for (j = 0; j < 4; j = j + 1) begin
                if (dut.hidden_u[j*16 +: 16] !== hu[j][15:0] ||
                    dut.spike_hidden[j] !== hs[j][0]) begin

                    $display("FAIL: step=%0d hidden=%0d",
                             step_count, j);
                    $display("Expected: u=%0d spike=%0d",
                             hu[j], hs[j]);
                    $display("Actual: u=%0d spike=%0d",
                             $signed(dut.hidden_u[j*16 +: 16]),
                             dut.spike_hidden[j]);
                    $fatal(1, "Hidden mismatch");
                end
            end

            for (j = 0; j < 2; j = j + 1) begin
                if (dut.output_u[j*16 +: 16] !== ou[j][15:0] ||
                    spike_out[j] !== os[j][0]) begin

                    $display("FAIL: step=%0d output=%0d",
                             step_count, j);
                    $display("Expected: u=%0d spike=%0d",
                             ou[j], os[j]);
                    $display("Actual: u=%0d spike=%0d",
                             $signed(dut.output_u[j*16 +: 16]),
                             spike_out[j]);
                    $fatal(1, "Output mismatch");
                end
            end
        end
    endtask

    task automatic reset_network;
        integer j;
        begin
            @(negedge clk);
            rst = 1;
            hidden_en = 1;
            output_en = 1;

            for (j = 0; j < 4; j = j + 1) begin
                hu[j] = 0;
                hs[j] = 0;
            end

            for (j = 0; j < 2; j = j + 1) begin
                ou[j] = 0;
                os[j] = 0;
            end

            @(posedge clk);
            #1;
            check_all();
        end
    endtask

    // 一个完整SNN时间步：先隐藏层，再输出层
    task automatic run_step;
        input [3:0] s;
        input [127:0] wh;
        input [63:0] wo;

        integer j, m, cur;
        begin
            // 第一阶段：隐藏层更新
            @(negedge clk);
            rst = 0;
            hidden_en = 1;
            output_en = 0;

            spike_in = s;
            hidden_weights = wh;
            output_weights = wo;

            for (j = 0; j < 4; j = j + 1) begin
                cur = 0;

                for (m = 0; m < 4; m = m + 1)
                    if (s[m])
                        cur = cur +
                            $signed(wh[j*32 + m*8 +: 8]);

                hs[j] = next_spike(hu[j], cur);
                hu[j] = next_u(hu[j], cur);
            end

            @(posedge clk);
            #1;
            check_all();

            // 第二阶段：输出层更新
            @(negedge clk);
            hidden_en = 0;
            output_en = 1;

            for (j = 0; j < 2; j = j + 1) begin
                cur = 0;

                for (m = 0; m < 4; m = m + 1)
                    if (hs[m])
                        cur = cur +
                            $signed(wo[j*32 + m*8 +: 8]);

                os[j] = next_spike(ou[j], cur);
                ou[j] = next_u(ou[j], cur);
            end

            @(posedge clk);
            #1;
            check_all();

            step_count = step_count + 1;
        end
    endtask

    initial begin
        $dumpfile("network_wave.vcd");
        $dumpvars(0, tb_snn_network_442);

        reset_network();

        // 固定测试：验证两层权重和Spike传递
        run_step(
            4'b0001,
            {32'h00000000, 32'h00000028,
             32'h000000F6, 32'h00000014},
            {32'h00050000, 32'h000A000A}
        );

        $display("Demo: hidden=%b output=%b",
                 dut.spike_hidden, spike_out);

        // 100个随机SNN时间步
        for (i = 0; i < 100; i = i + 1) begin

            if (i % 25 == 0)
                reset_network();

            run_step(
                $random,
                {$random, $random, $random, $random},
                {$random, $random}
            );
        end

        // 两层全部禁用，改变输入，状态应保持
        @(negedge clk);
        hidden_en = 0;
        output_en = 0;
        spike_in = 4'b1111;
        hidden_weights = {4{32'h7F7F7F7F}};
        output_weights = {2{32'h7F7F7F7F}};

        @(posedge clk);
        #1;
        check_all();

        $display("--------------------------------");
        $display("PASS: %0d network steps verified!", step_count);
        $display("All 6 neurons matched reference.");
        $display("--------------------------------");

        $finish;
    end

endmodule
