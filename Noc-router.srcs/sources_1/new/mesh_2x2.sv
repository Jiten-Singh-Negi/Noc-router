`timescale 1ns/1ps
import noc_params::*;

module mesh_2x2 #(
    parameter int PORTS      = 5,
    parameter int VCS        = 2,
    parameter int FLIT_WIDTH = 39
)(
    input  logic clk,
    input  logic rst_n,

    input  logic [1:0][1:0][FLIT_WIDTH-1:0] local_rx_flit,
    input  logic [1:0][1:0]                 local_rx_valid,
    input  logic [1:0][1:0]                 local_rx_vc_id,
    output logic [1:0][1:0][VCS-1:0]        local_rx_credit,

    output logic [1:0][1:0][FLIT_WIDTH-1:0] local_tx_flit,
    output logic [1:0][1:0]                 local_tx_valid,
    output logic [1:0][1:0]                 local_tx_vc_id,
    input  logic [1:0][1:0][VCS-1:0]        local_tx_credit
);

    localparam int LOCAL = 0;
    localparam int NORTH = 1;
    localparam int SOUTH = 2;
    localparam int EAST  = 3;
    localparam int WEST  = 4;

    logic [1:0][1:0][PORTS-1:0][FLIT_WIDTH-1:0] rx_flit;
    logic [1:0][1:0][PORTS-1:0]                 rx_valid;
    logic [1:0][1:0][PORTS-1:0]                 rx_vc_id;
    logic [1:0][1:0][PORTS-1:0][VCS-1:0]        rx_credit;

    logic [1:0][1:0][PORTS-1:0][FLIT_WIDTH-1:0] tx_flit;
    logic [1:0][1:0][PORTS-1:0]                 tx_valid;
    logic [1:0][1:0][PORTS-1:0]                 tx_vc_id;
    logic [1:0][1:0][PORTS-1:0][VCS-1:0]        tx_credit;

    generate
        for (genvar x = 0; x < 2; x++) begin : COL
            for (genvar y = 0; y < 2; y++) begin : ROW
                router_top #(
                    .PORTS(PORTS), .VCS(VCS), .FLIT_WIDTH(FLIT_WIDTH), .MY_X(x), .MY_Y(y)
                ) router_inst (
                    .clk(clk), .rst_n(rst_n),
                    .rx_flit(rx_flit[x][y]), .rx_valid(rx_valid[x][y]), .rx_vc_id(rx_vc_id[x][y]), .rx_credit(rx_credit[x][y]),
                    .tx_flit(tx_flit[x][y]), .tx_valid(tx_valid[x][y]), .tx_vc_id(tx_vc_id[x][y]), .tx_credit(tx_credit[x][y])
                );
            end
        end
    endgenerate

    always_comb begin
        rx_flit   = '0;
        rx_valid  = '0;
        rx_vc_id  = '0;
        tx_credit = '0;

        // X-DIMENSION WIRING (East-West)
        for (int y = 0; y < 2; y++) begin
            rx_flit[1][y][WEST]   = tx_flit[0][y][EAST];
            rx_valid[1][y][WEST]  = tx_valid[0][y][EAST];
            rx_vc_id[1][y][WEST]  = tx_vc_id[0][y][EAST];
            tx_credit[0][y][EAST] = rx_credit[1][y][WEST];

            rx_flit[0][y][EAST]   = tx_flit[1][y][WEST];
            rx_valid[0][y][EAST]  = tx_valid[1][y][WEST];
            rx_vc_id[0][y][EAST]  = tx_vc_id[1][y][WEST];
            tx_credit[1][y][WEST] = rx_credit[0][y][EAST];
        end

        // Y-DIMENSION WIRING (North-South)
        for (int x = 0; x < 2; x++) begin
            rx_flit[x][1][SOUTH]   = tx_flit[x][0][NORTH];
            rx_valid[x][1][SOUTH]  = tx_valid[x][0][NORTH];
            rx_vc_id[x][1][SOUTH]  = tx_vc_id[x][0][NORTH];
            tx_credit[x][0][NORTH] = rx_credit[x][1][SOUTH];

            rx_flit[x][0][NORTH]   = tx_flit[x][1][SOUTH];
            rx_valid[x][0][NORTH]  = tx_valid[x][1][SOUTH];
            rx_vc_id[x][0][NORTH]  = tx_vc_id[x][1][SOUTH];
            tx_credit[x][1][SOUTH] = rx_credit[x][0][NORTH];
        end

        // LOCAL ENDPOINT WIRING
        for (int x = 0; x < 2; x++) begin
            for (int y = 0; y < 2; y++) begin
                rx_flit[x][y][LOCAL]   = local_rx_flit[x][y];
                rx_valid[x][y][LOCAL]  = local_rx_valid[x][y];
                rx_vc_id[x][y][LOCAL]  = local_rx_vc_id[x][y];
                local_rx_credit[x][y]  = rx_credit[x][y][LOCAL];

                local_tx_flit[x][y]    = tx_flit[x][y][LOCAL];
                local_tx_valid[x][y]   = tx_valid[x][y][LOCAL];
                local_tx_vc_id[x][y]   = tx_vc_id[x][y][LOCAL];
                tx_credit[x][y][LOCAL] = local_tx_credit[x][y];
            end
        end
    end
endmodule