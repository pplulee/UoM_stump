// Stump Processor
//
// Created by Paul W Nutter, April 2019
//
// Update

`include "Stump/Stump_definitions.v"
// 'include' definitions of function codes etc.

/*----------------------------------------------------------------------------*/

module Stump (input  wire        clk,		// System clock
              input  wire        rst,		// Master reset
              input  wire [15:0] data_in,	// Data from memory
              output wire [15:0] data_out,	// Data to memory
              output wire [15:0] address,	// Address
              output wire        mem_wen,	// Memory write enable
              output wire        mem_ren,	// Memory read enable
              // Extra signals for observability
              output wire        fetch,		// CPU in the fetch state
              input  wire [ 2:0] srcC,		// Extra register port select
              output wire [15:0] regC,		// Extra register port data
              output wire [ 3:0] cc);		// Flags

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Declarations of any internal signals and buses used                        */




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate modules here                                                   */







/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/


/*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/
