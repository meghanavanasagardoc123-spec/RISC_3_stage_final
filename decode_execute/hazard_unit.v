/*
------------------------------------------------------------------------------
File        : hazard_unit.v
Module      : hazard_unit
Purpose     : Load-use hazard detection unit for 3-stage/5-stage style pipeline

Functionality:
- Detects load-use hazards that cannot be solved by forwarding alone
- Requests a stall of PC and IF/ID pipeline register
- Requests insertion of a bubble into the next pipeline stage

Hazard condition:
- If current instruction in execute-side stage is a load
- And its destination register matches rs1 or rs2 of instruction in decode stage
- Then stall one cycle

Major inputs:
- id_rs1_addr      : Source register 1 of instruction in decode stage
- id_rs2_addr      : Source register 2 of instruction in decode stage
- ex_rd_addr       : Destination register of instruction in execute-side stage
- ex_mem_read      : 1 when execute-side instruction is a load

Major outputs:
- stall_pc         : Freeze PC update
- stall_if_id      : Freeze IF/ID pipeline register
- flush_id_ex      : Insert bubble into ID/EX pipeline register

Notes:
- x0 is ignored because writes to x0 have no effect
- Pure combinational logic
- This is the classic load-use hazard rule
------------------------------------------------------------------------------
*/

module hazard_unit (
    input  [4:0] id_rs1_addr,
    input  [4:0] id_rs2_addr,
    input  [4:0] ex_rd_addr,
    input        ex_mem_read,

    output reg   stall_pc,
    output reg   stall_if_id,
    output reg   flush_id_ex
);

    always @(*) begin
        // Default: no hazard
        stall_pc   = 1'b0;
        stall_if_id = 1'b0;
        flush_id_ex = 1'b0;

        // Load-use hazard detection
        if (ex_mem_read &&
            (ex_rd_addr != 5'd0) &&
            ((ex_rd_addr == id_rs1_addr) ||
             (ex_rd_addr == id_rs2_addr))) begin
            stall_pc    = 1'b1;
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1;
        end
    end

endmodule
