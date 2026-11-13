module accumulator_16(
    input clk,
    input rst,
    input en,
    input signed [15:0] d,
    output reg signed [15:0] q
);

    // 由你完成
    always@(posedge clk) begin
        if(rst)
            q <= 16'b0;
        else if(en)
            q <= q + d;
    end

endmodule