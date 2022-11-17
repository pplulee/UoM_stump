// Stump Datapath
// Implement your Stump datapath for COMP22111, 2022, no control block
//

module Stump_datapath (input  wire        clk, 			// System clock
                       input  wire        rst,			// Master reset
                       input  wire [15:0] data_in,		// Data from memory
                       input  wire        fetch,		// State from control	
                       input  wire        execute,		// State from control
                       input  wire        memory,		// State from control
                       input  wire        ext_op,		// sign extender control
                       input  wire        opB_mux_sel,	        // src_B mux control
                       input  wire [ 1:0] shift_op,		// shift operation
                       input  wire [ 2:0] alu_func,		// ALU function 
                       input  wire        cc_en,		// Status register enable
                       input  wire        reg_write,	        // Register bank write
                       input  wire [ 2:0] dest,			// Register bank dest reg
                       input  wire [ 2:0] srcA,			// Source A from reg bank
                       input  wire [ 2:0] srcB,			// Source B from reg bank
                       input  wire [ 2:0] srcC,			// Used by Perentie
                       output reg [15:0] ir,			// IR contents for control
                       output wire [15:0] data_out,		// Data to memory
                       output wire [15:0] address,		// Address
                       output wire [15:0] regC,			// Used by Perentie
                       output reg [ 3:0] cc);	 		// Flags


wire [15:0] reg_data;
wire [15:0] regA, regB;
wire [15:0] alu_out;
wire [15:0] operand_A;
wire [15:0] operand_B;
wire [3:0] alu_flags;
reg  [15:0] addr_reg;

Stump_registers registers (.clk(clk),
                           .rst(rst),
                           .write_en(reg_write),
                           .write_addr(dest),
                           .write_data(reg_data),
                           .read_addr_A(srcA), 
                           .read_data_A(regA),
                           .read_addr_B(srcB), 
                           .read_data_B(regB),
                           .read_addr_C(srcC), 		// Debug port address 
                           .read_data_C(regC));		// Debug port data    


Stump_shifter shifter(.shift_op(shift_op), .operand_A(regA), .c_in(cc[0]), .shift_out(operand_A), .c_out(csh));
Stump_ALU alu(.operand_A(operand_A), .operand_B(operand_B), .result(alu_out), .flags_out(alu_flags), .func(alu_func), .csh(csh), .c_in(cc[0]));


always @(posedge clk) if(fetch) ir <= data_in;
always @(posedge clk) if(cc_en) cc <= alu_flags;
always @(posedge clk) if(execute) addr_reg <=  alu_out;

assign reg_data = memory ? data_in : alu_out;
assign operand_B = fetch ? 1 : (opB_mux_sel && ext_op) ? {{8{ir[7]}}, ir[7:0]} : opB_mux_sel ? {{11{ir[4]}}, ir[4:0]} : regB;
assign data_out = regA;
assign address = memory ? addr_reg : regA;


endmodule

/*============================================================================*/
