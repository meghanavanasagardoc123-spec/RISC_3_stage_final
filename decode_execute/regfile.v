
/*This structure matches the expected RISC-V register file behavior: x0 is hardwired to zero, writes to x0 are ignored, and the design supports two simultaneous reads and one write. That is exactly the behavior expected for RV32I integer registers and is the standard organization used in simple RISC-V cores.

Design notes
A few important points about this implementation:

regs[0] <= 0 is kept explicitly so even accidental corruption gets overwritten on every clock edge.

Reset initializes all registers to zero, which is useful for simulation clarity even though not all real hardware register files are physically reset this way.

Reads are combinational, which is the simplest and most common style for student RV32I processor projects*/
`include "riscv_defines.vh"

module regfile (
    input                  clk,
    input                  rst_n,
    input                  reg_write_en,
    input  [4:0]           rs1_addr,
    input  [4:0]           rs2_addr,
    input  [4:0]           rd_addr,
    input  [`XLEN-1:0]     rd_wdata,
    output [`XLEN-1:0]     rs1_rdata,
    output [`XLEN-1:0]     rs2_rdata
);

    reg [`XLEN-1:0] regs [0:31];
    integer i;

    // Synchronous write, active-low reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= {`XLEN{1'b0}};
        end
        else begin
            if (reg_write_en && (rd_addr != 5'd0))
                regs[rd_addr] <= rd_wdata;

            regs[0] <= {`XLEN{1'b0}};
        end
    end

    // Combinational read ports
    assign rs1_rdata = (rs1_addr == 5'd0) ? {`XLEN{1'b0}} : regs[rs1_addr];
    assign rs2_rdata = (rs2_addr == 5'd0) ? {`XLEN{1'b0}} : regs[rs2_addr];

endmodule
