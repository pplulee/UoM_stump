//Verilog HDL for "Stump", "Stump_mux16bit_test" "functional"

`include "Stump/Stump_definitions.v"

module Stump_mux16bit_test ( );

reg [15:0] D0, D1;
reg            S;
reg [1:0] testpoint;

wire [15:0] Q;

Stump_mux16bit mux1 (D0, D1, S, Q);

initial
 testpoint = `MEMORY;

initial
 begin
   D0 = 16'hDEAD;
   D1 = 16'hBEEF;
   S = 0;
   #100 S=1;
   #100 $stop();
 end

endmodule
