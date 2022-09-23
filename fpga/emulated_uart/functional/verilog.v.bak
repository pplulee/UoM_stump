//Verilog HDL for "Board_lib", "emulated_uart" "functional"


module emulated_uart(clk, epp_din, epp_dout, epp_astrb, epp_dstrb, epp_rnw, epp_wait, byte_out,
			     byte_in, get, put, rts, rtr, get_ack, put_ack );

// This module implements the bi-directional Digilent emulated parallel port(DEPP)
// and sets up a byte wide input stream and a byte wide output stream
// See Digilent Asynchronous Parallel Interface (DEPP).pdf

input            clk;
input      [7:0] epp_din; // Data input.
output reg [7:0] epp_dout; // Data output.
input            epp_astrb; // Address strobe. Write to the address register. Active low.
input            epp_dstrb; // Data strobe. Write to/read from a data register. Active low.
input            epp_rnw; // Transfer direction control. High=read, host read from peripheral;
			  // Low=write, host writes to pheripheral
output reg       epp_wait; // Handshake signal used to indicate when the peripheral is ready
			   // to accept data or has data available
output reg [7:0] byte_out; // Data output
input      [7:0] byte_in; // Data input
input            get; // High=perihperal wants to read data
input            put; // High=peripheral wants to write data
output reg       get_ack; // Acknowledge data write
output reg       put_ack; // Acknowledge data read


reg [1:0]        addr;
output reg       rts; // UART is ready to send
output reg       rtr; // UART is ready to read
reg [7:0]        byte2pc;

initial
 begin
  epp_wait = 1;		//Wait when set to 1
  rts = 0;		//Ready To Send (1 = ready)
  rtr = 1;		//Ready To Recieve (1 = ready)
  get_ack = 0;
  put_ack = 0;
 end


always @(posedge clk)
 begin
  if((epp_wait == 1) & (epp_astrb == 1) & (epp_dstrb == 1)) epp_wait <= 0; //End of transaction

  else if((epp_astrb == 0) & (epp_rnw == 0)) // Address write
   begin
    addr <= epp_din;
    epp_wait <= 1;
   end
  else if((epp_dstrb == 0) & (epp_rnw == 0)) // Data write
   begin
    byte_out <= epp_din;
    rtr <= 0;
    epp_wait <= 1;
   end
  else if((epp_dstrb == 0) & (epp_rnw == 1)) // Data read
   begin
    case(addr)
     0 : epp_dout <= rtr; // Can I send a byte to FPGA
     2 : epp_dout <= rts; // Can I read a byte from FPGA
     3 : begin
          epp_dout <= byte2pc; // Read byte from FPGA
          rts <= 0;
         end
    endcase
    epp_wait <= 1;
   end
  else
   begin
    if((get == 1) & (get_ack == 0)) // Send data on UART
     begin
      get_ack <= 1;
      rtr <= 1;
     end
    else if((get == 0) & (get_ack == 1))
     get_ack <= 0;
    if((put == 1) & (put_ack == 0)) // Read data from UART
     begin
      byte2pc <= byte_in;
      put_ack <= 1;
      rts <= 1;
     end
    else if((put == 0) & (put_ack == 1))
     put_ack <= 0;          
   end
 end       
     
      
       
    
 

endmodule

