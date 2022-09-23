// Verilog HDL for "STUMP_lib", "memory_stump" "functional"

// Author J Pepper
// Author I Wodiany
// Author Tong Li
// June 2018
//
// Version 2.0

// Dual port memory/register module
// Uses a Synchronous RAM on a negedge clock, to fool processor into think its just a RAM
// Address range 0 to 16'h1FFF is main memory/RAM
// Address range 16'hFF00 to 16'hFFFF are address decoded registers to give access to the
// 2nd year engineering lab board peripherals
  `define MEM_SIZE     16'h1FFF // Size of main memory
  `define IO_SIZE      8'hFF    // Size of IO

module memory_stump(
    input   wire        Clk,        // 8MHz system clock, externally generated on S6cmod
    // CPU memory operations signals
    input   wire [15:0] address_cpu,   // CPU memory address bus
    input   wire [15:0] write_data_cpu,// Data from cpu to memory
    output  reg  [15:0] read_data_cpu, // Data from memory to cpu
    input   wire        WEnCPU,        // CPU memory write enable, active high
    // Ackie/perentie memory operations signals
    input   wire [15:0] address_ackie, // Ackie/perentie memory address bus
    input   wire [15:0] write_data_ackie, // Data from ackie/perentie to memory
    output  reg  [15:0] read_data_ackie,  // Data from memory to ackie/perentie
    input   wire        WEnAckie, // Ackie/perentie memory write enable, active high
    // S6CMOD board LEDs and Buttons
    output  reg  [3:0]  s6_leds,    // 4 leds on S6cmod board (LD0-LD3)
    input   wire        s6_button1, // Button 1 on S6cmod board (BTN1)
    input   wire        s6_button0, // Button 0 on S6cmod board (BTN0)
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
    // piezo buzzer control on/off
    output  reg         buzzer_pulses,
    // vibration motor
    output  reg         shaker,
    // numeric keypad and SW switches signals
    output  reg  [3:0]  key_row,    // drive the key rows
    input   wire [4:0]  key_col,    // read the key columns
    // i2c bus signals
    input   wire        sda,        // i2c serial data line
    input   wire        scl,        // i2c clock line
    output  reg         i2c_sda,    // drive sda and scl lines
    output  reg         i2c_scl,     // '0': driven low, '1': 'Z' (High Impedence, line released)
    input   wire        WEnAckie_bp,       				// breakpoint enable signal for ackie write
    input   wire [15:0] breakpoint_mem_adr,       // breakpoint memory address 
    input   wire        bp_mem_data_ackie_write,  // breakpoint data written to memory from ackie
    output  reg         bp_mem_data_ackie_read,   // breakpoint data read from memory to ackie 
    output  reg         bp_mem_detected           // detected breakpoint data from memory to ackie
);

// RAM
reg [15:0]  mem [16'h0000:`MEM_SIZE];  // memory array 16bit words x 8912 locations
// IO
reg [15:0]  io [8'h00:`IO_SIZE];        // I/O memory array 16bit words x 256 locations

// Memory enable sub-signals depending on which memory array (mem or io) current data are directed
reg WEnCPU_mem;   // set when CPU memory write operation is directed to RAM
reg WEnCPU_io;    // set when CPU memory write operation is directed to IO memory
reg WEnAckie_mem; // set when ackie memory write operation is directed to RAM
reg WEnAckie_io;  // set when ackie memory write operation is directed to IO memory

reg [15:0] address_mem_cpu;
reg [15:0] address_mem_ackie;
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

// Keypad / Switches
// Each key is mapped to a single bit
reg [11:0]  keypad = 12'h000; // keys 0-9 mapped to bits 0-9. * and # mapped to bits 10,11
reg [7:0]   sw_keys = 8'h00;   // mapped left to right and top-down
reg [2:0]   keyrow_scan_delay = 0; // clock cycles delay between each key row scan

initial
 begin
  key_row = 4'b1110; // must initialize with only 1 row driven low
 end

// Buzzer
reg [15:0] buzzer; // memory address decoded register for buzzer control
reg        buzzer_busy = 0; // high when buzzer is running in program mode
reg        buzzer_run = 0; // to indicate that the buzzer register has been written to
reg [20:0] buzzer_clk_count = 0; // Counter used to produce the buzzer time step delay
reg [3:0]  buzzer_time_step_count = 0; // Hold the number of buzzer time steps
reg [15:0] buzzer_note; // Buzzer note selected (in terms of clock cycles)
reg [15:0] buzzer_octave_and_note; // the buzzer note scaled by the octave selected
reg [15:0] buzzer_note_count = 0; // Counter used to count clock cycles of the determined note/octave

// free running counter
reg [15:0] free_run_counter = 0;
reg [2:0]  free_run_counter_delay = 0;

// I2C
reg [1:0] i2c_state = 0; // i2c main controller state, one state for each i2c driver

initial  // when I2C bus is idle both lines must be released
 begin
  i2c_sda <= 1; //'1' sets the tristate buffer output to sda line to 'Z'(High Impedence)
  i2c_scl <= 1;
 end

// RTC
// Registers for storing data from RTC
reg [7:0]  RTCSeconds;
reg [7:0]  RTCMinutes;
reg [7:0]  RTCHours;
reg [7:0]  RTCDay;
reg [7:0]  RTCDate;
reg [7:0]  RTCMonth;
reg [7:0]  RTCYear;

// Registers for storing data that will be written to RTC
reg [7:0]  RTCBufferSeconds;
reg [7:0]  RTCBufferMinutes;
reg [7:0]  RTCBufferHours;
reg [7:0]  RTCBufferDay;
reg [7:0]  RTCBufferDate;
reg [7:0]  RTCBufferMonth;
reg [7:0]  RTCBufferYear;

// visible flag, high when any RTC driver is busy, controlled by i2c main controller
reg        RTCBusy = 0;
// Internal flags that hold information if a RTC register has to be updated
reg [6:0]  RTCWEn = 7'b000_0000;
// Visible flags that hold information if a RTC write request to the register was successfull
reg [6:0]  RTCAck = 7'b111_1111;

reg        RTCRead = 0;    // User controlled Signal to Enable Reading the RTC
reg        RTCAckRead = 1; // Read-only visible Acknowledgemnt signal for RTC Read operation

// RTC OUT FSM
reg [4:0]  rtc_out_count = 0; // RTC Write FSM delay, from 0-24, incremented by i2c main controller
reg [7:0]  rtc_out_byte = 8'b1101_0000; // Current Byte send to RTC. Intitalise with RTC device i2c address
reg [2:0]  rtc_out_state = 0; // RTC write driver sate, from 0-7
reg [7:0]  rtc_out_bit_count = 8'b0000_0001; // count current bit transfered in current 1 byte cycle
reg        rtc_out_ack = 1; // to record acknowledgment from rtc device
reg        rtc_out_sda = 1; // current bit value to write to the sda line. When bus is idle must be '1'
reg        rtc_out_scl = 1; // current clock state to write to scl line. When bus is idle must be '1'
reg [2:0]  rtc_out_reg = 0; // Address of internal register of RTC (from 0-6)
reg [7:0]  rtc_out_value = 8'b0000_0000; // Data value that will be written to RTC

// RTC IN FSM
reg        rtc_in_read_en = 0; // internal signal controlled by the i2c main controller while a Read operation takes place
reg [4:0]  rtc_in_count = 0; // RTC read FSM delay, from 0-24, incremented by i2c main controller
reg [7:0]  rtc_in_byte = 8'b1101_0000; // Byte to send to RTC(device address, RTC register) or current data byte received
reg [3:0]  rtc_in_state = 0; // RTC read driver state, from 0-11
reg [7:0]  rtc_in_bit_count = 8'b0000_0001; // count current bit transfered in current 1 byte cycle
reg [2:0]  rtc_in_byte_count = 0; // count current data byte received from RTC
reg        rtc_in_ack = 1; // to record acknowledgment from rtc device
reg        rtc_in_sda = 1; // current bit value to write to the sda line. When bus is idle must be '1'
reg        rtc_in_scl = 1; // current clock state to write to scl line. When bus is idle must be '1'

// ADC FSM
reg [4:0]  adc_count = 0; // ADC FSM delay, from 0-24, incremented by i2c main controller
reg [7:0]  adc_byte = 8'b1001_1010; // Byte to send to ADC(device address) or current data byte received
reg [2:0]  adc_state = 0; // ADC driver state, from 0-6
reg [7:0]  adc_bit_count = 8'b0000_0001; // count current bit transfered in current 1 byte cycle
reg        adc_byte_count = 0; // count curent data byte received from ADC
reg        adc_ack = 1; // to record acknowledgment from ADC
reg        adc_sda = 1; // current bit value to write to the sda line. When bus is idle must be '1'
reg        adc_scl = 1; // current clock state to write to scl line. When bus is idle must be '1'

// ADC memory mapped registers
reg [15:0] ADCData = 0; // data read from ADC
reg        ADCBusy = 0; // ADC driver is busy receiving data, controlled by main i2c controller
reg        ADCAck  = 1; // set to '1' after ACK from ADC, to '0' after NACK 
reg        ADCReadEn = 0; // User controlled Signal to Enable Reading from ADC

// DAC FSM
reg [4:0]  dac_count = 0; // DAC FSM delay, from 0-24, incremented by i2c main controller
reg [7:0]  dac_byte = 8'b1001_1010; // current Byte to send to DAC, device address or data
reg [2:0]  dac_state = 0; // DAC driver state, from 0-7
reg [7:0]  dac_bit_count = 8'b0000_0001; // count current bit transfered in current 1 byte cycle
reg        dac_ack = 1; // to record acknowledgment from
reg        dac_sda = 1; // current bit value to write to the sda line. When bus is idle must be '1'
reg        dac_scl = 1; // current clock state to write to scl line. When bus is idle must be '1'
reg        DACWEn = 0; // internal flag. Set high by i2c main controller when DAC memory contents modified. Pending data for DAC

// DAC memory mapped Registers
reg [11:0] DACData = 0;       // data written to DAC. Exposed through memory mapped location
reg [11:0] DACBufferData = 0; // buffered data to be written to DAC
reg        DACFlag = 1;       // set to 1 after ACK from DAC, to '0' after NACK
reg        DACBusy = 0;       // DAC driver is busy sending data, controlled by main i2c controller


//breakpoint memory, added by Tong Li JUNE 2018
reg   bp_mem_ram [0:`MEM_SIZE]; // breakpoint ram for main memory
reg   bp_io_ram [0:`IO_SIZE];   // breakpoint ram for memory mapped IO
reg   WEnCPU_bp = 0;   					// breakpoint enable signal for CPU write
reg   WEnCPU_bp_data;        		// breakpoint data in WEnCPU_bp 


reg [15:0]  mem_read_data_cpu;        // cpu ram read port
reg [15:0]  mem_read_data_ackie;      // ackie ram read port
reg [15:0]  mem_read_data_io_cpu;     // cpu io read port
reg [15:0]  mem_read_data_io_ackie;   // ackie io read port

reg   WEnAckie_bp_mem;  					// ackie write enable signal for breakpoint ram, used for main memory
reg   WEnAckie_bp_io;        			// ackie write enable signal for breakpoint ram, used for memory mapped io
reg   WEnCPU_bp_mem;							// CPU write enable signal for breakpoint ram, used for main memory 
reg   WEnCPU_bp_io;								// CPU write enable signal for breakpoint ram, used for memory mapped io

reg   bp_mem_read_data_ackie;			// ackie read port for breakpoint ram, used for main memory
reg   bp_mem_read_data_io_ackie;	// ackie read port for breakpoint ram, used for memory mapped io
reg   bp_mem_read_data_cpu;				// cpu read port for breakpoint ram, used for main memory
reg   bp_mem_read_data_io_cpu;		// cpu read port for breakpoint ram, used for memory mapped io

// RAM R/W control
always @ (negedge Clk) // Done to make SRAM look like asynchronous RAM, makes simulation work
 begin
    if(WEnCPU_mem)  mem[address_mem_cpu] <= write_data_cpu; // Write cpu data to RAM array
    mem_read_data_cpu <= mem[address_mem_cpu];   // CPU reads from RAM
    if(WEnAckie_mem) mem[address_mem_ackie] <= write_data_ackie; // Write ackie data to RAM array
    mem_read_data_ackie <= mem[address_mem_ackie];   // Ackie reads from RAM
 end

// I/O memory R/W control, similar to RAM R/W
always @ (negedge Clk)
 begin
    if(WEnCPU_io)  io[address_io_cpu] <= write_data_cpu; // Write cpu data to io array
    mem_read_data_io_cpu <= io[address_io_cpu];  // cpu read from io memory
    if(WEnAckie_io) io[address_io_ackie] <= write_data_ackie; // Write ackie data to io array
    mem_read_data_io_ackie <= io[address_io_ackie];  // ackie read from io memory
 end


//Synchronous dual port RAM for breakpoint data only, R/W control for main memory.
always @(negedge Clk)
  begin 
    if(WEnAckie_bp_mem) bp_mem_ram[breakpoint_mem_adr] <= bp_mem_data_ackie_write;   	// Ackie writes breakpoint location into breakpint memory 
    bp_mem_read_data_ackie <= bp_mem_ram[breakpoint_mem_adr];                         // Ackie reads breakpoint location to display in perentie from breakpoint memory
    if(WEnCPU_bp_mem) bp_mem_ram[address_cpu] <= WEnCPU_bp_data;            					// Write never set for this port, required to trick synthesis to produce dual port RAM
    bp_mem_read_data_cpu <= bp_mem_ram[address_cpu];                                  // Indicates when the CPU's PC points at an address where a breakpoint is set  - Ackie should stop CPU clock
  end  


//Synchronous dual port RAM for breakpoint data only, R/W control for memory mapped io.
always @(negedge Clk)
  begin
    if(WEnAckie_bp_io) bp_io_ram[breakpoint_mem_adr[7:0]] <= bp_mem_data_ackie_write; // Ackie writes breakpoint location into breakpint memory  
    bp_mem_read_data_io_ackie <= bp_io_ram[breakpoint_mem_adr[7:0]];                  // Ackie reads breakpoint location to display in perentie from breakpoint memory
    if(WEnCPU_bp_io) bp_io_ram[address_cpu[7:0]] <= WEnCPU_bp_data;          					// Write never set for this port, required to trick synthesis to produce dual port RAM
    bp_mem_read_data_io_cpu <= bp_io_ram[address_cpu[7:0]];                           // Indicates when the CPU's PC points at an address where a breakpoint is set  - Ackie should stop CPU clock
  end


// Ackie write enable signal for breakpoint main memory and breakpoint memory mapped io.
always@(*)
 begin
  casex(breakpoint_mem_adr[15:8])
   8'h0? :  begin
              WEnAckie_bp_mem = WEnAckie_bp;
              WEnAckie_bp_io = 0;
            end
   8'h1? :  begin
              WEnAckie_bp_mem = WEnAckie_bp;
              WEnAckie_bp_io = 0;
            end 
   8'hFF :  begin 
              WEnAckie_bp_mem = 0;
              WEnAckie_bp_io = WEnAckie_bp;
            end 
   default :begin  
   						WEnAckie_bp_mem = 0;  
              WEnAckie_bp_io = 0;
            end        
  endcase
 end

// CPU write enable signal for breakpoint main memory and breakpoint memory mapped io.
always@(*)
 begin
  casex(address_cpu[15:8])
   8'h0? :  begin
              WEnCPU_bp_mem = WEnCPU_bp;
              WEnCPU_bp_io = 0;
            end 
   8'h1? :  begin 
              WEnCPU_bp_mem = WEnCPU_bp;
              WEnCPU_bp_io = 0;
            end 
   8'hFF :  begin 
              WEnCPU_bp_mem = 0;
              WEnCPU_bp_io = WEnCPU_bp;
            end
   default :begin
   						WEnCPU_bp_mem = 0;   
              WEnCPU_bp_io = 0;
            end      
  endcase
 end


// CPU read breakpoint memory port, used to read breakpoint signal to stop CPU clock.
always@(*)
 begin
  casex(address_cpu[15:8])
   8'h0? : bp_mem_detected = bp_mem_read_data_cpu;   			//CPU reads from breakpoint ram for main memory . 
   8'h1? : bp_mem_detected = bp_mem_read_data_cpu;
   8'hFF : bp_mem_detected = bp_mem_read_data_io_cpu;    	//CPU reads from breakpoint ram for io memory .   
   default : bp_mem_detected = 0;
  endcase
 end

// Ackie read breakpoint memory port, used to display in perentie from breakpoint memory
always@(*)
 begin
  casex(breakpoint_mem_adr[15:8])
   8'h0? : bp_mem_data_ackie_read = bp_mem_read_data_ackie; 		// Ackie reads from breakpoint ram for main memory.
   8'h1? : bp_mem_data_ackie_read = bp_mem_read_data_ackie;
   8'hFF : bp_mem_data_ackie_read = bp_mem_read_data_io_ackie;  // Ackie reads from breakpoint ram for io memory.    
   default : bp_mem_data_ackie_read = 0;
  endcase
 end



// Address decoders for ram and IO
always @(*)
 begin
  address_mem_cpu = address_cpu[15:0];
  address_mem_ackie = address_ackie[15:0];
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
  if((WEnCPU) & ((address_cpu[15:12] == 4'h0) | (address_cpu[15:12] == 4'h1)))
   WEnCPU_mem = 1;
  else
   WEnCPU_mem = 0;
  if((WEnAckie) & ((address_ackie[15:12] == 4'h0) | (address_ackie[15:12] == 4'h1)))
   WEnAckie_mem = 1;
  else
   WEnAckie_mem = 0;
 end

// Write enables for IO memory
always @(*)
 begin
  if((WEnCPU) & (address_cpu[15:8] == 8'hFF))
   WEnCPU_io = 1;
  else
   WEnCPU_io = 0;
  if((WEnAckie) & (address_ackie[15:8] == 8'hFF))
   WEnAckie_io = 1;
  else
   WEnAckie_io = 0;
 end

// CPU read memory port
always@(*)
 begin
  casex(address_cpu[15:8])
   8'h0? : read_data_cpu = mem_read_data_cpu; // from main RAM
   8'h1? : read_data_cpu = mem_read_data_cpu;
   8'hFF :                                    // from io memory
    begin
     case(address_cpu[7:0])
      8'h90 : read_data_cpu = s6_leds;
      8'h91 : read_data_cpu = {s6_button1, s6_button0};
      8'h92 : read_data_cpu = buzzer;
      8'h93 : read_data_cpu = buzzer_busy;
      8'h94 : read_data_cpu = keypad;
      8'h95 : read_data_cpu = sw_keys;
      8'h96 : read_data_cpu = shaker;
      8'h97 : read_data_cpu = sw_led;
      8'h98 : read_data_cpu = {RTCAck[0], RTCSeconds};
      8'h99 : read_data_cpu = {RTCAck[1], RTCMinutes};
      8'h9A : read_data_cpu = {RTCAck[2], RTCHours};
      8'h9B : read_data_cpu = {RTCAck[3], RTCDay};
      8'h9C : read_data_cpu = {RTCAck[4], RTCDate};
      8'h9D : read_data_cpu = {RTCAck[5], RTCMonth};
      8'h9E : read_data_cpu = {RTCAck[6], RTCYear};
      8'h9F : read_data_cpu = {RTCBusy, RTCAckRead, RTCRead};
      8'hA0 : read_data_cpu = ADCData;
      8'hA1 : read_data_cpu = {ADCAck, ADCBusy, ADCReadEn};
      8'hA2 : read_data_cpu = DACData;
      8'hA3 : read_data_cpu = {DACFlag, DACBusy};
      8'hA4 : read_data_cpu = free_run_counter;
      default : read_data_cpu = mem_read_data_io_cpu;
     endcase
    end
   default : read_data_cpu = 0;
  endcase
 end

// Ackie read memory port
always@(*)
 begin
  casex(address_ackie[15:8])
   8'h0? : read_data_ackie = mem_read_data_ackie; // from main Ram
   8'h1? : read_data_ackie = mem_read_data_ackie;
   8'hFF :                                        // from IO memory
    begin
     case(address_ackie[7:0])
      8'h90 : read_data_ackie = s6_leds;
      8'h91 : read_data_ackie = {s6_button1, s6_button0};
      8'h92 : read_data_ackie = buzzer;
      8'h93 : read_data_ackie = buzzer_busy;
      8'h94 : read_data_ackie = keypad;
      8'h95 : read_data_ackie = sw_keys;
      8'h96 : read_data_ackie = shaker;
      8'h97 : read_data_ackie = sw_led;
      8'h98 : read_data_ackie = {RTCAck[0], RTCSeconds};
      8'h99 : read_data_ackie = {RTCAck[1], RTCMinutes};
      8'h9A : read_data_ackie = {RTCAck[2], RTCHours};
      8'h9B : read_data_ackie = {RTCAck[3], RTCDay};
      8'h9C : read_data_ackie = {RTCAck[4], RTCDate};
      8'h9D : read_data_ackie = {RTCAck[5], RTCMonth};
      8'h9E : read_data_ackie = {RTCAck[6], RTCYear};
      8'h9F : read_data_ackie = {RTCBusy, RTCAckRead, RTCRead};
      8'hA0 : read_data_ackie = ADCData;
      8'hA1 : read_data_ackie = {ADCAck, ADCBusy, ADCReadEn};
      8'hA2 : read_data_ackie = DACData;
      8'hA3 : read_data_ackie = {DACFlag, DACBusy};
      8'hA4 : read_data_ackie = free_run_counter;
      default : read_data_ackie = mem_read_data_io_ackie;
     endcase
    end
   default : read_data_ackie = 0;
  endcase
 end

// Write address decoder for memory mapped peripherals
// Ackie(WEnAckie) takes preference for writes to same address of CPU(WEnCPU)
always @(posedge Clk)
 begin
  if(WEnAckie & address_ackie[15])
   case(address_ackie[7:0])
    8'h90 : s6_leds <= write_data_ackie[3:0];
    8'h96 : shaker <= write_data_ackie[0];
    8'h97 : sw_led <= write_data_ackie[7:0];
    8'h98 : RTCBufferSeconds <= {1'b0, write_data_ackie[6:0]}; // if RTCREAD write it else write RTCBufferseconds
    8'h99 : RTCBufferMinutes <= write_data_ackie[7:0];
    8'h9A : RTCBufferHours <= write_data_ackie[7:0];
    8'h9B : RTCBufferDay <= write_data_ackie[7:0];
    8'h9C : RTCBufferDate <= write_data_ackie[7:0];
    8'h9D : RTCBufferMonth <= write_data_ackie[7:0];
    8'h9E : RTCBufferYear <= write_data_ackie[7:0];
    8'h9F : RTCRead <= write_data_ackie[0];
    8'hA1 : ADCReadEn <= write_data_ackie[0];
    8'hA2 : DACBufferData <= write_data_ackie[11:0];
   endcase
  if(WEnCPU & address_cpu[15])
   if((WEnAckie == 0) | (address_cpu != address_ackie)) // Just make sure that Ackie(WEnAckie) is not trying to write to same peripheral
    case(address_cpu[7:0])
     8'h90 : s6_leds <= write_data_cpu[3:0];
     8'h96 : shaker <= write_data_cpu[0];
     8'h97 : sw_led <= write_data_cpu[7:0];
     8'h98 : RTCBufferSeconds <= {1'b0, write_data_cpu[6:0]};
     8'h99 : RTCBufferMinutes <= write_data_cpu[7:0];
     8'h9A : RTCBufferHours <= write_data_cpu[7:0];
     8'h9B : RTCBufferDay <= write_data_cpu[7:0];
     8'h9C : RTCBufferDate <= write_data_cpu[7:0];
     8'h9D : RTCBufferMonth <= write_data_cpu[7:0];
     8'h9E : RTCBufferYear <= write_data_cpu[7:0];
     8'h9F : RTCRead <= write_data_cpu[0];
     8'hA1 : ADCReadEn <= write_data_cpu[0];
     8'hA2 : DACBufferData <= write_data_cpu[11:0];
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


// Buzzer driver

// Note definitions for use by the buzzer device driver
// Define the lowest octave of notes as the number of system clock cycles, given an 8MHz clock
`define   C4  30578
`define   C4_s  29304
`define   D4  28030
`define   D4_s  26756
`define   E4  25482
`define   F4  24208
`define   F4_s  22934
`define   G4  21659
`define   G4_s  20385
`define   A5  19111
`define   A5_s  17837
`define   B5  16563

// Define buzzer duration time step, 1/10 second at 8MHz clock
`define   buzzer_time_step 800_000

// Address decoder for buzzer
always @(posedge Clk)
 if((WEnAckie_io) & (address_io_ackie == 8'h92)) //Ackie write to buzzer
  begin
   buzzer <= write_data_ackie;
   buzzer_run <= 1; // Let the rest of the buzzer system know that the buzzer register has been written to
  end
 else if((WEnCPU_io) & (address_io_cpu == 8'h92)) // CPU write to buzzer
  begin
   buzzer <= write_data_cpu;
   buzzer_run <= 1; // Let the rest of the buzzer system know that the buzzer register has been written to
  end
 else
  buzzer_run <= 0;

// buzzer duration timer
always @(posedge Clk)
 // Check that buzzer should be run in program mode and a valid duration
 if((buzzer_run == 1) & (buzzer[11:8] != 0) & (buzzer[15] == 1))
  begin
   buzzer_busy <= 1; // Indicate that the buzzer is running
  end
 else if(buzzer_busy)
  begin
   if(buzzer_time_step_count == buzzer[11:8]) // End of buzzer duration
    begin
     // Reset buzzer duration registers
     buzzer_clk_count <= 0;
     buzzer_time_step_count <= 0;
     buzzer_busy <= 0;
    end
   else if(buzzer_clk_count == `buzzer_time_step) // Increment buzzer time step
    begin
     buzzer_time_step_count <= buzzer_time_step_count + 1;
     buzzer_clk_count <= 0;
    end
   else
    buzzer_clk_count <= buzzer_clk_count + 1; // Keep count clock cycles to produce time delay
  end

// buzzer pulse generator
always @(posedge Clk)
  if(buzzer[15] == 0)          // Check for bypass mode
    buzzer_pulses <= buzzer[0]; // LSB drive buzzer directly in bypass mode
  else if(buzzer_busy == 0)    // Finished note, turn off buzzer
   begin
    buzzer_pulses <= 0;
    buzzer_note_count <= 0;
   end
  else if(buzzer_busy == 1)           // If buzzer is running in program mode
    if(buzzer_note_count == buzzer_octave_and_note)     // Finished a cycle of note - start repeating
     begin
      buzzer_pulses <= 0;
      buzzer_note_count <= 0;
    end
  else if(buzzer_note_count == buzzer_octave_and_note[15:1]) // Half cycle of buzzer note - toggle buzzer line
   begin
    buzzer_pulses <= 1;
    buzzer_note_count <= buzzer_note_count + 1;
   end
  else
   begin
    buzzer_note_count <= buzzer_note_count + 1; // Keep counting clock cycles for buzzer note calculation
   end
  else
    buzzer_pulses <= 0; // Buzzer not in bypass and finished in program mode - stop sending pulses to buzzer device

// buzzer note selector, uses [3:0] bits of buzzer register located at 'hFFD
always @(*)
 case(buzzer[3:0])
  0  : buzzer_note = `C4;
  1  : buzzer_note = `C4_s;
  2  : buzzer_note = `D4;
  3  : buzzer_note = `D4_s;
  4  : buzzer_note = `E4;
  5  : buzzer_note = `F4;
  6  : buzzer_note = `F4_s;
  7  : buzzer_note = `G4;
  8  : buzzer_note = `G4_s;
  9  : buzzer_note = `A5;
  10 : buzzer_note = `A5_s;
  11 : buzzer_note = `B5;
  default : buzzer_note = `C4;
 endcase

// buzzer octave selector, uses [7:4] bits of buzzer register located at 'hFFD
always @(*)
 case(buzzer[7:4])
  0         : buzzer_octave_and_note = 0; // used for generating silent pause of given duration
  1,2,3,4   : buzzer_octave_and_note = buzzer_note;       // Lowest octave select, no need to divide "note" delay down and change octave
  5         : buzzer_octave_and_note = {1'b0, buzzer_note[15:1]}; // divide by 2 to select octave 5
  6         : buzzer_octave_and_note = {2'b00,buzzer_note[15:2]}; // divide by 4 to select octave 6
  7         : buzzer_octave_and_note = {3'b000,buzzer_note[15:3]};  // divide by 8 to select octave 7
  8         : buzzer_octave_and_note = {4'b0000,buzzer_note[15:4]}; // divide by 16 to select octave 8
  9         : buzzer_octave_and_note = {5'b0000_0,buzzer_note[15:5]}; // divide by 32 to select octave 9
  default   : buzzer_octave_and_note = 0; // defaults to case 0
 endcase


// free running counter
always @(posedge Clk) begin
    if (free_run_counter_delay == 7) begin
        free_run_counter <= free_run_counter + 1;
        free_run_counter_delay <= 0;
    end
    else
        free_run_counter_delay <= free_run_counter_delay + 1;
end


// Keypad / Switches Driver
always @(posedge Clk) begin
    // By default all key columns are high. Key Rows are scanned in turn by
    // setting each one to low. Then the columns are read. A column with
    // low value means the key is pressed.
    // Fpga clock is too fast for the key values to settle through the 10k
    // pull up resistors at keypresses. A slower key row scan rate is required
    if (keyrow_scan_delay == 7) begin // scan at 1MHz (8 times slower then system clock)
        key_row <= {key_row[2:0], key_row[3]}; // shift the row that is set low
        keyrow_scan_delay <= 0;
    end
    else
        keyrow_scan_delay <= keyrow_scan_delay + 1;

    // Mappings between each row/col position and register bits
    // When a key is pressed then the column value read goes low, but we wish
    // that the value in the mapped register is high. So we invert the value read.
    case(key_row)
        4'b1110 :  begin // scan 1st row
            keypad[1] <= ~key_col[0];   // key '1'
            keypad[2] <= ~key_col[1];   // key '2'
            keypad[3] <= ~key_col[2];   // key '3'
            sw_keys[4] <= ~key_col[3];  // SW-E Switch
            sw_keys[7] <= ~key_col[4];  // SW-H Switch
        end
        4'b1101 :  begin // scan 2nd row
            keypad[4] <= ~key_col[0];   // key '4'
            keypad[5] <= ~key_col[1];   // key '5'
            keypad[6] <= ~key_col[2];   // key '6'
            sw_keys[5] <= ~key_col[3];  // SW-F Switch
            sw_keys[0] <= ~key_col[4];  // SW-A Switch
        end
        4'b1011 :  begin // scan 3d row
            keypad[7] <= ~key_col[0];   // key '7'
            keypad[8] <= ~key_col[1];   // key '8'
            keypad[9] <= ~key_col[2];   // key '9'
            sw_keys[6] <= ~key_col[3];  // SW-G Switch
            sw_keys[1] <= ~key_col[4];  // SW-B Switch
        end
        4'b0111 :  begin // scan 4th row
            keypad[10] <= ~key_col[0];  // key '*'
            keypad[0] <= ~key_col[1];   // key '0'
            keypad[11] <= ~key_col[2];  // key '#'
            sw_keys[3] <= ~key_col[3];  // SW-D Switch
            sw_keys[2] <= ~key_col[4];  // SW-C Switch
        end
    endcase // key_row
end // Keypad / Switches Driver


// I2C MAIN CONTROLLER
always @(posedge Clk)
 begin

  // First set up control signals and flags depending on memory updates by user
  // When an i2c memory mapped location is updated by CPU or Ackie set an
  // internal Write Enable flag showing that there are updated data,
  // stored in separate buffer register(s), that need to be written to RTC/DAC.
  // Also set a busy flag to show that device is busy
  // The Write Enable flag will be cleared once the driver responsible to write
  // the data gains access to the bus
  // The busy flag will be cleared when the driver completes the write operation
  if(WEnCPU_io) // written by CPU
    case(address_io_cpu)
      8'h98 : begin RTCWEn[0] <= 1; RTCBusy <= 1; end
      8'h99 : begin RTCWEn[1] <= 1; RTCBusy <= 1; end
      8'h9A : begin RTCWEn[2] <= 1; RTCBusy <= 1; end
      8'h9B : begin RTCWEn[3] <= 1; RTCBusy <= 1; end
      8'h9C : begin RTCWEn[4] <= 1; RTCBusy <= 1; end
      8'h9D : begin RTCWEn[5] <= 1; RTCBusy <= 1; end
      8'h9E : begin RTCWEn[6] <= 1; RTCBusy <= 1; end
      8'hA2 : begin DACWEn <= 1; DACBusy <= 1; end
    endcase
  if(WEnAckie_io) // written by Ackie
    case(address_io_ackie)
      8'h98 : begin RTCWEn[0] <= 1; RTCBusy <= 1; end
      8'h99 : begin RTCWEn[1] <= 1; RTCBusy <= 1; end
      8'h9A : begin RTCWEn[2] <= 1; RTCBusy <= 1; end
      8'h9B : begin RTCWEn[3] <= 1; RTCBusy <= 1; end
      8'h9C : begin RTCWEn[4] <= 1; RTCBusy <= 1; end
      8'h9D : begin RTCWEn[5] <= 1; RTCBusy <= 1; end
      8'h9E : begin RTCWEn[6] <= 1; RTCBusy <= 1; end
      8'hA2 : begin DACWEn <= 1; DACBusy <= 1; end
    endcase

  // When Read Enable signals are set by user to read ADC or RTC, activate the
  // relevant internal read enable or visible busy signals
  if(ADCReadEn) ADCBusy <= 1;
  if(RTCRead) begin RTCBusy <= 1; rtc_in_read_en <= 1; end

  // The i2c main controller FSM decides what driver/device has access to I2C bus,
  // controls drivers' delay FSMs counters to generate clock, and clears the
  // signals/flags setup above when an operation has finished
  // Follows Round-Robin algorithm
  // If there is nothing to read/write to/from a device, the next driver gets access
  case(i2c_state)
    0 : // RTC READ
     begin
      if(rtc_in_read_en) // only proceed if a RTC read enable internal signal is active
       begin
        i2c_scl <= rtc_in_scl;
        i2c_sda <= rtc_in_sda;

        // Control driver's delay FSM(for generating clock)
        if(rtc_in_count == 24) // FSM delay shows 1 bit transfer cycle is done
         begin
          rtc_in_count <= 0;    // reset delay counter to start the next bit cycle
          if(rtc_in_state == 0) // if the RTC READ state FSM has returned to initial state
           begin                // the whole RTC Read operation is done
            rtc_in_read_en <= 0;// clear internal read enable signal
            RTCBusy <= 0;       // clear visible busy flag
            i2c_state <= 1;     // give bus access to next device
           end
         end
        else // in the middle of 1 bit transfer cycle
          rtc_in_count <= rtc_in_count + 1; // increment delay FSM
       end
      else // no RTC read is requested or is in progress
        i2c_state <= 1; // give bus access to next device
     end // RTC READ

    1 : // RTC WRITE
     begin
      i2c_scl <= rtc_out_scl;
      i2c_sda <= rtc_out_sda;

      // Control driver's delay FSM(for generating clock)
      if(rtc_out_count == 0 & rtc_out_state == 0) // device is idle: check for pending write requests
        // if a pending request found for a register clear its internal WEn flag,
        // load register data and increment the delay FSM counter to start the write operation
        // Note: if a write fails there are no retries(WEn is cleared at the beginning of operation)
        if(RTCWEn[0]) begin rtc_out_reg <= 0; rtc_out_value <= RTCBufferSeconds; RTCWEn[0] <= 0; rtc_out_count <= rtc_out_count
 + 1; end
        else if(RTCWEn[1]) begin rtc_out_reg <= 1; rtc_out_value <= RTCBufferMinutes; RTCWEn[1] <= 0; rtc_out_count <= rtc_out_count + 1; end
        else if(RTCWEn[2]) begin rtc_out_reg <= 2; rtc_out_value <= RTCBufferHours; RTCWEn[2] <= 0; rtc_out_count <= rtc_out_count + 1; end
        else if(RTCWEn[3]) begin rtc_out_reg <= 3; rtc_out_value <= RTCBufferDay; RTCWEn[3] <= 0; rtc_out_count <= rtc_out_count + 1; end
        else if(RTCWEn[4]) begin rtc_out_reg <= 4; rtc_out_value <= RTCBufferDate; RTCWEn[4] <= 0; rtc_out_count <= rtc_out_count + 1; end
        else if(RTCWEn[5]) begin rtc_out_reg <= 5; rtc_out_value <= RTCBufferMonth; RTCWEn[5] <= 0; rtc_out_count <= rtc_out_count + 1; end
        else if(RTCWEn[6]) begin rtc_out_reg <= 6; rtc_out_value <= RTCBufferYear; RTCWEn[6] <= 0; rtc_out_count <= rtc_out_count + 1; end
        else begin RTCBusy <= 0; i2c_state <= 2; end // no pending write requests, give bus to next device
      else if(rtc_out_count == 24) // device not idle but FSM delay shows 1 bit transfer cycle is done
       begin
        rtc_out_count <= 0; // reset delay counter to start the next bit cycle
        if(rtc_out_state == 0 & RTCWEn == 0) // if the RTC WRITE state FSM has returned to initial state
         begin                               // and no other registers are pending to be written
          RTCBusy <= 0;     // clear visible Busy flag
          i2c_state <= 2;   // give bus access to next device
         end
       end
      else // device not idle, device in the middle of 1 bit transfer cycle
        rtc_out_count <= rtc_out_count + 1; // increment delay FSM
     end // RTC WRITE

    2 : // ADC Read
     begin
      if(ADCBusy) // only proceed if an ADC read request was flagged
       begin
        i2c_sda <= adc_sda;
        i2c_scl <= adc_scl;

        // Control driver's delay FSM(for generating clock)
        if(adc_count == 24) // FSM delay shows 1 bit transfer cycle is done
         begin
          adc_count <= 0;    // reset delay counter to start the next bit cycle
          if(adc_state == 0) // if the ADC state FSM has returned to initial state
           begin             // the whole ADC Read operation is done
            ADCBusy <= 0;    // clear ADC busy flag
            i2c_state <= 3;  // and give access to next device
           end
         end
        else // in the middle of 1 bit transfer cycle
          adc_count <= adc_count + 1; // increment delay FSM
       end
      else // if no ADC read is requested
        i2c_state <= 3; // give bus access to next device
     end // ADC Read

    3 : // DAC Write
     begin
        i2c_sda <= dac_sda;
        i2c_scl <= dac_scl;

        // Control driver's delay FSM(for generating clock)
        if(dac_count == 0 & dac_state == 0) // device is idle: check for pending write requests
          if(DACWEn)        // if pending write request exists for the DAC
           begin
            DACWEn <= 0; // clear internal WEn flag that data write is pending
            dac_count <= dac_count + 1; // increment the delay FSM counter to start the write operation
           end           // Note: if a write fails there are no retries(WEn is cleared at the beginning of operation)
          else           // no pending write requests
           i2c_state <= 0; // give bus access to next device
        else if(dac_count == 24) // device not idle but FSM delay shows 1 bit transfer cycle is done
         begin
          dac_count <= 0; // reset delay counter to start the next bit cycle
          if(dac_state == 0) // if the DAC state FSM has returned to initial state
           begin             // the whole write operation is done
            DACBusy <= 0;    // clear DAC busy flag
            i2c_state <= 0;  // give bus access to next device
           end
         end
        else // device not idle, device in the middle of 1 bit transfer cycle
          dac_count <= dac_count + 1; // increment delay FSM
     end  // DAC Write

  endcase // i2c_state
 end // I2C MAIN CONTROLLER


// I2C Drivers
  // Each driver/device actually has two FSMs:
  // - A state FSM that depends on the general progress of the transfer operation
  // - A delay FSM with a delay variable(xx_count) used to generate the "clock"
  // and ensure that the state transitions happen in the exact time.
  // I2C Fast Mode is used. This corresponds to a delay of 24 times the
  // system_clock_period for each i2c "clock cycle"(scl=low then scl=high)
  // This is aproximately 333KHz
  // During one "clock cycle" 1 bit is written or read to or from the i2c bus.
  // At each clock cycle the clock starts low, then at _count=10 during write
  // cycles the data bit to be written is registered to the SDA line,
  // at _count=14 the clock goes high, then at _count=18 during read cycles
  // the received data bit is read from the sda line and the clock goes low
  // again. Then at _count=22 depending on current state and possible acknowledge
  // bits received the decisions for the next "clock cycle" are taken and the
  // relevant data and signals are set up. At _count=24 the main i2c controller
  // FSM is responsible to reset the delay the count to zero and decides whether
  // to repeat a clock cycle or give access to the next device/driver

// RTC WRITE DRIVER
always @(posedge Clk)
begin
 if(rtc_out_count == 10)
  case(rtc_out_state)
   // START SEQUENCE
   0 : rtc_out_sda <= 0; // Begin START sequence

   // ADDRESS SENDING
   1 : begin rtc_out_sda <= rtc_out_byte[7]; rtc_out_byte <= rtc_out_byte << 1; end // Send bit of address to sda

   // SEND REGISTER ADDRESS
   3 : begin rtc_out_sda <= rtc_out_byte[7]; rtc_out_byte <= rtc_out_byte << 1; end // Send bit of register to sda

   // WRITING DATA
   5 : begin rtc_out_sda <= rtc_out_byte[7]; rtc_out_byte <= rtc_out_byte << 1; end // Send bit of data

   // STOP SEQUENCE
   7 : rtc_out_sda <= 0; // Prapare SDA to go high

  endcase
 else if(rtc_out_count == 14)
  case(rtc_out_state)
   // START SEQUENCE
   0 : rtc_out_scl <= 0;

   // ADDRESS SENDING
   1 : rtc_out_scl <= 1;
   // GETTING ACK
   2 : rtc_out_scl <= 1;

   // SEND REGISTER ADDRESS
   3 : rtc_out_scl <= 1;
   // GETTING ACK
   4 : rtc_out_scl <= 1;

   // WRITING DATA
   5 : rtc_out_scl <= 1;
   // GETTING ACK
   6 : rtc_out_scl <= 1;

   // STOP SEQUENCE
   7 : rtc_out_scl <= 1;

  endcase
 else if(rtc_out_count == 18)
  case(rtc_out_state)
   // ADDRESS SENDING
   1 : rtc_out_scl <= 0;
   // GETTING ACK
   2 : begin rtc_out_scl <= 0; rtc_out_ack <= sda; end

   // SEND REGISTER ADDRESS
   3 : rtc_out_scl <= 0;
   // GETTING ACK
   4 : begin rtc_out_scl <= 0; rtc_out_ack <= sda; end

   // WRITE DATA
   5 : rtc_out_scl <= 0;
   // GETTING ACK
   6 : begin rtc_out_scl <= 0; rtc_out_ack <= sda; end

   // STOP SEQUENCE
   7: rtc_out_sda <= 1;

  endcase
 else if(rtc_out_count == 22)
  case(rtc_out_state)
   // START SEQUENCE
   0 : begin rtc_out_state <= 1; rtc_out_byte <= 8'b1101_0000; rtc_out_bit_count <= 8'b0000_0001; end // Load address od I2C device to register

   // ADDRESS SENDING
   1 : if(rtc_out_bit_count[7] == 1) begin rtc_out_sda <= 1; rtc_out_state <= 2; end // Release SDA line
       else rtc_out_bit_count <= rtc_out_bit_count << 1; // Increment bit counter
   // GETTING ACK
   2 : begin
       if(rtc_out_ack == 0) rtc_out_state <= 3; // Check if acknowledge was set. If something went wrong begin STOP sequence
       else begin rtc_out_state <= 7; RTCAck[rtc_out_reg] <= 0; end
       rtc_out_byte <= {5'b0000_0, rtc_out_reg}; // Load address of internal RTC register
       rtc_out_bit_count <= 8'b0000_0001;
       end // Load register address and progress to next state

   // SEND REGISTER ADDRESS
   3 : if(rtc_out_bit_count[7] == 1) begin rtc_out_sda <= 1; rtc_out_state <= 4; end // Release SDA line
       else rtc_out_bit_count <= rtc_out_bit_count << 1; // Increment bit counter
   // GETTING ACK
   4 : begin
        if(rtc_out_ack == 0) rtc_out_state <= 5;
        else begin rtc_out_state <= 7; RTCAck[rtc_out_reg] <= 0; end
        rtc_out_byte <= rtc_out_value;
        rtc_out_bit_count <= 8'b0000_0001;
       end

   // WRITE DATA
   5 : if(rtc_out_bit_count[7] == 1) begin rtc_out_sda <= 1; rtc_out_state <= 6; end // Release SDA line
       else rtc_out_bit_count <= rtc_out_bit_count << 1; // Increment bit counter
   // GETTING ACK
   6 : begin
        RTCAck[rtc_out_reg] <= ~rtc_out_ack; // Write acknowledge from RTC to flags register
        rtc_out_state <= 7;
       end

   // STOP SEQUENCE
   7: rtc_out_state <= 0;// Start procedure again

  endcase
end

// RTC READ DRIVER
always @(posedge Clk)
begin
 if(rtc_in_count == 10)
  case(rtc_in_state)
   // START SEQUENCE
   0 : rtc_in_sda <= 0; // Begin START sequence

   // ADDRESS SENDING
   1 : begin rtc_in_sda <= rtc_in_byte[7]; rtc_in_byte <= rtc_in_byte << 1; end // Send bit of address to sda

   // SEND REGISTER ADDRESS
   3 : begin rtc_in_sda <= rtc_in_byte[7]; rtc_in_byte <= rtc_in_byte << 1; end // Send bit of register to sda

   // RESTART
   5 : rtc_in_sda <= 0; // Begin START sequence

   // ADDRESS SENDING
   6 : begin rtc_in_sda <= rtc_in_byte[7]; rtc_in_byte <= rtc_in_byte << 1; end // Send bit of address to sda
   // SEND ACK
   9 : rtc_in_sda <= 0;

   // SEND NACK
   10 : rtc_in_sda <= 1;

   // STOP SEQUENCE
   11 : rtc_in_sda <= 0; // Prapre SDA to going high

  endcase
 else if(rtc_in_count == 14)
  case(rtc_in_state)
   // START SEQUENCE
   0 : rtc_in_scl <= 0; // Continue START sequence

   // ADDRESS SENDING
   1 : rtc_in_scl <= 1;
   // GETTING ACK
   2 : rtc_in_scl <= 1;

   // SEND REGISTER ADDRESS
   3 : rtc_in_scl <= 1;
   // GETTING ACK
   4 : rtc_in_scl <= 1;

   // RESTART
   5 : rtc_in_scl <= 0;

   // SEND REGISTER ADDRESS
   6 : rtc_in_scl <= 1;
   // GETTING ACK
   7 : rtc_in_scl <= 1;

   // BYTE READ
   8 : rtc_in_scl <= 1;
   // SEND ACK
   9 : rtc_in_scl <= 1;

   // SEND NACK
   10 : rtc_in_scl <= 1;

   // STOP SEQUENCE
   11 : rtc_in_scl <= 1;

  endcase
 else if(rtc_in_count == 18)
  case(rtc_in_state)
   // ADDRESS SENDING
   1 : rtc_in_scl <= 0; // Set clock low after sending address
   // GETTING ACK
   2 : begin rtc_in_scl <= 0; rtc_in_ack <= sda; end

   // SEND REGISTER ADDRESS
   3 : rtc_in_scl <= 0;
   // GETTING ACK
   4 : begin rtc_in_scl <= 0; rtc_in_ack <= sda; end

   // SEND REGISTER ADDRESS
   6 : rtc_in_scl <= 0;
   // GETTING ACK
   7 : begin rtc_in_scl <= 0; rtc_in_ack <= sda; end

   // BYTE READ
   8 : begin rtc_in_scl <= 0; rtc_in_byte <= {rtc_in_byte, sda}; end
   // SEND ACK
   9 : rtc_in_scl <= 0;

   // SEND NACK
   10 : rtc_in_scl <= 0;

   // STOP SEQUENCE
   11: rtc_in_sda <= 1;

  endcase
 else if(rtc_in_count == 22)
  case(rtc_in_state)
   // START SEQUENCE
   0 : begin rtc_in_state <= 1; rtc_in_byte <= 8'b1101_0000; rtc_in_bit_count <= 8'b0000_0001; end // Load address of I2C device to output register

   // ADDRESS SENDING
   1 : if(rtc_in_bit_count[7] == 1) begin rtc_in_sda <= 1; rtc_in_state <= 2; end // Release SDA line
       else rtc_in_bit_count <= rtc_in_bit_count << 1; // Increment bit counter
   // GETTING ACK
   2 : begin
        if(rtc_in_ack == 0) rtc_in_state <= 3; // Check the acknowledge if there is no acknowledge go to STOP sequence
        else begin rtc_in_state <= 11; RTCAckRead <= 0; end
        rtc_in_byte <= 8'b0000_0000; // Load addeess of first internal register
        rtc_in_bit_count <= 8'b0000_0001;
       end // Load register address and progress to next state

   // SEND REGISTER ADDRESS
   3 : if(rtc_in_bit_count[7] == 1) begin rtc_in_sda <= 1; rtc_in_state <= 4; end // Release SDA line
       else rtc_in_bit_count <= rtc_in_bit_count << 1; // Increment bit counter
   // GETTING ACK
   4 : begin
        if(rtc_in_ack == 0)
         begin
          rtc_in_byte <= 8'b1101_0001; // Load address of I2C devices (reading mode)
          rtc_in_bit_count <= 8'b0000_0001;
          rtc_in_byte_count <=  0;
          rtc_in_state <= 5;
          rtc_in_scl <= 1; // Preapre for restart
         end
        else begin rtc_in_state <= 11; RTCAckRead <= 0; end
       end

   // RESTART
   5 : rtc_in_state <= 6;

   // ADDRESS SENDING
   6 : if(rtc_in_bit_count[7] == 1) begin rtc_in_sda <= 1; rtc_in_state <= 7; end // Release SDA line
       else rtc_in_bit_count <= rtc_in_bit_count << 1; // Increment bit counter
   // GETTING ACK
   7 : begin
        if(rtc_in_ack == 0) rtc_in_state <= 8;
        else begin  rtc_in_state <= 11; RTCAckRead <= 0; end
        rtc_in_bit_count <= 8'b0000_0001;
       end // Load register address and progress to next state

   // READ BYTE
   8 : begin
        if(rtc_in_bit_count[7] == 1)
        begin
         rtc_in_bit_count <= 8'b0000_0001;
         // Write data from RTC to specific register
         case(rtc_in_byte_count)
          0 : begin RTCSeconds <= rtc_in_byte; rtc_in_byte_count <= 1; rtc_in_state <= 9; end
          1 : begin RTCMinutes <= rtc_in_byte; rtc_in_byte_count <= 2;  rtc_in_state <= 9; end
          2 : begin RTCHours <= rtc_in_byte; rtc_in_byte_count <= 3;  rtc_in_state <= 9; end
          3 : begin RTCDay <= rtc_in_byte; rtc_in_byte_count <= 4;  rtc_in_state <= 9; end
          4 : begin RTCDate <= rtc_in_byte; rtc_in_byte_count <= 5;  rtc_in_state <= 9; end
          5 : begin RTCMonth <= rtc_in_byte; rtc_in_byte_count <= 6;  rtc_in_state <= 9; end
          6 : begin RTCYear <= rtc_in_byte; rtc_in_state <= 10; RTCAckRead <= 1; end
         endcase
        end
        else
         rtc_in_bit_count <= rtc_in_bit_count << 1;
       end
   // SEND ACK
   9 : begin rtc_in_state <= 8; rtc_in_sda <= 1; end

   // SEND NACK
   10 : rtc_in_state <= 11;

   // STOP SEQUENCE
   11: rtc_in_state <= 0;// Start procedure again

  endcase
end


// ADC READ DRIVER
always @(posedge Clk)
 begin
  if(adc_count == 10) // clock is low (except in START SEQUENCE)
    case(adc_state)
      // START SEQUENCE, clock and sda are high
      0 : adc_sda <= 0; // Begin START sequence by driving sda low

      1 : // ADDRESS SENDING
       begin
          adc_sda <= adc_byte[7];     // send the MSBit to sda line
          adc_byte <= adc_byte << 1;  // shift byte register to the next bit
       end // Send bit of address to sda

      // SEND ACK
      4 : adc_sda <= 0; // for ACK drive SDA low

      // SEND NACK
      5 : adc_sda <= 1; // for NACK leave SDA released

      // STOP SEQUENCE, clock is low
      6 : adc_sda <= 0; // drive SDA low now, so when later clock goes high, SDA can also be driven high
    endcase

  else if(adc_count == 14) // drive clock high (except for START sequence)
    case(adc_state)
      // START SEQUENCE, clock is high, sda is low
      0 : adc_scl <= 0; // Continue START sequence, drive clock low

      // ADDRESS SENDING
      1 : adc_scl <= 1;

      // GETTING ACK
      2 : adc_scl <= 1;

      // BYTE READ
      3 : adc_scl <= 1;

      // SEND ACK
      4 : adc_scl <= 1;

      // SEND NACK
      5 : adc_scl <= 1;

      // STOP SEQUENCE
      6 : adc_scl <= 1;
    endcase

  else if(adc_count == 18) // clk is high, drive it low (except for STOP sequence)
    case(adc_state)
      // ADDRESS SENDING
      1 : adc_scl <= 0; // Set clock low after sending address

      // GETTING ACK
      2 : begin adc_scl <= 0; adc_ack <= sda; end // read ack response

      // BYTE READ: shift register and read received bit into LSB position
      3 : begin adc_scl <= 0; adc_byte <= {adc_byte, sda}; end

      // SEND ACK
      4 : adc_scl <= 0;

      // SEND NACK
      5 : adc_scl <= 0;

      // STOP SEQUENCE, clock is kept high while sda is also driven high
      6: adc_sda <= 1;
    endcase

  else if(adc_count == 22) // clock is low (except for STOP sequence)
    case(adc_state)
      0 : // START SEQUENCE is done
       begin
          adc_state <= 1;           // go to ADDRESS SENDING state
          adc_byte <= 8'b1001_1011; // Load address of I2C device to output register
          adc_bit_count <= 8'b0000_0001;  // initialise the bit counter
       end

      1 : // ADDRESS SENDING
        if(adc_bit_count[7] == 1) // check bit counter if all bits are sent
         begin
          adc_sda <= 1;    // release sda line so that slave can send ACK
          adc_state <= 2;  // go to GET ACK state
         end
        else adc_bit_count <= adc_bit_count << 1; // else increment bit counter

      2 : // GETTING ACK
       begin
          // Write Acknowledgement received to memory mapped register
          ADCAck <= ~adc_ack; // In order to be meaningful to programmer invert so that high means Acknowledged
          if(adc_ack == 0)  // Check the acknowledge. 0 means ack received
            adc_state <= 3; // go to READ BYTE state
          else // if there is no acknowledge go to STOP sequence
            adc_state <= 6;
          adc_bit_count <= 8'b0000_0001; // reset bit count for next state
          adc_byte_count <= 0;           // reset bytes count for next state
       end

      3 : // READ BYTE
       begin
          if(adc_bit_count[7] == 1) // check bit counter if all bits are sent
           begin
            adc_bit_count <= 8'b0000_0001; // reset bit count for next byte
            // Write byte read from ADC to memory mapped register
            if(~adc_byte_count) // if this was first byte received
             begin
              ADCData[15:8] <= adc_byte; // write upper byte of ADC data
              adc_byte_count <= 1; // count received byte
              adc_state <= 4; // go to SEND ACK state
             end
            else // this was the second byte received
             begin
              ADCData[7:0] <= adc_byte; // write lower byte of ADC data
              ADCAck <= 1;
              adc_state <= 5;   // end of transmission, go to send NACK
             end
           end
          else  // not all bits are sent, keep reading next bit
           adc_bit_count <= adc_bit_count << 1; // increment bit counter
       end
      // SEND ACK
      4 : begin adc_state <= 3; adc_sda <= 1; end

      // SEND NACK
      5 : adc_state <= 6;  // NACK is sent, start STOP sequence

      // STOP SEQUENCE, clock and sda are high
      6 : adc_state <= 0; // Start procedure again
    endcase
end


// DAC WRITE DRIVER
always @(posedge Clk)
begin
 if(dac_count == 10)
  case(dac_state)
   // START SEQUENCE
   0 : dac_sda <= 0; // Begin START sequence

   // ADDRESS SENDING
   1 : begin dac_sda <= dac_byte[7]; dac_byte <= dac_byte << 1; end // Send bit of address to sda

   // 1st BYTE
   3 : begin dac_sda <= dac_byte[7]; dac_byte <= dac_byte << 1; end // Send bit of register to sda

   // 2nd BYTE
   5 : begin dac_sda <= dac_byte[7]; dac_byte <= dac_byte << 1; end // Send bit of data

   // STOP SEQUENCE
   7 : dac_sda <= 0; // Prapre SDA to go high

  endcase
 else if(dac_count == 14)
  case(dac_state)
   // START SEQUENCE
   0 : dac_scl <= 0;

   // ADDRESS SENDING
   1 : dac_scl <= 1;
   // GETTING ACK
   2 : dac_scl <= 1;

   // 1st BYTE
   3 : dac_scl <= 1;
   // GETTING ACK
   4 : dac_scl <= 1;

   // 2nd BYTE
   5 : dac_scl <= 1;
   // GETTING ACK
   6 : dac_scl <= 1;

   // STOP SEQUENCE
   7 : dac_scl <= 1;

  endcase
 else if(dac_count == 18)
  case(dac_state)
   // ADDRESS SENDING
   1 : dac_scl <= 0;
   // GETTING ACK
   2 : begin dac_scl <= 0; dac_ack <= sda; end

   // 1st BYTE
   3 : dac_scl <= 0;
   // GETTING ACK
   4 : begin dac_scl <= 0; dac_ack <= sda; end

   // 2nd BYTE
   5 : dac_scl <= 0;
   // GETTING ACK
   6 : begin dac_scl <= 0; dac_ack <= sda; end

   // STOP SEQUENCE
   7: dac_sda <= 1;

  endcase
 else if(dac_count == 22)
  case(dac_state)
   // START SEQUENCE
   0 : begin dac_state <= 1; dac_byte <= 8'b1100_0000; dac_bit_count <= 8'b0000_0001; end // Load address od I2C device to register

   // ADDRESS SENDING
   1 : if(dac_bit_count[7] == 1) begin dac_sda <= 1; dac_state <= 2; end // Release SDA line
       else dac_bit_count <= dac_bit_count << 1; // Increment bit counter
   // GETTING ACK
   2 : begin
        if(dac_ack == 0) dac_state <= 3; // Check if acknowledge was set. If something went wrong begin STOP sequence
        else begin dac_state <= 7; DACFlag <= 0; end
        dac_byte <= {4'b0000, DACBufferData[11:8]}; // Load first byte of data
        dac_bit_count <= 8'b0000_0001;
       end // Load register address and progress to next state

   // 1st BYTE
   3 : if(dac_bit_count[7] == 1) begin dac_sda <= 1; dac_state <= 4; end // Release SDA line
       else dac_bit_count <= dac_bit_count << 1; // Increment bit counter
   // GETTING ACK
   4 : begin
        if(dac_ack == 0) dac_state <= 5;
        else begin dac_state <= 7; DACFlag <= 0; end
        dac_byte <= DACBufferData[7:0];
        dac_bit_count <= 8'b0000_0001;
       end

   // 2nd BYTE
   5 : if(dac_bit_count[7] == 1) begin dac_sda <= 1; dac_state <= 6; end // Release SDA line
       else dac_bit_count <= dac_bit_count << 1; // Increment bit counter
   // GETTING ACK
   6 : begin
        if(dac_ack == 0) begin DACData <= DACBufferData; DACFlag <= 1; end
        else DACFlag <= 0;
        dac_state <= 7;
       end

   // STOP SEQUENCE
   7: dac_state <= 0; // Start procedure again

  endcase
end

endmodule
