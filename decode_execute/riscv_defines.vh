
//opcode macros
//funct3 macros
//funct7 macros
//ALU operation macros
//writeback select macros
//immediate type macros
//FFT custom instruction macros
`ifndef RISCV_DEFINES_VH
`define RISCV_DEFINES_VH

// ============================================================
// Basic architectural parameters
// ============================================================
`define XLEN           32
`define REG_ADDR_W     5
`define INSTR_W        32
`define DATA_W         32
`define IMEM_DEPTH     1024
`define DMEM_DEPTH     1024
`define RESET_PC             0
// ============================================================
// RV32I opcodes
// ============================================================
`define OPCODE_OP      7'b0110011   // R-type
`define OPCODE_OP_IMM  7'b0010011   // I-type ALU
`define OPCODE_LOAD    7'b0000011   // LW
`define OPCODE_STORE   7'b0100011   // SW
`define OPCODE_BRANCH  7'b1100011   // BEQ/BNE
`define OPCODE_JAL     7'b1101111   // JAL

// ============================================================
// Custom opcode space for FFT instruction
// custom-0 opcode
// ============================================================
`define OPCODE_FFT     7'b0001011

// ============================================================
// funct3 values
// ============================================================
`define FUNCT3_ADD_SUB 3'b000
`define FUNCT3_XOR     3'b100
`define FUNCT3_OR      3'b110
`define FUNCT3_AND     3'b111

`define FUNCT3_ADDI    3'b000

`define FUNCT3_LW      3'b010
`define FUNCT3_SW      3'b010

`define FUNCT3_BEQ     3'b000
`define FUNCT3_BNE     3'b001

// ============================================================
// funct7 values
// ============================================================
`define FUNCT7_ADD     7'b0000000
`define FUNCT7_SUB     7'b0100000
`define FUNCT7_LOGIC   7'b0000000

// ============================================================
// FFT custom instruction fields
// Example: FFT_BLY rd, rs1, rs2
// ============================================================
`define FUNCT3_FFT_BLY 3'b000
`define FUNCT7_FFT_BLY 7'b0000001

// ============================================================
// ALU operation select
// ============================================================
`define ALU_ADD        4'd0
`define ALU_SUB        4'd1
`define ALU_AND        4'd2
`define ALU_OR         4'd3
`define ALU_XOR        4'd4
`define ALU_PASS       4'd5

// ============================================================
// Writeback select
// ============================================================
`define WB_ALU         2'd0
`define WB_MEM         2'd1
`define WB_PC4         2'd2
`define WB_FFT         2'd3

// ============================================================
// Immediate type select
// ============================================================
`define IMM_I          3'd0
`define IMM_S          3'd1
`define IMM_B          3'd2
`define IMM_J          3'd3
`define IMM_NONE       3'd4

`endif
