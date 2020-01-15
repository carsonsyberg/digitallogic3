`timescale 1 ns / 100 ps

module test_bench();

    reg [9:0] sw_in;
    reg [1:0] k_in;
    reg clock;
    wire [9:0] l_out;
    wire [7:0] H0;


    top_V2 T0(.SW(sw_in), .HEX0(H0), .LEDR(l_out), .ADC_CLK_10(clock), .KEY(k_in));

    initial begin
        $dumpfile("out.vcd");
        $dumpvars;
        $display($time, "<<Starting Simulation>>");
        clock = 1'b0; // initial clock value LOW
        k_in = 2'b10; // initial reset
        sw_in = 10'b0000000000; // initial sw_in values in-active
        #10
        k_in = 2'b11; // reset off

        $display($time, "<<IDLE State>>");
        // IDLE State
        #100
        
        $display($time, "<<HAZARD State>>");
        // HAZARD State
        sw_in = 10'b0000000001; // SW0 active
        #100
        sw_in = 10'b0000000000; // SW0 in-active
        #25

        // TURN State
        $display($time, "<<LEFT State>>");
        sw_in = 10'b0000000010; // SW1 active
        #100 // Left Blinker

        $display($time, "<<RIGHT State>>");
        k_in = 2'b01;
        #100 // Right Blinker
        sw_in = 10'b0000000000; // right blinker off
        #25

        sw_in = 10'b0000000001; // hazards on
        #100
        k_in = 2'b00; // RESET active
        #50
        k_in = 2'b01; // RESET in-active
        #100 
        k_in = 2'b11; // return to IDLE
        sw_in = 10'b0000000000;
        #50
        $display($time, "<<Simulation Complete>>");
        $finish;             
    end

    always
        #5 clock = ~clock; // creates 100 Mhz Clock

endmodule