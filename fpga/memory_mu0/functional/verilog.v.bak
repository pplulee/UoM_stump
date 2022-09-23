
// Author I Wodiany
// JULY 2016
// Author Tong Li
// JUNE 2018
// Version 2.0

// Dual port memory/register module
// Based on memory_stump.v module, however only the LED matrix and LCD drivers are 
// so that the demo programs that use LEDs and LCD can run
// Address range 0 to 16'hEFF is main memory/RAM
// Address range 16'hF00 to 16'hFFF are address decoded registers
// The same address offsets(8 LSBs) are used like memory_stump.v

  `define MEM_SIZE     12'hEFF // Size of main memory
  `define IO_SIZE      8'hFF    // Size of IO

module memory_mu0(
    input   wire        Clk,        // 8MHz system clock, externally generated on S6cmod
    // CPU memory operations signals
    input   wire [11:0] address_cpu,   // CPU memory address bus
    input   wire [15:0] write_data_cpu,// Data from cpu to memory
    output  reg  [15:0] read_data_cpu, // Data from memory to cpu
    input   wire        WEnCPU,        // CPU memory write enable, active high
    // Ackie/perentie memory operations signals
    input   wire [11:0] address_ackie, // Ackie/perentie memory address bus
    input   wire [15:0] write_data_ackie, // Data from ackie/perentie to memory
    output  reg  [15:0] read_data_ackie,  // Data from memory to ackie/perentie
    input   wire        WEnAckie, // Ackie/perentie memory write enable, active high
    // 8x8 LED matrix & SW LEDs control signals
    output  reg         green_en,   // signal to enable green matrix LEDs
    output  reg         red_en,     // signal to enable red matrix LEDs
    output  reg         blue_en,    // signal to enable blue matrix LEDs
    output  reg         sw_led_en,  // signal to enable SW LEDs above switches
    output  reg  [7:0]  rgb_col,    // signals to matrix columns
    output  reg  [7:0]  rgb_row,    // signals to matrix rows
    // LCD HD44780 display connected signals
    output  reg         lcd_rs, // Register select, Data('1') or instruction('0') Register
    output  reg         lcd_e,  // Strobe signal to start read/write
    output  reg         lcd_rw, // select Read('1') or Write('0')
    output  reg  [7:0]  lcd_data, // 8bit parallel data bus
    input   wire        WEnAckie_bp,              // breakpoint enable signal for ackie write
    input   wire [15:0] breakpoint_mem_adr,       // breakpoint memory address 
    input   wire        bp_mem_data_ackie_write,  // breakpoint data written to memory from ackie
    output  reg         bp_mem_data_ackie_read,   // breakpoint data read from memory to ackie 
    output  reg         bp_mem_detected           // detected breakpoint data from memory to ackie
);


// RAM
reg [15:0]  mem [12'h000:`MEM_SIZE];    // memory array 16bit words x (4096-256) locations
// IO
reg [15:0]  io [8'h00:`IO_SIZE];        // I/O memory array 16bit words x 256 locations

// Memory enable sub-signals depending on which memory array (mem or io) current data are directed
reg WEnCPU_mem;   // set when CPU memory write operation is directed to RAM
reg WEnCPU_io;    // set when CPU memory write operation is directed to IO memory
reg WEnAckie_mem; // set when ackie memory write operation is directed to RAM
reg WEnAckie_io;  // set when ackie memory write operation is directed to IO memory

reg [11:0] address_mem_cpu;
reg [11:0] address_mem_ackie;
reg [7:0]  address_io_cpu;
reg [7:0]  address_io_ackie;

// LED Matrix
reg [8:0] count = 0;

reg [7:0] pixel1, pixel2, pixel3, pixel4;
reg [7:0] pixel5, pixel6, pixel7, pixel8;

reg [4:0] rgb_count = 0;
reg [2:0] rgb_row_count = 0;

initial
 begin
  rgb_row = 8'b0000_0001;
 end

// SW LEDS
reg [7:0] sw_led = 0;  // visible memory mapped register for SW-LEDS
wire [7:0] sw_led_map; // to map each LED to the expected labelled letter
assign  sw_led_map[0] = sw_led[4]; // LED-E
assign  sw_led_map[1] = sw_led[5]; // LED-F
assign  sw_led_map[2] = sw_led[6]; // LED-G
assign  sw_led_map[3] = sw_led[3]; // LED-D
assign  sw_led_map[4] = sw_led[7]; // LED-H
assign  sw_led_map[5] = sw_led[0]; // LED-A
assign  sw_led_map[6] = sw_led[1]; // LED-B
assign  sw_led_map[7] = sw_led[2]; // LED-C

// LCD Display
reg [12:0] lcd_delay;
reg [4:0]  lcd_state;
reg [7:0]  lcd_count;
reg [7:0]  lcd_char;

initial
 begin
  lcd_rs = 0;
  lcd_e = 0;
  lcd_rw = 0;
  lcd_data = 8'b0000_0000;
  lcd_delay = 0;
  lcd_state = 0;
  lcd_count = 9'h040;
 end

//breakpoint memory, added by Tong Li JUNE 2018
reg   bp_mem_ram [0:`MEM_SIZE]; // breakpoint ram for main memory
reg   bp_io_ram [0:`IO_SIZE];   // breakpoint ram for memory mapped IO
reg   WEnCPU_bp = 0;            // breakpoint enable signal for CPU write
reg   WEnCPU_bp_data;        		// breakpoint data in WEnCPU_bp 


reg [15:0]  mem_read_data_cpu;        // cpu ram read port
reg [15:0]  mem_read_data_ackie;      // ackie ram read port
reg [15:0]  mem_read_data_io_cpu;     // cpu io read port
reg [15:0]  mem_read_data_io_ackie;   // ackie io read port


reg   WEnAckie_bp_mem;            // ackie write enable signal for breakpoint ram, used for main memory
reg   WEnAckie_bp_io;             // ackie write enable signal for breakpoint ram, used for memory mapped io
reg   WEnCPU_bp_mem;              // CPU write enable signal for breakpoint ram, used for main memory 
reg   WEnCPU_bp_io;               // CPU write enable signal for breakpoint ram, used for memory mapped io


reg   bp_mem_read_data_ackie;     // ackie read port for breakpoint ram, used for main memory
reg   bp_mem_read_data_io_ackie;  // ackie read port for breakpoint ram, used for memory mapped io
reg   bp_mem_read_data_cpu;       // cpu read port for breakpoint ram, used for main memory
reg   bp_mem_read_data_io_cpu;    // cpu read port for breakpoint ram, used for memory mapped io



// RAM R/W control
always @ (negedge Clk) // Done to make SRAM look like asynchronous RAM, makes simulation work
 begin
    if(WEnCPU_mem)  mem[address_mem_cpu] <= write_data_cpu; // Write cpu data to RAM array
    mem_read_data_cpu <= mem[address_mem_cpu];	 // CPU reads from RAM
    if(WEnAckie_mem) mem[address_mem_ackie] <= write_data_ackie; // Write ackie data to RAM array
    mem_read_data_ackie <= mem[address_mem_ackie];	 // Ackie reads from RAM
 end

// I/O memory R/W control, similar to RAM R/W
always @ (negedge Clk)
 begin
    if(WEnCPU_io)  io[address_io_cpu] <= write_data_cpu; // Write cpu data to io array
    mem_read_data_io_cpu <= io[address_io_cpu];	 // cpu read from io memory
    if(WEnAckie_io) io[address_io_ackie] <= write_data_ackie; // Write ackie data to io array
    mem_read_data_io_ackie <= io[address_io_ackie];	 // ackie read from io memory
 end


//Synchronous dual port RAM for breakpoint data only, R/W control for main memory.
always @(negedge Clk)
  begin 
    if(WEnAckie_bp_mem) bp_mem_ram[breakpoint_mem_adr] <= bp_mem_data_ackie_write;     // Ackie writes breakpoint location into breakpint memory 
    bp_mem_read_data_ackie <= bp_mem_ram[breakpoint_mem_adr];                          // Ackie reads breakpoint location to display in perentie from breakpoint memory
    if(WEnCPU_bp_mem) bp_mem_ram[address_cpu] <= WEnCPU_bp_data;                       // Write never set for this port, required to trick synthesis to produce dual port RAM
    bp_mem_read_data_cpu <= bp_mem_ram[address_cpu];                                   // Indicates when the CPU's PC points at an address where a breakpoint is set  - Ackie should stop CPU clock
  end  


//Synchronous dual port RAM for breakpoint data only, R/W control for IO memory.
always @(negedge Clk)
  begin
    if(WEnAckie_bp_io) bp_io_ram[breakpoint_mem_adr[7:0]] <= bp_mem_data_ackie_write;   // Ackie writes breakpoint location into breakpint memory 
    bp_mem_read_data_io_ackie <= bp_io_ram[breakpoint_mem_adr[7:0]];                    // Ackie reads breakpoint location to display in perentie from breakpoint memory 
    if(WEnCPU_bp_io) bp_io_ram[address_cpu[7:0]] <= WEnCPU_bp_data;                     // Write never set for this port, required to trick synthesis to produce dual port RAM
    bp_mem_read_data_io_cpu <= bp_io_ram[address_cpu[7:0]];                             // Indicates when the CPU's PC points at an address where a breakpoint is set  - Ackie should stop CPU clock
  end


// Ackie write enable signal for breakpoint main memory and breakpoint memory mapped io.
always@(*)
 	begin
 		if (breakpoint_mem_adr[11:8] == 4'hF)
 			begin 
        WEnAckie_bp_mem = 0;
        WEnAckie_bp_io = WEnAckie_bp;
      end 
    else
    	begin             
        WEnAckie_bp_mem = WEnAckie_bp;
        WEnAckie_bp_io = 0;
      end    
	end

// CPU write enable signal for breakpoint main memory and breakpoint memory mapped io.
always@(*)
 	begin
 		if (address_cpu[11:8] == 4'hF)
 			begin 
        WEnCPU_bp_mem = 0;
        WEnCPU_bp_io = WEnCPU_bp;
      end 
    else
    	begin             
        WEnCPU_bp_mem = WEnCPU_bp;
        WEnCPU_bp_io = 0;
      end    
	end



// Ackie read breakpoint memory port, used to display in perentie from breakpoint memory
always@(*)
 	begin
 		if (breakpoint_mem_adr[11:8] == 4'hF) bp_mem_data_ackie_read = bp_mem_read_data_io_ackie;  // Ackie reads from breakpoint ram for io memory.      
 		else bp_mem_data_ackie_read = bp_mem_read_data_ackie;                                      // Ackie reads from breakpoint ram for main memory.
 	end

// CPU read breakpoint memory port, used to read breakpoint signal to stop CPU clock.
always@(*)
 	begin
 		if (address_cpu[11:8] == 4'hF) bp_mem_detected = bp_mem_read_data_io_cpu;                 //CPU reads from breakpoint ram for io memory .   
 		else bp_mem_detected = bp_mem_read_data_cpu;                                              //CPU reads from breakpoint ram for main memory . 
 	end 


// Address decoders for ram and IO
always @(*)
 begin
  address_mem_cpu = address_cpu[11:0];
  address_mem_ackie = address_ackie[11:0];
  address_io_cpu  = address_cpu[7:0];
  if(WEnAckie_io)
   address_io_ackie = address_ackie[7:0];
  else if((lcd_delay == 0) & (lcd_state == 15))
   address_io_ackie = lcd_count;
  else if((rgb_count == 0) & (count[8:3] == 0))
   address_io_ackie = {2'b00, rgb_row_count, count[2:0]};
  else
   address_io_ackie = address_ackie[7:0];
 end

// Write enables for main RAM
always @(*)
 begin
  if((WEnCPU) & (address_cpu[11:8] != 4'hF))
   WEnCPU_mem = 1;
  else
   WEnCPU_mem = 0;
  if((WEnAckie) & (address_ackie[11:8] != 4'hF))
   WEnAckie_mem = 1;
  else
   WEnAckie_mem = 0;
 end

// Write enables for IO memory
always @(*)
 begin
  if((WEnCPU) & (address_cpu[11:8] == 4'hF))
   WEnCPU_io = 1;
  else
   WEnCPU_io = 0;
  if((WEnAckie) & (address_ackie[11:8] == 4'hF))
   WEnAckie_io = 1;
  else
   WEnAckie_io = 0;
 end

// CPU read memory port
always@(*) begin
    read_data_cpu = 0;
    if (address_cpu[11:8] == 4'hF) begin // from io memory
        case(address_cpu[7:0])
            8'h97 : read_data_cpu = sw_led;
            default : read_data_cpu = mem_read_data_io_cpu;
        endcase
    end
    else // from main RAM
        read_data_cpu = mem_read_data_cpu;
end

// Ackie read memory port
always@(*) begin
    read_data_ackie = 0;
    if (address_ackie[11:8] == 4'hF) begin // from io memory
        case(address_ackie[7:0])
            8'h97 : read_data_ackie = sw_led;
            default : read_data_ackie = mem_read_data_io_ackie;
        endcase
    end
    else // from main RAM
        read_data_ackie = mem_read_data_ackie;
end

// Write address decoder for memory mapped peripherals
// Ackie(WEnAckie) takes preference for writes to same address of CPU(WEnCPU)
always @(posedge Clk)
 begin
  if(WEnAckie & (address_ackie[11:8] == 4'hF))
   case(address_ackie[7:0])
    8'h97 : sw_led <= write_data_ackie[7:0];
   endcase
  if(WEnCPU & (address_cpu[11:8] == 4'hF))
   if((WEnAckie == 0) | (address_cpu != address_ackie)) // Just make sure that Ackie(WEnAckie) is not trying to write to same peripheral
    case(address_cpu[7:0])
     8'h97 : sw_led <= write_data_cpu[7:0];
    endcase
 end


// LED Matrix driver

// Transfer pixels for a row while in blanking phase (rgb_count == 0)
always @(posedge Clk)
 begin
  if((rgb_count == 0) & ~((lcd_delay == 0) & (lcd_state == 15)))
   case(count)
    0 : pixel1 <= mem_read_data_io_ackie[7:0];
    1 : pixel2 <= mem_read_data_io_ackie[7:0];
    2 : pixel3 <= mem_read_data_io_ackie[7:0];
    3 : pixel4 <= mem_read_data_io_ackie[7:0];
    4 : pixel5 <= mem_read_data_io_ackie[7:0];
    5 : pixel6 <= mem_read_data_io_ackie[7:0];
    6 : pixel7 <= mem_read_data_io_ackie[7:0];
    7 : pixel8 <= mem_read_data_io_ackie[7:0];
   endcase
 end

always @(*) // Turn leds on/off for required time
 begin
  case(rgb_count)
  0           : rgb_col = 8'b1111_1111;
  1,2,3       : rgb_col = ~{pixel8[0], pixel7[0], pixel6[0], pixel5[0], pixel4[0], pixel3[0], pixel2[0], pixel1[0]};
  4,5,6,7     : rgb_col = ~{pixel8[1], pixel7[1], pixel6[1], pixel5[1], pixel4[1], pixel3[1], pixel2[1], pixel1[1]};
  8           : rgb_col = ~{pixel8[2], pixel7[2], pixel6[2], pixel5[2], pixel4[2], pixel3[2], pixel2[2], pixel1[2]};
  9, 10       : rgb_col = ~{pixel8[3], pixel7[3], pixel6[3], pixel5[3], pixel4[3], pixel3[3], pixel2[3], pixel1[3]};
  11,12,13,14 : rgb_col = ~{pixel8[4], pixel7[4], pixel6[4], pixel5[4], pixel4[4], pixel3[4], pixel2[4], pixel1[4]};
  15          : rgb_col = ~{pixel8[5], pixel7[5], pixel6[5], pixel5[5], pixel4[5], pixel3[5], pixel2[5], pixel1[5]};
  16, 17      : rgb_col = ~{pixel8[6], pixel7[6], pixel6[6], pixel5[6], pixel4[6], pixel3[6], pixel2[6], pixel1[6]};
  18,19,20,21 : rgb_col = ~{pixel8[7], pixel7[7], pixel6[7], pixel5[7], pixel4[7], pixel3[7], pixel2[7], pixel1[7]};
  22,23,24,
  25,26,27,28 : rgb_col = ~sw_led_map;
  default     : rgb_col = 8'b1111_1111;
  endcase
 end

always @(*)
 begin
  case(rgb_count)
  0          : {red_en, green_en, blue_en, sw_led_en} = 4'b1111; // Blanking phase
  1,2,3,
  4,5,6,7    : {red_en, green_en, blue_en, sw_led_en} = 4'b1101; // Blue phase
  8,9,10,
  11,12,13,14: {red_en, green_en, blue_en, sw_led_en} = 4'b1011; // Green phase
  15,16,17,
  18,19,20,21: {red_en, green_en, blue_en, sw_led_en} = 4'b0111; // Red phase
  22,23,24,
  25,26,27,28: {red_en, green_en, blue_en, sw_led_en} = 4'b1110; // SW led phase
  default    : {red_en, green_en, blue_en, sw_led_en} = 4'b1111;
  endcase
 end


// LED matrix control and timing
always @(posedge Clk)
  begin
   if(count[8] == 1)
    begin
     count <= 0;
     if(rgb_count == 28) // Move to next row and enter blanking phase
      begin
       rgb_row <= {rgb_row[6:0],rgb_row[7]};
       rgb_count <= 0;
       if(rgb_row_count == 7)
        rgb_row_count <= 0;
       else
        rgb_row_count <= rgb_row_count + 1;
      end
     else
      begin
       rgb_count <= rgb_count + 1;
      end
    end
   else    // count[8] != 1 keep counting
    begin
     count <= count + 1;
    end
  end


// LCD Driver
always @ (posedge Clk)
 begin
  if((lcd_delay == 0) & (lcd_state == 15))
   lcd_char <= mem_read_data_io_ackie[7:0];
 end

always @ (posedge Clk)
 begin
  if(lcd_delay[12] == 1)
   begin
    lcd_delay <= 0;
    case(lcd_state)
     0  : begin lcd_e <= 1; lcd_state <= lcd_state + 1; end
     1  : begin lcd_data <= 8'b0011_1000; lcd_state <= lcd_state + 1; end // Set N and F (2 lines, 5x8 font)
     2  : begin lcd_e <= 0; lcd_state <= lcd_state + 1; end

     3  : begin lcd_e <= 1; lcd_state <= lcd_state + 1; end
     4  : begin lcd_data <= 8'b0000_0110; lcd_state <= lcd_state + 1; end // Set display to Increment and no Shift
     5  : begin lcd_e <= 0; lcd_state <= lcd_state + 1; end

     6  : begin lcd_e <= 1; lcd_state <= lcd_state + 1; end
     7  : begin lcd_data <= 8'b0000_1100; lcd_state <= lcd_state + 1; end // Set D, C, B (Display=on, Cursor=off, Blink=off)
     8  : begin lcd_e <= 0; lcd_state <= lcd_state + 1; end

     9  : begin lcd_e <= 1; lcd_state <= lcd_state + 1; end
     10 : begin lcd_data <= 8'b0000_0001; lcd_state <= lcd_state + 1; end // Clear display
     11 : begin lcd_e <= 0; lcd_state <= lcd_state + 1; end

     12 : begin lcd_e <= 1; lcd_state <= lcd_state + 1; end
     13 : begin lcd_data <= 8'b0000_0010; lcd_state <= lcd_state + 1; end // Return home
     14 : begin lcd_e <= 0; lcd_state <= lcd_state + 1; end

     15 : begin lcd_e <= 1; lcd_state <= lcd_state + 1; end
     16 : begin lcd_rs <= 1; if(lcd_char == 0) lcd_data <= 8'h20; else lcd_data <= lcd_char; lcd_state <= lcd_state + 1; end // Write character to lcd. If value is zero(non-empty char) write space instead
     17 : begin
           lcd_e <= 0;
           if(lcd_count == 8'h53)
            lcd_count <= 8'h68;
           else if(lcd_count == 8'h7B)
            lcd_count <= 8'h54;
           else if(lcd_count == 8'h67)
            lcd_count <= 8'h7C;
           else
            lcd_count <= lcd_count + 1;
           lcd_state <= lcd_state + 1;
          end

     18 : begin
           if(lcd_count == 8'h90) begin lcd_count <= 9'h040; lcd_rs <= 0; lcd_state <= 12; end
           else lcd_state <= 15;
          end
    endcase
   end
  else
   lcd_delay <= lcd_delay + 1;
 end

endmodule