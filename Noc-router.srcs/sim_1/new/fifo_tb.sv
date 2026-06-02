`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.06.2026 23:18:33
// Design Name: 
// Module Name: fifo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_tb;

    parameter int DEPTH = 4;
    parameter int WIDTH = 32;

    logic                   clk;
    logic                   rst_n;
    logic                   wr_en;
    logic [WIDTH-1:0]       wr_data;
    logic                   full;
    logic                   rd_en;
    logic [WIDTH-1:0]       rd_data;
    logic                   empty;
    logic [$clog2(DEPTH):0] count;

    // DUT instantiation
    fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_en(rd_en), .rd_data(rd_data), .empty(empty),
        .count(count)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Expected data tracker
    logic [WIDTH-1:0] expected_data [DEPTH];
    int exp_idx;

    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, fifo_tb);

        // Initialize
        rst_n = 0; wr_en = 0; wr_data = 0; rd_en = 0;

        // --- RESET ---
        $display("\n--- TEST 1: Reset ---");
        #20; rst_n = 1; #10;
        assert(empty == 1) else $error("Reset failed: empty not asserted");
        assert(count == 0) else $error("Reset failed: count = %0d", count);
        $display("PASS: Reset verified. Empty=%0d Count=%0d", empty, count);

        // --- WRITE UNTIL FULL ---
        $display("\n--- TEST 2: Write until full ---");
        for (int i = 0; i < DEPTH; i++) begin
            @(posedge clk);
            wr_en = 1;
            wr_data = (i+1) * 10;
            expected_data[i] = (i+1) * 10;
        end
        @(posedge clk); wr_en = 0; #1;
        assert(full  == 1)     else $error("FAIL: full not asserted after %0d writes", DEPTH);
        assert(count == DEPTH) else $error("FAIL: count=%0d expected %0d", count, DEPTH);
        $display("PASS: Full flag asserted. Count=%0d", count);

        // Try one more write - should be rejected
        @(posedge clk); wr_en = 1; wr_data = 999;
        @(posedge clk); wr_en = 0; #1;
        assert(count == DEPTH) else $error("FAIL: overflow - count=%0d", count);
        $display("PASS: Overflow rejected. Count still=%0d", count);

        // --- READ UNTIL EMPTY ---
        $display("\n--- TEST 3: Read until empty ---");
        exp_idx = 0;
        for (int i = 0; i < DEPTH; i++) begin
            @(posedge clk); rd_en = 1;
            @(posedge clk); rd_en = 0;
            #1;
            assert(rd_data == expected_data[exp_idx])
                else $error("FAIL: rd_data=%0d expected=%0d", rd_data, expected_data[exp_idx]);
            $display("Read[%0d]: got=%0d expected=%0d MATCH=%0d",
                i, rd_data, expected_data[exp_idx], rd_data==expected_data[exp_idx]);
            exp_idx++;
        end
        #1;
        assert(empty == 1) else $error("FAIL: empty not asserted after all reads");
        assert(count == 0) else $error("FAIL: count=%0d after empty", count);
        $display("PASS: Empty flag asserted. Count=%0d", count);

        // Try one more read - should be rejected
        @(posedge clk); rd_en = 1;
        @(posedge clk); rd_en = 0; #1;
        assert(count == 0) else $error("FAIL: underflow - count=%0d", count);
        $display("PASS: Underflow rejected. Count still=%0d", count);

        // --- SIMULTANEOUS READ AND WRITE ---
        $display("\n--- TEST 4: Simultaneous read and write ---");
        // Preload one flit
        @(posedge clk); wr_en = 1; wr_data = 77;
        @(posedge clk); wr_en = 0; #1;
        assert(count == 1) else $error("FAIL: preload count=%0d", count);
        // Now read and write simultaneously
        @(posedge clk); wr_en = 1; wr_data = 88; rd_en = 1;
        @(posedge clk); wr_en = 0; rd_en = 0; #1;
        assert(count == 1) else $error("FAIL: sim rw count=%0d expected 1", count);
        $display("PASS: Simultaneous RW. Count stable=%0d", count);

        // --- RESET MID-OPERATION ---
        $display("\n--- TEST 5: Reset mid-operation ---");
        @(posedge clk); wr_en = 1; wr_data = 111;
        @(posedge clk); wr_en = 1; wr_data = 222;
        @(posedge clk); wr_en = 0;
        #5; rst_n = 0;
        #10; rst_n = 1;
        @(posedge clk); #1;
        assert(count == 0) else $error("FAIL: post-reset count=%0d", count);
        assert(empty == 1) else $error("FAIL: post-reset empty not asserted");
        $display("PASS: Reset mid-operation. Count=%0d Empty=%0d", count, empty);

        $display("\n=== ALL TESTS COMPLETE ===");
        $finish;
    end
endmodule