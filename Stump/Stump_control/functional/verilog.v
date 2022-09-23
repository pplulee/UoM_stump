// Stump control block
//
// P W Nutter
//
// April 2019
//
// Update


`include "Stump/Stump_definitions.v"

/*----------------------------------------------------------------------------*/

module Stump_control(input  wire		rst,
                     input  wire        	clk,
		     input  wire [3:0] 	        cc,	         // current status of cc
              	     input  wire [15:0] 	ir,	         // current instruction
                     output wire                fetch,
                     output wire                execute,	 // current state
                     output wire                memory,
 		     output wire                ext_op,		      
 		     output wire                reg_write,	 // register write enable
		     output wire  [2:0]         dest,		 // destination register		      
		     output wire  [2:0]         srcA,		 // Source register operand A
		     output wire  [2:0]         srcB,		 // Source register operand B
		     output wire  [1:0]         shift_op,
              	     output wire                opB_mux_sel,     // operandB mux select
		     output wire  [2:0]         alu_func,	 // function derived from ir
              	     output wire                cc_en,		 // cc register enable
                     output wire                mem_ren,	 // Memory read enable		      
                     output wire                mem_wen);	 // Memory write enable
                   

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Declarations of any internal signals and buses used                        */




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate modules                                                        */

     
     
     
     
     
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/


/*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/
