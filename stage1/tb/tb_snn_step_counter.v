`timescale 1ns/1ps

module tb_snn_step_counter;

    reg clk;
    reg rst;
    reg en;
    wire [3:0] step;
    wire done;
    integer i, temp;

    snn_step_counter dut(.clk(clk), .rst(rst), .en(en), .step(step), .done(done));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_snn_step_counter);

        //测试1：正常复位
        rst = 1;
        en = 0;

        @(posedge clk);
        #1;

        if(step !== 4'b0)
            $fatal(1,"Test 1 failed.");

        //测试2：正常计数
        @(negedge clk);
        rst = 0;
        en = 1;

        for(i=1;i<=15;i=i+1) begin  
            @(posedge clk);
            #1;

            if(step !== i[3:0])
                $fatal(1,"Test 2 failed.");
        end

        //测试3：终值检测
        @(negedge clk);
        rst = 0;
        en = 1;
        #1;

        if(done !== 1)
            $fatal(1,"Done failed.");

        @(posedge clk);
        #1;

        if(step !== 4'b0 || done !== 0)
            $fatal(1,"Test 3 failed.");

        //测试4：回绕
        @(posedge clk);
        #1;

        if(step !== 4'b1)
            $fatal(1,"Test 4 failed.");

        //测试5：状态保持
        @(negedge clk);
        rst = 0;
        en = 0;
        temp = step;

        @(posedge clk);
        #1;

        if(step !== temp)
            $fatal(1,"Test 5 failed.");

        //测试6：复位优先
        @(negedge clk);
        rst = 1;
        en = 1;

        @(posedge clk);
        #1;

        if(step !== 4'b0)
            $fatal(1,"Test 6 failed.");

        $display("All test finished.");
        $finish;
    end
endmodule
