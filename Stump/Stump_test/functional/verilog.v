// Stump Testign Module
//
// Updated by Paul W Nutter, Feb 2015
// Original design J D Garside
//
// ** Update this header **

`define CLOCK_PERIOD  10

module Stump_test();

reg         clk;       // System clock
reg         rst;       // Master reset
reg  [15:0] data_in;   // Data from memory
wire [15:0] data_out;  // Data to memory
wire [15:0] address;   // Address
wire        mem_wen;   // Memory write enable
wire        mem_ren;   // Memory read enable


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate module under test                                              */

Stump Processor (.clk(clk),
                 .rst(rst),
                 .data_in(data_in),
                 .data_out(data_out),
                 .address(address),
                 .mem_wen(mem_wen),
                 .mem_ren(mem_ren),
                 // Debug/observation signals
                 .fetch(),		// Leave output disconnected
                 .srcC(3'h7),		// Choose R7 (PC)
                 .regC(),
                 .cc() );

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Define Memory                                                              */

reg [15:0] memory [0:1023];		// Small memory to hold test code

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Test design                                                                */

initial begin

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Load program held in memory map                                            */
/* Uncomment test programs you would like to use, comment the others          */
      
      $readmemh("$COMP22111/Stump_src/first.hex", memory);
      $display("Running first");
//      $readmemh("$COMP22111/Stump_src/test1.hex", memory);
//      $display("Running test 1");
//      $readmemh("$COMP22111/Stump_src/test2.hex", memory);
//      $display("Running test 2");
//      $readmemh("$COMP22111/Stump_src/test3.hex", memory);
//      $display("Running test 3");
//      $readmemh("$COMP22111/Stump_src/test4.hex", memory);
//      $display("Running test 4");
	end

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Memory access                                                              */

always @ (negedge clk)			                // Commit writes in mid cycle
  if (mem_wen) memory[address] <= data_out;

always @ (mem_ren, address, negedge clk)        // clk to pick up writes
  #(`CLOCK_PERIOD/4)                            // Some delay before data 
  if (mem_ren) data_in <= memory[address];      // (dis)appears
  else         data_in <= 16'hxxxx;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Clock for testing                                                          */

initial clk = 0;		                         
always #(`CLOCK_PERIOD/2) clk = !clk;

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

always @ (posedge clk)
  if (mem_wen) $display("%t Address %x  := %x", $time, address, data_out);

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

always @ (posedge clk)		// Stop simulation by writing to address FFFF
  if (mem_wen && (address == 16'hFFFF)) #(10*`CLOCK_PERIOD) $stop;

initial
begin
rst = 0;
#`CLOCK_PERIOD
rst = 1;
#`CLOCK_PERIOD
rst = 0;

#(200*`CLOCK_PERIOD)		// Time limit in simulation befor complete
                            
$stop;
end 

/*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/
