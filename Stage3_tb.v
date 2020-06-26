`timescale 1ns / 1ps 

module stage3_tb;
	reg clk;
	reg signal_in=0;
	wire signal_out;
	Debounce Db(.clk(clk),.signal_in(signal_in),.signal_out(signal_out));
	
	initial begin
		clk = 0;
		forever begin
		#20
		clk = !clk;  // Generate 50MHz CLOCK
		end
	end
	
	initial begin
		#10000 signal_in=!signal_in;
		#10000 signal_in=!signal_in;
		#10000 signal_in=!signal_in;
		#320000 signal_in=!signal_in;
		#320000 signal_in=!signal_in;
		#320000 signal_in=!signal_in;
		#320000 signal_in=!signal_in;
	end
endmodule 