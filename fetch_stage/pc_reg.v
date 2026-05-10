//`include "../riscv_defines.vh"
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : pc_reg.v
Module      : pc_reg
Purpose     : Program Counter register for baseline RV32I datapath

Functionality:
- Holds the current Program Counter (PC)
- Updates PC on every clock edge
- Supports reset, stall, and next-PC loading
- Used by instruction fetch stage

Major inputs:
- clk        : Clock input
- rst_n      : Active-low reset
- stall      : Holds current PC when asserted
- next_pc    : Next PC value to be loaded

Major outputs:
- pc_out     : Current PC value

Notes:
- Sequential logic block
- On reset, PC is initialized to RESET_PC
- If stall = 1, current PC is retained
- Otherwise, PC is updated with next_pc
- Written in Verilog-only style for Icarus compatibility

Run note:
- This is an RTL module, so it is compiled together with its testbench
------------------------------------------------------------------------------
*/

//module pc_reg (
//    input                  clk,
//    input                  rst_n,
//    input                  stall,
//    input  [31:0]     next_pc,
//    output reg [31:0] pc_out
//);
//
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n)
//          //  pc_out <= `RESET_PC;
//pc_out <= 32'h0000_1000; 
//        else if (stall)
//            pc_out <= pc_out;
//        else
//            pc_out <= next_pc;
//    end
//
//endmodule
`timescale 1ns/1ps

module pc_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_out <= 32'h0000_1000;
        else if (!stall)
            pc_out <= next_pc;
    end

endmodule
