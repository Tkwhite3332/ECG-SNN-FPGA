module snn_step_counter(
    input clk,
    input rst,
    input en,
    output reg [3:0] step,
    output done
);

    // 由你完成
    always @(posedge clk) begin
        if(rst)
            step <= 4'b0;
        else if(en)
            step <= step + 4'b1;
    end

    assign done = !rst && en && (step == 4'd15);

endmodule