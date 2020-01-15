// clock divider from the 10 MHz input clock to a 1 Hz clock
module clk_div_V2 (clk, reset, clk_out);

    input clk;
    input reset;
    output clk_out;

    reg [23:0] counter;
    wire [23:0] counterplus;
    reg clk_track;

    always @(posedge clk or negedge reset)
    begin
        
        if(~reset) begin
            counter = 0;
            clk_track <= 0;
        end
        else if(counterplus == 5000000) begin
            counter = 0;
            clk_track <= ~clk_track;
        end
        else
            counter = counterplus; 
    end

    assign counterplus = counter + 1;
    assign clk_out = clk_track;

endmodule