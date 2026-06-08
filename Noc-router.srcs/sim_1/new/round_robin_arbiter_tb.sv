`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:28:49
// Design Name: 
// Module Name: round_robin_arbiter_tb
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



module round_robin_arbiter_tb;

    parameter int PORTS = 5;

    logic             clk;
    logic             rst_n;
    logic [PORTS-1:0] req;
    logic [PORTS-1:0] grant;

    round_robin_arbiter #(.PORTS(PORTS)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant)
    );

    // Clock Generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Waveform dumping
        $dumpfile("rr_arbiter_tb.vcd");
        $dumpvars(0, round_robin_arbiter_tb);

        // Initialize
        req = '0;
        rst_n = 0;
        #15 rst_n = 1;

        $display("--- Starting Arbiter Verification ---");

        // Test 1: Idle State (Should hold at 0, no grants)
        @(posedge clk);
        if (grant !== 5'b00000) $error("FAIL: Granted during idle!");

        // Test 2: Wrap-around (Pointer at 0, Port 4 requests)
        req = 5'b10000; 
        @(posedge clk); #1; 
        if (grant !== 5'b10000) $error("FAIL: Wrap-around logic failed!");
        
        // Test 3: Fair Rotation (Fixed Timing)
        req = 5'b11111;
        #1; // let combinational settle, priority_ptr still 0
        if (grant !== 5'b00001) $error("FAIL: Rotation 0 - got %b", grant);
        
        @(posedge clk); #1; // priority_ptr now 1
        if (grant !== 5'b00010) $error("FAIL: Rotation 1 - got %b", grant);
        
        @(posedge clk); #1; // priority_ptr now 2
        if (grant !== 5'b00100) $error("FAIL: Rotation 2 - got %b", grant);
        
        @(posedge clk); #1; // priority_ptr now 3
        if (grant !== 5'b01000) $error("FAIL: Rotation 3 - got %b", grant);
        
        @(posedge clk); #1; // priority_ptr now 4
        if (grant !== 5'b10000) $error("FAIL: Rotation 4 - got %b", grant);

        // Test 4: No requests
        req = 5'b00000;
        #1;
        if (grant !== 5'b00000) $error("FAIL: Grant issued with no requests");
        $display("PASS: No spurious grants");

        // Test 5: Critical Double-Grant Assertion
        for (int i = 0; i < 20; i++) begin
            req = $urandom_range(0, 31); // random 5-bit request
            @(posedge clk); #1;
            if ($countones(grant) > 1)
                $error("FAIL: Double grant detected - grant=%b", grant);
        end
        $display("PASS: No double grants in 20 random cycles");

        $display("--- Verification Complete ---");
        $finish;
    end

endmodule
