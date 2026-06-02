`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.05.2026 23:24:16
// Design Name: 
// Module Name: fifo
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



module fifo #(
    parameter int DEPTH = 4,
    parameter int WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    wr_en,
    input  logic [WIDTH-1:0]        wr_data,
    output logic                    full,
    input  logic                    rd_en,
    output logic [WIDTH-1:0]        rd_data,
    output logic                    empty,
    output logic [$clog2(DEPTH):0]  count
);

    // Internal Memory and Pointers
    logic [WIDTH-1:0] mem [DEPTH];
    logic [$clog2(DEPTH)-1:0] wr_ptr;
    logic [$clog2(DEPTH)-1:0] rd_ptr;

    // Instant Warning Flags
    always_comb begin
        full  = (count == DEPTH);
        empty = (count == 0);
    end

    // Sequential Clocked Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // RESET: Clear the room
            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
        end else begin
            
            // 1. WRITE LOGIC
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                // Pointer wrap-around logic
                if (wr_ptr == DEPTH - 1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
            end
            
            // 2. READ LOGIC
            if (rd_en && !empty) begin
                rd_data <= mem[rd_ptr];
                // Pointer wrap-around logic
                if (rd_ptr == DEPTH - 1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
            end
            
            // 3. COUNT LOGIC (Handling simultaneous operations)
            if (wr_en && !full && rd_en && !empty) begin
                count <= count;     // +1 and -1 cancel out, do nothing
            end else if (wr_en && !full) begin
                count <= count + 1; // Only entering
            end else if (rd_en && !empty) begin
                count <= count - 1; // Only leaving
            end
            
        end
    end

endmodule
    
            

