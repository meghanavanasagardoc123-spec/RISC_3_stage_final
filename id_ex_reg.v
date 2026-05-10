`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : id_ex_reg.v
Module      : id_ex_reg
Purpose     : Pipeline register between Decode and Execute stages

Functionality:
- Latches decoded data and control signals on rising clock edge
- Supports synchronous reset
- Supports stall/flush behavior through enable and flush inputs
- Used to move operands and control into the execute stage

Major inputs:
- clk             : Clock input
- rst_n           : Active-low reset
- stall           : Hold current pipeline contents when asserted
- flush           : Insert bubble/NOP when asserted

Data/control inputs:
- pc_in           : Current PC
- rs1_data_in     : Register file read data 1
- rs2_data_in     : Register file read data 2
- imm_in          : Immediate value
- rs1_addr_in     : Source register 1 address
- rs2_addr_in     : Source register 2 address
- rd_addr_in      : Destination register address

Control inputs:
- reg_write_in
- mem_read_in
- mem_write_in
- mem_to_reg_in
- alu_src_in
- branch_in
- alu_ctrl_in

Outputs:
- pc_out
- rs1_data_out
- rs2_data_out
- imm_out
- rs1_addr_out
- rs2_addr_out
- rd_addr_out
- reg_write_out
- mem_read_out
- mem_write_out
- mem_to_reg_out
- alu_src_out
- branch_out
- alu_ctrl_out

Notes:
- On flush, control signals are cleared and data outputs are zeroed
- On stall, register holds its previous values
- Written in Verilog-only style for Icarus compatibility
------------------------------------------------------------------------------
*/

`timescale 1ns/1ps

`timescale 1ns/1ps

module id_ex_reg (
    input                  clk,
    input                  rst_n,
    input                  stall,
    input                  flush,

    input  [`XLEN-1:0]     pc_in,
    input  [`XLEN-1:0]     rs1_data_in,
    input  [`XLEN-1:0]     rs2_data_in,
    input  [4:0]           rs1_addr_in,
    input  [4:0]           rs2_addr_in,
    input  [4:0]           rd_addr_in,

    input                  reg_write_in,
    input                  mem_read_in,
    input                  mem_write_in,
    input                  mem_to_reg_in,
    input                  alu_src_in,
    input                  branch_in,
    input  [3:0]           alu_ctrl_in,

    output reg [`XLEN-1:0] pc_out,
    output reg [`XLEN-1:0] rs1_data_out,
    output reg [`XLEN-1:0] rs2_data_out,
    output reg [4:0]       rs1_addr_out,
    output reg [4:0]       rs2_addr_out,
    output reg [4:0]       rd_addr_out,

    output reg              reg_write_out,
    output reg              mem_read_out,
    output reg              mem_write_out,
    output reg              mem_to_reg_out,
    output reg              alu_src_out,
    output reg              branch_out,
    output reg [3:0]        alu_ctrl_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out         <= {`XLEN{1'b0}};
            rs1_data_out   <= {`XLEN{1'b0}};
            rs2_data_out   <= {`XLEN{1'b0}};
            rs1_addr_out   <= 5'd0;
            rs2_addr_out   <= 5'd0;
            rd_addr_out    <= 5'd0;
            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_src_out    <= 1'b0;
            branch_out     <= 1'b0;
            alu_ctrl_out   <= 4'd0;
        end
        else if (flush) begin
            pc_out         <= {`XLEN{1'b0}};
            rs1_data_out   <= {`XLEN{1'b0}};
            rs2_data_out   <= {`XLEN{1'b0}};
            rs1_addr_out   <= 5'd0;
            rs2_addr_out   <= 5'd0;
            rd_addr_out    <= 5'd0;
            reg_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_src_out    <= 1'b0;
            branch_out     <= 1'b0;
            alu_ctrl_out   <= 4'd0;
        end
        else if (!stall) begin
            pc_out         <= pc_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            rs1_addr_out   <= rs1_addr_in;
            rs2_addr_out   <= rs2_addr_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_src_out    <= alu_src_in;
            branch_out     <= branch_in;
            alu_ctrl_out   <= alu_ctrl_in;
        end
    end

endmodule
