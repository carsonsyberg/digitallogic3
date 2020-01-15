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
reg mem_key;

assign reset_n = KEY[0];
assign signalEnable = SW[1];
assign LR = SW[9] ? mem_key : KEY[1];
assign hazard = SW[0];

wire sysClock, displayClock, memoryClock;
assign sysClock = ADC_CLK_10;
 
reg [1:0] CState, NState, mem_state;
wire [1:0] state, addIDLE, addHAZ, addTURN, mem_idle, mem_haz, mem_turn;
assign addIDLE = 2'b00;
assign addHAZ = 2'b01;
assign addTURN = 2'b10;
// make mem_state output of memory module INSTANTIATE mem module
assign state = SW[9] ? mem_state : CState;

reg [2:0] blinkL, blinkR;
//assign LEDR[9:7] = ((signalEnable & LR) | hazard) ? blinkL : 0;
//assign LEDR[2:0] = (hazard | (signalEnable & ~LR)) ? blinkR : 0;

clk_div_V1 C0(.clk(ADC_CLK_10), .reset(KEY[0]), .clk_out(displayClock));
clk_div_V2 C1(.clk(ADC_CLK_10), .reset(KEY[0]), .clk_out(memoryClock));
segmentdriver S0(.numIn(state), .hexOut(HEX0));

memBlock M0(.address(addIDLE), .clock(ADC_CLK_10), .q(mem_idle));
memBlock M1(.address(addHAZ), .clock(ADC_CLK_10), .q(mem_haz));
memBlock M2(.address(addTURN), .clock(ADC_CLK_10), .q(mem_turn));
// PUT THIS IN MEMORY MODULE MADE BY MIF FILE
// Memory Controller Logic
reg [5:0] countM;
wire [5:0] countPlusM;
assign countPlusM = countM + 1;

always @ (posedge memoryClock) begin
    if(countM == 0) begin
        mem_state <= mem_idle;
        countM = countPlusM;
    end
    else if(countM == 5) begin // 5 seconds of OFF
        // Hazard State
        mem_state <= mem_haz;
        countM = countPlusM;
    end
    else if(countM == 10) begin
        // hazards OFF and Left ON Turn State
        mem_state <= mem_turn;
        mem_key <= 0;
        countM = countPlusM;
    end
    else if(countM == 15) begin
        // Left OFF and Right ON Turn State
        mem_key <= 1;
        countM = countPlusM;
    end
    else if(countM == 20) begin
        // waits til done with Right blinker to return to IDLE
        mem_state <= mem_idle;
        countM = 0; // restart
    end
    else
        countM = countPlusM;
end

// Output Logic
always @ (state) begin

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