`timescale 1ns/1ps

module control_unit (
    input  wire [31:0] instr,

    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         alu_src,
    output reg [2:0]   alu_ctrl,
    output reg         branch,
    output reg         branch_ne,
    output reg         jump,
    output reg         fft_en,
    output reg         valid_instr
);

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    localparam [6:0] OPCODE_RTYPE  = 7'b0110011;
    localparam [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam [6:0] OPCODE_STORE  = 7'b0100011;
    localparam [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam [6:0] OPCODE_JAL    = 7'b1101111;

    // Custom FFT instruction opcode
    // NOTE: This matches instruction value 32'h000000BB because 0xBB[6:0] = 7'b0111011
    localparam [6:0] OPCODE_FFT    = 7'b0111011;

    always @(*) begin
        // default outputs
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        alu_src     = 1'b0;
        alu_ctrl    = 3'b000;
        branch      = 1'b0;
        branch_ne   = 1'b0;
        jump        = 1'b0;
        fft_en      = 1'b0;
        valid_instr = 1'b0;

        case (opcode)

            OPCODE_RTYPE: begin
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: begin // ADD
                        reg_write   = 1'b1;
                        alu_ctrl    = 3'b010;
                        valid_instr = 1'b1;
                    end

                    {7'b0100000, 3'b000}: begin // SUB
                        reg_write   = 1'b1;
                        alu_ctrl    = 3'b110;
                        valid_instr = 1'b1;
                    end

                    {7'b0000000, 3'b111}: begin // AND
                        reg_write   = 1'b1;
                        alu_ctrl    = 3'b000;
                        valid_instr = 1'b1;
                    end

                    {7'b0000000, 3'b110}: begin // OR
                        reg_write   = 1'b1;
                        alu_ctrl    = 3'b001;
                        valid_instr = 1'b1;
                    end

                    {7'b0000000, 3'b100}: begin // XOR
                        reg_write   = 1'b1;
                        alu_ctrl    = 3'b011;
                        valid_instr = 1'b1;
                    end

                    default: begin
                        reg_write   = 1'b0;
                        valid_instr = 1'b0;
                    end
                endcase
            end

            OPCODE_LOAD: begin
                case (funct3)
                    3'b010: begin // LW
//                        reg_write   = 1'b1;
//                        mem_read    = 1'b1;
//                        mem_to_reg  = 1'b1;
//                        alu_src     = 1'b1;
//                        alu_ctrl    = 3'b010; // address = rs1 + imm
//                        valid_instr = 1'b1;
		            reg_write   = 1'b1;
		            mem_read    = 1'b1;
		            mem_write   = 1'b0;
		            mem_to_reg  = 1'b1;
		            alu_src     = 1'b1;
		            alu_ctrl    = 3'b010;
		            branch      = 1'b0;
		            branch_ne   = 1'b0;
		            jump        = 1'b0;
		            fft_en      = 1'b0;
		            valid_instr = 1'b1;
                    end

                    default: begin
                        valid_instr = 1'b0;
                    end
                endcase
            end

            OPCODE_STORE: begin
                case (funct3)
                    3'b010: begin // SW
                        mem_write   = 1'b1;
                        alu_src     = 1'b1;
                        alu_ctrl    = 3'b010; // address = rs1 + imm
                        valid_instr = 1'b1;
                    end

                    default: begin
                        valid_instr = 1'b0;
                    end
                endcase
            end

            OPCODE_BRANCH: begin
                case (funct3)
                    3'b000: begin // BEQ
                        branch      = 1'b1;
                        branch_ne   = 1'b0;
                        alu_src     = 1'b0;
                        alu_ctrl    = 3'b110; // compare using subtraction
                        valid_instr = 1'b1;
                    end

                    3'b001: begin // BNE
                        branch      = 1'b1;
                        branch_ne   = 1'b1;
                        alu_src     = 1'b0;
                        alu_ctrl    = 3'b110; // compare using subtraction
                        valid_instr = 1'b1;
                    end

                    default: begin
                        valid_instr = 1'b0;
                    end
                endcase
            end

            OPCODE_JAL: begin // JAL
                jump        = 1'b1;
                reg_write   = 1'b1;
                valid_instr = 1'b1;
            end

            OPCODE_FFT: begin // Custom FFT instruction
                fft_en      = 1'b1;
                reg_write   = 1'b1;
                alu_src     = 1'b0;
                alu_ctrl    = 3'b000;
                valid_instr = 1'b1;
            end

            default: begin
                reg_write   = 1'b0;
                mem_read    = 1'b0;
                mem_write   = 1'b0;
                mem_to_reg  = 1'b0;
                alu_src     = 1'b0;
                alu_ctrl    = 3'b000;
                branch      = 1'b0;
                branch_ne   = 1'b0;
                jump        = 1'b0;
                fft_en      = 1'b0;
                valid_instr = 1'b0;
            end
        endcase
    end

endmodule
