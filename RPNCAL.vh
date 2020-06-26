// Operation values are defined randomly, but one IP number will never have two more instructions
`define WAIT 8'd0
`define PUSH 8'd10
`define OVERFLOW 8'd30
`define POP 8'd40
`define ADD 8'd80
`define MULT 8'd120
`define NORM 8'd160


//Stack Stack[3:0] stores the input number
`define STACK0 8'd0 //register[0]
`define STACK1 8'd1 //register[1]
`define STACK2 8'd2 //register[2]
`define STACK3 8'd3 //register[3]
`define STKSIZE 8'd4 //register[4] stores the number of elements