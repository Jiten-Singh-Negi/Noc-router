`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2026 02:07:38
// Design Name: 
// Module Name: round_robin_arbiter
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
module round_robin_arbiter #(
    parameter int PORTS = 5
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [PORTS-1:0] req,
    output logic [PORTS-1:0] grant
);

    // Pointer width dynamically scales based on the number of ports
    logic [$clog2(PORTS)-1:0] priority_ptr;
    logic [$clog2(PORTS)-1:0] next_priority_ptr;
    
    // Double-width vectors for zero-math wrap-around
    logic [(2*PORTS)-1:0]     double_req;
    logic [(2*PORTS)-1:0]     double_grant;

    assign double_req = {req, req};

    // --------------------------------------------------------
    // 1. Grant Computation (Combinational)
    // --------------------------------------------------------
    always_comb begin
        double_grant = '0;
        grant        = '0;
        
        // Scan starting from the priority pointer.
        // The (double_grant == '0) lock ensures only the FIRST active request wins.
        for (int i = 0; i < PORTS; i++) begin
            if (double_req[priority_ptr + i] && (double_grant == '0)) begin
                double_grant[priority_ptr + i] = 1'b1;
            end
        end
        
        // Fold the double-width grant back into the actual output wire
        grant = double_grant[PORTS-1:0] | double_grant[(2*PORTS)-1:PORTS];
    end

    // --------------------------------------------------------
    // 2. Next Priority Calculation (Combinational)
    // --------------------------------------------------------
    // Winner goes to the back of the line.
    always_comb begin
        next_priority_ptr = priority_ptr; // Default: hold state if no requests
        
        for (int i = 0; i < PORTS; i++) begin
            if (grant[i]) begin
                if (i == PORTS - 1) 
                    next_priority_ptr = '0; // Wrap to 0 without division
                else 
                    // Explicit cast prevents strict linter truncation warnings
                    next_priority_ptr = ($clog2(PORTS))'(i + 1); 
            end
        end
    end

    // --------------------------------------------------------
    // 3. Clocked Memory (Sequential)
    // --------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_ptr <= '0;
        end else begin
            priority_ptr <= next_priority_ptr;
        end
    end

endmodule