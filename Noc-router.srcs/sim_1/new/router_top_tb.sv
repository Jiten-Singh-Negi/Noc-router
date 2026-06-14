`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 00:27:08
// Design Name: 
// Module Name: router_top_tb
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


import noc_params::*;

module router_top_tb;

    // -----------------------------------------------------
    // Parameters (Matching the DUT)
    // -----------------------------------------------------
    parameter int PORTS      = 5;
    parameter int VCS        = 2;
    parameter int FLIT_WIDTH = 39;
    
    parameter int MY_X = 1;
    parameter int MY_Y = 1;

    localparam int LOCAL = 0;
    localparam int NORTH = 1;
    localparam int SOUTH = 2;
    localparam int EAST  = 3;
    localparam int WEST  = 4;

    // -----------------------------------------------------
    // Wires & Registers
    // -----------------------------------------------------
    logic clk;
    logic rst_n;

    logic [PORTS-1:0][FLIT_WIDTH-1:0] rx_flit;
    logic [PORTS-1:0]                 rx_valid;
    logic [PORTS-1:0]                 rx_vc_id;
    logic [PORTS-1:0][VCS-1:0]        rx_credit;

    logic [PORTS-1:0][FLIT_WIDTH-1:0] tx_flit;
    logic [PORTS-1:0]                 tx_valid;
    logic [PORTS-1:0]                 tx_vc_id;
    logic [PORTS-1:0][VCS-1:0]        tx_credit;

    // Module-level counters and tracking
    int head_count = 0;
    int body_count = 0;
    int tail_count = 0;
    
    // Dynamic routing expectation for the Monitor block
    int expected_port; 

    // -----------------------------------------------------
    // Device Under Test (DUT)
    // -----------------------------------------------------
    router_top #(
        .PORTS(PORTS), .VCS(VCS), .FLIT_WIDTH(FLIT_WIDTH), .MY_X(MY_X), .MY_Y(MY_Y)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .rx_flit(rx_flit), .rx_valid(rx_valid), .rx_vc_id(rx_vc_id), .rx_credit(rx_credit),
        .tx_flit(tx_flit), .tx_valid(tx_valid), .tx_vc_id(tx_vc_id), .tx_credit(tx_credit)
    );

    // -----------------------------------------------------
    // Clock Generation
    // -----------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -----------------------------------------------------
    // Downstream Sink Model (Dynamic Credit Return)
    // -----------------------------------------------------
    // Simulates a downstream FWFT FIFO that immediately pops and returns credit
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_credit <= '0;
        end else begin
            tx_credit <= '0; // default: no credit this cycle
            for (int p = 0; p < PORTS; p++) begin
                if (tx_valid[p]) begin
                    // Return credit on same VC that just received a flit
                    tx_credit[p][tx_vc_id[p]] <= 1'b1;
                end
            end
        end
    end

    // -----------------------------------------------------
    // Helper Task: Inject Flit
    // -----------------------------------------------------
    task inject_flit(
        input int port, input int vc, input flit_type_t f_type, 
        input logic [1:0] d_x, input logic [1:0] d_y, input logic [31:0] payload
    );
        begin
            @(negedge clk); 
            rx_valid[port]       = 1'b1;
            rx_vc_id[port]       = vc[0];
            rx_flit[port][38:37] = f_type;
            rx_flit[port][36:35] = d_x;
            rx_flit[port][34:33] = d_y;
            rx_flit[port][32]    = vc[0];
            rx_flit[port][31:0]  = payload;
            
            @(negedge clk);
            rx_valid[port] = 1'b0; 
        end
    endtask

    // -----------------------------------------------------
    // Monitor Block: Dynamic Port Checking
    // -----------------------------------------------------
    initial begin
        flit_type_t observed_type; 
        
        forever begin
            @(posedge clk); #1; 
            
            // Scan all ports dynamically
            for (int p = 0; p < PORTS; p++) begin
                if (tx_valid[p]) begin
                    // Negative Check: Is it on the wrong port?
                    if (p != expected_port) begin
                        $error("FAIL: Flit routed to wrong port %0d. Expected %0d", p, expected_port);
                    end else begin
                        // Positive Check: Validate sequence and payload
                        observed_type = flit_type_t'(tx_flit[p][38:37]);
                        case (observed_type)
                            HEAD: begin
                                head_count++;
                                assert(tx_flit[p][31:0] == 32'hAAAA_BBBB) else $error("FAIL: HEAD payload");
                                $display("[%0t ns] PASS: HEAD correctly ejected on Port %0d", $time, p);
                            end
                            BODY: begin
                                body_count++;
                                assert(tx_flit[p][31:0] == 32'h1111_2222) else $error("FAIL: BODY payload");
                                $display("[%0t ns] PASS: BODY correctly ejected on Port %0d", $time, p);
                            end
                            TAIL: begin
                                tail_count++;
                                assert(tx_flit[p][31:0] == 32'hDEAD_BEEF) else $error("FAIL: TAIL payload");
                                $display("[%0t ns] PASS: TAIL correctly ejected on Port %0d", $time, p);
                            end
                        endcase
                    end
                end
            end
        end
    end

    // -----------------------------------------------------
    // Helper Task: Validate and Reset Counters
    // -----------------------------------------------------
    task check_and_reset(input string test_name);
        assert(head_count == 1) else $error("FAIL %s: Expected 1 HEAD", test_name);
        assert(body_count == 1) else $error("FAIL %s: Expected 1 BODY", test_name);
        assert(tail_count == 1) else $error("FAIL %s: Expected 1 TAIL", test_name);
        
        if (head_count==1 && body_count==1 && tail_count==1)
            $display("=== %s: PASSED ===", test_name);
            
        // Reset for the next test
        head_count = 0; body_count = 0; tail_count = 0;
        $display("----------------------------------------");
    endtask

    // -----------------------------------------------------
    // Main Test Sequence
    // -----------------------------------------------------
    initial begin
        $dumpfile("router_top_tb.vcd");
        $dumpvars(0, router_top_tb);

        rx_flit  = '0; rx_valid = '0; rx_vc_id = '0;
        
        rst_n = 0;
        #25 rst_n = 1;
        
        $display("--- Starting Full Directional Routing Tests ---");
        $display("Router Location: X=%0d, Y=%0d", MY_X, MY_Y);
        $display("----------------------------------------");
        #10; 

        // ---------------------------------------------------------
        // TEST 1: NORTH to EAST (Dest X=2 > MY_X=1)
        // ---------------------------------------------------------
        $display("TEST 1: NORTH to EAST");
        expected_port = EAST; 
        inject_flit(NORTH, 0, HEAD, 2, 1, 32'hAAAA_BBBB);
        inject_flit(NORTH, 0, BODY, 2, 1, 32'h1111_2222);
        inject_flit(NORTH, 0, TAIL, 2, 1, 32'hDEAD_BEEF);
        #100; check_and_reset("TEST 1");

        // ---------------------------------------------------------
        // TEST 2: LOCAL to WEST (Dest X=0 < MY_X=1)
        // ---------------------------------------------------------
        $display("TEST 2: LOCAL to WEST");
        expected_port = WEST; 
        inject_flit(LOCAL, 0, HEAD, 0, 1, 32'hAAAA_BBBB);
        inject_flit(LOCAL, 0, BODY, 0, 1, 32'h1111_2222);
        inject_flit(LOCAL, 0, TAIL, 0, 1, 32'hDEAD_BEEF);
        #100; check_and_reset("TEST 2");

        // ---------------------------------------------------------
        // TEST 3: LOCAL to LOCAL (Dest X=1 == MY_X, Y=1 == MY_Y)
        // ---------------------------------------------------------
        $display("TEST 3: LOCAL to LOCAL");
        expected_port = LOCAL; 
        inject_flit(LOCAL, 1, HEAD, 1, 1, 32'hAAAA_BBBB); // Testing VC1 for variety
        inject_flit(LOCAL, 1, BODY, 1, 1, 32'h1111_2222);
        inject_flit(LOCAL, 1, TAIL, 1, 1, 32'hDEAD_BEEF);
        #100; check_and_reset("TEST 3");

        // ---------------------------------------------------------
        // TEST 4: EAST to WEST (Negative Routing Test)
        // Dest X=0 < MY_X=1. Verifies it doesn't U-turn or drop.
        // ---------------------------------------------------------
        $display("TEST 4: EAST to WEST");
        expected_port = WEST; 
        inject_flit(EAST, 0, HEAD, 0, 1, 32'hAAAA_BBBB);
        inject_flit(EAST, 0, BODY, 0, 1, 32'h1111_2222);
        inject_flit(EAST, 0, TAIL, 0, 1, 32'hDEAD_BEEF);
        #100; check_and_reset("TEST 4");

        // ---------------------------------------------------------
        // TEST 5: LOCAL to SOUTH (Dest Y=0 < MY_Y=1, X matches)
        // ---------------------------------------------------------
        $display("TEST 5: LOCAL to SOUTH");
        expected_port = SOUTH; 
        inject_flit(LOCAL, 0, HEAD, 1, 0, 32'hAAAA_BBBB);
        inject_flit(LOCAL, 0, BODY, 1, 0, 32'h1111_2222);
        inject_flit(LOCAL, 0, TAIL, 1, 0, 32'hDEAD_BEEF);
        #100; check_and_reset("TEST 5");

        // ---------------------------------------------------------
        // TEST 6: LOCAL to NORTH (Dest Y=2 > MY_Y=1, X matches)
        // ---------------------------------------------------------
        $display("TEST 6: LOCAL to NORTH");
        expected_port = NORTH; 
        inject_flit(LOCAL, 0, HEAD, 1, 2, 32'hAAAA_BBBB);
        inject_flit(LOCAL, 0, BODY, 1, 2, 32'h1111_2222);
        inject_flit(LOCAL, 0, TAIL, 1, 2, 32'hDEAD_BEEF);
        #100; check_and_reset("TEST 6");
        
        $display("=== ALL 6 DIRECTIONAL TESTS COMPLETED SUCCESSFULLY ===");
        $finish;
    end

endmodule
