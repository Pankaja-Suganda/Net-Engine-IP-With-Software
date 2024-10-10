# Neural Network Implementation

The neural network module is a fundamental part of the system, consisting of several components such as layers, channels, and kernels. Before processing begins, the weights and biases for each layer are stored in a static memory location on the Processing System (PS).

![Neural Network Component Sequence Diagram](images/neural_network_sequence_diagram.png)  
<p align="center">Figure : The Sequence Diagram of the Neural Network Component</p>

## Overview

The workflow for neural network processing involves interactions between various components during both model initialization and prediction phases. The following sections detail these interactions:

### Initialization Phase

1. **Neural Network Model Setup**:
   - The Neural Network (NN) Model first communicates with the **Net Engine Driver** to initialize the hardware addresses for the Net Engine.
   - It also configures necessary interrupts through the **Interrupt Handler** to manage processing efficiently.

2. **Layer Initialization**:
   - Once the Net Engine is set up, the NN Model initializes its layers.
   - Each layer then initializes its corresponding channels to prepare for data processing.

### Prediction Phase

During the prediction phase, the following sequence occurs:

1. **Triggering Layer Processing**:
   - The NN Model initiates the layer processing, which involves configuring how data will be handled within each channel.

2. **Channel Operations**:
   - Channels are responsible for processing data using the **Net Engine Driver**. They set up data transfers and manage operations related to the hardware.

3. **Interrupt Management**:
   - An important aspect of this process is handling interrupts. The **Interrupt Handler** works with the **Net Engine Driver** to manage any interruptions from the processing unit.
   - This mechanism ensures that data processing can be paused and resumed as necessary, maintaining efficiency and data integrity.

4. **Output Handling**:
   - After processing is complete, the **Net Engine Driver** returns the processed output to the channels, where activation functions are applied.
   - The processed data is then passed back to the layers, which perform any required post-processing before delivering the final output to the NN Model.

### Example Code

The following example demonstrates how to initialize the neural network and add layers:

```c
NeuralNetwork *pnet_model = NULL;
Layer *prev_layer = NULL;
Layer *prev_layer_1 = NULL;
Layer *prev_layer_2 = NULL;

// Initialize the neural network model
NEURAL_NETWORK_init(&pnet_model, (u32*)NN_RECEIVE_MEM_BASE);

// Add layers to the neural network
prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_3X3,
    (Layer_init_cb*)LAYER_CNN_1_init_cb,
    NULL,
    (u32*)NN_MEM_POOL_1_BASE,
    NN_MEM_POOL_1_LEN,
    LAYER_ACTIVATION_RELU);

prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_MAXPOOLING,
    (Layer_init_cb*)LAYER_MAXPOOLING_1_init_cb,
    prev_layer,
    (u32*)NN_MEM_POOL_2_BASE,
    NN_MEM_POOL_2_LEN,
    LAYER_ACTIVATION_NOT_REQUIRED);

prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_3X3,
    (Layer_init_cb*)LAYER_CNN_2_init_cb,
    prev_layer,
    (u32*)NN_MEM_POOL_1_BASE,
    NN_MEM_POOL_1_LEN,
    LAYER_ACTIVATION_RELU);

prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_3X3,
    (Layer_init_cb*)LAYER_CNN_3_init_cb,
    prev_layer,
    (u32*)NN_MEM_POOL_2_BASE,
    NN_MEM_POOL_2_LEN,
    LAYER_ACTIVATION_RELU);

// Branch 1
prev_layer_1 = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_1X1,
    (Layer_init_cb*)LAYER_CNN_4_init_cb,
    prev_layer,
    (u32*)NN_MEM_POOL_3_BASE,
    NN_MEM_POOL_3_LEN,
    LAYER_ACTIVATION_SOFTMAX);

// Branch 2
prev_layer_2 = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_1X1,
    (Layer_init_cb*)LAYER_CNN_5_init_cb,
    prev_layer,
    (u32*)NN_MEM_POOL_1_BASE,
    NN_MEM_POOL_1_LEN,
    LAYER_ACTIVATION_NOT_REQUIRED);
```

### Layer Initialization Callbacks

The following functions demonstrate how each layer is initialized within the neural network:

#### 1. `LAYER_CNN_1_init_cb`

This function initializes the first convolutional layer:

```c
void LAYER_CNN_1_init_cb(Layer *layer, Layer prev_layer) {
    UNUSED(prev_layer);

    // Adding input channels
    LAYER_add_input_channel(layer, INPUT_SIZE, INPUT_SIZE, (u32*)NN_INPUT_RED_CHANNEL);
    LAYER_add_input_channel(layer, INPUT_SIZE, INPUT_SIZE, (u32*)NN_INPUT_GREEN_CHANNEL);
    LAYER_add_input_channel(layer, INPUT_SIZE, INPUT_SIZE, (u32*)NN_INPUT_BLUE_CHANNEL);

    // Adding output channels
    LAYER_add_cnn_output_channels(&layer, (void*)&layer_1_f10_weights, (void*)&PRelu_Layer_2_10_weights, 10, (INPUT_SIZE-2), (INPUT_SIZE-2));
}
```