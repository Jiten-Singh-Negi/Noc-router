`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:30:23
// Design Name: 
// Module Name: credit_counter_tb
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


module credit_counter_tb;

    parameter int MAX_CREDITS = 4;

    logic clk;
    logic rst_n;
    logic flit_sent;
    logic credit_rx;
    logic has_credit;

    credit_counter #(.MAX_CREDITS(MAX_CREDITS)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .flit_sent(flit_sent),
        .credit_rx(credit_rx),
        .has_credit(has_credit)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("credit_counter_tb.vcd");
        $dumpvars(0, credit_counter_tb);

        flit_sent = 0;
        credit_rx = 0;
        rst_n = 0;
        #15 rst_n = 1;

        // Drive all stimulus on the falling edge to prevent race conditions
        @(negedge clk);

        $display("--- Starting Credit Counter Verification ---");

        // Test 1: Reset state
        if (dut.count !== MAX_CREDITS) $error("FAIL: Reset count is %0d", dut.count);
        else $display("PASS: Reset state correct");

        // Test 2: Send until empty
        for (int i = 0; i < 4; i++) begin
            flit_sent = 1;
            @(negedge clk);
        end
        flit_sent = 0;
        if (dut.count !== 0) $error("FAIL: Count not 0 after 4 sends");
        else $display("PASS: Send until empty correct");

        // Test 3: Underflow protection
        flit_sent = 1;
        @(negedge clk);
        flit_sent = 0;
        if (dut.count !== 0) $error("FAIL: Underflow occurred!");
        else $display("PASS: Underflow protection working");

        // Test 4: Credit return
        for (int i = 0; i < 4; i++) begin
            credit_rx = 1;
            @(negedge clk);
        end
        credit_rx = 0;
        if (dut.count !== MAX_CREDITS) $error("FAIL: Count not MAX after 4 receives");
        else $display("PASS: Credit return correct");

        // Test 5: Simultaneous send/receive
        flit_sent = 1;
        credit_rx = 1;
        @(negedge clk);
        flit_sent = 0;
        credit_rx = 0;
        if (dut.count !== MAX_CREDITS) $error("FAIL: Simultaneous logic failed.");
        else $display("PASS: Simultaneous send/receive stable");

        $display("--- Verification Complete ---");
        $finish;
    end

endmodule