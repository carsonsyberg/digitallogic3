// clock divider from the 10 MHz input clock to a 1 Hz clock
module clk_div_V1 (clk, reset, clk_out);

    input clk;
    input reset;
    output clk_out;

    reg [19:0] counter;
    wire [19:0] counterplus;
    reg clk_track;

    always @(posedge clk or negedge reset)
    begin
        
        if(~reset) begin
            counter = 0;
            clk_track <= 0;
        end
        else if(counterplus == 750000) begin
            counter = 0;
            clk_track <= ~clk_track;
        end
        else
            counter = counterplus; 
    end

    assign counterplus = counter + 1;
    assign clk_out = clk_track;

endmodule