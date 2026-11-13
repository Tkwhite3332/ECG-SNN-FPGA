module snn_neuron_4in(
    input clk,
    input en,
    input rst,

    input [3:0] spike_in,

    input signed [7:0] w_0,
    input signed [7:0] w_1,
    input signed [7:0] w_2,
    input signed [7:0] w_3,

    output signed [15:0] u,
    output spike_out
);
    
    wire signed [15:0] current;

    synapse_sum_4 u_synapse(
        .spike_in(spike_in),

        .w_0(w_0),
        .w_1(w_1),
        .w_2(w_2),
        .w_3(w_3),

        .current(current)
    );

    lif_neuron neuron_0(
        .clk(clk),
        .step_en(en),
        .rst(rst),

        .current(current),
        
        .u(u),
        .spike(spike_out)
    );

endmodule