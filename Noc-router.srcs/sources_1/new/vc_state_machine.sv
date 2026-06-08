`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:26:49
// Design Name: 
// Module Name: vc_state_machine
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


module vc_state_machine #(
    parameter int PORTS = 5
)(
    input  logic clk,
    input  logic rst_n,
    
    // Flit Control Signals
    input  logic flit_valid,
    input  logic is_head,
    input  logic is_tail,
    input  logic [$clog2(PORTS)-1:0] route_dest, // Calculated by XY routing logic
    
    // Outputs to the Switch Allocator / Crossbar
    output logic vc_locked,
    output logic [$clog2(PORTS)-1:0] locked_dest
);

    typedef enum logic [1:0] {
        IDLE   = 2'b00, // Waiting for a Head flit
        ACTIVE = 2'b01  // Locked on a packet, waiting for Tail flit
    } state_t;

    state_t state, next_state;
    logic [$clog2(PORTS)-1:0] next_locked_dest;

    // Combinational State Transition Logic
    always_comb begin
        // Default assignments to prevent latches
        next_state       = state;
        next_locked_dest = locked_dest;
        vc_locked        = 1'b0;

        case (state)
            IDLE: begin
                // Only a HEAD flit can claim an idle VC
                if (flit_valid && is_head) begin
                    next_state       = ACTIVE;
                    next_locked_dest = route_dest; // Capture the destination
                    vc_locked        = 1'b1;
                end
            end

            ACTIVE: begin
                vc_locked = 1'b1; // Hold the lock
                
                // Only a TAIL flit can release the VC
                if (flit_valid && is_tail) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Sequential State Memory
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            locked_dest <= '0;
        end else begin
            state       <= next_state;
            locked_dest <= next_locked_dest;
        end
    end

endmodule
