module snn_network_442(
    input clk,
    input hidden_en,
    input output_en,
    input rst,

    input [3:0] spike_in,
    
    input [127:0] hidden_weights,
    input [63:0] output_weights,

    output [1:0] spike_out
);

    wire [3:0] spike_hidden;
    wire [63:0] hidden_u;
    wire [31:0] output_u;

    snn_hidden_layer4 hidden_layer(
        .clk(clk),
        .en(hidden_en),
        .rst(rst),
        .spike_in(spike_in),
        .weights(hidden_weights),
        .spike_out(spike_hidden),
        .u_out(hidden_u)
    );

    snn_output_layer2 output_layer(
        .clk(clk),
        .en(output_en),
        .rst(rst),
        .spike_in(spike_hidden),
        .weights(output_weights),
        .spike_out(spike_out),
        .u_out(output_u)
    );


endmodule