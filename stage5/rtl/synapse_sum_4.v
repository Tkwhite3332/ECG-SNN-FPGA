module synapse_sum_4 (
    input [3:0] spike_in,

    input signed [7:0] w_0,
    input signed [7:0] w_1,
    input signed [7:0] w_2,
    input signed [7:0] w_3,

    output signed [15:0] current
);

    wire signed [15:0] term0,term1,term2,term3;

    assign term0 = spike_in[0] ? {{8{w_0[7]}}, w_0} : 16'sd0;
    assign term1 = spike_in[1] ? {{8{w_1[7]}}, w_1} : 16'sd0;
    assign term2 = spike_in[2] ? {{8{w_2[7]}}, w_2} : 16'sd0;
    assign term3 = spike_in[3] ? {{8{w_3[7]}}, w_3} : 16'sd0;

    wire signed [15:0] sum01, sum23;

    assign sum01 = term0 + term1;
    assign sum23 = term2 + term3;

    assign current = sum01 + sum23;
endmodule