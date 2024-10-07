# Net-Engine FPGA with Software

This project provides an FPGA-based hardware accelerator called the **Net Engine** for improving the performance of convolutional neural networks (CNNs) on resource-constrained edge devices. The system accelerates tasks like convolution and max-pooling by offloading them from the CPU to the FPGA.

## Project Overview

The **Net Engine** enhances real-time facial computing by speeding up the execution of deep learning models. The project includes the FPGA hardware design, software drivers, pre-trained neural network models, and test data.

## Folder Structure

```plaintext
Net-Engine-FPGA-With-Software
├───data                     # Input and output data for testing and validation
├───documents                # Detailed documentation and design diagrams
├───images                   # Image files related to the project
├───model                    # Pre-trained model weights for testing
└───source files             # Source code and hardware design files
    ├───net engine driver    # C code for the Net Engine driver
    ├───net engine ip        # Verilog/VHDL files for the custom IP core
    │   ├───sources          # HDL source files for the Net Engine IP
    │   └───test bench       # Testbenches for verifying IP functionality
    └───neural network       # Neural network code used for testing
```

# Key Components

## Net Engine IP
The Net Engine IP is a custom FPGA block designed to perform 2D convolution and max-pooling operations. It accelerates deep learning tasks by offloading these operations from the CPU to the FPGA.

- Input: Data is streamed using AXI interfaces.
- Output: Processed data is returned to memory using DMA.

## Net Engine Driver

The Net Engine Driver is software that configures the Net Engine and manages data transfer between the CPU and the FPGA.

Key functions:
- NET_ENGINE_init(): Initializes the Net Engine.
- NET_ENGINE_config(): Configures the operation and kernel settings.
- NET_ENGINE_process(): Sends data to the FPGA for processing.

## Neural Network Implementation

