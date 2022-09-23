// Stump control decode module.
// Behavioural Verilog module describing combinatorial logic.
//
// P W Nutter
//
// April 2019
//
// Update


`include "Stump/Stump_definitions.v"

/*----------------------------------------------------------------------------*/

module Stump_control_decode (input  wire [1:0]  state,      // current state of FSM
		             input  wire [3:0]  cc,         // current status of cc
              	             input  wire [15:0] ir,	    // current instruction
                             output reg         fetch,
                             output reg         execute,    // current state
                             output reg         memory,
 		             output reg         ext_op,		      
 		             output reg         reg_write,  // register write enable
		             output reg  [2:0]  dest,	    // destination register		      
		             output reg  [2:0]  srcA,	    // Source register operand A
		             output reg  [2:0]  srcB,	    // Source register operand B
		             output reg  [1:0]  shift_op,
              	             output reg         opB_mux_sel,// operandB mux select
		             output reg  [2:0]  alu_func,   // function derived from ir
              	             output reg         cc_en,      // cc register enable
                             output reg         mem_ren,    // Memory read enable		      
                             output reg         mem_wen	    // Memory write enable
                      );

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Declarations of any internal signals and buses used                        */




/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/



/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Control decoder                                                             */







/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Condition evaluation - an example 'function'                               */

function Testbranch; 		// Returns '1' if branch taken, '0' otherwise
input [3:0] condition;		// Condition bits from instruction
input [3:0] CC;				// Current condition code register
reg N, Z, V, C;

begin
  {N,Z,V,C} = CC;			// Break condition code register into flags
  case (condition)
     0 : Testbranch =   1;	// Always (true)
     1 : Testbranch =   0;	// Never (false)
     2 : Testbranch = ~(C|Z);
     3 : Testbranch =   C|Z;
     4 : Testbranch =  ~C;
     5 : Testbranch =   C;
     6 : Testbranch =  ~Z;
     7 : Testbranch =   Z;
     8 : Testbranch =  ~V;
     9 : Testbranch =   V;
    10 : Testbranch =  ~N;
    11 : Testbranch =   N;
    12 : Testbranch =   V~^N;
    13 : Testbranch =   V^N;
    14 : Testbranch = ~((V^N)|Z) ;
    15 : Testbranch =  ((V^N)|Z) ;
  endcase
end
endfunction

/*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/
