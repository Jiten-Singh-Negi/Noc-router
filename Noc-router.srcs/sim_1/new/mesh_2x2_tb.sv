`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:28:04
// Design Name: 
// Module Name: mesh_2x2_tb
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

module mesh_2x2_tb;

    parameter int PORTS      = 5;
    parameter int VCS        = 2;
    parameter int FLIT_WIDTH = 39;

    logic clk;
    logic rst_n;

    logic [1:0][1:0][FLIT_WIDTH-1:0] local_rx_flit;
    logic [1:0][1:0]                 local_rx_valid;
    logic [1:0][1:0]                 local_rx_vc_id;
    logic [1:0][1:0][VCS-1:0]        local_rx_credit;

    logic [1:0][1:0][FLIT_WIDTH-1:0] local_tx_flit;
    logic [1:0][1:0]                 local_tx_valid;
    logic [1:0][1:0]                 local_tx_vc_id;
    logic [1:0][1:0][VCS-1:0]        local_tx_credit;

    int head_count = 0;
    int body_count = 0;
    int tail_count = 0;

    mesh_2x2 #(
        .PORTS(PORTS), .VCS(VCS), .FLIT_WIDTH(FLIT_WIDTH)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .local_rx_flit(local_rx_flit), .local_rx_valid(local_rx_valid),
        .local_rx_vc_id(local_rx_vc_id), .local_rx_credit(local_rx_credit),
        .local_tx_flit(local_tx_flit), .local_tx_valid(local_tx_valid),
        .local_tx_vc_id(local_tx_vc_id), .local_tx_credit(local_tx_credit)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Dynamic Credit Return for all endpoints
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            local_tx_credit <= '0;
        end else begin
            local_tx_credit <= '0; 
            for (int x = 0; x < 2; x++) begin
                for (int y = 0; y < 2; y++) begin
                    if (local_tx_valid[x][y]) begin
                        local_tx_credit[x][y][local_tx_vc_id[x][y]] <= 1'b1;
                    end
                end
            end
        end
    end

    // Inject flit at a specific router's LOCAL port
    task inject_flit(
        input int inj_x, input int inj_y, input int vc, input flit_type_t f_type, 
        input logic [1:0] d_x, input logic [1:0] d_y, input logic [31:0] payload
    );
        begin
            @(negedge clk); 
            local_rx_valid[inj_x][inj_y]       = 1'b1;
            local_rx_vc_id[inj_x][inj_y]       = vc[0];
            local_rx_flit[inj_x][inj_y][38:37] = f_type;
            local_rx_flit[inj_x][inj_y][36:35] = d_x;
            local_rx_flit[inj_x][inj_y][34:33] = d_y;
            local_rx_flit[inj_x][inj_y][32]    = vc[0];
            local_rx_flit[inj_x][inj_y][31:0]  = payload;
            @(negedge clk);
            local_rx_valid[inj_x][inj_y] = 1'b0; 
        end
    endtask

    // Monitor Block checking destination (1,1)
    initial begin
        flit_type_t observed_type; 
        forever begin
            @(posedge clk); #1; 
            if (local_tx_valid[1][1]) begin
                observed_type = flit_type_t'(local_tx_flit[1][1][38:37]);
                case (observed_type)
                    HEAD: begin
                        head_count++;
                        assert(local_tx_flit[1][1][31:0] == 32'hAAAA_BBBB) else $error("HEAD mismatch");
                        $display("[%0t ns] PASS: HEAD reached (1,1) successfully!", $time);
                    end
                    BODY: begin
                        body_count++;
                        assert(local_tx_flit[1][1][31:0] == 32'h1111_2222) else $error("BODY mismatch");
                        $display("[%0t ns] PASS: BODY reached (1,1) successfully!", $time);
                    end
                    TAIL: begin
                        tail_count++;
                        assert(local_tx_flit[1][1][31:0] == 32'hDEAD_BEEF) else $error("TAIL mismatch");
                        $display("[%0t ns] PASS: TAIL reached (1,1) successfully!", $time);
                    end
                endcase
            end
        end
    end

    // Main Test Sequence
    initial begin
        $dumpfile("mesh_2x2_tb.vcd");
        $dumpvars(0, mesh_2x2_tb);

        local_rx_flit = '0; local_rx_valid = '0; local_rx_vc_id = '0;
        rst_n = 0; #25 rst_n = 1;
        
        $display("--- Starting 2x2 Mesh Multi-Hop Test ---");
        #10; 

        // Inject at (0,0) targeting (1,1)
        $display("[%0t ns] Injecting packet at Router (0,0) targeting (1,1)...", $time);
        inject_flit(0, 0, 0, HEAD, 1, 1, 32'hAAAA_BBBB);
        inject_flit(0, 0, 0, BODY, 1, 1, 32'h1111_2222);
        inject_flit(0, 0, 0, TAIL, 1, 1, 32'hDEAD_BEEF);

        #150; 
        
        assert(head_count == 1) else $error("FAIL: Expected 1 HEAD");
        assert(body_count == 1) else $error("FAIL: Expected 1 BODY");
        assert(tail_count == 1) else $error("FAIL: Expected 1 TAIL");
        
        if (head_count==1 && body_count==1 && tail_count==1)
            $display("=== MESH VERIFICATION PASSED: 2-Hop XY Routing Successful ===");
            
        $finish;
    end
endmodule