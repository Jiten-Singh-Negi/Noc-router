`timescale 1ns/1ps
import noc_params::*;

module traffic_gen_tb;
    parameter int PORTS      = 5;
    parameter int VCS        = 2;
    parameter int FLIT_WIDTH = 39;
    parameter int NUM_CYCLES = 2000;  
    parameter int PACKET_LEN = 3;    

    logic clk, rst_n;
    logic [1:0][1:0][FLIT_WIDTH-1:0] local_rx_flit;
    logic [1:0][1:0]                 local_rx_valid;
    logic [1:0][1:0]                 local_rx_vc_id;
    logic [1:0][1:0][VCS-1:0]        local_rx_credit;

    logic [1:0][1:0][FLIT_WIDTH-1:0] local_tx_flit;
    logic [1:0][1:0]                 local_tx_valid;
    logic [1:0][1:0]                 local_tx_vc_id;
    logic [1:0][1:0][VCS-1:0]        local_tx_credit;

    int unsigned inject_time  [1:0][1:0]; 
    int unsigned total_latency;
    int unsigned packet_count;
    int unsigned cycle_count;
    integer fd;

    mesh_2x2 #(.PORTS(PORTS), .VCS(VCS), .FLIT_WIDTH(FLIT_WIDTH)) dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .local_rx_flit   (local_rx_flit),
        .local_rx_valid  (local_rx_valid),
        .local_rx_vc_id  (local_rx_vc_id),
        .local_rx_credit (local_rx_credit),
        .local_tx_flit   (local_tx_flit),
        .local_tx_valid  (local_tx_valid),
        .local_tx_vc_id  (local_tx_vc_id),
        .local_tx_credit (local_tx_credit)
    );

    initial clk = 0;
    always #5 clk = ~clk;

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

    always_ff @(posedge clk) begin
        for (int x = 0; x < 2; x++) begin
            for (int y = 0; y < 2; y++) begin
                if (local_tx_valid[x][y]) begin
                    flit_type_t ft;
                    ft = flit_type_t'(local_tx_flit[x][y][38:37]);
                    if (ft == TAIL) begin
                        total_latency += (cycle_count - inject_time[x][y]);
                        packet_count++;
                    end
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycle_count <= 0;
        else        cycle_count <= cycle_count + 1;
    end

    real inj_rate;
    int         flits_to_send    [1:0][1:0];
    int         endpoint_credits [1:0][1:0]; 
    logic [1:0] saved_dest_x     [1:0][1:0];
    logic [1:0] saved_dest_y     [1:0][1:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            local_rx_valid <= '0;
            local_rx_flit  <= '0;
            local_rx_vc_id <= '0;
            for (int x = 0; x < 2; x++) begin
                for (int y = 0; y < 2; y++) begin
                    flits_to_send[x][y]    <= 0;
                    endpoint_credits[x][y] <= 4; 
                end
            end
        end else begin
            local_rx_valid <= '0; 

            for (int x = 0; x < 2; x++) begin
                for (int y = 0; y < 2; y++) begin
                    
                    int current_creds;
                    current_creds = endpoint_credits[x][y];

                    if (local_rx_credit[x][y][0]) begin
                        current_creds++;
                    end

                    if (current_creds > 0) begin

                        if (flits_to_send[x][y] == 0) begin
                            if ($urandom_range(0, 999) < inj_rate * 1000) begin
                                automatic int dx = $urandom_range(0, 1);
                                automatic int dy = $urandom_range(0, 1);

                                if (dx == x && dy == y) begin
                                    dx = (x == 0) ? 1 : 0; 
                                end

                                saved_dest_x[x][y] <= dx[1:0];
                                saved_dest_y[x][y] <= dy[1:0];

                                local_rx_valid[x][y]       <= 1'b1;
                                local_rx_vc_id[x][y]       <= 1'b0;
                                local_rx_flit[x][y][38:37] <= HEAD;
                                local_rx_flit[x][y][36:35] <= dx[1:0];
                                local_rx_flit[x][y][34:33] <= dy[1:0];
                                local_rx_flit[x][y][32]    <= 1'b0;
                                local_rx_flit[x][y][31:0]  <= $urandom;

                                inject_time[x][y]   <= cycle_count;
                                flits_to_send[x][y] <= PACKET_LEN - 1; 
                                current_creds--; 
                            end

                        end else if (flits_to_send[x][y] > 1) begin
                            local_rx_valid[x][y]       <= 1'b1;
                            local_rx_vc_id[x][y]       <= 1'b0;
                            local_rx_flit[x][y][38:37] <= BODY;
                            local_rx_flit[x][y][36:35] <= saved_dest_x[x][y];
                            local_rx_flit[x][y][34:33] <= saved_dest_y[x][y];
                            local_rx_flit[x][y][32]    <= 1'b0;
                            local_rx_flit[x][y][31:0]  <= $urandom;

                            flits_to_send[x][y] <= flits_to_send[x][y] - 1;
                            current_creds--; 

                        end else begin
                            local_rx_valid[x][y]       <= 1'b1;
                            local_rx_vc_id[x][y]       <= 1'b0;
                            local_rx_flit[x][y][38:37] <= TAIL;
                            local_rx_flit[x][y][36:35] <= saved_dest_x[x][y];
                            local_rx_flit[x][y][34:33] <= saved_dest_y[x][y];
                            local_rx_flit[x][y][32]    <= 1'b0;
                            local_rx_flit[x][y][31:0]  <= $urandom;

                            flits_to_send[x][y] <= 0;
                            current_creds--; 
                        end
                    end
                    
                    endpoint_credits[x][y] <= current_creds;
                end
            end
        end
    end

    initial begin
        fd = $fopen("noc_results.csv", "w");
        if (fd == 0) begin
            $display("ERROR: Could not open noc_results.csv for writing");
            $finish;
        end
        $fdisplay(fd, "Injection_Rate,Average_Latency,Throughput");

        local_rx_flit  = '0;
        local_rx_valid = '0;
        local_rx_vc_id = '0;

        rst_n = 0;
        #30;
        rst_n = 1;
        #20;

        $display("--- Starting Traffic Sweep ---");
        $display("%-12s %-16s %-16s %-10s", "Rate", "Avg_Latency", "Throughput", "Packets");
        $display("------------------------------------------------------------");

        for (real r = 0.05; r <= 0.91; r = r + 0.05) begin
            inj_rate = r;

            total_latency = 0;
            packet_count  = 0;
            cycle_count   = 0;

            repeat(500) @(posedge clk);

            total_latency = 0;
            packet_count  = 0;
            cycle_count   = 0;

            repeat(NUM_CYCLES) @(posedge clk);

            begin
                real avg_lat, throughput;
                avg_lat = (packet_count > 0) ? (real'(total_latency) / real'(packet_count)) : 0.0;
                throughput = real'(packet_count) / real'(4 * NUM_CYCLES);

                $fdisplay(fd, "%.2f,%.2f,%.4f", r, avg_lat, throughput);
                $display("%-12.2f %-16.1f %-16.4f %-10d", r, avg_lat, throughput, packet_count);
            end
        end

        $fclose(fd);
        $display("------------------------------------------------------------");
        $display("--- Sweep complete. Results written to noc_results.csv ---");
        $display("--- Run: python plot_performance.py to generate graphs ---");
        $finish;
    end
endmodule