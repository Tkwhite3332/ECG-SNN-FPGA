module lif_neuron(
    input clk,
    input rst,
    input step_en,
    input signed [15:0] current,
    output reg signed [15:0] u,
    output reg spike
);

    wire signed [15:0] leak;
    wire signed [16:0] u_raw_1;
    wire signed [16:0] u_raw_2;
    wire spike_next;
    reg signed [15:0] u_next;

    assign leak = u >>> 1;

    assign u_raw_1 = {leak[15], leak} + {current[15], current};
    assign u_raw_2 = u_raw_1 - 17'sd15;
    assign spike_next = (u_raw_2 > 17'sd0); 
    
    always@(*) begin
        if(u_raw_2 > 17'sd32767)
            u_next = 16'sd32767;
        else if(u_raw_1 < -17'sd32768)
            u_next = 16'sh8000;
        else
            u_next = spike_next ? u_raw_2 : u_raw_1;
    end
    
    
    always@(posedge clk) begin
        if(rst) begin
            spike <= 16'sd0;
            u <= 16'sd0;
        end
        else if(step_en) begin
            spike <= spike_next;
            u <= u_next;
        end
    end 

endmodule