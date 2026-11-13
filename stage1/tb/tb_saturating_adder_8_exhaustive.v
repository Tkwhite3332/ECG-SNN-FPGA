`timescale 1ns/1ps

module tb_saturating_adder_8_exhaustive;

    reg signed [7:0] a;
    reg signed [7:0] b;
    wire signed [7:0] sum;
    wire overflow;

    saturating_adder_8 dut(.a(a), .b(b), .sum(sum), .overflow(overflow));

    integer i,j;
    integer true_sum;
    integer test_count;
    reg signed [7:0] expected_sum;
    reg expected_overflow;

    initial begin

        test_count = 0;

        for(i = -128;i <= 127;i = i + 1) begin
            for(j = -128;j <= 127;j = j + 1) begin
                a = i;
                b = j;
                true_sum = i + j;

                #1;

                expected_overflow =(true_sum > 127) || (true_sum <-128);

                if (true_sum > 127)
                    expected_sum = 8'sd127;
                else if (true_sum < -128)
                    expected_sum = -8'sd128;
                else
                    expected_sum = true_sum[7:0];

                if((sum !== expected_sum) || (overflow !== expected_overflow))
                    $fatal(1,
                        "a=%0d b=%0d | sum=%0d expected=%0d | overflow=%b expected=%b",
                        i, j, sum, expected_sum,
                        overflow, expected_overflow);
                else
                    test_count = test_count + 1;
            end
        end
        if (test_count !== 65536)
            $fatal(1, "Wrong test count: %0d", test_count);

        $display("All %0d tests passed!", test_count);
        $finish;
    end

endmodule