module snn_inference_442(
    input clk,
    input rst,
    input start,

    input [3:0] spike_in,

    input [127:0] hidden_weights,
    input [63:0] output_weights,

    output [3:0] step,
    output done,

    output [4:0] count0,
    output [4:0] count1,

    output [1:0] spike_out
);

    wire hidden_en;
    wire output_en;
    wire count_en;
    wire clear;
    wire network_rst;

    assign network_rst = rst | clear;

    snn_controller controller(
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

    snn_network_442 network(
        .clk(clk),
        .hidden_en(hidden_en),
        .output_en(output_en),
        .rst(network_rst),

        .spike_in(spike_in),
        
        .hidden_weights(hidden_weights),
        .output_weights(output_weights),

        .spike_out(spike_out)
    );

    snn_spike_counter2 counter(
        .clk(clk),
        .count_en(count_en),
        .rst(network_rst),

        .spike_in(spike_out),

        .count0(count0),
        .count1(count1)
    );

endmodule