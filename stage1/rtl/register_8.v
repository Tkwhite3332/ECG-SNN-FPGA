module register_8(
    input clk,
    input rst,
    input en,
    input signed [7:0] d,
    output reg signed [7:0] q
);

    // 由你完成
    always @(posedge clk) begin
        if(rst == 1'b1)
            q = 8'b00000000;
        else if(en == 1'b1)
            q <= d;
        else;

    end
endmodule