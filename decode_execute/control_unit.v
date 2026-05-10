/*
------------------------------------------------------------------------------
File        : control_unit.v
Module      : control_unit
Purpose     : Main decoder + ALU decoder for 3-stage RV32I pipeline
Supported   : ADD, SUB, AND, OR, XOR, LW, SW, BEQ, BNE, JAL, FFTBLY

Decode style:
- Combinational control generation
- Defaults assigned first to avoid latches
- ALU control generated directly from opcode/funct fields
- Custom FFT instruction recognized using:
    opcode = 7'h3B
    funct3 = 3'b000
    funct7 = 7'h01

Outputs:
- reg_write   : register file write enable
- mem_read    : data memory read enable
- mem_write   : data memory write enable
- mem_to_reg  : WB mux select, 1 => memory data, 0 => exec result
- alu_src     : ALU input-B select, 1 => immediate, 0 => rs2 data
- alu_ctrl    : operation code to ALU
- branch      : branch-class instruction present
- branch_ne   : 0 => BEQ, 1 => BNE
- jump        : jump-class instruction present
- fft_en      : select custom FFT datapath in execute stage
- valid_instr : high when opcode/funct combination is supported

Suggested ALU control encoding:
- 4'b0000 : ADD
- 4'b0001 : SUB
- 4'b0010 : AND
- 4'b0011 : OR
- 4'b0100 : XOR
- 4'b0101 : PASS_B   (useful for future ops if needed)
------------------------------------------------------------------------------
*/

module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,

    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       mem_to_reg,
    output reg       alu_src,
    output reg [3:0] alu_ctrl,
    output reg       branch,
    output reg       branch_ne,
    output reg       jump,
    output reg       fft_en,
    output reg       valid_instr
);

    // ------------------------------------------------------------------------
    // Opcode localparams
    // ------------------------------------------------------------------------
    localparam [6:0] OPCODE_RTYPE   = 7'b0110011;
    localparam [6:0] OPCODE_LOAD    = 7'b0000011; // LW
    localparam [6:0] OPCODE_STORE   = 7'b0100011; // SW
    localparam [6:0] OPCODE_BRANCH  = 7'b1100011; // BEQ/BNE
    localparam [6:0] OPCODE_JAL     = 7'b1101111; // JAL
    localparam [6:0] OPCODE_FFT     = 7'b0111011; // custom opcode 0x3B

    // ------------------------------------------------------------------------
    // ALU control localparams
    // ------------------------------------------------------------------------
    localparam [3:0] ALU_ADD    = 4'b0000;
    localparam [3:0] ALU_SUB    = 4'b0001;
    localparam [3:0] ALU_AND    = 4'b0010;
    localparam [3:0] ALU_OR     = 4'b0011;
    localparam [3:0] ALU_XOR    = 4'b0100;
    localparam [3:0] ALU_PASS_B = 4'b0101;

    always @(*) begin
        // --------------------------------------------------------------------
        // Safe defaults
        // --------------------------------------------------------------------
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        alu_src     = 1'b0;
        alu_ctrl    = ALU_ADD;
        branch      = 1'b0;
        branch_ne   = 1'b0;
        jump        = 1'b0;
        fft_en      = 1'b0;
        valid_instr = 1'b0;

        case (opcode)

            // ----------------------------------------------------------------
            // R-type ALU: ADD, SUB, AND, OR, XOR
            // ----------------------------------------------------------------
            OPCODE_RTYPE: begin
                reg_write   = 1'b1;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                mem_to_reg  = 1'b0;
                alu_src     = 1'b0;
                branch      = 1'b0;
                jump        = 1'b0;
                fft_en      = 1'b0;

                case ({funct7, funct3})
                    10'b0000000_000: begin
                        alu_ctrl    = ALU_ADD;
                        valid_instr = 1'b1;
                    end

                    10'b0100000_000: begin
                        alu_ctrl    = ALU_SUB;
                        valid_instr = 1'b1;
                    end

                    10'b0000000_111: begin
                        alu_ctrl    = ALU_AND;
                        valid_instr = 1'b1;
                    end

                    10'b0000000_110: begin
                        alu_ctrl    = ALU_OR;
                        valid_instr = 1'b1;
                    end

                    10'b0000000_100: begin
                        alu_ctrl    = ALU_XOR;
                        valid_instr = 1'b1;
                    end

                    default: begin
                        reg_write   = 1'b0;
                        valid_instr = 1'b0;
                    end
                endcase
            end

            // ----------------------------------------------------------------
            // Load: LW
            // ----------------------------------------------------------------
            OPCODE_LOAD: begin
                if (funct3 == 3'b010) begin
                    reg_write   = 1'b1;
                    mem_read    = 1'b1;
                    mem_write   = 1'b0;
                    mem_to_reg  = 1'b1;
                    alu_src     = 1'b1;
                    alu_ctrl    = ALU_ADD; // address = rs1 + imm
                    branch      = 1'b0;
                    jump        = 1'b0;
                    fft_en      = 1'b0;
                    valid_instr = 1'b1;
                end
            end

            // ----------------------------------------------------------------
            // Store: SW
            // ----------------------------------------------------------------
            OPCODE_STORE: begin
                if (funct3 == 3'b010) begin
                    reg_write   = 1'b0;
                    mem_read    = 1'b0;
                    mem_write   = 1'b1;
                    mem_to_reg  = 1'b0;
                    alu_src     = 1'b1;
                    alu_ctrl    = ALU_ADD; // address = rs1 + imm
                    branch      = 1'b0;
                    jump        = 1'b0;
                    fft_en      = 1'b0;
                    valid_instr = 1'b1;
                end
            end

            // ----------------------------------------------------------------
            // Branch: BEQ, BNE
            // Compare done via ALU subtract
            // ----------------------------------------------------------------
            OPCODE_BRANCH: begin
                case (funct3)
                    3'b000: begin // BEQ
                        reg_write   = 1'b0;
                        mem_read    = 1'b0;
                        mem_write   = 1'b0;
                        mem_to_reg  = 1'b0;
                        alu_src     = 1'b0;
                        alu_ctrl    = ALU_SUB;
                        branch      = 1'b1;
                        branch_ne   = 1'b0;
                        jump        = 1'b0;
                        fft_en      = 1'b0;
                        valid_instr = 1'b1;
                    end

                    3'b001: begin // BNE
                        reg_write   = 1'b0;
                        mem_read    = 1'b0;
                        mem_write   = 1'b0;
                        mem_to_reg  = 1'b0;
                        alu_src     = 1'b0;
                        alu_ctrl    = ALU_SUB;
                        branch      = 1'b1;
                        branch_ne   = 1'b1;
                        jump        = 1'b0;
                        fft_en      = 1'b0;
                        valid_instr = 1'b1;
                    end

                    default: begin
                        valid_instr = 1'b0;
                    end
                endcase
            end

            // ----------------------------------------------------------------
            // JAL
            // Write PC+4 into rd, next PC handled by branch/jump logic elsewhere
            // ALU control is not critical here, kept benign
            // ----------------------------------------------------------------
            OPCODE_JAL: begin
                reg_write   = 1'b1;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                mem_to_reg  = 1'b0;
                alu_src     = 1'b0;
                alu_ctrl    = ALU_ADD;
                branch      = 1'b0;
                jump        = 1'b1;
                fft_en      = 1'b0;
                valid_instr = 1'b1;
            end

            // ----------------------------------------------------------------
            // Custom FFT instruction
            // FFTBLY rd, rs1, rs2
            // funct7 = 7'h01, funct3 = 3'b000, opcode = 7'h3B
            // ----------------------------------------------------------------
            OPCODE_FFT: begin
                if ((funct7 == 7'h01) && (funct3 == 3'b000)) begin
                    reg_write   = 1'b1;
                    mem_read    = 1'b0;
                    mem_write   = 1'b0;
                    mem_to_reg  = 1'b0;
                    alu_src     = 1'b0;
                    alu_ctrl    = ALU_ADD; // ignored when fft_en=1
                    branch      = 1'b0;
                    jump        = 1'b0;
                    fft_en      = 1'b1;
                    valid_instr = 1'b1;
                end
            end

            default: begin
                reg_write   = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                mem_to_reg  = 1'b0;
                alu_src     = 1'b0;
                alu_ctrl    = ALU_ADD;
                branch      = 1'b0;
                branch_ne   = 1'b0;
                jump        = 1'b0;
                fft_en      = 1'b0;
                valid_instr = 1'b0;
            end
        endcase
    end

endmodule
