// Stump ALU
// Implement your Stump ALU here
//
// Created by Paul W Nutter, Feb 2015
//
// ** Update this header **
//

`include "Stump/Stump_definitions.v"

// 'include' definitions of function codes etc.
// e.g. can use "`ADD" instead of "'h0" to aid readability
// Substitute your own definitions if you prefer by
// modifying Stump_definitions.v

/*----------------------------------------------------------------------------*/

module Stump_ALU (input  wire [15:0] operand_A,		// First operand
                                 input  wire [15:0] operand_B,		// Second operand
		                          input  wire [ 2:0] func,		// Function specifier
		                          input  wire        c_in,		// Carry input
		                          input  wire        csh,  		// Carry from shifter
		                          output reg  [15:0] result,		// ALU output
		                          output reg  [ 3:0] flags_out);	// Flags {N, Z, V, C}


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Declarations of any internal signals and buses used                        */


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Verilog code                                                               */



/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

/*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/

