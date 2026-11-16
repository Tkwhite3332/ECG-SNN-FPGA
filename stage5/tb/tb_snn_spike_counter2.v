
`timescale 1ns/1ps

module tb_snn_spike_counter2;

    reg clk = 0;
    reg rst = 0;
    reg clear = 0;
    reg count_en = 0;
    reg [1:0] spike_in = 0;

    wire [4:0] count0;
    wire [4:0] count1;

    integer expected0 = 0;
    integer expected1 = 0;
    integer tests = 0;
    integer i;

    snn_spike_counter2 dut (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .count_en(count_en),
        .spike_in(spike_in),
        .count0(count0),
        .count1(count1)
    );

    always #5 clk = ~clk;

    task automatic check_step;
        input r;
        input c;
        input en;
        input [1:0] s;

        begin
            @(negedge clk);

            rst = r;
            clear = c;
            count_en = en;
            spike_in = s;

            if (r || c) begin
                expected0 = 0;
                expected1 = 0;
            end
            else if (en) begin
                expected0 = (expected0 + s[0]) % 32;
                expected1 = (expected1 + s[1]) % 32;
            end

            @(posedge clk);
            #1;

            tests = tests + 1;

            if (count0 !== expected0[4:0] ||
                count1 !== expected1[4:0]) begin

                $display("FAIL: Test %0d", tests);
                $display("Expected: %0d %0d",
                         expected0, expected1);
                $display("Actual: %0d %0d",
                         count0, count1);

                $fatal(1, "Counter mismatch");
            end
        end
    endtask

    initial begin
        $dumpfile("counter_wave.vcd");
        $dumpvars(0, tb_snn_spike_counter2);

        // 1. 系统复位
        check_step(1, 0, 0, 2'b00);

        // 2. 连续16个时间步，两个神经元都发放
        for (i = 0; i < 16; i = i + 1)
            check_step(0, 0, 1, 2'b11);

        if (count0 !== 5'd16 || count1 !== 5'd16)
            $fatal(1, "16-spike boundary failed");

        $display("16 steps: count0=%0d count1=%0d",
                 count0, count1);

        // 3. 使能关闭：即使Spike=1也不能计数
        check_step(0, 0, 0, 2'b11);

        // 4. clear优先于count_en
        check_step(0, 1, 1, 2'b11);

        // 5. 分别测试两个计数器
        check_step(0, 0, 1, 2'b01);
        check_step(0, 0, 1, 2'b10);
        check_step(0, 0, 1, 2'b01);

        // 6. 随机测试
        for (i = 0; i < 500; i = i + 1) begin
            check_step(
                (i % 97) == 0,
                (i % 31) == 0,
                (i % 7) != 0,
                $random
            );
        end

        $display("------------------------------");
        $display("PASS: All %0d tests passed!", tests);
        $display("------------------------------");

        $finish;
    end

endmodule
