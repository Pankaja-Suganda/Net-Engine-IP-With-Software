# Net-Engine IP with Software

This project provides an FPGA-based hardware accelerator called the **Net Engine** for improving the performance of convolutional neural networks (CNNs) on embedded system. The system accelerates tasks like convolution and max-pooling by offloading them from the CPU to the FPGA.

## Project Overview

The **Net Engine** enhances real-time facial computing by speeding up the execution of deep learning models. The project includes the FPGA hardware design, software drivers, pre-trained neural network models, and test data.

## Implementation

To verify and measure performance, the **Net Engine IP** and **Net Engine Driver** were used to implement the **Proposed Network** for detecting facial bounding boxes. 

- **Net Engine IP**: A hardware IP core designed for efficient convolution operations.
- **Net Engine Driver**: A driver that facilitates communication/ manipulation between the hardware IP and the processing system.

## Folder Structure

```plaintext
Net-Engine-FPGA-With-Software
├───data                     # Input and output data for testing and validation
├───documents                # Detailed documentation and design diagrams
├───images                   # Image files related to the project
├───model                    # Pre-trained model weights for testing
└───source files             # Source code and hardware design files
    ├───net engine driver    # C code for the Net Engine driver
    ├───net engine ip        # Verilog files for the custom IP core
    │   ├───sources          # Verilog source files for the Net Engine IP
    │   └───test bench       # Testbenches for verifying IP functionality
    └───neural network       # Neural network component used for testing
```

# Key Components

## System Overview
For a detailed explanation of the system's architecture and design, please refer to the [System Overview](./documents/system_overview.md).
## Net Engine IP
The Net Engine IP is a custom FPGA block designed to perform 2D convolution and max-pooling operations. It accelerates deep learning tasks by offloading these operations from the CPU to the FPGA. 
Links:
- [Net Engine IP Documentation](./documents/net_engine_ip.md).
- [Source Folder](./source%20files/net%20engine%20ip/sources/).

## Net Engine Driver
The Net Engine Driver is software that configures the Net Engine and manages data transfer between the CPU and the FPGA.
Links:
- [Net Engine Driver Implementation Documentation](./documents/net_engine_driver.md).
- [Source Folder](./source%20files/net%20engine%20driver/).


## Neural Network Implementation
The neural Network Implementation is software component, that can be used to predict a output using above mentioned components. 
Links:
- [Simple Neural Network Implementation Documentation](./documents/neural_network.md).
- [Source Folder](./source%20files/neural%20network/).

## Additional Resources
- Detailed technical documentation is available in the [Dissertation](./academic/Dissertation-23PG1-015.pdf).
- A visual presentation of the implementation and summarized results can be found in the [Project Presentation](./academic/Presentation-23PG1-015.pptx).



