module signed_adder_8(
    input  signed [7:0] a,
    input  signed [7:0] b,
    output signed [8:0] sum
);

    // 在这里完成设计
    assign sum = $signed{a[7], a} + $signed{b[7], b};

endmodule