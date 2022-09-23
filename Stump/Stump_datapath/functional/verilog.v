// Stump Datapath
// Implement your Stump datapath in structural Verilog here, no control block
//
// Created by Paul W Nutter, Feb 2015
//
// ** Update this header **

// 'include' definitions of function codes etc.

`include "Stump/Stump_definitions.v"

// Main module
/*----------------------------------------------------------------------------*/


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
                       output wire [15:0] ir,			// IR contents for control
                       output wire [15:0] data_out,		// Data to memory
                       output wire [15:0] address,		// Address
                       output wire [15:0] regC,			// Used by Perentie
                       output wire [ 3:0] cc);	 		// Flags



/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Declarations of any internal signals and buses used                        */





/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate register bank                                                  */

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

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate other datapath modules here                                    */




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/


/*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/
