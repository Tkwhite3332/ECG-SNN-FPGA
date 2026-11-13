`timescale 1ns/1ps

module tb_saturating_adder_8;

    reg signed [7:0] a;
    reg signed [7:0] b;
    wire signed [7:0] sum;
    wire overflow;


    saturating_adder_8 dut(a, b, sum, overflow);

    initial begin

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_saturating_adder_8);

        //text1
        a = 8'sd30;
        b = 8'sd40;

        #10;

        $display("a=%0d,b=%0d,sum=%0d,overflow=%0d",a ,b, sum, overflow);
        if((sum !== 8'sd70) || (overflow !== 1'b0))
            $fatal(1,"text1 failed");

        //text2
        a = 8'sd100;
        b = 8'sd60;

        #10;

        $display("a=%0d,b=%0d,sum=%0d,overflow=%0d",a ,b, sum, overflow);
        if((sum !== 8'sd127) || (overflow !== 1'b1))
            $fatal(1,"text2 failed");

        //text3
        a = -8'sd100;
        b = -8'sd100;

        #10;

        $display("a=%0d,b=%0d,sum=%0d,overflow=%0d",a ,b, sum, overflow);
        if((sum !== -8'sd128) || (overflow !== 1'b1))
            $fatal(1,"text3 failed");
        
        //text4
        a = -8'sd100;
        b = 8'sd80;

        #10;

        $display("a=%0d,b=%0d,sum=%0d,overflow=%0d",a ,b, sum, overflow);
        if((sum !== -8'sd20) || (overflow !== 1'b0))
            $fatal(1,"text4 failed");

        //text5
        a = 8'sd127;
        b = 8'sd127;

        #10;

        $display("a=%0d,b=%0d,sum=%0d,overflow=%0d",a ,b, sum, overflow);
        if((sum !== 8'sd127) || (overflow !== 1'b1))
            $fatal(1,"text5 failed");      

        //text6
        a = -8'sd128;
        b = -8'sd128;

        #10;

        $display("a=%0d,b=%0d,sum=%0d,overflow=%0d",a ,b, sum, overflow);
        if((sum !== -8'sd128) || (overflow !== 1'b1))
            $fatal(1,"text6 failed");

        $display("All tests passed!");
        $finish;    
    end
endmodule