ORG 0

B clear_LCD

ORG 1
DATA "Hello!",0
ORG 8
DATA "This is a painting board",0


LCD_start_pos	data 0xff40
LCD_stop_pos	data 0xff8f
clear_LCD
	LD R1, LCD_start_pos
	LD R2, LCD_start_pos
	LD R3, LCD_stop_pos
clear_LCD_loop
	ST R0, [R1]
	ADD R1,R1,#1
	CMP R1,R3
	BLS clear_LCD_loop
	;B clear_matrix
	B write_LCD
str1 DATA 1
str2 DATA 8
str2_start_pos data 0xff54
write_LCD
	LD R1, str1
write_LCD_loop_1
	LD R4, [R1]
	ST R4, [R2]
	ADD R1, R1, #1
	ADD R2, R2, #1
	CMP R4,R0
	BNE write_LCD_loop_1
	LD R1, str2
	LD R2, str2_start_pos
	B write_LCD_loop_2
write_LCD_loop_2
	LD R4, [R1]
	ST R4, [R2]
	ADD R1, R1, #1
	ADD R2, R2, #1
	CMP R4,R0
	BNE write_LCD_loop_2
	B clear_matrix
	

matrix_start_pos 	data 0xff00
matrix_end_pos 	data 0xff3f
default_colour		data 0b11	
clear_matrix
	LD R6, matrix_start_pos ; R6 will be used as pointer
	LD R5, default_colour ; R5 will be used to store colour
	LD R1, matrix_start_pos
  	LD R3, matrix_end_pos
clear_matrix_loop 
	ST R0, [R1]
  	ADD  R1, R1, #1
  	CMP R1, R3
  	BLS clear_matrix_loop
  	B update

set_pos
	MOV R6, R1
	B update
min_matrix_addr defw 0xff00
max_matrix_addr defw 0xff3f
check_range
	LD R1, min_matrix_addr
	CMP R1, R6
	BGE set_pos
	LD R1, max_matrix_addr
	CMP R1,R6
	BLS set_pos
	B update
sw_addr	defw 0xFF95
sw_led		defw 0xFF97
color_blue	defw 0x11
motor_addr defw 0xff96
update	
	LD R1, sw_addr ; check button
	LD R2, [R1]		; load button data
	LD R3, motor_addr
	ST R0, [R4]
	ST R0, [R3]
	ST R0, [R6]
	ST R5, [R6]
	CMP R2, #0
	BEQ cup
	LD R3, sw_led ; switch on/off LED
	ST R2, [R3]
	LD R3, motor_addr
	MOV R4, R0
	ADD R4,R4,#1
	ST R4,[R3]
	B cup
	sw_d defw 0x0008
cup	
	LD R3, sw_d
	CMP R2, R3
	BNE cdown
	SUB R6, R6, #8
	B c_end
	sw_h defw 0x0080
cdown	
	LD R3, sw_h
	CMP R2, R3
	BNE cleft
	ADD R6, R6, #8
	B c_end
	sw_e defw 0x0010
cleft	
	LD R3, sw_e
	CMP R2, R3
	BNE cright
	SUB R6, R6, #1
	B c_end
	sw_g defw 0x0040
cright	
	LD R3, sw_g
	CMP R2, R3
	BNE update_keypad
	ADD R6, R6, #1	
	B c_end

c_end
	LD R2, [R1]
	CMP R2,#0
	BEQ check_range
	;ST R5, [R6]	
	BNE c_end
	
key_pad_addr	defw 0xFF94
update_keypad
	LD R1,key_pad_addr
	LD R1, [R1]
	CMP R1, R0
	BEQ update
	CMP R1, #1
	BEQ clear_matrix
	B check_num_1
	
num_1 defw 0b10
check_num_1
	LD R2, num_1
	CMP R1, R2
	BNE check_num_2
	BEQ colour_green3
green3	DEFW 0b11100
colour_green3
	LD R5, green3
	B update
	
num_2 defw 0b100
check_num_2
	LD R2, num_2
	CMP R1, R2
	BNE check_num_3
	BEQ colour_red3
red3	DEFW 0b111000000
colour_red3
	LD R5, red3
	B update
	
num_3 defw 0b1000
check_num_3
	LD R2, num_3
	CMP R1, R2
	BNE check_num_4
	BEQ colour_blue3
blue3	DEFW 0b11
colour_blue3
	LD R5, blue3
	B update

num_4 defw 0b10000
check_num_4
	LD R2, num_4
	CMP R1, R2
	BNE check_num_5
	BEQ colour_yellow
yellow	DEFW 0b11111100
colour_yellow
	LD R5, yellow
	B update
	
num_5 defw 0b100000
check_num_5
	LD R2, num_5
	CMP R1, R2
	BNE check_num_6
	BEQ colour_pink
pink	DEFW 0b111000011
colour_pink
	LD R5, pink
	B update

num_6 defw 0b1000000
check_num_6
	LD R2, num_6
	CMP R1, R2
	BNE check_num_7
	BEQ colour_cyan
cyan	DEFW 0b11111
colour_cyan
	LD R5, cyan
	B update
	
num_7 defw 0b10000000
check_num_7
	LD R2, num_7
	CMP R1, R2
	BNE check_num_8
	BEQ colour_green1
green1	DEFW 0b100
colour_green1
	LD R5, green1
	B update	

num_8 defw 0b100000000
check_num_8
	LD R2, num_8
	CMP R1, R2
	BNE check_num_9
	BEQ colour_red1
red1	DEFW 0b001000000
colour_red1
	LD R5, red1
	B update
	
num_9 defw 0b1000000000
check_num_9
	LD R2, num_9
	CMP R1, R2
	BNE update
	MOV R5,R0
	B update
