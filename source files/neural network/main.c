
#include <stdio.h>
#include <xil_printf.h>
#include <xil_types.h>
#include "neural_network.h"
#include "layer.h"
#include "test_sample.h"
#include "conv_layer.h"
#include "xscutimer.h"
#include "utility.h"
#include "time_measure.h"
#include "sleep.h"

#ifndef DDR_BASE_ADDR
#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, \
DEFAULT SET TO 0x01000000
#define MEM_BASE_ADDR		0x01000000
#else
#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x1000000)
#endif

#define NN_INPUT_SIZE             (0xA000)
#define NN_INPUT_RED_CHANNEL      (MEM_BASE_ADDR + 0x00300000)
#define NN_INPUT_GREEN_CHANNEL    (NN_INPUT_RED_CHANNEL   + 0xA000)
#define NN_INPUT_BLUE_CHANNEL     (NN_INPUT_GREEN_CHANNEL + 0xA000)

#define NN_RECEIVE_MEM_BASE (MEM_BASE_ADDR + 0x00400000)
#define NN_RECEIVE_MEM_LEN  (0xA000)
#define NN_RECEIVE_MEM_HIGH (NN_RECEIVE_MEM_BASE + NN_RECEIVE_MEM_LEN)

#define FIRST_CONV_LAYER_MEM_BASE (MEM_BASE_ADDR + 0x00500000)
#define FIRST_CONV_LAYER_MEM_LEN  (0x200000)
#define FIRST_CONV_LAYER_MEM_HIGH (FIRST_CONV_LAYER_MEM_BASE + FIRST_CONV_LAYER_MEM_LEN)


#define NN_MEM_POOL_1_BASE        (MEM_BASE_ADDR + 0x00500000)
#define NN_MEM_POOL_1_LEN         0x0005DCC8
#define NN_MEM_POOL_1_HIGH        (NN_MEM_POOL_1_BASE + NN_MEM_POOL_1_LEN)

#define NN_MEM_POOL_2_BASE        (NN_MEM_POOL_1_HIGH)
#define NN_MEM_POOL_2_LEN         NN_MEM_POOL_1_LEN
#define NN_MEM_POOL_2_HIGH        (NN_MEM_POOL_2_BASE + NN_MEM_POOL_2_LEN)

#define NN_MEM_POOL_3_BASE        (NN_MEM_POOL_2_HIGH)
#define NN_MEM_POOL_3_LEN         NN_MEM_POOL_1_LEN
#define NN_MEM_POOL_3_HIGH        (NN_MEM_POOL_3_BASE + NN_MEM_POOL_3_LEN)

#define INPUT_SIZE  100
#define OUTPUT_SIZE 98
#define CNN_INPUT_SIZE_2  49
#define CNN_OUTPUT_SIZE_2 47
#define CNN_INPUT_SIZE_3  47
#define CNN_OUTPUT_SIZE_3 45
#define CNN_OUTPUT_SIZE_4 CNN_OUTPUT_SIZE_3
#define CNN_OUTPUT_SIZE_5 CNN_OUTPUT_SIZE_3

#define MAX_POOLING_POOL_SIZE_1  2
#define MAX_POOLING_STRIDE_1     2
#define MAX_POOLING_PADDING_1    0
#define MAX_POOLING_OUT_SIZE     49
#define MAX_POOLING_OUT_CHANNELS 10

#define UNUSED(x) (void)(x)

#define PROCESS_TIME_MEASURE


Layer *layer_list[10] = {NULL};

void Test_NN_Model(NeuralNetwork *model){
    xil_printf("NN Model\r\n");
    xil_printf("Status          %d \r\n", model->status);
    xil_printf("Completed Count %d \r\n", model->completed_count);
    xil_printf("Layer Count     %d \r\n", model->layer_count);
    xil_printf("Receive Ptr     %p \r\n\n", model->receive_memory_ptr);

    NN_Layer_Node *layer = NULL;
    Channel_Node  *channel = NULL;
    Channel_Kernal_Data_Node *kernals = NULL;

    layer = model->layers;

    while (layer != NULL) {
        xil_printf("Layer %d - T(%d), S(%d), MP(%p), MT(%p), MA(%d), MU(%d) \r\n", 
            layer->layer.index,
            layer->layer.type,
            layer->layer.state,
            layer->layer.memory.memory_ptr,
            layer->layer.memory.memory_tail,
            layer->layer.memory.availale_mem_size,
            layer->layer.memory.used_mem_size
            );
        // xil_printf("\tType %p \r\n", layer->layer.type);
        // xil_printf("\tState %p \r\n", layer->layer.state);
        // xil_printf("\tInput Channel Count  %d \r\n", layer->layer.input_channels.count);
        // xil_printf("\tOutput Channel Count %d \r\n", layer->layer.output_channels.count);
        // xil_printf("\tMemory Ptr  %p \r\n", layer->layer.memory.memory_ptr);
        // xil_printf("\tMemory Tail %p \r\n", layer->layer.memory.memory_tail);
        // xil_printf("\tMemory available %d \r\n", layer->layer.memory.availale_mem_size);
        // xil_printf("\tMemory Used      %d \r\n\n", layer->layer.memory.used_mem_size);
        xil_printf("Input Channels %d\n", layer->layer.input_channels.count);
        channel = layer->layer.input_channels.channels;

        while (channel != NULL) {
            xil_printf("\tIndex %d - S(%d), T(%d), KC(%d), H(%d), W(%d), Tb(%d), IP(%p), TP(%p), OP(%p) \r\n", 
                channel->data.index,
                channel->data.state,
                channel->data.type,
                channel->data.kernal_data_count,
                channel->data.height,
                channel->data.width,
                channel->data.total_bytes,
                channel->data.input_ptr,
                channel->data.temp_ptr,
                channel->data.output_ptr
                );
            // xil_printf("\t\tSate  %d\n", channel->data.state);
            // xil_printf("\t\tChannel Count %d\n", channel->data.kernal_data_count);
            // xil_printf("\t\tHeight        %d\n", channel->data.height);
            // xil_printf("\t\tWidth         %d\n", channel->data.width);
            // xil_printf("\t\tTotal bytes   %d\n", channel->data.total_bytes);
            // xil_printf("\t\tInput Ptr     %p\n", channel->data.input_ptr);
            // xil_printf("\t\tOutput Ptr    %p\n", channel->data.output_ptr);
            // xil_printf("\t\tTemp Ptr      %p\n", channel->data.temp_ptr);
            channel = channel->next;
        }

        xil_printf("Output Channels %d\n", layer->layer.output_channels.count);
        channel = layer->layer.output_channels.channels;

        while (channel != NULL) {
            xil_printf("\tIndex %d - S(%d), T(%d), KC(%d), H(%d), W(%d), Tb(%d), IP(%p), TP(%p), OP(%p) \r\n", 
                channel->data.index,
                channel->data.state,
                channel->data.type,
                channel->data.kernal_data_count,
                channel->data.height,
                channel->data.width,
                channel->data.total_bytes,
                channel->data.input_ptr,
                channel->data.temp_ptr,
                channel->data.output_ptr
                );

            kernals = channel->data.cnn_data.kernal_node;
            while (kernals != NULL) {
                // xil_printf("\t\t Kernal %d - S(%d), R(%p), K1(%08x), K2(%08x), B(%08x)\r\n",
                //     kernals->data.index,
                //     kernals->data.state,
                //     kernals->data.reference,
                //     kernals->data.Kernal.Kernal_1,
                //     kernals->data.Kernal.Kernal_2,
                //     // kernals->data.Kernal.Kernal_3,
                //     // kernals->data.Kernal.Kernal_4,
                //     // kernals->data.Kernal.Kernal_5,
                //     // kernals->data.Kernal.Kernal_6,
                //     // kernals->data.Kernal.Kernal_7,
                //     // kernals->data.Kernal.Kernal_8,
                //     // kernals->data.Kernal.Kernal_9,
                //     kernals->data.Bias
                //     );
                kernals = kernals->next;
            }
            // xil_printf("\t\tIndex %d\n", channel->data.index);
            // xil_printf("\t\tSate  %d\n", channel->data.state);
            // xil_printf("\t\tChannel Count %d\n", channel->data.kernal_data_count);
            // xil_printf("\t\tHeight        %d\n", channel->data.height);
            // xil_printf("\t\tWidth         %d\n", channel->data.width);
            // xil_printf("\t\tTotal bytes   %d\n", channel->data.total_bytes);
            // xil_printf("\t\tInput Ptr     %p\n", channel->data.input_ptr);
            // xil_printf("\t\tOutput Ptr    %p\n", channel->data.output_ptr);
            // xil_printf("\t\tTemp Ptr      %p\n", channel->data.temp_ptr);
            channel = channel->next;
        }


        layer = layer->next;
    }
}

void LAYER_CNN_1_init_cb(Layer *layer, Layer prev_layer){
    UNUSED(prev_layer);

    // adding input channels
    LAYER_add_input_channel(layer, INPUT_SIZE, INPUT_SIZE, (u32*)NN_INPUT_RED_CHANNEL);
    LAYER_add_input_channel(layer, INPUT_SIZE, INPUT_SIZE, (u32*)NN_INPUT_GREEN_CHANNEL);
    LAYER_add_input_channel(layer, INPUT_SIZE, INPUT_SIZE, (u32*)NN_INPUT_BLUE_CHANNEL);

    // adding output channels
    LAYER_add_cnn_output_channels(&layer, (void*)&layer_1_f10_weights, (void*)&PRelu_Layer_2_10_weights, 10, (INPUT_SIZE-2), (INPUT_SIZE-2));
}

void LAYER_CNN_2_init_cb(Layer *layer, Layer prev_layer){
    Channel_Node * prev_output_channels = NULL;

    prev_output_channels = prev_layer.output_channels.channels;

    while(prev_output_channels != NULL){
        LAYER_add_input_channel(layer, prev_output_channels->data.height, prev_output_channels->data.width, prev_output_channels->data.output_ptr);

        prev_output_channels = (Channel_Node *)prev_output_channels->next;
    }

    layer->input_channels.count    = prev_layer.output_channels.count;

    // adding output channels
    LAYER_add_cnn_output_channels(&layer, (void*)&layer_4_f16_weights, (void*)&PRelu_Layer_5_16_weights, 16, CNN_OUTPUT_SIZE_2, CNN_OUTPUT_SIZE_2);
}

void LAYER_CNN_3_init_cb(Layer *layer, Layer prev_layer){
    Channel_Node * prev_output_channels = NULL;

    prev_output_channels = prev_layer.output_channels.channels;

    while(prev_output_channels != NULL){
        LAYER_add_input_channel(layer, prev_output_channels->data.height, prev_output_channels->data.width, prev_output_channels->data.output_ptr);

        prev_output_channels = (Channel_Node *)prev_output_channels->next;
    }

    layer->input_channels.count = prev_layer.output_channels.count;

    // adding output channels
    LAYER_add_cnn_output_channels(&layer, (void*)&layer_6_f32_weights, (void*)&PRelu_Layer_7_32_weights, 32, CNN_OUTPUT_SIZE_3, CNN_OUTPUT_SIZE_3);

}

void LAYER_CNN_4_init_cb(Layer *layer, Layer prev_layer){
    Channel_Node * prev_output_channels = NULL;

    prev_output_channels = prev_layer.output_channels.channels;

    while(prev_output_channels != NULL){
        LAYER_add_input_channel(layer, prev_output_channels->data.height, prev_output_channels->data.width, prev_output_channels->data.output_ptr);

        prev_output_channels = (Channel_Node *)prev_output_channels->next;
    }

    layer->input_channels.count = prev_layer.output_channels.count;

    // adding output channels
    LAYER_add_cnn_1x1_output_channels(&layer, (void*)&layer_8_f2_weights, (void*)&layer_8_f2_bias, 64, 2, CNN_OUTPUT_SIZE_4, CNN_OUTPUT_SIZE_4);

}

void LAYER_CNN_5_init_cb(Layer *layer, Layer prev_layer){
    Channel_Node * prev_output_channels = NULL;

    prev_output_channels = prev_layer.output_channels.channels;

    while(prev_output_channels != NULL){
        LAYER_add_input_channel(layer, prev_output_channels->data.height, prev_output_channels->data.width, prev_output_channels->data.output_ptr);

        prev_output_channels = (Channel_Node *)prev_output_channels->next;
    }

    layer->input_channels.count = prev_layer.output_channels.count;

    // adding output channels
    LAYER_add_cnn_1x1_output_channels(&layer, (void*)&layer_9_f4_weights, (void*)&layer_9_f4_bias, 128, 4, CNN_OUTPUT_SIZE_4, CNN_OUTPUT_SIZE_4);

}

void LAYER_MAXPOOLING_1_init_cb(Layer *layer, Layer prev_layer){
    UNUSED(prev_layer);

    LAYER_link(&prev_layer, layer);

    // adding output channels
    LAYER_add_maxpool_output_channels(
        &layer, 
        MAX_POOLING_POOL_SIZE_1, 
        MAX_POOLING_STRIDE_1, 
        MAX_POOLING_PADDING_1, 
        MAX_POOLING_OUT_CHANNELS,
        MAX_POOLING_OUT_SIZE, 
        MAX_POOLING_OUT_SIZE);
}


#define CONF_THRESHOLD 0.5
#define NMS_THRESHOLD 0.5
#define IMAGE_SIZE 45


void append_bounding_boxes(BoundingBox_Node **bb_list, BoundingBox_Node *boundingboxs) {
    BoundingBox_Node *head_list = *bb_list;
    BoundingBox_Node *head = boundingboxs;
    int last_index = 0;

    if (head_list == NULL) {
        *bb_list = head;
        while (head != NULL) {
            head->data.index = last_index;
            last_index++;
            head = head->next;
        }
        xil_printf("Last index %d \n", last_index);
        return;
    }

    while (head_list->next != NULL) {
        last_index++;
        head_list = head_list->next;
    }

    last_index++; // To move to the next index after the last node.

    while (head != NULL) {
        head->data.index = last_index;
        head_list->next = head;
        head_list = head_list->next;
        last_index++;
        head = head->next;
    }
    xil_printf("Last index %d \n", last_index);
}


int main() {

    NeuralNetwork *pnet_model = NULL;
    Layer *prev_layer = NULL;
    Layer *prev_layer_1 = NULL;
    Layer *prev_layer_2 = NULL;
    int ret = 0;

    float scale = 1.0f; // Example scale
    float threshold = 0.5f; // Example threshold
    // static float bounding_boxes[45 * 45 * 6]; // Allocate space for bounding boxes
    int num_boxes = 0;
    int i = 0;
    float scales[4] = {0.6, 0.42539999999999994, 0.30160859999999995};
    int out_width = 0;
    measure_init();

    xil_printf("System Task\r\n");

    NEURAL_NETWORK_init(&pnet_model, (u32*)NN_RECEIVE_MEM_BASE);
    prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_3X3,        (Layer_init_cb*)LAYER_CNN_1_init_cb,        NULL,       (u32*) NN_MEM_POOL_1_BASE, NN_MEM_POOL_1_LEN, LAYER_ACTIVATION_RELU);
    prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_MAXPOOLING,     (Layer_init_cb*)LAYER_MAXPOOLING_1_init_cb, prev_layer, (u32*) NN_MEM_POOL_2_BASE, NN_MEM_POOL_2_LEN, LAYER_ACTIVATION_NOT_REQUIRED);
    prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_3X3,        (Layer_init_cb*)LAYER_CNN_2_init_cb,        prev_layer, (u32*) NN_MEM_POOL_1_BASE, NN_MEM_POOL_1_LEN, LAYER_ACTIVATION_RELU);
    prev_layer = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_3X3,        (Layer_init_cb*)LAYER_CNN_3_init_cb,        prev_layer, (u32*) NN_MEM_POOL_2_BASE, NN_MEM_POOL_2_LEN, LAYER_ACTIVATION_RELU);
    // branch 1
    prev_layer_1 = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_1X1,      (Layer_init_cb*)LAYER_CNN_4_init_cb,        prev_layer, (u32*) NN_MEM_POOL_3_BASE, NN_MEM_POOL_3_LEN, LAYER_ACTIVATION_SOFTMAX);
    // branch 2
    prev_layer_2 = NEURAL_NETWORK_add_layer(pnet_model, LAYER_TYPE_CNN_1X1,      (Layer_init_cb*)LAYER_CNN_5_init_cb,        prev_layer, (u32*) NN_MEM_POOL_1_BASE, NN_MEM_POOL_1_LEN, LAYER_ACTIVATION_NOT_REQUIRED);

    BoundingBox_Node *boundingboxs      = NULL;
    BoundingBox_Node *boundingboxs_list = NULL;



    // TickType_t tickCount = xTaskGetTickCount();
    for(int k = 0; k < 10; k++){
        printf("Trail %d\n",k);
        for(int j = 0; j < 3; j++){
            printf("Scale %f\n", scales[j]);
            image_resize((float*)&image_channel_red,   (float*)NN_INPUT_RED_CHANNEL,   100, 100, scales[j]);
            image_resize((float*)&image_channel_green, (float*)NN_INPUT_GREEN_CHANNEL, 100, 100, scales[j]);
            image_resize((float*)&image_channel_blue,  (float*)NN_INPUT_BLUE_CHANNEL,  100, 100, scales[j]);

            out_width  = round(100 * scales[j]);

            // Test_NN_Model(pnet_model);

            NEURAL_NETWORK_update(pnet_model, out_width,  out_width);

#ifdef PROCESS_TIME_MEASURE
            measure_start(TIME_MEASURE_SIGNAL_0);
#endif
            NEURAL_NETWORK_process(pnet_model);
        
#ifdef PROCESS_TIME_MEASURE
            measure_end(TIME_MEASURE_SIGNAL_0);
#endif
            // generate_bounding_boxes(prev_layer_1, prev_layer_2, 45, 45, scales[j], threshold, &boundingboxs, &num_boxes);
            // printf("generate_bounding_boxes num_boxes %d\n", num_boxes);

            // non_max_suppression(boundingboxs, &num_boxes);
            // printf("non_max_suppression num_boxes %d\n", num_boxes);

            // append_bounding_boxes(&boundingboxs_list, boundingboxs);

        }
        // non_max_suppression(boundingboxs_list, &num_boxes);
        printf("final non_max_suppression num_boxes %d\n", num_boxes);
    }

    //non_max_suppression(boundingboxs_list, &num_boxes);
    printf("final non_max_suppression num_boxes %d\n", num_boxes);

    xil_printf("completed \n");


    while(TRUE){
        xil_printf("System Task Running\r\n");

    }

    return 0;
}

