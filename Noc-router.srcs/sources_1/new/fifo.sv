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
    output logic [WIDTH-1:0]        rd_data,  // NOW COMBINATIONAL
    output logic                    empty,
    output logic [$clog2(DEPTH):0]  count
);
    logic [WIDTH-1:0]            mem    [DEPTH];
    logic [$clog2(DEPTH)-1:0]    wr_ptr;
    logic [$clog2(DEPTH)-1:0]    rd_ptr;

    // Combinational flags
    always_comb begin
        full  = (count == DEPTH);
        empty = (count == 0);
    end

    // FWFT: rd_data combinationally shows current head of queue
    // No rd_en needed to SEE the data - rd_en only CONSUMES it
    assign rd_data = mem[rd_ptr];

    // Sequential logic - pointer and count management only
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            // Write logic
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end

            // Read logic - advance pointer only, data visible combinationally
            if (rd_en && !empty) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            end

            // Count logic
            if      (wr_en && !full && rd_en && !empty) count <= count;
            else if (wr_en && !full)                    count <= count + 1;
            else if (rd_en && !empty)                   count <= count - 1;
        end
    end
endmodule
    
            

