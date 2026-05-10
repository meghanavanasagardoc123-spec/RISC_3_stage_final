`timescale 1ns/1ps
`include "riscv_defines.vh"

/*
------------------------------------------------------------------------------
File        : tb_data_mem.v
Testbench   : tb_data_mem
Purpose     : Self-checking testbench for data_mem.v

What this TB verifies:
1. Write occurs only on positive clock edge
2. Read returns previously written data
3. No write occurs when mem_write = 0
4. Read output is zero when mem_read = 0
5. Word-aligned addressing uses addr_in[31:2]
6. Different addresses store independent values
7. Out-of-range read returns zero

DUT inputs driven by TB:
- clk         : Clock input
- mem_read    : Read enable
- mem_write   : Write enable
- addr_in     : Byte address from ALU
- write_data  : Data written into memory

DUT outputs checked by TB:
- read_data   : Data read from memory

Pass/Fail method:
- TB performs directed write/read sequences
- TB checks read_data against expected values
- Prints PASS/FAIL messages using $display
- Dumps waveform file for GTKWave debug

Run command (Icarus Verilog):
- Compile : iverilog -o dmem_tb data_mem.v tb_data_mem.v
- Run     : vvp dmem_tb
- Waveform: gtkwave tb_data_mem.vcd

Notes:
- Pure Verilog testbench, no SystemVerilog features used
- This TB assumes synchronous write and combinational read behavior
------------------------------------------------------------------------------
*/

module tb_data_mem;

    reg              clk;
    reg              mem_read;
    reg              mem_write;
    reg  [`XLEN-1:0] addr_in;
    reg  [`XLEN-1:0] write_data;

    wire [`XLEN-1:0] read_data;

    integer errors;

    data_mem #(
        .MEM_DEPTH(16)
    ) uut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr_in    (addr_in),
        .write_data (write_data),
        .read_data  (read_data)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_read;
        input [`XLEN-1:0] expected_data;
        input [127:0]     test_name;
        begin
            #1;
            if (read_data !== expected_data) begin
                $display("FAIL : %s", test_name);
                $display("       addr_in=%h mem_read=%b mem_write=%b write_data=%h",
                         addr_in, mem_read, mem_write, write_data);
                $display("       expected read_data=%h", expected_data);
                $display("       got      read_data=%h", read_data);
                errors = errors + 1;
            end
            else begin
                $display("PASS : %s  read_data=%h", test_name, read_data);
            end
        end
    endtask

    task write_word;
        input [`XLEN-1:0] addr;
        input [`XLEN-1:0] data;
        begin
            @(negedge clk);
            addr_in    = addr;
            write_data = data;
            mem_write  = 1'b1;
            mem_read   = 1'b0;
            @(posedge clk);
            #1;
            mem_write  = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("tb_data_mem.vcd");
        $dumpvars(0, tb_data_mem);

        errors = 0;

        // Initialize
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        addr_in    = 32'h0000_0000;
        write_data = 32'h0000_0000;

        // ------------------------------------------------------
        // Test 1: Read disabled => output should be zero
        // ------------------------------------------------------
        addr_in   = 32'h0000_0000;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        check_read(32'h0000_0000, "READ_DISABLED_ZERO");

        // ------------------------------------------------------
        // Test 2: Write one word at address 0
        // ------------------------------------------------------
        write_word(32'h0000_0000, 32'hDEAD_BEEF);
        mem_read = 1'b1;
        addr_in   = 32'h0000_0000;
        check_read(32'hDEAD_BEEF, "WRITE_READ_ADDR0");

        // ------------------------------------------------------
        // Test 3: Write another word at address 4
        // ------------------------------------------------------
        write_word(32'h0000_0004, 32'h1234_5678);
        mem_read = 1'b1;
        addr_in   = 32'h0000_0004;
        check_read(32'h1234_5678, "WRITE_READ_ADDR1");

        // ------------------------------------------------------
        // Test 4: Original address still holds old value
        // ------------------------------------------------------
        addr_in  = 32'h0000_0000;
        mem_read = 1'b1;
        check_read(32'hDEAD_BEEF, "ADDR0_UNCHANGED");

        // ------------------------------------------------------
        // Test 5: Word alignment check
        // addr 0x00000006 maps to word address 1
        // ------------------------------------------------------
        addr_in  = 32'h0000_0006;
        mem_read = 1'b1;
        check_read(32'h1234_5678, "WORD_ALIGN_ADDR1");

        // ------------------------------------------------------
        // Test 6: No write when mem_write = 0
        // ------------------------------------------------------
        @(negedge clk);
        addr_in    = 32'h0000_0008;
        write_data = 32'hAAAA_AAAA;
        mem_write  = 1'b0;
        mem_read   = 1'b1;
        @(posedge clk);
        #1;
        check_read(32'hxxxx_xxxx, "NO_WRITE_UNKNOWN_OR_UNINITIALIZED");

        // ------------------------------------------------------
        // Test 7: Read disabled again => zero output
        // ------------------------------------------------------
        mem_read = 1'b0;
        addr_in  = 32'h0000_0000;
        check_read(32'h0000_0000, "READ_DISABLED_AGAIN");

        // ------------------------------------------------------
        // Test 8: Out-of-range read => zero output
        // MEM_DEPTH = 16, valid word addresses are 0 to 15
        // address 0x00000100 => word address 64 => out of range
        // ------------------------------------------------------
        addr_in  = 32'h0000_0100;
        mem_read = 1'b1;
        check_read(32'h0000_0000, "OUT_OF_RANGE_READ");

        if (errors == 0)
            $display("\nALL DATA_MEM TESTS PASSED\n");
        else
            $display("\nDATA_MEM TESTS FAILED : total errors = %0d\n", errors);

        $finish;
    end

endmodule
