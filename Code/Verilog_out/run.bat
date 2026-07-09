iverilog -o fir_tb.vvp fir_tb.v fir_filter.v    
vvp fir_tb.vvp
gtkwave fir_wave.vcd
