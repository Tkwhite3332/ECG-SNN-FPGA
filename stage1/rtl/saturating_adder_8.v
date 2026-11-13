module saturating_adder_8(
    input  signed [7:0] a,
    input  signed [7:0] b,
    output signed [7:0] sum,
    output overflow
);

    // 由你完成
    wire signed [7:0] raw_sum = a+b;
    assign overflow = (~(a[7] ^ b[7])) & (a[7] ^ raw_sum[7]);
    assign sum = overflow ? $signed({a[7],{7{~a[7]}}}) : raw_sum;
endmodule