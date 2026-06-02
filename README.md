\# NoC Router — 5-Port Wormhole Router with Virtual Channels



\## Overview

A parameterized 5-port Network-on-Chip router implementing

XY routing, wormhole flow control, credit-based backpressure,

and 2 virtual channels per port in SystemVerilog.



\## Architecture

\- 5 ports: North, South, East, West, Local

\- 2 Virtual Channels per port

\- 4-flit input buffers per VC

\- Round-robin arbitration

\- Credit-based flow control

\- XY deterministic routing (deadlock-free)



\## Module Status

| Module | Status |

|--------|--------|

| noc\_params.sv | Complete |

| fifo.sv | Complete and verified |

| fifo\_tb.sv | Complete — all 5 tests passing |

| round\_robin\_arbiter.sv | In progress |

| credit\_counter.sv | Not started |

| vc\_state\_machine.sv | Not started |

| router\_top.sv | Not started |



\## Simulation Results

FIFO: All 5 tests passing

\- Reset verified

\- Overflow protection confirmed

\- Data integrity confirmed (10,20,30,40 correct order)

\- Underflow protection confirmed

\- Simultaneous RW stable

\- Reset mid-operation verified



\## Tools

\- Vivado ML Standard 2025.2

\- SystemVerilog IEEE 1800-2017

\- Python 3 for post-processing



\## Target Companies

AMD, NVIDIA, Qualcomm, Astera Labs

