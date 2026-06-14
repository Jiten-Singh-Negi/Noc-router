# 2x2 Mesh Network-on-Chip (NoC) Router

## Overview
A fully parameterizable, 2x2 Mesh Network-on-Chip (NoC) designed in SystemVerilog. This project implements a high-performance, deadlock-free routing architecture utilizing Virtual Channels (VCs), strict Wormhole flow control, and XY Dimension-Order Routing. 

The design is rigorously verified using a custom statistical traffic generator and Formally Verified using SystemVerilog Assertions (SVA) to guarantee protocol integrity under extreme network congestion.

## Key Architectural Features
* **Topology:** 2x2 Mesh Network with 5-port routers (North, South, East, West, Local).
* **Routing Algorithm:** XY Dimension-Order Routing (guarantees a deadlock-free physical routing path).
* **Flow Control:** Strict Wormhole Routing with credit-based backpressure. Flits are buffered using First-Word Fall-Through (FWFT) FIFOs.
* **Virtual Channels:** Parameterized Virtual Channel (VC) allocation to prevent Head-of-Line (HoL) blocking and maximize crossbar utilization.
* **Switch Allocation:** Round-Robin Arbiters at each output port ensure fair grant allocation.
* **Crossbar Locking:** Stateful crossbar allocation ensures a granted Virtual Channel remains locked from the `HEAD` flit arrival until the `TAIL` flit departs, preventing flit interleaving.

## Formal Verification (SVA)
To ensure enterprise-grade reliability, the RTL includes embedded SystemVerilog Assertions (SVA) to continuously monitor internal states:
* **Mutex Grants:** Guarantees no two input ports are ever granted the same output port simultaneously.
* **Credit Bounds:** Asserts that downstream credit trackers never overflow or underflow (`0 <= count <= MAX_CREDITS`).
* **Wormhole Protocol Integrity:** Proves that `BODY` and `TAIL` flits can only traverse the crossbar if the VC was properly locked by a preceding `HEAD` flit.

## Performance Analysis & Traffic Generation
The verification environment includes a custom probabilistic traffic generator (`traffic_gen_tb.sv`) that subjects the 2x2 mesh to Uniform Random traffic across a sweep of injection rates. 

### Latency vs. Throughput Metrics
**Results:**
* **Zero-Load Latency:** The network exhibits ultra-low latency (~5-18 cycles) in the uncongested linear region (Injection Rate `0.05` - `0.20`).
* **Throughput Tracking:** Actual throughput flawlessly tracks ideal throughput up to `0.20` flits/node/cycle.
* **Saturation Point:** Network saturation is accurately modeled at an injection rate of `0.25`, where maximum FIFO capacity is reached, crossbars lock, and latency asymptotes—demonstrating physically accurate Wormhole Routing backpressure.

## Technologies Used
* **Hardware Description:** SystemVerilog (IEEE 1800-2012)
* **Simulation & Synthesis:** Xilinx Vivado
* **Data Analytics:** Python (Pandas, Matplotlib)