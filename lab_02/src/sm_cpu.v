/*
 * schoolMIPS - small MIPS CPU for "Young Russian Chip Architects" 
 *              summer school ( yrca@googlegroups.com )
 *
 * originally based on Sarah L. Harris MIPS CPU 
 * 
 * Copyright(c) 2017 Stanislav Zhelnio 
 *                   Alexander Romanov 
 */ 

module sm_cpu
(
    input           clk,
    input           rst_n,
    input   [ 4:0]  regAddr,
    output  [31:0]  regData
);
    //control wires
    wire        pcSrc;
    wire        regDst;
    wire        regWrite;
    wire        aluSrc;
    wire        aluZero;
    wire [ 3:0] aluControl;
    wire        jump;

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch;
    wire [31:0] pcJump;
    wire [31:0] pcNext  = pc + 1;
    wire [31:0] pc_new  = ~pcSrc ? pcNext : pcBranch;
    wire [31:0] pc_new1 = ~jump ? pc_new : pcJump;
    sm_register r_pc(clk, rst_n, pc_new1, pc);

    //program memory
    wire [31:0] instr;
    sm_rom reset_rom(pc, instr);

    //debug register access
    wire [31:0] rd0;
    assign regData = (regAddr != 0) ? rd0 : pc;

    //register file
    wire [ 4:0] a3  = regDst ? instr[15:11] : instr[20:16];
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;

    sm_register_file rf
    (
        .clk        ( clk          ),
        .a0         ( regAddr      ),
        .a1         ( instr[25:21] ),
        .a2         ( instr[20:16] ),
        .a3         ( a3           ),
        .rd0        ( rd0          ),
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( wd3          ),
        .we3        ( regWrite     )
    );

    //sign extension
    wire [31:0] signImm = { {16 { instr[15] }}, instr[15:0] };
    assign pcBranch = pcNext + signImm;

    //jump count
    assign pcJump = {pc[31:28], instr[25:0], 2'b00 };

    //alu
    wire [31:0] srcB = aluSrc ? signImm : rd2;

    sm_alu alu
    (
        .srcA       ( rd1          ),
        .srcB       ( srcB         ),
        .oper       ( aluControl   ),
        .shift      ( instr[10:6 ] ),
        .zero       ( aluZero      ),
        .result     ( wd3          ) 
    );

    //control
    sm_control sm_control
    (
        .cmdOper    ( instr[31:26] ),
        .cmdFunk    ( instr[ 5:0 ] ),
        .aluZero    ( aluZero      ),
        .pcSrc      ( pcSrc        ), 
        .regDst     ( regDst       ), 
        .regWrite   ( regWrite     ), 
        .aluSrc     ( aluSrc       ),
        .aluControl ( aluControl   ),
        .jump       ( jump         )
    );

endmodule

module sm_control
(
    input  [5:0] cmdOper,
    input  [5:0] cmdFunk,
    input        aluZero,
    output       pcSrc, 
    output       regDst, 
    output       regWrite, 
    output       aluSrc,
    output [3:0] aluControl,
    output       jump
);
    wire         branch;
    wire         condZero;
    assign pcSrc = branch & (aluZero == condZero);

    // cmdOper values
    localparam  C_SPEC  = 6'b000000, // Special instructions (depends on cmdFunk field)
                C_ADDIU = 6'b001001, // I-type, Integer Add Immediate Unsigned
                                     //         Rd = Rs + Immed
                C_BEQ   = 6'b000100, // I-type, Branch On Equal
                                     //         if (Rs == Rt) PC += (int)offset
                C_LUI   = 6'b001111, // I-type, Load Upper Immediate
                                     //         Rt = Immed << 16
                C_BNE   = 6'b000101, // I-type, Branch on Not Equal
                                     //         if (Rs != Rt) PC += (int)offset
                C_J     = 6'b000010, // JUMP, PC = Immed
                C_ANDI  = 6'b001100; // I-type, AND Immediate
                                     //         Rt = Rs && Immed

    // cmdFunk values
    localparam  F_ADDU  = 6'b100001, // R-type, Integer Add Unsigned
                                     //         Rd = Rs + Rt
                F_OR    = 6'b100101, // R-type, Logical OR
                                     //         Rd = Rs | Rt
                F_SRL   = 6'b000010, // R-type, Shift Right Logical
                                     //         Rd = Rs∅ >> shift
                F_SLTU  = 6'b101011, // R-type, Set on Less Than Unsigned
                                     //         Rd = (Rs∅  < Rt∅) ? 1 : 0
                F_SUBU  = 6'b100011, // R-type, Unsigned Subtract
                                     //         Rd = Rs – Rt
                F_SLL   = 6'b000000, // R-type, Shift Word Logical Left
                                     //         Rd = Rt << shift
                F_SRLV  = 6'b000110, // R-type, Shift Word Logical Right Variable
                                     //         Rd = Rt >> Rs
                F_ANY   = 6'b??????;

    reg    [9:0] conf;
    assign { branch, condZero, regDst, regWrite, aluSrc, aluControl, jump } = conf;

    always @ (*) begin
        casez( {cmdOper,cmdFunk} )
            default             : conf = 10'b00;
            { C_SPEC,  F_ADDU } : conf = 10'b0011000000;
            { C_SPEC,  F_OR   } : conf = 10'b0011000010;
            { C_ADDIU, F_ANY  } : conf = 10'b0001100000;
            { C_BEQ,   F_ANY  } : conf = 10'b1100000000;
            { C_LUI,   F_ANY  } : conf = 10'b0001100100;
            { C_SPEC,  F_SRL  } : conf = 10'b0011000110;
            { C_SPEC,  F_SLTU } : conf = 10'b0011001000;
            { C_BNE,   F_ANY  } : conf = 10'b1000000000;
            { C_SPEC,  F_SUBU } : conf = 10'b0011001010;
            { C_J,     F_ANY  } : conf = 10'b0000000001;
            { C_ANDI,  F_ANY  } : conf = 10'b0001101100;
            { C_SPEC,  F_SLL  } : conf = 10'b0011001110;
            { C_SPEC,  F_SRLV } : conf = 10'b0011010000;
        endcase
    end
endmodule


module sm_alu
(
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 3:0] oper,
    input  [ 4:0] shift,
    output        zero,
    output reg [31:0] result
);
    localparam ALU_ADD  = 4'b0000,
               ALU_OR   = 4'b0001,
               ALU_LUI  = 4'b0010,
               ALU_SRL  = 4'b0011,
               ALU_SLTU = 4'b0100,
               ALU_SUBU = 4'b0101,
               ALU_AND  = 4'b0110,    
               ALU_SLL  = 4'b0111,
               ALU_SRLV = 4'b1000;

    always @ (*) begin
        case (oper)
            default  : result = srcA + srcB;
            ALU_ADD  : result = srcA + srcB;
            ALU_OR   : result = srcA | srcB;
            ALU_LUI  : result = (srcB << 16);
            ALU_SRL  : result = srcB >> shift;
            ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            ALU_SUBU : result = srcA - srcB;
            ALU_AND  : result = srcA & srcB;
            ALU_SLL  : result = srcB << shift;
            ALU_SRLV : result = srcB >> srcA;
        endcase
    end

    assign zero   = (result == 0);
endmodule

module sm_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always @ (posedge clk)
        if(we3) rf [a3] <= wd3;
endmodule
