module snn_hidden_layer4(
    input clk,
    input rst,
    input en,

    input [3:0] spike_in,
    input [127:0] weights,

    output [3:0] spike_out,
    output [63:0] u_out
);

    genvar i;

    generate
        for (i = 0; i < 4; i = i + 1) begin : GEN_NEURON
            snn_neuron_4in hidden_lif(
              .clk(clk),
              .rst(rst),
              .en(en),

              .spike_in(spike_in),
              .w_0(weights[i*32 +: 8]),
              .w_1(weights[i*32+1*8 +: 8]),
              .w_2(weights[i*32+2*8 +: 8]),
              .w_3(weights[i*32+3*8 +: 8]),

              .spike_out(spike_out[i]),
              .u(u_out[i*16 +: 16])  
            );
        end
    endgenerate

endmodule