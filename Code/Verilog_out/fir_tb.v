`timescale 1ns/1ns
module fir_tb;

    reg clk = 0;
    always #5 clk = ~clk;   // 10 ns period

    reg reset;
    reg signed [7:0] din;
    wire signed [15:0] dout;

    fir_filter dut (
        .clk(clk),
        .reset(reset),
        .din(din),
        .dout(dout)
    );

    integer fin, fout;
    reg [7:0] byte_val;
    reg signed [7:0] mem[0:200000]; 
    integer i, num_samples, code;

    localparam FIR_TAPS = 29;
    localparam LATENCY  = (FIR_TAPS-1)/2; // = 14

    initial begin
        // dump waveform
        $dumpfile("fir_wave.vcd");
        $dumpvars(0, fir_tb);

        // --- đọc input hex ---
        $display("FIR TB: reading input file...");
        fin = $fopen("ECG_Input.txt", "r");
        if (fin == 0) begin
            $display("Cannot open input file");
            $finish;
        end

        i = 0;
        code = $fscanf(fin, "%h", byte_val);
        while (code == 1) begin
            mem[i] = $signed(byte_val);   // Q1.7 signed
            i = i + 1;
            code = $fscanf(fin, "%h", byte_val);
        end
        $fclose(fin);
        num_samples = i;
        $display("Loaded %0d samples", num_samples);

        fout = $fopen("Output_V.txt", "w");

        // --- reset & prime ---
        reset = 1;
        din   = 0;
        repeat (3) @(posedge clk);
        reset = 0;

        // --- main processing: drive trước, ghi sau LATENCY ---
        for (i = 0; i < num_samples; i = i + 1) begin
            // lái input cho chu kỳ kế tiếp
            din = mem[i];
            @(posedge clk);

            // sau khi qua đủ LATENCY chu kỳ, dout mới hợp lệ để ghi
            if (i >= LATENCY)
                $fwrite(fout, "%04X\n", dout[15:0]); // signed 16-bit hex
        end

        // --- flush pipeline: thêm LATENCY chu kỳ để xả hết ---
        for (i = 0; i < LATENCY; i = i + 1) begin
            din = 0; // hoặc giữ mem[num_samples-1], tuỳ bạn
            @(posedge clk);
            $fwrite(fout, "%04X\n", dout[15:0]);
        end

        $fclose(fout);
        $display("Simulation output written to Output_V.txt");
        $finish;
    end
endmodule
