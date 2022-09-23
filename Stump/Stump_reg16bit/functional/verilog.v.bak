// 16-bit register used in Stump design
//
// Original design J Pepper
//

module Stump_reg16bit  (input wire CLK,
			            input wire CE,
			            input wire [15:0] D,
			            output reg [15:0] Q);

// Simple 16-bit register. On rising edge of clock the value of Q is updated
// to the value of D

always @(posedge CLK)       // sequential design
if (CE == 1)
  Q <= D;                   // will reuslt in a register being implemented to
                            // hold the state of Q    
endmodule
