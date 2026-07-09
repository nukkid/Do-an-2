`timescale 1ns/1ns
module fir_filter (
    input  wire              clk,
    input  wire              reset,
    input  wire signed [7:0] din,   // Q1.7
    output reg  signed [15:0] dout  // Q1.15
);

    parameter N_TAPS = 29;

    // =========================================================
    // FIR coefficients Q1.15 (fc = 3 Hz, COPY từ MATLAB)
    // =========================================================
    reg signed [15:0] h [0:N_TAPS-1];
    initial begin
        h[0]  = 16'h0085; h[1]  = 16'h009F; h[2]  = 16'h00E3; h[3]  = 16'h0152;
        h[4]  = 16'h01EB; h[5]  = 16'h02A8; h[6]  = 16'h0382; h[7]  = 16'h046E;
        h[8]  = 16'h0560; h[9]  = 16'h064A; h[10] = 16'h0721; h[11] = 16'h07D6;
        h[12] = 16'h0861; h[13] = 16'h08B7; h[14] = 16'h08D4; h[15] = 16'h08B7;
        h[16] = 16'h0861; h[17] = 16'h07D6; h[18] = 16'h0721; h[19] = 16'h064A;
        h[20] = 16'h0560; h[21] = 16'h046E; h[22] = 16'h0382; h[23] = 16'h02A8;
        h[24] = 16'h01EB; h[25] = 16'h0152; h[26] = 16'h00E3; h[27] = 16'h009F;
        h[28] = 16'h0085;
    end

    // =========================================================
    // Shift register (Q1.7)
    // =========================================================
    reg signed [7:0] sr [0:N_TAPS-1];
    integer i;

    // =========================================================
    // Multiply-Accumulate + Saturation
    // =========================================================
    reg signed [31:0] acc;
    reg signed [31:0] shifted;
    reg signed [15:0] tmp;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < N_TAPS; i = i + 1)
                sr[i] <= 0;
            dout <= 0;
        end else begin
            // shift register
            for (i = N_TAPS-1; i > 0; i = i - 1)
                sr[i] <= sr[i-1];
            sr[0] <= din;

            // multiply-accumulate
            acc = 0;
            for (i = 0; i < N_TAPS; i = i + 1)
                acc = acc + sr[i] * h[i]; // giữ đúng thứ tự hệ số

            // scale Q1.7 * Q1.15 = Q2.22 → Q1.15
            shifted = acc >>> 7;

            // saturation
            if (shifted > 32767)
                dout <= 16'sh7FFF;
            else if (shifted < -32768)
                dout <= -16'sh8000;
            else begin
                tmp = shifted[15:0];
                dout <= tmp;
            end
        end
    end

endmodule
