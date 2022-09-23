// Name:   mu0_fpga_top
// Author: Igor Wodiany
// Date:   19/07/2016

// Name:   stump_fpga_top
// Author: Paris Mitsides
// Author: Igor Wodiany
// Date:   16/6/2016

// Author: Tong Li
// Date: 25/06/2018

// This is the to view of the whole system
// Connects the CPU to its memory and the peripherals on the board

module mu0_fpga_top (
    input  wire         clk_pad,
    output wire [1:0]   epp_output_pads,
    input  wire [2:0]   epp_input_pads,
    inout  wire [7:0]   epp_data_pads,
    // LED matrix pads
    output wire         green_en_pad,
    output wire         red_en_pad,
    output wire         blue_en_pad,
    output wire         sw_led_en_pad,
    output wire [7:0]   rgb_col_pads,
    output wire [7:0]   rgb_row_pads,
    // LCD display pads
    output wire         lcd_rs_pad,
    output wire         lcd_e_pad,
    output wire         lcd_rw_pad,
    output wire [7:0]   lcd_data_pads
);


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Declarations of internal signals and buses                                 */

wire          clk;
wire          gnd_0;
wire          gnd_1;
wire          gnd_2;

wire          cpu_fetch;
wire          cpu_clk;
wire          cpu_reset;
wire  [3:0]   cc;

wire  [15:0]  acc;
wire  [11:0]  pc;

wire          WEnCPU;
wire  [11:0]  address_cpu;
wire  [15:0]  write_data_cpu;
wire  [15:0]  read_data_cpu;

wire          mem_wen;
wire  [11:0]  mem_addr;
wire  [15:0]  mem_dout;
wire  [15:0]  mem_din;
wire  [15:0]  proc_din;

wire  [7:0]   byte_out;
wire  [7:0]   byte_in;
wire          get;
wire          put;
wire          rts;
wire          rtr;
wire          get_ack;
wire          put_ack;

wire  [7:0]   epp_din;
wire  [7:0]   epp_dout;
wire          epp_astrb; 
wire          epp_dstrb; 
wire          epp_rnw; 
wire          epp_wait;
wire          epp_wr;

// LED Matrix
wire          green_en;
wire          red_en;
wire          blue_en;
wire          sw_led_en;
wire  [7:0]   rgb_col;
wire  [7:0]   rgb_row;

//LCD display
wire          lcd_rs;
wire          lcd_e;
wire          lcd_rw;
wire [7:0]    lcd_data;

wire          bp_mem_write_en;
wire  [15:0]  breakpoint_adr;
wire          bp_mem_data_write;
wire          bp_mem_data_read;
wire          bp_detected;


/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate modules                                                        */


MU0_1 cpu   (.clk           (cpu_clk),
           .rst           (cpu_reset),
           .memory_read   (gnd_0),
           .memory_write  (WEnCPU),
           .address       (address_cpu[11:0]),
           .data_in       (read_data_cpu[15:0]),
           .data_out      (write_data_cpu[15:0]),
           .fetch         (cpu_fetch),
           .acc           (acc),
           .pc            (pc),
           .flags         (cc[1:0])
          );

// 16-bit MUX that chooses between two MU0 registers
assign proc_din = mem_addr[0] ? {4'b0000, pc} : acc;

memory_mu0 memory   (.Clk               (clk),
                     .WEnCPU            (WEnCPU),
                     .address_cpu       (address_cpu[11:0]),
                     .write_data_cpu    (write_data_cpu[15:0]),
                     .read_data_cpu     (read_data_cpu[15:0]),
                     .WEnAckie          (mem_wen),
                     .address_ackie     (mem_addr[11:0]),
                     .write_data_ackie  (mem_dout[15:0]),
                     .read_data_ackie   (mem_din[15:0]),
                     // LED matrix
                     .green_en          (green_en),
                     .red_en            (red_en),
                     .blue_en           (blue_en),
                     .sw_led_en         (sw_led_en),
                     .rgb_col           (rgb_col[7:0]),
                     .rgb_row           (rgb_row[7:0]),
                     //LCD display
                     .lcd_rs            (lcd_rs),
                     .lcd_e             (lcd_e),
                     .lcd_rw            (lcd_rw),
                     .lcd_data          (lcd_data[7:0]),
                     .WEnAckie_bp (bp_mem_write_en),
                     .breakpoint_mem_adr (breakpoint_adr),
                     .bp_mem_data_ackie_write (bp_mem_data_write),
                     .bp_mem_data_ackie_read (bp_mem_data_read),
                     .bp_mem_detected (bp_detected)
                    );

ackie ackie_interface     (.clk       (clk),
                           .byte_out  (byte_in[7:0]),
                           .byte_in   (byte_out[7:0]),
                           .get       (get),
                           .put       (put), 
                           .rts       (rts), 
                           .rtr       (rtr), 
                           .get_ack   (get_ack), 
                           .put_ack   (put_ack),
                           .mem_wen   (mem_wen), 
                           .mem_addr  (mem_addr[11:0]), 
                           .mem_dout  (mem_dout[15:0]), 
                           .mem_din   (mem_din[15:0]),
                           .proc_din  (proc_din[15:0]), 
                           .proc_wen  (gnd_1), 
                           .proc_clk  (cpu_clk),
                           .fetch     (cpu_fetch), 
                           .cc        (cc[3:0]), 
                           .cpu_reset (cpu_reset), 
                           .halted    (gnd_2),
                           .bp_mem_write_en (bp_mem_write_en),
                           .breakpoint_adr (breakpoint_adr),
                           .bp_mem_data_write (bp_mem_data_write),
                           .bp_mem_data_read (bp_mem_data_read),
                           .bp_detected (bp_detected)
                          );

emulated_uart uart (.clk       (clk), 
                    .epp_din   (epp_din[7:0]), 
                    .epp_dout  (epp_dout[7:0]),
                    .epp_astrb (epp_astrb), 
                    .epp_dstrb (epp_dstrb), 
                    .epp_rnw   (epp_rnw), 
                    .epp_wait  (epp_wait), 
                    .byte_out  (byte_out[7:0]),
                    .byte_in   (byte_in[7:0]), 
                    .get       (get), 
                    .put       (put), 
                    .rts       (rts), 
                    .rtr       (rtr), 
                    .get_ack   (get_ack), 
                    .put_ack   (put_ack)
                   );

// Grounds and clock

GND ground_0 (.G (gnd_0));

GND ground_1 (.G (gnd_1));

GND ground_2 (.G (gnd_2));

IBUF clk_buf (.I (clk_pad),
              .O (clk)
             );

// DEPP

OBUF epp_buf_0 (.I (epp_wait),           
                .O (epp_output_pads[0])
               );

IOBUF epp_buf_1 [7:0] (.I  (epp_dout[7:0]),
                       .O  (epp_din[7:0]),
                       .IO (epp_data_pads[7:0]),
                       .T  (epp_wr)
                      );
                    
IBUF epp_buf_2 (.I (epp_input_pads[0]),   
                .O (epp_astrb)
               );

IBUF epp_buf_3 (.I (epp_input_pads[1]),
                .O (epp_dstrb)
               );
             
IBUF epp_buf_4 (.I (epp_input_pads[2]),
                .O (epp_rnw)
               );

INV epp_inv (.I (epp_rnw), 
             .O (epp_wr)
            );


// I/O pads
OBUF matrix_buf_0 (.I (green_en),
                   .O (green_en_pad)
                  );

OBUF matrix_buf_1 (.I (red_en),
                   .O (red_en_pad)
                  );

OBUF matrix_buf_2 (.I (blue_en),
                   .O (blue_en_pad)
                  );

OBUF matrix_buf_3 [7:0] (.I (rgb_col[7:0]),
                         .O (rgb_col_pads[7:0])
                          );

OBUF matrix_buf_4 [7:0] (.I (rgb_row[7:0]),
                         .O (rgb_row_pads[7:0])
                        );

OBUF matrix_buf_5 (.I(sw_led_en),
                   .O(sw_led_en_pad)
                  );

OBUF lcd_buf_0 (.I(lcd_rs),
                .O(lcd_rs_pad)
               );

OBUF lcd_buf_1 (.I(lcd_e),
                .O(lcd_e_pad)
               );

OBUF lcd_buf_2 (.I(lcd_rw),
                .O(lcd_rw_pad)
               );

OBUF lcd_buf_3 [7:0] (.I(lcd_data[7:0]),
                      .O(lcd_data_pads[7:0])
                     );


endmodule

