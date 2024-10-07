
#ifndef UTILITY_H
#define UTILITY_H

#include "layer.h"

typedef struct {
    u8    index;
    float dx1;
    float dy1;
    float dx2;
    float dy2;
    float q1_x;
    float q1_y;
    float q2_x;
    float q2_y;
    float score;
    float nscore;
} BoundingBox;

typedef struct BoundingBox_Node_{
    struct BoundingBox_Node  *next;
    BoundingBox              data;
} BoundingBox_Node;

void generate_bounding_boxes(Layer * layer_imap, Layer *reg, int width, int height, float scale, float threshold, BoundingBox_Node **boundingbox, int *num_boxes);

void image_resize(float* input, float* output, u32 height, u32 width, float scale_factor);

void non_max_suppression(BoundingBox_Node* boxes, int *num_boxes);

#endif // !UTILITY_H