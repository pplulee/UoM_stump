// Name:   stump_fpga_top
// Author: Paris Mitsides
// Author: Igor Wodiany
// Date:   16/6/2016

// Author: Tong Li
// Date: 25/06/2018

// This is the to view of the whole system
// Connects the CPU to its memory and the peripherals on the board

module stump_fpga_top (input  wire  clk_pad,

                       output wire [1:0] epp_output_pads,
                       input  wire [2:0] epp_input_pads,
                       inout  wire [7:0] epp_data_pads,

                       output wire [3:0] S6_leds_pads,
                       input  wire       S6_btn0_pad,
                       input  wire       S6_btn1_pad,
                       output wire        green_en_pad,
                       output wire        red_en_pad,
                       output wire        blue_en_pad,
                       output wire       sw_led_en_pad,
                       output wire [7:0] rgb_col_pads,
                       output wire [7:0] rgb_row_pads,
                       output wire       lcd_rs_pad,
                       output wire       lcd_e_pad,
                       output wire       lcd_rw_pad,
                       output wire [7:0] lcd_data_pads,

                       output wire       buzzer_pad,

                       output wire       shaker_pad,

                       output wire  [3:0] key_rows_pads,
                       input  wire  [4:0] key_cols_pads,

                       inout  wire        sda_pad,
                       inout  wire        scl_pad
                      );
// Define CPU type to STUMP, override parameters in ackie.
defparam ackie_interface.CPU_TYPE = 8'd3;
defparam ackie_interface.CPU_SUB = 16'd0;
defparam ackie_interface.FEATURE_COUNT = 8'd0;
defparam ackie_interface.MEM_SEGS = 8'd1;
defparam ackie_interface.MEM_START = 32'd0;
defparam ackie_interface.MEM_SIZE = 32'd12;

// Define width of data and address buses(32 bits max)
// Subtracted one from values, because verilog counts from zero
defparam ackie_interface.MEM_ADDR_WIDTH = 8'd15;
defparam ackie_interface.MEM_DATA_WIDTH = 8'd15;
defparam ackie_interface.PROC_DAT_WIDTH = 8'd15;

// Address mapped by perentie to the CPU Flags Register
defparam ackie_interface.PROC_FLAG_ADDR = 4'd8;
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

wire          WEnCPU;
wire  [15:0]  address_cpu;
wire  [15:0]  write_data_cpu;
wire  [15:0]  read_data_cpu;

wire          mem_wen;
wire  [15:0]  mem_addr;
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

wire  [3:0]   S6_leds;
wire          S6_btn0;
wire          S6_btn1;
wire           green_en;
wire           red_en;
wire           blue_en;
wire          sw_led_en;
wire  [7:0]   rgb_col;
wire  [7:0]   rgb_row;

wire          lcd_rs;
wire          lcd_e;
wire          lcd_rw;
wire [7:0]    lcd_data;

wire          buzzer;

wire          shaker;

wire  [3:0]   key_row;
wire  [4:0]   key_col;

wire          sda;
wire          scl;
wire          i2c_sda;
wire          i2c_scl;

wire          bp_mem_write_en;
wire  [15:0]  breakpoint_adr;
wire          bp_mem_data_write;
wire          bp_mem_data_read;
wire          bp_detected;
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
/* Instantiate modules                                                        */


Stump cpu (.clk      (cpu_clk),
           .rst      (cpu_reset),
           .mem_ren  (gnd_0),
           .mem_wen  (WEnCPU),
           .address  (address_cpu[15:0]),
           .data_in  (read_data_cpu[15:0]),
           .data_out (write_data_cpu[15:0]),
           .srcC     (mem_addr[2:0]),
           .regC     (proc_din[15:0]),
           .cc       (cc),
           .fetch    (cpu_fetch)
          );


memory_stump memory (.Clk           (clk),
                     .WEnCPU        (WEnCPU),
                     .address_cpu    (address_cpu[15:0]),
                     .write_data_cpu   (write_data_cpu[15:0]),
                     .read_data_cpu    (read_data_cpu[15:0]),
                     .WEnAckie      (mem_wen),
                     .address_ackie  (mem_addr[15:0]),
                     .write_data_ackie   (mem_dout[15:0]),
                     .read_data_ackie    (mem_din[15:0]),
                     .s6_leds       (S6_leds[3:0]),
                     .s6_button0    (S6_btn0),
                     .s6_button1    (S6_btn1),
                     .green_en      (green_en),
                     .red_en        (red_en),
                     .blue_en       (blue_en),
                     .sw_led_en     (sw_led_en),
                     .rgb_col       (rgb_col[7:0]),
                     .rgb_row       (rgb_row[7:0]),
                     .lcd_rs        (lcd_rs),
                     .lcd_e         (lcd_e),
                     .lcd_rw        (lcd_rw),
                     .lcd_data      (lcd_data[7:0]),
                     .buzzer_pulses (buzzer),
                     .shaker        (shaker),
                     .key_row       (key_row),
                     .key_col       (key_col),
                     .sda           (sda),
                     .scl           (scl),
                     .i2c_sda       (i2c_sda),
                     .i2c_scl       (i2c_scl),
                     .WEnAckie_bp (bp_mem_write_en),
                     .breakpoint_mem_adr (breakpoint_adr),
                     .bp_mem_data_ackie_write (bp_mem_data_write),
                     .bp_mem_data_ackie_read (bp_mem_data_read),
                     .bp_mem_detected (bp_detected)
                    );

ackie ackie_interface (.clk       (clk),
                       .byte_out  (byte_in[7:0]),
                       .byte_in   (byte_out[7:0]),
                       .get       (get),
                       .put       (put), 
                       .rts       (rts), 
                       .rtr       (rtr), 
                       .get_ack   (get_ack), 
                       .put_ack   (put_ack),
                       .mem_wen   (mem_wen), 
                       .mem_addr  (mem_addr[15:0]), 
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

// IO

OBUF led_buf [3:0] (.I (S6_leds[3:0]),
                    .O (S6_leds_pads[3:0])
                   );

IBUF btn_buf_0 (.I (S6_btn0_pad),
                .O (S6_btn0)
               );

IBUF btn_buf_1 (.I (S6_btn1_pad),
                .O (S6_btn1)
               );

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

OBUFT keypad_buf_0  [3:0]  (.I(1'b0),
                            .O(key_rows_pads[3:0]),
                            .T(key_row[3:0])
                           );

IBUF keypad_buf_1  [4:0]  (.I(key_cols_pads[4:0]),
                           .O(key_col[4:0])
                          );

OBUF buzzer_buf_0 (.I(buzzer),
                   .O(buzzer_pad)
                  );

OBUF shaker_buf_0 (.I(shaker),
                   .O(shaker_pad)
                  );

IOBUF sda_buf_0 (.I (1'b0),
                 .O (sda),
                 .IO (sda_pad),
                 .T (i2c_sda)
                );

IOBUF scl_buf_0 (.I (1'b0),
                 .O (scl),
                 .IO (scl_pad),
                 .T (i2c_scl)
                );

endmodule
