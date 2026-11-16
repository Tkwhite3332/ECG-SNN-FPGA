
`timescale 1ns/1ps

module tb_snn_inference_442;

    reg clk = 0;
    reg rst = 0;
    reg start = 0;

    reg [3:0] patterns [0:15];

    wire [3:0] step;
    wire [3:0] spike_in;
    wire done;
    wire [4:0] count0, count1;
    wire [1:0] spike_out;

    reg [127:0] hidden_weights;
    reg [63:0] output_weights;

    integer hu [0:3];
    integer hs [0:3];
    integer ou [0:1];
    integer os [0:1];

    integer ref_count0 = 0;
    integer ref_count1 = 0;

    integer i, n, k, cur;
    integer new_u, new_spike;

    // 根据FSM时间步自动选择输入Spike
    assign spike_in = patterns[step];

    snn_inference_442 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .spike_in(spike_in),
        .hidden_weights(hidden_weights),
        .output_weights(output_weights),
        .step(step),
        .done(done),
        .count0(count0),
        .count1(count1),
        .spike_out(spike_out)
    );

    always #5 clk = ~clk;

    // 独立整数参考模型
    task automatic model_lif;
        input integer old_u;
        input integer input_current;
        output integer result_u;
        output integer result_spike;

        integer leak, v, raw;
        begin
            leak = old_u / 2;
            if (old_u < 0 && old_u % 2 != 0)
                leak = leak - 1;

            v = leak + input_current;
            result_spike = (v > 15);

            raw = v;
            if (result_spike)
                raw = raw - 15;

            if (raw > 32767)
                result_u = 32767;
            else if (raw < -32768)
                result_u = -32768;
            else
                result_u = raw;
        end
    endtask

    task automatic check_hidden;
        integer j;
        begin
            for (j = 0; j < 4; j = j + 1) begin
                if (dut.network.hidden_u[j*16 +: 16]
                        !== hu[j][15:0] ||
                    dut.network.spike_hidden[j]
                        !== hs[j][0]) begin
                    $display("Hidden neuron %0d failed", j);
                    $fatal(1, "Hidden state mismatch");
                end
            end
        end
    endtask

    task automatic check_output;
        integer j;
        begin
            for (j = 0; j < 2; j = j + 1) begin
                if (dut.network.output_u[j*16 +: 16]
                        !== ou[j][15:0] ||
                    spike_out[j] !== os[j][0]) begin
                    $display("Output neuron %0d failed", j);
                    $fatal(1, "Output state mismatch");
                end
            end
        end
    endtask

    initial begin
        $dumpfile("inference_wave.vcd");
        $dumpvars(0, tb_snn_inference_442);

        // 每个隐藏层神经元使用独立权重
        hidden_weights = {
            32'h32000000,
            32'h00280000,
            32'h00001E00,
            32'h00000014
        };

        output_weights = {
            32'hF60A1905,
            32'h14141414
        };

        // 准备16组输入Spike
        for (i = 0; i < 16; i = i + 1)
            patterns[i] = (i * 5 + 3) ^ (i >> 1);

        for (i = 0; i < 4; i = i + 1) begin
            hu[i] = 0;
            hs[i] = 0;
        end

        for (i = 0; i < 2; i = i + 1) begin
            ou[i] = 0;
            os[i] = 0;
        end

        // 系统复位
        @(negedge clk);
        rst = 1;

        @(posedge clk);
        #1;

        // 启动推理
        @(negedge clk);
        rst = 0;
        start = 1;

        @(posedge clk);
        #1;

        if (dut.clear !== 1'b1)
            $fatal(1, "INIT missing");

        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;

        if (step !== 4'd0 ||
            dut.hidden_en !== 1'b1)
            $fatal(1, "First HIDDEN missing");

        // 检查16个完整SNN时间步
        for (i = 0; i < 16; i = i + 1) begin

            if (step !== i[3:0] ||
                dut.hidden_en !== 1'b1)
                $fatal(1, "HIDDEN/step error at %0d", i);

            // 参考模型：隐藏层
            for (n = 0; n < 4; n = n + 1) begin
                cur = 0;

                for (k = 0; k < 4; k = k + 1)
                    if (patterns[i][k])
                        cur = cur + $signed(
                            hidden_weights[n*32+k*8 +: 8]
                        );

                model_lif(hu[n], cur, new_u, new_spike);
                hu[n] = new_u;
                hs[n] = new_spike;
            end

            @(posedge clk);
            #1;
            check_hidden();

            if (dut.output_en !== 1'b1)
                $fatal(1, "OUTPUT missing");

            // 参考模型：输出层
            for (n = 0; n < 2; n = n + 1) begin
                cur = 0;

                for (k = 0; k < 4; k = k + 1)
                    if (hs[k])
                        cur = cur + $signed(
                            output_weights[n*32+k*8 +: 8]
                        );

                model_lif(ou[n], cur, new_u, new_spike);
                ou[n] = new_u;
                os[n] = new_spike;
            end

            @(posedge clk);
            #1;
            check_output();

            if (dut.count_en !== 1'b1)
                $fatal(1, "COUNT missing");

            // COUNT状态对应的上升沿
            @(posedge clk);
            #1;

            ref_count0 = ref_count0 + os[0];
            ref_count1 = ref_count1 + os[1];

            if (count0 !== ref_count0[4:0] ||
                count1 !== ref_count1[4:0])
                $fatal(1, "Spike count mismatch at %0d", i);

            if (i < 15 && dut.hidden_en !== 1'b1)
                $fatal(1, "Next HIDDEN missing");

            $display("Step %0d: spikes=%b counts=%0d,%0d",
                     i, spike_out, count0, count1);
        end

        if (done !== 1'b1 || step !== 4'd15)
            $fatal(1, "DONE or final step incorrect");

        @(posedge clk);
        #1;

        if (done !== 1'b0)
            $fatal(1, "DONE not deasserted");

        $display("--------------------------------");
        $display("PASS: 16 SNN steps verified!");
        $display("Final count0 = %0d", count0);
        $display("Final count1 = %0d", count1);
        $display("--------------------------------");

        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "Simulation timeout");
    end

endmodule
