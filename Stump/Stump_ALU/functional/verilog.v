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

    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/
    /* Verilog code                                                               */
    always @(*) begin
        N = 1'b0;
        Z = 1'b0;
        V = 1'b0;
        C = 1'b0;
        case (func)
            3'b000: //add
                begin
                    result = operand_A+operand_B;
                    if (operand_A[15] == operand_B[15]) begin // same sign
                        if (result[15] != operand_A[15]) begin
                            V = 1'b1;
                        end
                    end
                    C = result[16];
                end
            3'b001: //add with carry
                begin
                    result = operand_A+operand_B+c_in;
                    if (operand_A[15] == operand_B[15]) begin // same sign
                        if (result[15] != operand_A[15]) begin
                            V = 1'b1;
                        end
                    end
                    C = result[16];
                end
            3'b010: //sub
                begin
                    result = operand_A + (~operand_B+1);
                    if (operand_A[15] != operand_B[15]) begin // different sign
                        if (result[15] != operand_A[15]) begin
                            V = 1'b1;
                        end
                    end
                    C = ~result[16];
                end
            3'b011: //sub with carry
                begin
                    result = operand_A + (~operand_B+1)+(~c_in);
                    if (operand_A[15] != operand_B[15]) begin // different sign
                        if (result[15] != operand_A[15]) begin
                            V = 1'b1;
                        end
                    end
                    C = ~result[16];
                end
            3'b100: //and
                begin
                    result = operand_A & operand_B;
					C = csh;
                end
            3'b101: //or
                begin
                    result = operand_A | operand_B;
					C = csh;
                end
            3'b110: //Memory Transfer
                begin
                    result = operand_A;
                end
            3'b111: //branch
                begin
                    result = operand_A;
                end
        endcase
        N = result[15]; // set Negative
        if (result == 0) begin // set Zero
            Z = 1'b1;
        end
        flags_out[3] = C;
        flags_out[2] = V;
        flags_out[1] = Z;
        flags_out[0] = N;
    end


    /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

    /*----------------------------------------------------------------------------*/

endmodule

/*============================================================================*/

