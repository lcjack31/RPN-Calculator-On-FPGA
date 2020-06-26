`include "CPU.vh"
`include "RPNCAL.vh"   /* All defined Constant is Stored in the file "RPNCAL.vh", 
defined names are each operation names which is easy to use in the memory and easy to read, 
rather than using numbers directly*/


/*All functions are defined at the bottom with some NEW ideas*/

module AsyncROM(

	input [7:0] addr,

	output reg [34:0] data );


	always @(addr)
		case (addr)

			//Wait
			`WAIT + 1	: data = atc(3, `PUSH);	//Check the status of PUSH BOTTON[3], if 1, JUMP to PUSH IP, then clean the FLAG REG												
			`WAIT + 2	: data = atc(2, `POP);	//Check the status of POP BOTTON[2], if 1, JUMP to POP IP, then clean the FLAG REG									
			`WAIT + 3	: data = atc(1, `ADD);	//CHeck the status of ADD BOTTON[1],if 1, JUMP to ADD IP, then clean the FLAG REG												
			`WAIT + 4	: data = atc(0, `MULT);	//CHeck the status of MULT BOTTON[0],if 1, JUMP to MULT IP, then clean the FLAG REG												
			`WAIT + 5	: data = jmp(`WAIT);		// Nothing pressed, KEEP WAITING!!!!!!!												

			//Push   
			
			/*NOTE: if there is no element in the Stack, Set the STKSIZE to 0000_0001, when PUSHING a number in,
			rather than LEFT SHIFT, because when STKSIZE is zero, no matter how to SHiFT bits, it is always 0*/
			
			`PUSH			: data = mov(`STACK2,`STACK3);
			`PUSH + 1	: data = mov(`STACK1,`STACK2);
			`PUSH + 2	: data = mov(`STACK0,`STACK1);		//move stack up
			`PUSH + 3	: data = mov(`DINP,`STACK0);			//move the new input DINP to stack0
			`PUSH + 4  	: data = mov(`STACK0,`DOUT);			//display the value of stack0
			`PUSH + 5	: data = EQUAL_jmp(`STKSIZE, 8'd8, `OVERFLOW);		// Stack size equal to 8=0000_1000 --> overflow
			`PUSH + 6	: data = clr_bit(`GOUT, 4);
			`PUSH + 7	: data = clr_bit(`GOUT, 5);			//turing off overflow leds
			`PUSH + 8	: data = EQUAL_jmp(`STKSIZE, 8'd0, `PUSH+11);	//check the size of stack, if equal to 0 then set it to 1
			`PUSH + 9	: data = left_shift(`STKSIZE,`STKSIZE);	//Stacksize+1
			`PUSH + 10	: data = jmp(`PUSH+12);
			`PUSH + 11	: data = set_bit(`STKSIZE,0);		//set the stack size to 1	
			`PUSH + 12  : data = mov(`STKSIZE,`GOUT);		//send the contents of register 4 to the led pins
			`PUSH + 13	: data = set_bit(`GOUT,7);		//turn on the 7-seg dislplays
			`PUSH + 14	: data = jmp(`WAIT);				//back to wait

			//Overflow
			`OVERFLOW		: data = clr_bit(`GOUT, 5);	//turn off the led indicating the arthmetic overflow
			`OVERFLOW + 1	: data = set_bit(`GOUT, 4);	//turn on the led indicating stack overflow
			`OVERFLOW + 2	: data = jmp(`WAIT);				//jump back to wait

			//Pop
			`POP			: data = EQUAL_jmp(`STKSIZE, 8'd0, `WAIT);	//jump to wait state when the size of stack is 0
			`POP + 1		: data = clr_bit(`GOUT, 4);
			`POP + 2		: data = clr_bit(`GOUT, 5);		//turn off the overflow leds
			`POP + 3		: data = mov(`STACK1,`STACK0);								
			`POP + 4		: data = mov(`STACK2,`STACK1);
			`POP + 5		: data = mov(`STACK3,`STACK2);	//move down the stack
			`POP + 6		: data = right_shift(`STKSIZE,`STKSIZE);	//shift the register 4 to the right
			`POP + 7		: data = mov(`STKSIZE,`GOUT);					//Display Stack size on LEDs
			`POP + 8		: data = clr_bit(`GOUT, 7);					//turn off the 7-seg displays
			`POP + 10	: data = EQUAL_jmp(`STKSIZE, 8'd0, `WAIT);	//jump to wait for stack size equal to 0
			`POP + 11	: data = mov(`STACK0,`DOUT);					//display stack0 on the display
			`POP + 12	: data = set_bit(`GOUT,7);						//enable the 7-seg display
			`POP + 13	: data = jmp(`WAIT);								//jump back to wait

			//Addition
			`ADD			: data = clr_bit(`GOUT, 4);						//turn off the led of arthmetic overflow
			`ADD + 1		: data = EQUAL_jmp(`STKSIZE, 8'd0, `WAIT);	//jump to wait if stack size is 0
			`ADD + 2		: data = EQUAL_jmp(`STKSIZE, 8'd1, `WAIT);	//jump to wait if stack size if 1
			`ADD + 3		: data = arithmetic(`SAD,`STACK0,`STACK1);	//process calculation stack0=stack0+stack1
			`ADD + 4		: data = mov(`STACK0,`DOUT);						//display stack0 on the 7-seg display
			`ADD + 5		: data = set_bit(`GOUT,7);							//Set Dval=1,turn on the 7-seg display
			`ADD + 6		: data = atc(4,`ADD+8);													
			`ADD + 7		: data = jmp(`ADD+9);
			`ADD + 8		: data = set_bit(`GOUT,5);		//turn on arithmetic overflow led
			`ADD + 9		: data = clr_bit(`GOUT,4);		//turn off stack overflow led, FLAG Register OVERFLOW is connected to GOUT[8] 
			`ADD + 10	: data = mov(`STACK2,`STACK1);
			`ADD + 11	: data = mov(`STACK3,`STACK2);						//move the stack down
			`ADD + 12	: data = right_shift(`STKSIZE,`STKSIZE);			//shift STKSIZE to the right
			`ADD + 17	: data = mov(`STKSIZE,`GOUT);	//display stack size on LEDs
			`ADD + 18	: data = set_bit(`GOUT, 7);  	//turn out the 7 segment display
			`ADD + 19	: data = jmp(`WAIT);				//jump back to WAIT, wait for further input

			//Multiplication
			`MULT			: data = EQUAL_jmp(`STKSIZE, 8'd0, `WAIT);		//jump to WAIT if the stack is empty
			`MULT + 1	: data = clr_bit(`GOUT, 5);			//turn off the arthmetic overflow led
			`MULT + 2	: data = {`JMP, `SLT,`REG, `STKSIZE, `NUM, 8'd2, `MULT+4};		//if there are one or zero element jump to mult+4
			`MULT + 3	: data = jmp(`NORM);						//jump to NORM if there are two or more elements
			`MULT + 4	: data = clr_bit(`STACK0, 7);											
			`MULT + 5	: data = clr_bit(`STACK0, 6);
			`MULT + 6	: data = clr_bit(`STACK0, 5);
			`MULT + 7	: data = clr_bit(`STACK0, 4);
			`MULT + 8	: data = clr_bit(`STACK0, 3);
			`MULT + 9	: data = clr_bit(`STACK0, 2);
			`MULT + 10	: data = clr_bit(`STACK0, 1);
			`MULT + 11	: data = clr_bit(`STACK0, 0);	//set stack0 to 0, or use: set(8'b0,`STACK0);
			`MULT + 12	: data = mov(`STACK0,`DOUT);	//dislplay stack0
			`MULT + 13	: data = set_bit(`GOUT,7); 	//enable the display
			`MULT + 14	: data = jmp(`WAIT);

			//Normal
			`NORM			: data = arithmetic(`SMT,`STACK0,`STACK1);	//stack0 = stack0 * stack1
			`NORM + 1	: data = atc(4,`NORM+3);		//if overflow then turn on the led(jump to NORM+3)
			`NORM + 2	: data = jmp(`NORM+4);			//if Stack is not overflow then turn off the overflow LED
			`NORM + 3	: data = set_bit(`GOUT,5);		//turn on arithmetic overflow led
			`NORM + 4	: data = clr_bit(`GOUT,4);		//turn off the stack overflow led
			`NORM + 5	: data = mov(`STACK0,`DOUT);	//Display the content of Stack[0] 
			`NORM + 6	: data = mov(`STACK2,`STACK1);
			`NORM + 7	: data = mov(`STACK3,`STACK2); //move the stack down
			`NORM + 8	: data = right_shift(`STKSIZE,`STKSIZE);		//shift STKSIZE to the right(STKSIZE-1)
			`NORM + 9	: data = mov(`STKSIZE,`GOUT);
			`NORM + 10	: data = set_bit(`GOUT,7);
			`NORM + 11	: data = jmp(`WAIT);

			default: data = 35'b0; // NOP */

		endcase
	
	function [34:0] set;
		input [7:0] reg_num;
		input [7:0] value;
		set = {`MOV, `PUR, `NUM, value, `REG, reg_num, `N8};
	endfunction
	
	function [34:0] mov;
		input [7:0] src_reg;
		input [7:0] dst_reg;
		mov = {`MOV, `PUR, `REG, src_reg, `REG, dst_reg, `N8};
	endfunction
	
	function [34:0] jmp;
		input [7:0] addr;
		jmp = {`JMP, `UNC, `N10, `N10, addr};
	endfunction
	
	function [34:0] EQUAL_jmp; //JMP if two numbers are equal
		input [7:0] reg_jmp;
		input [7:0] num;
		input [7:0] addr;
		EQUAL_jmp = {`JMP, `EQ, `REG, reg_jmp, `NUM, num, addr};
	endfunction
	
	function [34:0] atc;
		input [2:0] bit;
		input [7:0] addr;
		atc = {`ATC, bit, `N10, `N10, addr};
	endfunction
	
	function [34:0] acc;
		input [2:0] op;
		input [7:0] reg_num;
		input [7:0] value;
		acc = {`ACC, op, `REG, reg_num, `NUM, value, `N8};
	endfunction
	
	function [34:0]set_bit;
		input [7:0] reg_num;
		input [2:0] bit;
		set_bit={`ACC,`OR,`REG,reg_num,`NUM,8'b1<<bit,`N8};
	endfunction

	function [34:0]clr_bit;
		input [7:0] reg_num;
		input [2:0] bit;
		clr_bit={`ACC,`AND,`REG,reg_num,`NUM, ~(8'b1<<bit),`N8};
	endfunction
	
	function [34:0]left_shift; 
		input [7:0] src_reg;
		input [7:0] dst_reg;
		left_shift={`MOV, `SHL, `REG, src_reg, `REG, dst_reg, `N8};
	endfunction
	
	
	function [34:0]right_shift;
		input [7:0] src_reg;
		input [7:0] dst_reg;
		right_shift={`MOV, `SHR, `REG, src_reg, `REG, dst_reg, `N8};
	endfunction
	
	function [34:0] arithmetic; //The funtion doing addtion and multiplication, the first input choose the operation 
		input [2:0] op;
		input [7:0] reg_num;
		input [7:0] val;
		arithmetic = {`ACC, op, `REG, reg_num, `REG, val, `N8};
	endfunction
	
endmodule

