`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.05.2026 23:23:12
// Design Name: 
// Module Name: noc_params
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


package noc_params;
        //Network Dimensions
        parameter int MESH_X =4;  // number of colouns
        parameter int MESH_Y = 4;  // number of rows in mesh
        parameter int COORD_BITS = 2; //bits needed for coordinates $clog2(4) = 2 , clog is no of wires , clog is ceiliong of log base 2
        
        // Flit Dimesions 
        parameter int DATA_WIDTH = 32; // flit payload in bits
        parameter int NUM_PORTS = 5; 
        parameter int NUM_VCS = 2;
        parameter int BUFFER_DEPTH = 4; // flit slots per VC FIFO
        parameter int CREDIT_WIDTH = 3; //$clog2(buffer depth + 1) = if  chairs , we can have 5 states so need 3 bits/wires to tell so log2(5) = 2.32 = 3
        
        //PORT DIRECTION ENCODING
        parameter int PORT_LOCAL    = 0;
        parameter int PORT_NORTH    = 1;
        parameter int PORT_SOUTH    = 2;
        parameter int PORT_EAST     = 3;
        parameter int PORT_WEST     = 4; 
        
        //Flit type
        typedef enum logic [1:0]{
            HEAD = 2'b00,
            BODY = 2'b01,
            TAIL = 2'b10
        } flit_type_t;
        
        //Flit Structure
        typedef struct packed {
            flit_type_t         flit_type; // HEAD, BODY, or TAIL
            logic [COORD_BITS-1:0]   dest_x;     // destination X coordinate
            logic [COORD_BITS-1:0]   dest_y;     // destination Y coordinate
            logic                    vc_id;       // which VC (0 or 1)
            logic [DATA_WIDTH-1:0]   data;        // payload
        } flit_t;
        
endpackage
