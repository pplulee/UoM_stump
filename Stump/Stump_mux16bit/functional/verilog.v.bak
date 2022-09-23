// 16-bit 2-to-1 MUX used in Stump design
//
// Original design J Pepper
//

module Stump_mux16bit  (input wire [15:0] D0,
			            input wire [15:0] D1,
			            input wire        S,
			            output reg [15:0] Q);

// Output Q is assigned one of two 16-bit values, D0 or D1, depending on the
// state of the control signal S. S = 0: Q = D0, S = 1: Q = D1
						
always @ (*)        // Combinatorial logic block
 if(S == 1)         // Simple decode on S
  Q = D1;
 else
  Q = D0;
 
endmodule
