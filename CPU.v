`include "CPU.vh"

// CPU Module

module CPU(input clk,
	input [7:0]Din, 
	input Sample, 
	input [2:0] Btns,
	input Reset,
	input Turbo,
	output [7:0] Dout,
	output  Dval,
	output [5:0] GPO,
	output [3:0] Debug,
	output reg	 [7:0] IP
	// Fill this in
);
	// Registers
	reg [7:0] Reg [0:31];
	
	integer j,k;

	// Use these to Read the Special Registers
	wire [7:0] Rgout = Reg[29];
	wire [7:0] Rdout = Reg[30];
	wire [7:0] Rflag = Reg[31];
	
	
	
	
	assign Dval = Rgout[`DVAL];
// Debugging assignments – you can change these to suit yourself
	assign Debug[3] = Rflag[`SHFT]; //LEDR[9]
	assign Debug[2] = Rflag[`OFLW]; //LEDR[8]
	assign Debug[1] = Rflag[`SMPL]; //LEDR[7]
	assign Debug[0] = go;

	
	wire turbo_safe;
	Synchroniser tbo(clk, Turbo, turbo_safe);

	// Use these to Write to the Flags and Din Registers
	`define RFLAG Reg[31]
	`define RDINP Reg[28]

	// Connect certain registers to the external world
	assign Dout = Rdout;
	assign GPO = Rgout[5:0];///////////////////!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	
	// Clock circuitry (250 ms cycle)
	reg [23:0] cnt;
	localparam CntMax = 12500000;
	
	// Synchronise CPU operations to when cnt == 0
	wire go = !Reset && ((cnt == 0)||turbo_safe);
	//if turbo is on, CPU runs at full speed 50MHz, otherwise 4Hz.
	
	
	wire [34:0] instruction;
	AsyncROM Pmem(IP , instruction);
	
	// instruction Cycle
	wire [3:0] cmd_grp = instruction[34:31];
	wire [2:0] cmd = instruction[30:28];
	wire [1:0] arg1_typ = instruction[27:26];
	wire [7:0] arg1 = instruction[25:18];
	wire [1:0] arg2_typ = instruction[17:16];
	wire [7:0] arg2 = instruction[15:8];
	wire [7:0] addr = instruction[7:0];
	
	// Instruction Cycle - Instruction Cycle Block
	reg [7:0] cnum;
	reg [15:0] word;
	reg signed [15:0] s_word;
	reg [7:0] cloc;
	reg [0:0] cond;
	
	
	always @(posedge clk) begin
// Process Instruction
		cnt <= (cnt == CntMax) ? 0 : cnt + 1;
		if (go) begin
			IP <= IP + 8'b1;
			case (cmd_grp)
				`MOV: begin
					cnum = get_number(arg1_typ, arg1);
					case (cmd)
						`SHL: begin
						`RFLAG[`SHFT] <= cnum[7];
						cnum = {cnum[6:0], 1'b0};
						end
						`SHR: begin
						`RFLAG[`SHFT] <= cnum[0];
						cnum = {1'b0, cnum[7:1]};
						end
					endcase
					Reg[ get_location(arg2_typ, arg2) ] <= cnum;
				end

//---------------------------------------------------------------------------------
				`ACC:begin
					cnum = get_number(arg2_typ, arg2);
					cloc = get_location(arg1_typ, arg1);
					case (cmd)
						`UAD: word = Reg[ cloc ] + cnum;
						`SAD: s_word = $signed( Reg[ cloc ] ) + $signed( cnum );
						`UMT: word = Reg[ cloc ] * cnum; 
						`SMT: s_word = $signed(Reg[cloc]) * $signed(cnum);
						`AND: cnum = Reg[ cloc ] & cnum;
						`OR:  cnum = Reg[ cloc ] | cnum;
						`XOR: cnum = Reg[ cloc ] ^ cnum;
					endcase
					if (cmd[2] == 0)
						if (cmd[0] == 0) begin // Unsigned addition or multiplication
							cnum = word[7:0];
							`RFLAG[`OFLW] <= (word > 255);
						end
						else begin // Signed addition or multiplication
							cnum = s_word[7:0];
							`RFLAG[`OFLW] <= (s_word > 127 || s_word < -128);
						end
					Reg[ cloc ] <=cnum; // Fill this in
					end
					`JMP : begin
						case (cmd)
							`UNC: cond = 1;
							`EQ: cond = ( get_number(arg1_typ, arg1) == get_number(arg2_typ, arg2) );
							`ULT: cond =( get_number(arg1_typ, arg1) < get_number(arg2_typ, arg2)) ;
							`SLT: cond = ( $signed(get_number(arg1_typ, arg1)) < $signed(get_number(arg2_typ, arg2)));
							`ULE: cond = ( get_number(arg1_typ, arg1) == get_number(arg2_typ, arg2)||(get_number(arg1_typ, arg1) < get_number(arg2_typ, arg2)));
							`SLE: cond = ( $signed(get_number(arg1_typ, arg1)) < $signed(get_number(arg2_typ, arg2)))||
							( $signed(get_number(arg1_typ, arg1)) == $signed(get_number(arg2_typ, arg2)));
							default: cond = 0;
						endcase
						if (cond) IP <= addr;
					end
					`ATC: begin
						if (`RFLAG[cmd]) IP <= addr;
						`RFLAG[cmd] <= 0;
						end

//--------------------------------------------------------------------------------------
			endcase
		end
// Process Reset
		if (Reset) begin
			IP <= 8'b0;
			`RFLAG <= 0;
			for (k=0; k<=31; k=k+1) Reg[k] <= 8'd0;
		end
		else begin
		for(j=0; j<=3; j=j+1) 
						if(pb_activated[j]) `RFLAG[j] <= 1;
							
						if(pb_activated[3]) `RDINP <= din_safe;  //Sample Button pb[3]
		end  
	
	
	
	
	
	end
	

//=====================================================================
	function [7:0] get_number;
		input [1:0] arg_type;
		input [7:0] arg;
		begin
			case (arg_type)
				`REG: get_number = Reg[arg[5:0]];
				`IND: get_number = Reg[Reg[arg[5:0]][5:0]];
				default: get_number = arg;
			endcase
		end
	endfunction
	
	function [5:0] get_location;
		input [1:0] arg_type;
		input [7:0] arg;
		begin
			case (arg_type)
				`REG: get_location = arg[5:0];
				`IND: get_location = Reg[arg[5:0]][5:0];
				default: get_location = 0;
			endcase
		end
	endfunction
	wire [7:0] din_safe;
	Synchroniser sync0(clk, Din[7], din_safe[7]);
	Synchroniser sync1(clk, Din[6], din_safe[6]);
	Synchroniser sync2(clk, Din[5], din_safe[5]);
	Synchroniser sync3(clk, Din[4], din_safe[4]);
	Synchroniser sync4(clk, Din[3], din_safe[3]);
	Synchroniser sync5(clk, Din[2], din_safe[2]);
	Synchroniser sync6(clk, Din[1], din_safe[1]);
	Synchroniser sync7(clk, Din[0], din_safe[0]);
		
		
	wire [3:0] pb_safe;
	Synchroniser sync8(clk, Sample, pb_safe[3]);
	Synchroniser sync9(clk, Btns[2], pb_safe[2]);
	Synchroniser sync10(clk, Btns[1], pb_safe[1]);
	Synchroniser sync11(clk, Btns[0], pb_safe[0]);
	
	
	genvar i;
	wire [3:0] pb_activated;
	generate
		for(i=0; i<=3; i=i+1) begin :pb
			DetectFallingEdge dfe(clk, pb_safe[i], pb_activated[i]);
		end
	endgenerate
	
	
endmodule 






