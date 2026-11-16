module snn_spike_counter2(
    input clk,
    input rst,
    input count_en,

    input [1:0] spike_in,

    output reg [4:0] count0,
    output reg [4:0] count1
);

    always @(posedge clk) begin

        if (rst) begin
            count0 <= 5'd0;
            count1 <= 5'd0;
        end
        else if (count_en) begin
            count0 <= count0 + spike_in[0];
            count1 <= count1 + spike_in[1];
        end

    end

endmodule