module top_V2 (SW, HEX0, LEDR, ADC_CLK_10, KEY);

parameter IDLE = 3'b000;
parameter HAZARD = 3'b001;
parameter TURN = 3'b010;

input [9:0] SW;
output reg [9:0] LEDR;
output [7:0] HEX0;

input ADC_CLK_10;
input [1:0] KEY;

wire reset_n, signalEnable, LR, hazard;

assign reset_n = KEY[0];
assign signalEnable = SW[1];
assign LR = KEY[1];
assign hazard = SW[0];

wire sysClock, displayClock, memoryClock;
assign displayClock = ADC_CLK_10;
 
reg [1:0] CState, NState, mem_state;
wire [1:0] state; 
assign state = SW[9] ? mem_state : CState;

reg [2:0] blinkL, blinkR;
//assign LEDR[9:7] = ((signalEnable & LR) | hazard) ? blinkL : 0;
//assign LEDR[2:0] = (hazard | (signalEnable & ~LR)) ? blinkR : 0;

clk_div_V1 C0(.clk(ADC_CLK_10), .reset(KEY[0]), .clk_out(sysClock));
clk_div_V2 C1(.clk(ADC_CLK_10), .reset(KEY[0]), .clk_out(memoryClock));
segmentdriver S0(.numIn(CState), .hexOut(HEX0));

initial begin
        CState = 0;
        blinkL = 0;
        blinkR = 0;
        count = 0;
end

// Output Logic
always @ (state or blinkL or blinkR) begin

    if(state == IDLE) begin
        LEDR[9:7] <= 0;
        LEDR[2:0] <= 0;
    end
    else if(state == HAZARD) begin
        LEDR[9:7] <= blinkL;
        LEDR[2:0] <= blinkR;
    end
    else
        if(~LR) begin
            // if KEY[1] 0 blink left
            LEDR[9:7] <= blinkL;
            LEDR[2:0] <= 0;
        end
        else begin
            // if KEY[1] 1 blink right
            LEDR[9:7] <= 0;
            LEDR[2:0] <= blinkR;
        end

end

// Display Block
reg [3:0] count;
wire [3:0] countPlus;
always @ (posedge displayClock or negedge reset_n) begin
    if(~reset_n) begin
        blinkL <= 0;
        blinkR <= 0;
        count = 0;
    end
    else if(count == 3) begin
        blinkL <= 3'b111;
        blinkR <= 3'b111;
        count = 0;
    end
    else if(count == 2) begin
        blinkL <= 3'b011;
        blinkR <= 3'b110;
        count = countPlus;
    end
    else if(count == 1) begin
        blinkL <= 3'b001;
        blinkR <= 3'b100;
        count = countPlus;
    end
    else begin
        blinkL <= 0;
        blinkR <= 0;
        count = countPlus;
    end
end
assign countPlus = count + 1;

// Current State Logic
always @ (posedge sysClock or negedge reset_n)
    if(reset_n == 0)
        CState <= IDLE;
    else
        CState <= NState;

// Next State Logic
always @ (CState or LR or signalEnable or hazard) begin
    if(CState == IDLE) begin
        if(hazard)
            NState = HAZARD;
        else if(signalEnable)
            NState = TURN;
        else
            NState = IDLE;
    end

    if(CState == HAZARD) begin
        if(hazard)
            NState = HAZARD;
        else if(signalEnable)
            NState = TURN;
        else
            NState = IDLE;
    end

    if(CState == TURN) begin
        if(hazard)
            NState = HAZARD;
        else if(signalEnable)
            NState = TURN;
        else
            NState = IDLE;
    end
end

endmodule