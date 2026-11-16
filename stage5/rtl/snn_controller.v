module snn_controller(
    input clk,
    input rst,
    input start,

    output hidden_en,
    output output_en,
    output count_en,
    output clear,
    output done,
    output [3:0] step
);

    localparam IDLE   = 3'd0;
    localparam INIT   = 3'd1;
    localparam HIDDEN = 3'd2;
    localparam OUTPUT = 3'd3;
    localparam COUNT  = 3'd4;
    localparam DONE   = 3'd5;

    reg [2:0] state;
    reg [2:0] next_state;

    reg [3:0] step_reg;
    assign step = step_reg;

    // 根据当前状态生成控制信号
    assign hidden_en = (state == HIDDEN);
    assign output_en = (state == OUTPUT);
    assign count_en  = (state == COUNT);
    assign clear     = (state == INIT);
    assign done      = (state == DONE);

    // TODO 1：状态寄存器与时间步计数器
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            step_reg <= 4'd0;
        end
        else begin
            state <= next_state;
            if (state == INIT)
                step_reg <= 4'd0;
            else if ((state == COUNT) && (step_reg < 15))
                step_reg <= step_reg + 1;
        end
    end

    // TODO 2：下一状态组合逻辑
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start == 1)
                    next_state = INIT;
            end

            INIT: begin
                next_state = HIDDEN;
            end

            HIDDEN: begin
                next_state = OUTPUT;
            end

            OUTPUT: begin
                next_state = COUNT;
            end

            COUNT: begin
                if (step_reg == 15)
                    next_state = DONE;
                else
                    next_state = HIDDEN;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
