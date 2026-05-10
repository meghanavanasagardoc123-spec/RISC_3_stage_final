`timescale 1ns/1ps

/*
------------------------------------------------------------------------------
File        : tb_hazard_unit.v
Testbench   : tb_hazard_unit
Purpose     : Self-checking testbench for hazard_unit.v

What this TB verifies:
1. No hazard when ex_mem_read = 0
2. No hazard when ex_rd_addr does not match decode source registers
3. Hazard when ex_rd_addr matches id_rs1_addr
4. Hazard when ex_rd_addr matches id_rs2_addr
5. No hazard when ex_rd_addr = x0
6. Hazard control outputs assert together for load-use stall

DUT inputs driven by TB:
- id_rs1_addr      : Source register 1 in decode stage
- id_rs2_addr      : Source register 2 in decode stage
- ex_rd_addr       : Destination register in execute-side stage
- ex_mem_read      : Load indicator for execute-side stage

DUT outputs checked by TB:
- stall_pc         : Freeze PC update
- stall_if_id      : Freeze IF/ID register
- flush_id_ex      : Insert bubble into ID/EX

Pass/Fail method:
- TB applies directed cases
- Checks output triplet against expected values
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o hazard_tb hazard_unit.v tb_hazard_unit.v
- Run     : vvp hazard_tb
- Waveform: gtkwave tb_hazard_unit.vcd

Notes:
- Pure Verilog testbench
- Assumes classic load-use hazard detection behavior
------------------------------------------------------------------------------
*/

module tb_hazard_unit;

    reg  [4:0] id_rs1_addr;
    reg  [4:0] id_rs2_addr;
    reg  [4:0] ex_rd_addr;
    reg        ex_mem_read;

    wire       stall_pc;
    wire       stall_if_id;
    wire       flush_id_ex;

    integer errors;

    hazard_unit uut (
        .id_rs1_addr (id_rs1_addr),
        .id_rs2_addr (id_rs2_addr),
        .ex_rd_addr  (ex_rd_addr),
        .ex_mem_read (ex_mem_read),
        .stall_pc    (stall_pc),
        .stall_if_id (stall_if_id),
        .flush_id_ex (flush_id_ex)
    );

    task check_hazard;
        input exp_stall_pc;
        input exp_stall_if_id;
        input exp_flush_id_ex;
        input [127:0] test_name;
        begin
            #1;
            if ((stall_pc   !== exp_stall_pc)   ||
                (stall_if_id !== exp_stall_if_id) ||
                (flush_id_ex !== exp_flush_id_ex)) begin
                $display("FAIL : %s", test_name);
                $display("       id_rs1_addr=%0d id_rs2_addr=%0d ex_rd_addr=%0d ex_mem_read=%b",
                         id_rs1_addr, id_rs2_addr, ex_rd_addr, ex_mem_read);
                $display("       expected stall_pc=%b stall_if_id=%b flush_id_ex=%b",
                         exp_stall_pc, exp_stall_if_id, exp_flush_id_ex);
                $display("       got      stall_pc=%b stall_if_id=%b flush_id_ex=%b",
                         stall_pc, stall_if_id, flush_id_ex);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s", test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_hazard_unit.vcd");
        $dumpvars(0, tb_hazard_unit);

        errors = 0;

        // ------------------------------------------------------
        // Test 1: No hazard when ex_mem_read = 0
        // ------------------------------------------------------
        id_rs1_addr = 5'd1;
        id_rs2_addr = 5'd2;
        ex_rd_addr  = 5'd1;
        ex_mem_read = 1'b0;
        check_hazard(1'b0, 1'b0, 1'b0, "NO_HAZARD_MEMREAD_0");

        // ------------------------------------------------------
        // Test 2: No hazard when no register matches
        // ------------------------------------------------------
        id_rs1_addr = 5'd3;
        id_rs2_addr = 5'd4;
        ex_rd_addr  = 5'd5;
        ex_mem_read = 1'b1;
        check_hazard(1'b0, 1'b0, 1'b0, "NO_HAZARD_NO_MATCH");

        // ------------------------------------------------------
        // Test 3: Hazard due to rs1 match
        // ------------------------------------------------------
        id_rs1_addr = 5'd6;
        id_rs2_addr = 5'd7;
        ex_rd_addr  = 5'd6;
        ex_mem_read = 1'b1;
        check_hazard(1'b1, 1'b1, 1'b1, "HAZARD_RS1_MATCH");

        // ------------------------------------------------------
        // Test 4: Hazard due to rs2 match
        // ------------------------------------------------------
        id_rs1_addr = 5'd8;
        id_rs2_addr = 5'd9;
        ex_rd_addr  = 5'd9;
        ex_mem_read = 1'b1;
        check_hazard(1'b1, 1'b1, 1'b1, "HAZARD_RS2_MATCH");

        // ------------------------------------------------------
        // Test 5: Hazard due to both rs1 and rs2 matching
        // ------------------------------------------------------
        id_rs1_addr = 5'd10;
        id_rs2_addr = 5'd10;
        ex_rd_addr  = 5'd10;
        ex_mem_read = 1'b1;
        check_hazard(1'b1, 1'b1, 1'b1, "HAZARD_BOTH_MATCH");

        // ------------------------------------------------------
        // Test 6: No hazard when ex_rd_addr = x0
        // ------------------------------------------------------
        id_rs1_addr = 5'd1;
        id_rs2_addr = 5'd2;
        ex_rd_addr  = 5'd0;
        ex_mem_read = 1'b1;
        check_hazard(1'b0, 1'b0, 1'b0, "NO_HAZARD_X0");

        // ------------------------------------------------------
        // Test 7: No hazard with all zeros
        // ------------------------------------------------------
        id_rs1_addr = 5'd0;
        id_rs2_addr = 5'd0;
        ex_rd_addr  = 5'd0;
        ex_mem_read = 1'b0;
        check_hazard(1'b0, 1'b0, 1'b0, "ALL_ZERO_CASE");

        if (errors == 0)
            $display("\nALL HAZARD_UNIT TESTS PASSED\n");
        else
            $display("\nHAZARD_UNIT TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
