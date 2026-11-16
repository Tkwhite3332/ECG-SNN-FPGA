
`timescale 1ns/1ps

module tb_snn_controller;

    reg clk = 0;
    reg rst = 0;
    reg start = 0;

    wire hidden_en;
    wire output_en;
    wire count_en;
    wire clear;
    wire done;
    wire [3:0] step;

    integer hidden_count = 0;
    integer output_count = 0;
    integer count_count = 0;
    integer done_count = 0;
    integer cycle_count = 0;
    integer phase = 0;
    integer expected_step = 0;

    snn_controller dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .hidden_en(hidden_en),
        .output_en(output_en),
        .count_en(count_en),
        .clear(clear),
        .done(done),
        .step(step)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("controller_wave.vcd");
        $dumpvars(0, tb_snn_controller);

        // 同步复位
        @(negedge clk);
        rst = 1;

        @(posedge clk);
        #1;

        if (done !== 0 || step !== 0)
            $fatal(1, "Reset failed");

        // 启动一次推理
        @(negedge clk);
        rst = 0;
        start = 1;

        @(posedge clk);
        #1;

        if (clear !== 1)
            $fatal(1, "INIT state missing");

        // 撤销 start
        @(negedge clk);
        start = 0;

        // INIT -> HIDDEN
        @(posedge clk);
        #1;

        if (hidden_en !== 1 || step !== 0)
            $fatal(1, "HIDDEN state missing");

        // 检查16个时间步
        for (expected_step = 0;
             expected_step < 16;
             expected_step = expected_step + 1) begin

            // 当前为HIDDEN
            if (hidden_en !== 1 || step !== expected_step)
                $fatal(1, "HIDDEN mismatch at step %0d",
                       expected_step);
            hidden_count = hidden_count + 1;

            @(posedge clk);
            #1;

            // 进入OUTPUT
            if (output_en !== 1 || step !== expected_step)
                $fatal(1, "OUTPUT mismatch at step %0d",
                       expected_step);
            output_count = output_count + 1;

            @(posedge clk);
            #1;

            // 进入COUNT
            if (count_en !== 1 || step !== expected_step)
                $fatal(1, "COUNT mismatch at step %0d",
                       expected_step);
            count_count = count_count + 1;

            @(posedge clk);
            #1;
        end

        // 最后一轮COUNT结束后应该进入DONE
        if (done !== 1 || step !== 15)
            $fatal(1, "DONE state or final step incorrect");

        done_count = done_count + 1;

        @(posedge clk);
        #1;

        // DONE只持续一个周期
        if (done !== 0)
            $fatal(1, "DONE must be one cycle");

        if (hidden_count !== 16 ||
            output_count !== 16 ||
            count_count !== 16 ||
            done_count !== 1)
            $fatal(1, "Incorrect state counts");

        $display("--------------------------------");
        $display("PASS: FSM controller verified!");
        $display("HIDDEN = %0d", hidden_count);
        $display("OUTPUT = %0d", output_count);
        $display("COUNT  = %0d", count_count);
        $display("DONE   = %0d", done_count);
        $display("--------------------------------");

        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "Simulation timeout");
    end

endmodule
