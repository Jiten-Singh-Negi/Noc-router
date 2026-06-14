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


module vc_state_machine #(
    parameter int PORTS = 5
)(
    input  logic clk,
    input  logic rst_n,
    input  logic flit_valid,
    input  logic is_head,
    input  logic is_tail,
    input  logic [$clog2(PORTS)-1:0] route_dest,
    output logic vc_locked,
    output logic [$clog2(PORTS)-1:0] locked_dest  // NOW COMBINATIONAL
);
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        ACTIVE = 2'b01
    } state_t;

    state_t state, next_state;
    
    // Renamed: the actual register is locked_dest_reg
    logic [$clog2(PORTS)-1:0] locked_dest_reg;
    logic [$clog2(PORTS)-1:0] next_locked_dest;

    always_comb begin
        next_state       = state;
        next_locked_dest = locked_dest_reg;
        vc_locked        = 1'b0;
        locked_dest      = locked_dest_reg; // default: use registered value

        case (state)
            IDLE: begin
                if (flit_valid && is_head) begin
                    next_state       = ACTIVE;
                    next_locked_dest = route_dest;
                    vc_locked        = 1'b1;
                    locked_dest      = route_dest; // KEY FIX: immediate combinational output
                end
            end

            ACTIVE: begin
                vc_locked   = 1'b1;
                locked_dest = locked_dest_reg; // use registered value for BODY/TAIL
                if (flit_valid && is_tail) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= IDLE;
            locked_dest_reg <= '0;
        end else begin
            state           <= next_state;
            locked_dest_reg <= next_locked_dest;
        end
    end

endmodule