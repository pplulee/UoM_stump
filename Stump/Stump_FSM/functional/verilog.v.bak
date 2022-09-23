// Stump FSM
// 
// Three state FSM for the Stump processor. No signals are set apart from the current
// state.
// Reset acts asynchronously.
//
// Created by Paul W Nutter
//
// April 2019
//

`include "Stump/Stump_definitions.v"
// 'include' definitions of function codes etc.

module Stump_FSM (input  wire	     clk,	    // System clock
                  input  wire	     rst,	    // Master reset
                  input  wire [15:0] ir,            // Instruction Register
                  output reg  [ 1:0] state);	    // Current state of the FSM


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* FSM                                                                    */

always @ (posedge clk, posedge rst)
  if(rst)						   // asynchronous reset
     state <= `FETCH;                                      // reset to Fetch state
  else
    case(state)					           // next state depends on current state
      `FETCH:	state <= `EXECUTE;
      `EXECUTE: if(ir[15:13] == `LDST)  state <= `MEMORY;  // LDST instruction
                else                    state <= `FETCH;   // not LDST
      `MEMORY:  state <= `FETCH;
      default:  state <= 3'hx;                             // testing purposes
    endcase


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/


/*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/
