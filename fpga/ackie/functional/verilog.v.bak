//Verilog HDL for "Board_lib", "ackie" "functional"

// Author J Pepper
// Date 09/05/2016
//
// Modified by I Wodiany
// Date 16/06/2016
//
// Modified by Paris M
// Date 22/08/2016
//
// Modified by Tong Li
// Date 25/06/2018
// Version 2.0
// For any CPU

// Implementation of "ackie" a communication and control module for any CPU and its memory
// This version of ackie connects the perentie monitor software to any CPU and its memory via a custom
// byte wide uart that make use of the Digilent adept API (C library functions)
// Perentie and ackie communicate using the kmd communications protocol
// Please read https://studentnet.cs.manchester.ac.uk/resources/software/komodo/comms.html
// Ackie also generates the clock for the CPU

// This module is split into two clocked functions
// One function looks after commuicating with perentie and the monitoring of the CPU/MEMORY
// The other function has a controlling influence over the CPU, it starts, stops,
// pauses the cpu clock, it can cause a cpu reset
// It also holds the status of ackie - steps since reset, step remaining, etc

// Processor independent macros
`define MESSAGE_LEN     16'h0D00  // Number of bytes broadcast after this to produce message
          //(LSByte 1st, 13 bytes transmitted)

// Komodo communications protocol Definitions
  // Komodo commands send by the front-end(Perentie)
  `define   NOP             8'h00
  `define   PING            8'h01 // ping command, must reply "OK00" back to perentie
  `define   GET_SYSTEM      8'h02 // get cpu system
  `define   RESET_CPU       8'h04 // send a reset command to the CPU
  `define   GET_STATE       8'h20 // get CPU execution state, must reply back to perentie
  `define   STOP_CPU        8'h21 // stop CPU execution
  `define   PAUSE_CPU       8'h22 // pause CPU execution
  `define   CONTINUE_CPU    8'h23 // continue CPU execution
  `define   TOGGLE_BREAKPOINT 8'h30 // toggle breakpoint status set/not set, JSP AUG2017
  `define   READ_BREAKPOINT 8'h31 // read breakpoint status set/not set, JSP AUG2017
  `define   MEM_ACCESS      8'h4? // read/write to/from memory
  `define   CPU_REG_ACCESS  8'h5? // read/write to/from CPU Registers
  `define   RUN             8'hB0 // Run/execute the next instruction on the CPU
          // next 4 bytes give number of steps to execute
  `define   RUN_BREAK_EN    8'hB1 // Run/execute as above, enable breakpoints
                                  // on the first instruction executed
  
  // Execution status
  `define   RESET           8'h00
  //`define   BUSY            8'h01     // not used
  `define   STOPPED         8'h40     // Stopped
  //`define   STP_BREAKPOINT  8'h41     // Stopped due to breakpoint (TODO)
  //`define   STP_WATCHPOINT  8'h42     // Stopped due to watchpoint (TODO)
  //`define   STP_MEM_FAULT   8'h43     // Stopeed due to memory fault (not used)
  //`define   STP_PROGRAM     8'h44     // Stopped by programme request
  `define   RUNNING         8'h80     // Running normally
  //`define   SVC             8'h81     // Servicing a Supervisor Call
  //`define   SWI             8'h81     // Alias for SVC
  // Values 8'hC0 - 8'hFF can be used for Error Codes

module ackie (clk,
               byte_out, byte_in, get, put, rts, rtr, get_ack, put_ack,   // UART signals
               mem_wen, mem_addr, mem_dout, mem_din,        // memory signals
               proc_din, proc_wen, proc_clk, fetch, cc, cpu_reset, halted, // cpu signals
               bp_mem_write_en,                            // breakpoint enable signal for ackie write 
               breakpoint_adr,                             // breakpoint address
               bp_mem_data_write,                          // breakpoint data for ackie write 
               bp_mem_data_read,                           // breakpoint data read from memory
               bp_detected                                 // ackie detects breakpoint data from memory, stop the CPU clock if it is 1.
              );

// Define CPU type to MU0, parameters can be overrided, added by Tong Li June 2018 
parameter CPU_TYPE = 8'd4;    // MU0
parameter CPU_SUB = 16'd0;    // MU0
parameter FEATURE_COUNT = 8'd0;    // No features?
parameter MEM_SEGS = 8'd1;    // One continuous memory area
parameter MEM_START = 32'd0;
parameter MEM_SIZE = 32'd12;

// Define width of data and address buses(32 bits max)
// Subtracted one from values, because verilog counts from zero
parameter MEM_ADDR_WIDTH =  8'd11;   // Memory address bus width
parameter MEM_DATA_WIDTH =  8'd15;   // Memory data bus width
parameter PROC_DAT_WIDTH  = 8'd15;   // CPU data bus width

// Address mapped by perentie to the CPU Flags Register
parameter PROC_FLAG_ADDR = 2'd2;

input clk; // System hardware clock input, provided by the FPGA board

input [7:0]      byte_in;  // Byte from UART
input            rts;      // Ready to send UART status
input            rtr;      // Ready to receive UART status
input            get_ack;  // UART - byte_in now valid
input            put_ack;  // UART - got byte from ackie
output reg       put = 0;  // Request to send byte to UART
output reg       get = 0;  // Request to receive byte from UART
output reg [7:0] byte_out; // Byte to UART

// Normal memory signals
input       [MEM_DATA_WIDTH:0] mem_din;      // Data from memory module connected to ackie
output reg                      mem_wen;  // Memory write signal active high
output wire [MEM_ADDR_WIDTH:0] mem_addr;     // Address for memory module connected to ackie
output reg  [MEM_DATA_WIDTH:0] mem_dout; // Data to memory module 

// CPU signals
input                 halted;   // CPU has stopped (only relevant to MU0)
input       [PROC_DAT_WIDTH:0] proc_din; // Data from cpu/processor being monitored
input                 fetch;    // Used to show that an instruction has been executed
input [3:0]     cc;   // Used to monitor CPU flags
output reg            proc_wen = 0;  // Write enable signal, used to change cpu
                 // register contents, active high, for MU0
                 // and STUMP write to registers is not supported
output reg            proc_clk; // ackie generated clock that drives the cpu/processor
//input       [`MEM_ADDR_WIDTH:0] proc_addr; // Address generated by cpu - used for breakpoints 


// Declaration of Internal signals
reg [7:0]  state = 0;  // FSM states for ackie comms/monitor process
reg [31:0] address;    // ends up as memory address, 32bit is the Maximum width
           // Actually depends on CPU type, only the least significant bits are used
reg [15:0] num_elements; // Number of elements sent to/from perentie
reg [31:0] steps_to_execute = 0; // CPU steps required to execute
reg [31:0] steps_to_run     = 0; // ?? TODO difference from above 
reg        execute_cpu = 0;      // When set, start CPU clock
reg [4:0]  proc_clk_delay = 0;   // Set cpu clock pulse size

reg [7:0]  cmd;  // store the current perentie/kmd command


reg [119:0] cpu_system = {`MESSAGE_LEN, CPU_TYPE, CPU_SUB, 
        FEATURE_COUNT, MEM_SEGS, MEM_START, MEM_SIZE};
reg [119:0] return_message;
reg [7:0]   cpu_status = `RESET;   // the execution status of the cpu
reg [31:0]  steps_remain = 0;
reg [31:0]  steps_since_reset = 0; // CPU steps executed since last reset

reg [18:0]  put_counter; // Number of bytes or elements to transmit to UART
reg [18:0]  get_counter; // Number of bytes or elements to receive from UART

reg [3:0]   element_size;  // Size of CPU/MEMORY data word in bytes (1, 2, 4 or 8)
reg [3:0]   data_byte_sel; // Pointer to current byte of a CPU/MEMORY data word

// Signals to control the CPU. All are active high
output reg  cpu_reset; // Signal to reset the CPU
reg         cpu_stop  = 0; // Signal to stop CPU clock only when fetch is 1 (full instruction has executed)
         // and the cpu clock is in the correct position.
         // Resets CPU remaining steps to 0 
reg         cpu_pause = 0; // Same as cpu_stop, but without resetting remaining steps 


// pins added for breakpoints.    added by Tong Li, June 2018.
input      bp_mem_data_read;       // breakpoint data read from memory
input      bp_detected;            // ackie detects breakpoint data from memory, stop the CPU clock if it is 1.
output reg bp_mem_data_write;      // breakpoint data for ackie write 
output reg [15:0] breakpoint_adr;  // breakpoint address 
output reg bp_mem_write_en = 0;		 // breakpoint enable signal for ackie write 

initial
 begin
  put = 0;
  get = 0;
  mem_wen = 0;
  mem_dout = 0;
  proc_wen = 0;
  cpu_reset = 0;
 end


// ackie communication and monitor process
always @(posedge clk)
 begin
  case(state)
   0 :  begin  // Initial state 
         if((rtr == 0) & (get_ack == 0)) // UART has a byte ready for transfer to ackie
          begin
     get <= 1;  // request to receive a byte from UART
     state <= 1;
          end
  end

   // States 1-2: Get and Decode kmd command from Perentie
   1 :  if(get_ack == 1) // UART has responded with a valid byte
         begin
    cmd <= byte_in; // Get UART byte
    get <= 0;
    state <= 2;
   end

   2 : begin
  casex(cmd) // What does the UART byte represent
   `NOP : state <= 0;  // nop
   `PING :  begin  // ping command, reply "OK00" back to perentie
        put_counter <= 3;
        return_message <= "OK00";
        state <= 3;
    end
   `GET_SYSTEM :  begin  // get cpu system, reply back to perentie
        put_counter <= 14;
        return_message <= cpu_system;
        state <= 3;
    end
   `RESET_CPU : begin state <= 0; end // cpu_reset
   `GET_STATE : begin   // get cpu state, reply back to perentie
              put_counter <= 8;   // reply must be 9 bytes
              return_message <= {cpu_status,         // the cpu execution status, 1 byte
                                 steps_remain[7:0], steps_remain[15:8],    // 4 bytes 
         steps_remain[23:16], steps_remain[31:24],
                                 steps_since_reset[7:0], steps_since_reset[15:8], // 4 bytes
         steps_since_reset[23:16], steps_since_reset[31:24]};
              state <= 3;
    end
   `STOP_CPU : begin state <= 0; end  // stop cpu execution
   `PAUSE_CPU : begin state <= 0; end // pause cpu exexution
   `CONTINUE_CPU : begin state <= 0; end  // continue cpu execution
   `MEM_ACCESS, `CPU_REG_ACCESS : begin   // READ WRITE to/from MEMORY or CPU Registers
        get_counter <= 5;     // memory transfers are 6 bytes long
        element_size <= 4'b0001 << cmd[2:0]; // translate cmd code to an integer number of bytes
        state <= 5;
    end
         `RUN_BREAK_EN, `RUN : begin  // Start execution of CPU
        get_counter <= 3;       // next 4 bytes give number of steps to execute
        state <= 13; 
    end
        // Breakpoints added by JSP AUG2017
  `READ_BREAKPOINT : begin
        get_counter <= 1;       // next 2 bytes give breakpoint address 16bits
        state <= 16;
    end 
  `TOGGLE_BREAKPOINT : begin
        get_counter <= 1;       // next 2 bytes give breakpoint address 16bits
        state <= 20;
    end 
  endcase
       end // end state 2
   
   // States 3-4: Reply to perentie with appropriate message     
   3 : begin  // Send message to perentie via UART protocol
        if((rts == 0) & (put_ack == 0)) // Wait for UART ready to send to be clear
         begin
           byte_out <= return_message >> {put_counter, 3'b000}; // Send a byte at a time, MSByte first 
           put <= 1;   // request to send a byte to UART
     state <= 4;
   end
       end

   4 :  begin
         if(put_ack == 1) // Wait for UART respond to send byte request
          begin
           put <= 0;      
     if(put_counter == 0) // Has the last byte of message been sent?
      begin
       state <= 0;
      end
     else
      begin
       put_counter <= put_counter - 1; // Get ready to send next byte of message
             state <= 3;
      end
    end    
  end

   // States 5-12: ACCESS MEMORY
   // Do a memory transfer from/to Memory or CPU Registers
   5 : begin
        // Use states 5-6 to get the next 6 bytes which indicate the
        // start address(4 bytes) and the number of elements to get/put(2 bytes) 
        if((rtr == 0) & (get_ack == 0)) // UART has a byte ready for transfer
         begin
           get <= 1;  // request to receive a byte from UART
     state <= state + 1;  // TODO ?? why need to state +1 ??
    end
       end

   6 : begin
         if(get_ack == 1) // Shift byte from UART into number of elements and start address
          begin
           {num_elements, address} <= {byte_in, num_elements, address} >> 4'b1000;
           get <= 0;
     if(get_counter == 0) // Got start address and number of elements, move to next state
      begin
       state <= 7;
      end
     else // Go get next UART byte for start address and number of elements
      begin
       get_counter <= get_counter - 1;
             state <= 5;
      end
    end    
  end

   // State 7: Choose READ or WRITE
   7 : begin
         if(num_elements == 0) // No elements requested, return to start state
          state <= 0;
         else if(cmd[3] == 0) // WRITE to CPU or MEMORY
          begin
           get_counter <= 0;
           data_byte_sel <= 0;
           state <= 10; // Goto Write state 
          end
         else // READ from CPU or MEMORY
          begin
           put_counter <= 1;
           data_byte_sel <= 0;
           state <= 8; // Goto Read state
          end
        end

   // States 8-9: Memory/CPU READ operation
   8 : begin 
        if((rts == 0) & (put_ack == 0)) // UART ready to accept byte from ackie
         begin
          if(cmd[5:4] == 1)      // proc_read
      if(address == PROC_FLAG_ADDR)
        byte_out <= cc >> {data_byte_sel,3'b000}; // Read flags
      else
        byte_out <= proc_din >> {data_byte_sel,3'b000}; // Read data from register 
          else if(cmd[5:4] == 0) // mem read
      byte_out <= mem_din >> {data_byte_sel,3'b000}; 
          put <= 1;   // request to send byte to UART 
    state <= 9;
  end
       end

   9 : begin
         if(put_ack == 1) // UART has read the byte
          begin
           put <= 0;
     if((put_counter == num_elements) & ((data_byte_sel + 1) == element_size)) // Done CPU/memory read
      begin
       state <= 0;  // return to start
      end
           else if((data_byte_sel + 1) == element_size) // Get next element to send to UART
            begin
             data_byte_sel <= 0; // Reset to set 1st byte of new data element
       put_counter <= put_counter + 1; // Next data element
             address <= address + 1; // Set address of next data element
             state <= 8;
      end
     else // Get next byte of element to send to UART
            begin
             data_byte_sel <= data_byte_sel + 1; // Next byte of data element
             state <= 8;
            end 
    end    
  end

   // States 10-12: Memory/CPU WRITE operation
   10 : begin // Wait until uart has data to pass to ackie to write to memory/CPU
         if((rtr == 0) & (get_ack == 0))
          begin
           get <= 1;
     state <= 11;
    end
        end

   11 : begin
         if(get_ack == 1) // UART presents valid byte
          begin
           get <= 0;
           mem_dout <= {byte_in, mem_dout} >> 4'b1000;  // Shift in uart byte into element to write
           if((data_byte_sel + 1) == element_size) // Element ready to write to mem or proc
            begin
             if(cmd[5:4] == 0) // Write to MEMORY
    mem_wen <= 1;
             else if(cmd[5:4] == 1) // Write to CPU registers
    proc_wen <= 1;
       data_byte_sel <= 0; // Reset to set byte of data element
       get_counter <= get_counter + 1; // Next element
       state <= 12;            
            end
           else // element is not fully retrieved yet
            begin
             data_byte_sel <= data_byte_sel + 1; // Next byte of data element
             state <= 10; // Get next byte from UART
      end
    end    
  end

   12 : begin
   // writing byte to memory is done, unset write_enables
         mem_wen <= 0; 
         proc_wen <= 0;
         if(get_counter == num_elements) // Finished writing all data elements to MEMORY/CPU
          state <= 0;
         else // there are still elements left to write
          begin
           address <= address + 1; // Set address of next data element
           state <= 10; // Repeat, get byte from UART, build data element, write to MEMORY/CPU
          end
        end

   // States 13-15: EXECUTE COMANDS 
   13 : 
        if((rtr == 0) & (get_ack == 0)) // Wait until uart has transfered byte
         begin
           get <= 1; // request to get next byte from uart
     state <= 14;
   end
   
   14 : begin
         if(get_ack == 1) // uart byte ready
          begin
     // start building up steps to execute, need to get 4 bytes
           steps_to_execute <= {byte_in, steps_to_execute} >> 4'b1000; 
           get <= 0;
     if(get_counter == 0) // steps_to_execute now ready
      begin
             execute_cpu <= 1;
       state <= 15;
      end
     else
      begin
       get_counter <= get_counter - 1; // Get next uart byte
             state <= 13;
      end
    end    
  end
   
   15 : begin // End of command, wait for next perentie command
         execute_cpu <= 0; 
         state <= 0;
        end
   // Added AUG 2017 BREAKPOINTS by JSP  
   // States 16-19: GET BREAKPOINTS 
   16 : 
        if((rtr == 0) & (get_ack == 0)) // Wait until uart has transfered byte
         begin
           get <= 1; // request to get next byte from uart
     state <= 17;
   end
   
   17 : begin
         if(get_ack == 1) // uart byte ready
          begin
     // start building up breakpoint_address, need to get 2 bytes
           breakpoint_adr <= {byte_in, breakpoint_adr} >> 4'b1000; 
           get <= 0;
     if(get_counter == 0) // 
      begin
       state <= 18;
      end
     else
      begin
       get_counter <= get_counter - 1; // Get next uart byte
             state <= 16;
      end
    end    
  end

   18 : begin 
        if((rts == 0) & (put_ack == 0)) // UART ready to accept byte from ackie
         begin
          byte_out <= bp_mem_data_read; // Breakpoint value
          put <= 1;   // request to send byte to UART 
    state <= 19;
  end
       end

   19 : begin
         if(put_ack == 1) // UART has read the byte
          begin
           put <= 0;
     state <= 0;  // return to start
    end    
  end   
   // Added AUG 2017 BREAKPOINTS by JSP  
   // States 20-23: TOGGLE BREAKPOINT at given address 
   20 : 
        if((rtr == 0) & (get_ack == 0)) // Wait until uart has transfered byte
         begin
           get <= 1; // request to get next byte from uart
     state <= 21;
   end
   
   21 : begin
         if(get_ack == 1) // uart byte ready
          begin
     // start building up breakpoint_address, need to get 2 bytes
           breakpoint_adr <= {byte_in, breakpoint_adr} >> 4'b1000; 
           get <= 0;
     if(get_counter == 0) // 
      begin
       state <= 22;
      end
     else
      begin
       get_counter <= get_counter - 1; // Get next uart byte
             state <= 20;
      end
    end    
  end

    22 : begin
          bp_mem_data_write <= ~bp_mem_data_read; // Invert breakpoint
          bp_mem_write_en <= 1;
          state <= 23;
         end

   23  : begin
          bp_mem_write_en <= 0;
          state <= 0;
         end  
  endcase 
 end
 


// CPU status and CPU clock control
always @(posedge clk)
 begin
  // Reset, Stop and Pause must be synchronised with CPU clock, therefore the signals are initially set 
  // but the actions are performed at time when instruction has completed execution  
  if(cmd == `RESET_CPU) // Send synchronous reset signal
   begin
    cpu_status <= `RUNNING; // keep cpu running in order to execute the reset step
    steps_remain <= 1; // execute only one step with the cpu_reset signal active
    steps_since_reset <= 0;
    proc_clk_delay <= 0; // reset the clock pulse, to start executing the reset step
    proc_clk <= 0;
    cpu_reset <= 1;
    // after reset step is done, steps remain will become 0
   end
  else if(halted == 1)  // CPU has stopped
   cpu_status <= `STOPPED;
  else if(cmd == `STOP_CPU) // Stop CPU
   cpu_stop <= 1;  // activate the cpu_stop signal
  else if(cmd == `PAUSE_CPU) // Pause CPU
   cpu_pause <= 1; // activate the cpu_pause signal
  else if(cmd == `CONTINUE_CPU) // Cont CPU
   cpu_status <= `RUNNING;      
  else if(execute_cpu == 1) // Run CPU
   begin 
    cpu_status <= `RUNNING;  // CPU running  
    steps_remain <= steps_to_execute;
    proc_clk_delay <= 0;
    proc_clk <= 0;
    cpu_reset <= 0;
    cpu_stop <= 0;
    cpu_pause <= 0;
   end
  else if((cpu_status == `RUNNING) & ((steps_remain != 0) | (steps_to_execute == 0)))
   // cpu clock generation logic
   begin  // Run proc clk for number of steps (steps_to_execute == 0 means run forever) or
          // until stopped by perentie                                                                    
     if(proc_clk_delay == 7)
      begin
       proc_clk_delay <= 0;
       proc_clk <= 0;
      end
     else if(proc_clk_delay > 3)
      begin
       proc_clk_delay <= proc_clk_delay + 1;
       proc_clk <= 1;
      end
     else
      begin
       proc_clk_delay <= proc_clk_delay + 1;
       proc_clk <= 0;       
      end    
     if((fetch == 1) & (proc_clk_delay == 6)) // One full instruction execution
      // synchronise stop, pause and reset here
      begin
       steps_since_reset <= steps_since_reset + 1;
       if(steps_to_execute != 0) // Not in run forever mode, update remaining steps
        steps_remain <= steps_remain - 1;
       if(cpu_reset == 1) // Reset CPU
  begin
   cpu_status <= `STOPPED;
   steps_remain <= 0;
   steps_since_reset <= 0;
   proc_clk_delay <= 0;
   proc_clk <= 0;
  end
       else if(cpu_stop == 1) // Stop CPU, reset remaining steps to 0
        begin
         steps_remain <= 0;
         cpu_status <= `STOPPED; 
         cpu_stop <= 0;
        end
       else if(cpu_pause == 1) // Pause CPU, don't reset steps left to execute
        begin
         cpu_status <= `STOPPED;
         cpu_pause <= 0;          
        end
       else if(bp_detected == 1) // Pause CPU on breakpoint, don't reset steps left to execute, by JSP AUG 2017
        begin
         cpu_status <= `STOPPED;
         cpu_pause <= 0;          
        end
      end
   end
  else if(cpu_status == `RUNNING) // remaining steps 0; stop the proc clk
   begin
    cpu_status <= `STOPPED; // CPU status set to stop
   end
 end 

assign mem_addr = address[MEM_ADDR_WIDTH:0];

endmodule
