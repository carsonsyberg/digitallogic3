module segmentdriver(numIn, hexOut);

    input [1:0] numIn;
    output reg [7:0] hexOut; 

    always @ (numIn) begin
        // Controls hexOut
        if(numIn == 2'b11) // input 3
            hexOut <= 8'b10110000; // 3
        else if(numIn == 2'b10) // input 2
            hexOut <= 8'b10100100; // 2
        else if(numIn == 2'b01) // input 1
            hexOut <= 8'b11111001; // 1
        else if(numIn == 2'b00) // input 0
            hexOut <= 8'b11000000; // 0
        else
            hexOut <= 8'b11111111; // OFF
    end

endmodule