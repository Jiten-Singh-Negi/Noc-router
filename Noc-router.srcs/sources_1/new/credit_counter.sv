`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2026 16:25:34
// Design Name: 
// Module Name: credit_counter
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


module credit_counter #(
    parameter int MAX_CREDITS = 4
)(
    input  logic clk,
    input  logic rst_n,
    
    input  logic flit_sent,  // Decrement: We pushed a flit out
    input  logic credit_rx,  // Increment: Downstream router popped a flit
    
    output logic has_credit  // High if we are allowed to send
);

    // Width needs to hold values 0 through MAX_CREDITS
    logic [$clog2(MAX_CREDITS + 1)-1:0] count;

    assign has_credit = (count > 0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= MAX_CREDITS; // FIFOs start completely empty (full credits)
        end else begin
            // Simultaneous send and receive: counter stays the same
            if (flit_sent && credit_rx) begin
                count <= count;
            end 
            // Send only: decrement (with underflow protection)
            else if (flit_sent && !credit_rx) begin
                if (count > 0) count <= count - 1;
            end 
            // Receive only: increment (with overflow protection)
            else if (!flit_sent && credit_rx) begin
                if (count < MAX_CREDITS) count <= count + 1;
            end
        end
    end

endmodule