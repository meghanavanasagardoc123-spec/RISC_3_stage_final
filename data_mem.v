`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : data_mem.v
Module      : data_mem
Purpose     : Data memory for baseline RV32I load/store stage

Functionality:
- Stores 32-bit data words
- Supports SW write and LW read for current project subset
- Uses word-aligned addressing with addr_in[31:2]

Major inputs:
- clk         : Clock input
- mem_read    : Read enable
- mem_write   : Write enable
- addr_in     : Byte address from ALU
- write_data  : Data to be written into memory

Major outputs:
- read_data   : Data read from memory

Parameters:
- MEM_DEPTH   : Number of 32-bit words in data memory

Notes:
- Synchronous write
- Combinational read
- Word-aligned access uses addr_in[31:2]
- Lower 2 bits of address are ignored for current LW/SW-only design
- Out-of-range read returns 0
- Out-of-range write is ignored
- No reset is used because memory arrays are typically not cleared by reset in
  synthesizable RTL unless specifically required
- Written in Verilog-only style for Icarus compatibility
------------------------------------------------------------------------------
*/

module data_mem #(
    parameter MEM_DEPTH = 256
)(
    input                  clk,
    input                  mem_read,
    input                  mem_write,
    input  [`XLEN-1:0]     addr_in,
    input  [`XLEN-1:0]     write_data,
    output reg [`XLEN-1:0] read_data
);

    reg [`XLEN-1:0] mem [0:MEM_DEPTH-1];

    wire [`XLEN-1:0] word_addr;
    assign word_addr = addr_in >> 2;

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write && (word_addr < MEM_DEPTH))
            mem[word_addr] <= write_data;
    end

    // Combinational read
    always @(*) begin
        if (mem_read && (word_addr < MEM_DEPTH))
            read_data = mem[word_addr];
        else
            read_data = {`XLEN{1'b0}};
    end

endmodule
