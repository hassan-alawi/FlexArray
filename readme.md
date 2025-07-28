
# Flexible Systolic Array

This project is part of my KAUST summer internship under the direction of my mentor, Mohamed Bouaziz, and Prof. Suhaib Fahmy, in the Accelerated Connected Computing Lab (ACCL). A systolic array preforms accelerated and efficient matrix multiplication of matrices A (MXN), B (NxK) and outputs matrix C (MxK). The goal of this project is to design and implement a Systolic array in RTL, which utilizes DSP floating point primitives as processor elements, and interfaces to an AXI-Stream interface with a parameterizable:
 - Array Dimensions: M rows, K columns, N row/columns
 - Pipeline stages in DSP: (1-5)
 - System Interface bus width: Minimum of 2 (32 bit words)
 - System Interface: Can operate with no data loading and ofloading overhead to model pure compute latency

The hope of this endeavor is that this flexible RTL model can be used to aid systems research in ACCL, and to potentialy develop a reconfigurable dataflow architecture (RDA) from the base systolic array architecture, through more flexible PE interconnects 

## File Structure
To find the RTL files, navigate to sources1/new/  
 - Also includes the header files with interface and type definitions that can be modified  
To find testbench files, navigate to sim1/new/  
To find wave config files, navigate to wavecnfgs/

 
## Design Hierarchy
**sys_array**: Contains array of PEs and system interface, as well as all PE interconnect logic  
&darr;&rarr; **fifo_in**: Connected to input AXI-stream  
&darr;&rarr; **fifo_out**: Connected to output AXI-stream  
&darr;&rarr; **dispatcher**: Intermediarry between AXI-Stream and systolic array. Loads to systolic array  
&darr;&rarr; **collector**: Intermediarry between systolic array and AXI-Stream. Offloads data from systolic array  
&darr;&rarr; **dsp_wrapper**: PE with AXI interface logic, moves operands between neighboring PEs  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&darr;&rarr; **dsp_prim**: Wrapper for DSP primitive. Handles AXI interface blocking mode behavior. Doesn't allow new inputs to pass untill all operands are ready to be passed to the DSP. Fully pipelined operation, so after pipeline full, output data is ready every cycle.  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&darr;&rarr;**DSPFP32**: Xilinix DSP single precision floating point primitive 

![systolic_array_top_level](/uploads/479734d3060b3eb2ba24d3e43eb9c38c/systolic_array_top_level.png)
## Usage

#### Configuring the PE
The current implementation of the systolic array utilizes Xilinix's DSPFP32, as a single precision floating point operator. This uses the Versal AI boards DSP58 primitives. The DSPFP32 has configurable number of internal pipeline stages which are:
 - IN_STAGE_1 (0-1): Input pipeline stages for port A and B inputs
 - IN_STAGE_2 (0-1): Second Input pipeline stage for port A
 - MUL_PIP (0-1): Multiplication unit internal pipline stage
 - MUL_OUT_STAGE (0-1): Multiply output stage
 - ADD_OUT_STAGE (0-1): Adder output stage (Internal accumulator)
 - FPOPMODE_STAGE (0-3): Adder input selector input stages 
 - FPINMODE_STAGE (0-1):  Multiplier input selector input stages

 To configure mode of operation, set MODE:
 - 0: Multiply Accumulate
 - 1: Multiply (Usefull for calculations with N=1)

**Notes**:   
Systolic array only verified with minimumn of single stage execution. Single cycle not verified.  
Currently the PEs only support Multiply-Accumulate and Multiply Modes of operation.  
Ensure that FPOPMODE_STAGE < IN_STAGE_1 + IN_STAGE_2 + MUL_OUT_STAGE for correct operation, otherwise first op might get skipped

#### Configuring Systolic Array Dimensions
The systolic array by itself is fully flexible allowing any combination of:  
- M: Number of rows of input matrix A 
- N: Inner dimension, number of columns of A, rows of B 
- K: Number of Columns of B 

The number of PEs in the systolic array = M*K  
The total number of operations per PE = N   
Total number of operations = N\*M\*K 

#### Configuring System Interface
Users of the device can opt out of using the AXI-stream system interface and simply modeling how long it takes the systolic array to start and finish a computation, with data preloaded. To do so, set the parameter:
- NO_MEM: Removes AXI-stream interface, which includes the input/out FIFOs and dispatcher, and uses pre-loaded shift registers, connected to edge PEs, that pass data when PE is ready to accept it. There is a per-edge PE counter that counts how many operands passed in to ensure only N shifts occur. tb_sys_array polls for the done signal then reads the array of output signal and compares it to the computed output matrix to check for correctnes. The TB also has a cycle counter to measure compute latency

Otherwise if you want an accurate system simulation you would set NO_MEM to 0. This removes the shift register and counter logic and replaces it with dispatcher. This unit reads from the input FIFO and distributes the operands to their associated edge PEs, and collects the output when done to fill the output FIFO. You can configure the system interface and the dispatcher with the parameter:  
- BW: Bus Width (in terms of 32-bit Words). The bigger the BW, the wider the FIFO registers are, and the more edge PEs get passed their operands in a single cycle 

The use of the dispatcher and its design constrains the systolic array parameters. The constraints are:  
- BW is a multiple of 2 (Minimum of 2)
- M = K
- M = BW*g/2, where g is a scaling factor and integer s.t. g>=1

If these constraints are not maintained, then the dispatcher logic fails

#### Memory Layout
The use of the dispatcher also constrains how the input and output memory layout should look like.  
For input data, the dispatcher utilizes an interleaved operand format that looks like (assume a<sub>i,j</sub> means row i and col j from matrix A):  
**[a<sub>1,j</sub>, b<sub>j,1</sub>, a<sub>2,j</sub>, b<sub>j,2</sub>, ..., a<sub>M_j</sub>, b<sub>j,K</sub>, a<sub>1,j+1</sub>, b<sub>j+1,1</sub>, ...]**   

The dispatcher attempts to pass along a column of A and a row of B, for one of N iterations  
   
On each cycle the dispatcher takes **[a<sub>n_j</sub>, b<sub>j,n</sub>, ..., a<sub>n+BW/2,j</sub>, b<sub>j,n+BW/2</sub>]** operands and passes them to their edge PE. This ensures that on each cycle, PE<sub>i,j</sub> has both its operands ready to be processed as well as all PEs to the left or above it  

The bigger the BW relative to M/K, the faster a row or column of A and B respectivley is passed into the systolic array 

For the output data, the dispatcher also follows an interleaved model in the sense that it packs an element alongside its neighbor in the adjacent column as follows:  
**[c<sub>1,1</sub>, c<sub>1,2</sub>, ... , c<sub>1+BW/2,1</sub>, c<sub>1+BW/2,2</sub>]**   
  
In a single output FIFO register this is what you would find, or a single stream cycle of width BW. The larger BW again, the faster the output of the systolic array is read 


## Future Development
The current implementation can be improved in many ways, and is modular enough to be fashioned for specific experiemental setups

#### RDA Support
- Can add RDA functionality by making the interface per PE simialr to Xilinix and AMD's AI engine interface, in which there is a North, East, South, West I/O based interface by modifying the, currently fixed direction, dsp_wrapper module
- Adding per PE configuration memory that controls which of these ports is used for what purpose is possible by configuring the dsp_wrapper 
- Adding a second module in charge of transporting the AXI stream configuration data to these per PE memory, seperate from the dispatcher

#### Custom Internconnect Topology
- Similarly to RDA support, if in need of a different topology for how data would be routed, changes to the interconnection logic in sys_array is necessary. In addition, modifications to the dsp_wrapper module are also needed so the PE doesn't stall waiting on data that may not come (e.g. tying one of its inputs to 0)

#### Increased PE Functions
- If the goal is to include add and add acumulate functionality, then his would be a simple task, as it means adding more FPOPMODE configurations in the dsp_add_conf enum type within the dsp_sys_arr_pkg.vh and adding a given case statement within the dsp_prim file. Some re-routing logic would also be necessary to pass the A and B inputs to ports C and D instead, for pure add functionality. For more information on the DSPFP32 architechure, refer to [Architecture Manual](https://docs.amd.com/r/en-US/am004-versal-dsp-engine/DSPFP32-Unisim-Primitive). For more information on the primitive parameters and configuration refer to [User Guide](https://docs.amd.com/r/en-US/ug1344-versal-architecture-libraries/DSPFP32)

- For more variety of operations and functions beyond single precision floating point addition and multiplication, replacing the DSPFP32 primitive might be necessary. You can implement chains of primitives or other ALUs/functional units within the dsp_prim file and the systolic array would function as intended. This is conditioned on the implementation of an AXI interface with blocking mode behavior and proper assertion of the processing signal 

#### Replacing Dispatcher
- If in need of a simpler memory layout, more efficient dispatcher, or more flexibility with the system parameters, the logic can be rewritten in the dispatcher module, as long as it utilizes the same interface currently supplies


## Authors

- Hassan Al-alawi [@alawih](https://gitlab.kaust.edu.sa/alawih)


