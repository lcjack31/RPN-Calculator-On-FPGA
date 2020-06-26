// Add more auxillary modules here...



// Display a Hexadecimal Digit, a Negative Sign, or a Blank, on a 7-segment Display
module SSeg(input [3:0] bin, input neg, input enable, output reg [6:0] segs);
	always @(*)
		if (enable) begin
			if (neg) segs = 7'b011_1111;
			else begin
				case (bin)
					0: segs = 7'b100_0000;
					1: segs = 7'b111_1001;
					2: segs = 7'b010_0100;
					3: segs = 7'b011_0000;
					4: segs = 7'b001_1001;
					5: segs = 7'b001_0010; 
					6: segs = 7'b000_0010;
					7: segs = 7'b111_1000;
					8: segs = 7'b000_0000;
					9: segs = 7'b001_1000;
					10: segs = 7'b000_1000;
					11: segs = 7'b000_0011;
					12: segs = 7'b100_0110;
					13: segs = 7'b010_0001;
					14: segs = 7'b000_0110;
					15: segs = 7'b000_1110;
				endcase
			end
		end
		else segs = 7'b111_1111;
endmodule


//-----------------------------------------------------------------------//


module Debounce(input clk, input signal_in, output signal_out);
	localparam MAX_Count=1500000, A=0,B=1;
//content//
	wire syncd_signal;
	Synchroniser syncin(.clk(clk),.d_in(signal_in),.q_out(syncd_signal));
	reg [20:0] count=0;
	reg [20:0] next_count;
	reg state=0;
	reg next_state;
	always@(posedge clk)begin
		state<=next_state;
		count<=next_count;
	end
	always@(*)begin
		next_state = state;// can be overidden later, just give a next state a value
		if(signal_in==state) next_count=0;
		else begin
			next_count=count+1;
			if(count==MAX_Count)begin
				next_count=0;
				next_state=syncd_signal;
			end
		end
	end
	assign signal_out=state;	
endmodule


//----------------------------------------------//


module Disp2cNum(input signed [7:0] x,input enable, output [6:0] Disp3, output [6:0] Disp2, output [6:0] Disp1, output [6:0] Disp0);

	wire neg=(x<0);
	wire [7:0]ux=neg?-x:x;
	wire [7:0] xo0,xo1,xo2,xo3;
	wire eno0,eno1,eno2,eno3;
// DispDec instances
	DispDec H0(.x(ux),.neg(neg),.enable(enable),.xo(xo0),.eno(eno0),.segs(Disp0));
	DispDec H1(.x(xo0),.neg(neg),.enable(eno0),.xo(xo1),.eno(eno1),.segs(Disp1));
	DispDec H2(.x(xo1),.neg(neg),.enable(eno1),.xo(xo2),.eno(eno2),.segs(Disp2));
	DispDec H3(.x(xo2),.neg(neg),.enable(eno2),.xo(xo3),.eno(eno3),.segs(Disp3));

endmodule


//----------------------------------------------//
//Display a decimal number
//Each display should do: 1. Display a number? 2. Display a negative sign? 3. on or off 4. should the next display on?

module DispDec(input [7:0]x, input neg, enable, output reg [7:0]xo, output reg eno, output [6:0]segs);
	wire [3:0]digit;
	wire n=(neg && (x==0)); //whether the current diplay should display a negtive sign
	assign digit=x%10; //the current display bit
	SSeg converter(.bin(digit),.neg(n),.enable(enable),.segs(segs));
	always@(x)begin 
		xo = x/10; // the number passed to the next SSEG display
		if(enable==0)
			eno=0; // If the current display has nothing to do, then shut down the next ones.
		else
			if(neg==0)
				if(xo==0)
					eno=0; // if the current diplay is used and there is no number passed to the next display
				else eno=1; // the next display should be on if the current display is displaying a non-negative number
				//also a number passsed to the next display
			else eno=!( n && (xo==0)); // for a negative input,the next diplay should be on when c
	end
	
endmodule


//----------------------------------------------//


module DispHex(input [7:0] IP_num, output [6:0] Disp5, output [6:0] Disp4);
	reg neg=0;
	reg enable=1;
	wire [6:0]LB; //Left Hexadecimal Bit
	wire [6:0]RB; //Right Hexadecimal Bit
	SSeg Seg_LSB(.bin(IP_num[3:0]),.neg(neg),.enable(enable),.segs(LB));
	SSeg Seg_RSB(.bin(IP_num[7:4]),.neg(neg),.enable(enable),.segs(RB));
	assign Disp5 = RB;
	assign Disp4 = LB;
endmodule

//----------------------------------------------//


//----------------------------------------------//

module Synchroniser(input clk,d_in, output reg q_out);
	reg q1;
	always@(posedge clk)
		q1<=d_in;
	always@(posedge clk)
		q_out<=q1;
endmodule 

//------------------------------------------------------------------//

module DetectFallingEdge( input clk,btn_sync,output reg OUT);
   reg previous_btn_sync;
	always @(posedge clk)begin
      if ((previous_btn_sync==1)&&(btn_sync==0)) OUT<=1;
		else OUT<=0;
	   previous_btn_sync <= btn_sync;
	end		  
 endmodule
 
