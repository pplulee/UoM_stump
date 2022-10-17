// Stump ALU
// Implement your Stump ALU here
//
// Created by Paul W Nutter, Feb 2015
//
// ** Update this header **
//

`include "Stump/Stump_definitions.v"

// 'include' definitions of function codes etc.
// e.g. can use "`ADD" instead of "'h0" to aid readability
// Substitute your own definitions if you prefer by
// modifying Stump_definitions.v

/*----------------------------------------------------------------------------*/

module Stump_ALU(input wire[15:0] operand_A,        // First operand
    input wire[15:0] operand_B,        // Second operand
    input wire[2:0] func,        // Function specifier
    input wire c_in,        // Carry input
    input wire csh,        // Carry from shifter
    output reg[15:0] result,        // ALU output
    output reg[3:0] flags_out);    // Flags {N, Z, V, C}


    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
    /* Declarations of any internal signals and buses used                        */
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
    reg[16:0] newresult;
    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
    /* Verilog code                                                               */
    always @(*) begin
        flags_out = 4'b0000;
        case (func)
            3'b000: //add
                begin
                    newresult = operand_A+operand_B;
                    result = newresult[15:0];
                    if (operand_A[15] == operand_B[15]) begin // same sign
                        if (result[15] != operand_A[15]) begin
                            flags_out[1] = 1;
                        end
                    end
                    flags_out[0] = newresult[16];
                end
            3'b001: //add with carry
                begin
                    newresult = operand_A+operand_B+c_in;
                    result = newresult[15:0];
                    if (operand_A[15] == operand_B[15]) begin // same sign
                        if (result[15] != operand_A[15]) begin
                            flags_out[1] = 1;
                        end
                    end
                    flags_out[0] = newresult[16];
                end
            3'b010: //sub
                begin
                    newresult = operand_A+(~operand_B+1);
                    result = newresult[15:0];
                    if (operand_A[15] != operand_B[15]) begin // different sign
                        if (result[15] != operand_A[15]) begin
                            flags_out[1] = 1;
                        end
                    end
                    flags_out[0] = newresult[16];
                end
            3'b011: //sub with carry
                begin
                    newresult = operand_A+(~operand_B+1)+(~c_in+1);
                    result = newresult[15:0];
                    if (operand_A[15] != operand_B[15]) begin // different sign
                        if (result[15] != operand_A[15]) begin
                            flags_out[1] = 1;
                        end
                    end
                    flags_out[0] = newresult[16];
                end
            3'b100: //and
                begin
                    result = operand_A & operand_B;
                    flags_out[0] = csh;
                end
            3'b101: //or
                begin
                    result = operand_A | operand_B;
                    flags_out[0] = csh;
                end
            3'b110: //Memory Transfer
                begin
                    result = operand_A+operand_B;
                end
            3'b111: //branch
                begin
                    result = operand_A+operand_B;
                end
            default :
                begin
                    result = 0;
                end
        endcase
        flags_out[3] = result[15];
        if (result == 0) begin // set Zero
            flags_out[2] = 1'b1;
        end
        if (func==3'b110 | func==3'b111 || func==3'bxxx) begin
            flags_out=4'bxxxx;
        end
    end


    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

    /*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/

