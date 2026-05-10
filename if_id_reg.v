`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : if_id_reg.v
Module      : if_id_reg
Purpose     : IF/ID pipeline register for baseline 3-stage RV32I processor

Functionality:
- Stores fetched instruction and PC information between IF and ID stages
- Transfers fetch-stage outputs to decode stage on each clock edge
- Supports stall and flush control for hazard handling

Major inputs:
- clk           : Clock input
- rst_n         : Active-low reset
- stall         : Holds current IF/ID contents when asserted
- flush         : Clears IF/ID contents and inserts bubble/NOP
- pc_in         : Current PC from fetch stage
- pc_plus4_in   : PC + 4 from fetch stage
- instr_in      : Fetched instruction from instruction memory

Major outputs:
- pc_out        : Registered PC to decode stage
- pc_plus4_out  : Registered PC + 4 to decode stage
- instr_out     : Registered instruction to decode stage

Notes:
- Sequential logic block
- Reset clears outputs to zero
- Flush inserts a bubble by clearing outputs
- Stall freezes current contents
- Flush has priority over normal update
- Reset has highest priority
- Written in Verilog-only style for Icarus compatibility

Run note:
- This is an RTL module, so it is compiled together with its testbench
------------------------------------------------------------------------------
*/

module if_id_reg (
    input                  clk,
    input                  rst_n,
    input                  stall,
    input                  flush,
    input  [`XLEN-1:0]     pc_in,
    input  [`XLEN-1:0]     pc_plus4_in,
    input  [31:0]          instr_in,

    output reg [`XLEN-1:0] pc_out,
    output reg [`XLEN-1:0] pc_plus4_out,
    output reg [31:0]      instr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out       <= {`XLEN{1'b0}};
            pc_plus4_out <= {`XLEN{1'b0}};
            instr_out    <= 32'b0;
        end
        else if (flush) begin
            pc_out       <= {`XLEN{1'b0}};
            pc_plus4_out <= {`XLEN{1'b0}};
            instr_out    <= 32'b0;
        end
        else if (stall) begin
            pc_out       <= pc_out;
            pc_plus4_out <= pc_plus4_out;
            instr_out    <= instr_out;
        end
        else begin
            pc_out       <= pc_in;
            pc_plus4_out <= pc_plus4_in;
            instr_out    <= instr_in;
        end
    end

endmodule
