module saturating_accumulator_16(
    input clk,
    input rst,
    input en,
    input signed [15:0] d,
    output reg signed [15:0] q
);

    wire signed [15:0] raw_sum;
    wire overflow;

    // 1. 完成17位有符号加法
    assign raw_sum = d + q;
    assign overflow = ~(q[15] ^ d[15]) && (d[15] ^ raw_sum[15]);

    // 2. 完成寄存器更新逻辑
    always @(posedge clk) begin
        if (rst)
            q <= 16'sd0;
        else if (en) begin

            // 3. 检测正溢出
            if(overflow)
                q <= {d[15], {15{~d[15]}}};
            // 4. 正常情况下写入计算结果
            else
                q <= raw_sum;
        end
    end

endmodule