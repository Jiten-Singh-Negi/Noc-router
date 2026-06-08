`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:31:06
// Design Name: 
// Module Name: vc_state_machine_tb
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


module vc_state_machine_tb;

    parameter int PORTS = 5;

    logic clk;
    logic rst_n;
    logic flit_valid;
    logic is_head;
    logic is_tail;
    logic [$clog2(PORTS)-1:0] route_dest;
    
    logic vc_locked;
    logic [$clog2(PORTS)-1:0] locked_dest;

    vc_state_machine #(.PORTS(PORTS)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .flit_valid(flit_valid),
        .is_head(is_head),
        .is_tail(is_tail),
        .route_dest(route_dest),
        .vc_locked(vc_locked),
        .locked_dest(locked_dest)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("vc_state_machine_tb.vcd");
        $dumpvars(0, vc_state_machine_tb);

        // Initialize
        flit_valid = 0;
        is_head    = 0;
        is_tail    = 0;
        route_dest = '0;
        rst_n      = 0;
        #15 rst_n  = 1;
        @(posedge clk);

        $display("--- Starting VC State Machine Verification ---");

        // Test 1: Reset
        if (dut.state !== 2'b00) $error("FAIL: State not IDLE after reset");
        if (vc_locked !== 1'b0) $error("FAIL: vc_locked is high after reset");
        $display("PASS: Reset correct");

        // Test 5 (Done early): False trigger (Body flit while IDLE)
        flit_valid = 1;
        is_head = 0; 
        is_tail = 0;
        @(posedge clk);
        #1;
        if (vc_locked !== 1'b0) $error("FAIL: vc_locked went high on false trigger");
        if (dut.state !== 2'b00) $error("FAIL: FSM left IDLE on false trigger");
        
        // FIX: Cleanup state before next test
        flit_valid = 0;
        is_head = 0;
        is_tail = 0;
        @(posedge clk); 
        $display("PASS: No false trigger");

        // Test 2: Head flit arrives
        flit_valid = 1;
        is_head = 1;
        route_dest = 3; // Let's say routing to East (3)
        #1; 
        if (vc_locked !== 1'b1) $error("FAIL: vc_locked did not assert combinationally on HEAD");
        @(posedge clk); 
        #1;
        if (dut.state !== 2'b01) $error("FAIL: FSM did not enter ACTIVE");
        if (locked_dest !== 3) $error("FAIL: locked_dest did not capture route on clock edge");
        $display("PASS: Head flit capture and lock correct");

        // Test 3: Body flits (ACTIVE state holding)
        flit_valid = 1;
        is_head = 0;
        is_tail = 0;
        @(posedge clk);
        #1;
        if (vc_locked !== 1'b1) $error("FAIL: vc_locked dropped during body flit");
        if (dut.state !== 2'b01) $error("FAIL: FSM dropped out of ACTIVE during body flit");
        $display("PASS: Body flit hold correct");

        // Test 4: Tail flit arrives
        flit_valid = 1;
        is_tail = 1;
        #1;
        if (vc_locked !== 1'b1) $error("FAIL: vc_locked dropped too early (combinational on tail)");
        @(posedge clk);
        #1;
        if (dut.state !== 2'b00) $error("FAIL: FSM did not return to IDLE after tail");
        if (vc_locked !== 1'b0) $error("FAIL: vc_locked did not drop after clocking tail flit");
        $display("PASS: Tail flit release correct");

        $display("--- Verification Complete ---");
        $finish;
    end

endmodule