#include "utility.h"
#include <math.h>
#include <stdio.h>
#include <string.h>
#include <xil_printf.h>

// #define STRIDE 2
// #define CELLSIZE 12
#define STRIDE   1
#define CELLSIZE 20
#define NMS_THRESHOLD 0.5

// // Utility function to transpose a matrix
// void transpose(float *src, float *dest, int width, int height) {
//     for (int i = 0; i < height; ++i) {
//         for (int j = 0; j < width; ++j) {
//             dest[j * height + i] = src[i * width + j];
//         }
//     }
// }

// // Utility function to perform NMS
// void non_maximum_suppression(float *boxes, int num_boxes, float threshold, const char *method, int *pick, int *num_pick) {
//     if (num_boxes == 0) {
//         *num_pick = 0;
//         return;
//     }

//     float *x1 = (float *)malloc(num_boxes * sizeof(float));
//     float *y1 = (float *)malloc(num_boxes * sizeof(float));
//     float *x2 = (float *)malloc(num_boxes * sizeof(float));
//     float *y2 = (float *)malloc(num_boxes * sizeof(float));
//     float *s = (float *)malloc(num_boxes * sizeof(float));
//     float *area = (float *)malloc(num_boxes * sizeof(float));

//     // Extract box coordinates and scores
//     for (int i = 0; i < num_boxes; ++i) {
//         x1[i] = boxes[i * 5 + 0];
//         y1[i] = boxes[i * 5 + 1];
//         x2[i] = boxes[i * 5 + 2];
//         y2[i] = boxes[i * 5 + 3];
//         s[i] = boxes[i * 5 + 4];
//         area[i] = (x2[i] - x1[i] + 1) * (y2[i] - y1[i] + 1);
//     }

//     int *sorted_indices = (int *)malloc(num_boxes * sizeof(int));
//     for (int i = 0; i < num_boxes; ++i) {
//         sorted_indices[i] = i;
//     }

//     // Sort indices by scores
//     for (int i = 0; i < num_boxes - 1; ++i) {
//         for (int j = i + 1; j < num_boxes; ++j) {
//             if (s[sorted_indices[i]] < s[sorted_indices[j]]) {
//                 int temp = sorted_indices[i];
//                 sorted_indices[i] = sorted_indices[j];
//                 sorted_indices[j] = temp;
//             }
//         }
//     }

//     int count = 0;
//     for (int i = 0; i < num_boxes; ++i) {
//         int idx = sorted_indices[i];
//         int keep = 1;
//         for (int j = 0; j < count; ++j) {
//             int other_idx = pick[j];
//             float xx1 = fmaxf(x1[idx], x1[other_idx]);
//             float yy1 = fmaxf(y1[idx], y1[other_idx]);
//             float xx2 = fminf(x2[idx], x2[other_idx]);
//             float yy2 = fminf(y2[idx], y2[other_idx]);

//             float w = fmaxf(0.0f, xx2 - xx1 + 1);
//             float h = fmaxf(0.0f, yy2 - yy1 + 1);
//             float inter = w * h;

//             float o;
//             if (strcmp(method, "Min") == 0) {
//                 o = inter / fminf(area[idx], area[other_idx]);
//             } else {
//                 o = inter / (area[idx] + area[other_idx] - inter);
//             }

//             if (o > threshold) {
//                 keep = 0;
//                 break;
//             }
//         }
//         if (keep) {
//             pick[count++] = idx;
//         }
//     }

//     *num_pick = count;

//     free(x1);
//     free(y1);
//     free(x2);
//     free(y2);
//     free(s);
//     free(area);
//     free(sorted_indices);
// }

// add channel size
BoundingBox* BBOX_create(u8 index, float q1_x, float q1_y, float q2_x, float q2_y, float score, float nscore, float dx1, float dy1, float dx2, float dy2){
    BoundingBox *instance = NULL;

    instance = (BoundingBox *)malloc(sizeof(BoundingBox));
    if (instance == NULL) {
        printf("BoundingBox malloc failed\n");
        return NULL;
    }
    
    instance->index = index;
    instance->q1_x = q1_x;
    instance->q1_y = q1_y;
    instance->q2_x = q2_x;
    instance->q2_y = q2_y;
    instance->score = score;
    instance->nscore = nscore;
    instance->dx1 = dx1;
    instance->dy1 = dy1;
    instance->dx2 = dx2;
    instance->dy2 = dy2;

    return instance;
}

static BoundingBox_Node* create_bbox_node(BoundingBox data){
    BoundingBox_Node* new = (BoundingBox_Node*)malloc(sizeof(BoundingBox_Node));
    if(new == NULL){
        xil_printf("Node malloc error \r\n");
        return NULL;
    }
    new->data = data;
    new->next = NULL;

    return new;
}

static void append_bbox(BoundingBox_Node** head_ref, BoundingBox new_data) {
    BoundingBox_Node* new = create_bbox_node(new_data);
    if (new == NULL) {
        return;
    }

    if (*head_ref == NULL) {
        *head_ref = new;
        return;
    }

    BoundingBox_Node* last = (BoundingBox_Node*)*head_ref;
    while (last->next != NULL) {
        last = (BoundingBox_Node*)last->next;
    }

    last->next = new;
}

void removeAtIndex(BoundingBox_Node** head, int index) {
    printf("removeAtIndex start \n");
    if (*head == NULL) {
        printf("List is empty\n");
        return;
    }

    BoundingBox_Node* temp = *head;

    // Special case: removing the head node
    if (index == 0) {
        *head = temp->next;
        if(temp){
            printf("removeAtIndex free 0\n");
            free(temp);
        }
        return;
    }

    // Traverse to the node before the one we want to remove
    BoundingBox_Node* prev = NULL;
    int count = 0;
    while (temp != NULL && temp->data.index != index) {
        prev = temp;
        temp = temp->next;
        count++;
    }

    // If index is out of bounds
    if (temp == NULL) {
        printf("Index out of bounds\n");
        return;
    }

    // Remove the node
    prev->next = temp->next;
    if(temp){
        printf("removeAtIndex free 1\n");
        free(temp);
    }
    printf("removeAtIndex end \n");
}

// Function to generate bounding boxes from CNN outputs
void generate_bounding_boxes(Layer * layer_imap, Layer *reg, int width, int height, float scale, float threshold, BoundingBox_Node **boundingbox, int *num_boxes) {
    Channel_Node *chan_node_1 = (Channel_Node *)reg->output_channels.channels;
    Channel_Node *chan_node_2 = (Channel_Node *)chan_node_1->next;
    Channel_Node *chan_node_3 = (Channel_Node *)chan_node_2->next;
    Channel_Node *chan_node_4 = (Channel_Node *)chan_node_3->next;

    Channel_Node *no_face_score = (Channel_Node *)layer_imap->output_channels.channels;
    Channel_Node *face_score    = (Channel_Node *)no_face_score->next;

    BoundingBox *bbox_ins = NULL;

    width = chan_node_1->data.width;
    height = chan_node_1->data.height;

    printf("width(%d) height(%d) \n", width, height);

    float *transposed_nimap = (float *)no_face_score->data.output_ptr;
    float *transposed_imap = (float *)face_score->data.output_ptr;
    float *transposed_dx1 = (float *)chan_node_1->data.output_ptr;
    float *transposed_dy1 = (float *)chan_node_2->data.output_ptr;
    float *transposed_dx2 = (float *)chan_node_3->data.output_ptr;
    float *transposed_dy2 = (float *)chan_node_4->data.output_ptr;

    int *temp_boxes = (int *)malloc(width * height * sizeof(int));
    int box_count = 0;
    
    for (int i = 0; i < width * height; ++i) {
        if (transposed_imap[i] >= threshold ) {
            temp_boxes[box_count++] = i;
        }
    }
    
    // printf("Detected Box Count %d \n", box_count);
    if (box_count == 0) {
        *num_boxes = 0;
    }

    (*boundingbox)       = NULL;
    // (*boundingbox)->next = NULL;
    
    // *boundingbox = (float *)malloc(box_count * sizeof(BoundingBox));
    *num_boxes = box_count;

    int idx = 0, x = 0, y = 0;
    float score = 0.0f, nscore = 0.0f;
    float dx1 = 0.0f, dy1 = 0.0f, dx2 = 0.0f, dy2 = 0.0f;
    float q1_x = 0.0f, q1_y = 0.0f, q2_x = 0.0f, q2_y = 0.0f;

    for (int i = 0; i < box_count; ++i) {
        idx = temp_boxes[i];
        y = idx / width;
        x = idx % width;

        score = transposed_imap[idx];
        nscore = transposed_nimap[idx];
        dx1 = transposed_dx1[idx];
        dy1 = transposed_dy1[idx];
        dx2 = transposed_dx2[idx];
        dy2 = transposed_dy2[idx];

        q1_x = roundf((STRIDE * x + 1) / scale);
        q1_y = roundf((STRIDE * y + 1) / scale);
        q2_x = roundf((STRIDE * x + CELLSIZE) / scale);
        q2_y = roundf((STRIDE * y + CELLSIZE) / scale);

        bbox_ins = BBOX_create(
            i,
            q1_x, q1_y,
            q2_x, q2_y,
            score, nscore,
            dx1, dy1,
            dx2, dy2
        );

        append_bbox(boundingbox, *bbox_ins);




        // (*boundingbox)[i].index =
        // (*boundingbox)[i].q1_x  = q1_x;
        // (*boundingbox)[i].q1_y  = q1_y;
        // (*boundingbox)[i].q2_x  = q2_x;
        // (*boundingbox)[i].q2_y  = q2_y;
        // (*boundingbox)[i].score = score;
        // (*boundingbox)[i].nscore = nscore;
        // (*boundingbox)[i].dx1   = dx1;
        // (*boundingbox)[i].dy1   = dy1;
        // (*boundingbox)[i].dx2   = dx2;
        // (*boundingbox)[i].dy2   = dy2;

        printf("I(%d) X(%d) Y(%d) score(%f) nscore(%f) q1_x(%f) q1_y(%f) q2_x(%f) q2_y(%f) dx1(%f) dy1(%f) dx2(%f) dy2(%f)\n",
            i, x, y, score, nscore, q1_x + dx1, q1_y + dy1, q2_x + dx2, q2_y + dy2, dx1, dy1, dx2, dy2
        );

    }

    free(temp_boxes);
}

// void threshold_scores(Layer *layer, float threshold, BoundingBox* boxes, int* num_boxes) {
//     int height = layer->output_channels.channels->data.height;
//     int width  = layer->output_channels.channels->data.width;
//     *num_boxes = 0;

//     Channel_Node *second = layer->output_channels.channels->next;

//     float *chan = (float*)second->data.output_ptr;

//     for (int y = 0; y < height; y++) {
//         for (int x = 0; x < width; x++) {
//             float face_score = chan[(y*height)+x]; 
//             if (face_score > threshold) {
//                 boxes[*num_boxes].x = x;
//                 boxes[*num_boxes].y = y;
//                 boxes[*num_boxes].score = face_score;
//                 (*num_boxes)++;
//             }
//         }
//     }
// }

// void apply_offsets(Layer *layer, BoundingBox* boxes, int num_boxes) {
//     Channel_Node *chan_node_1 = layer->output_channels.channels;
//     Channel_Node *chan_node_2 = chan_node_1->next;
//     Channel_Node *chan_node_3 = chan_node_2->next;
//     Channel_Node *chan_node_4 = chan_node_3->next;

//     int height = chan_node_1->data.height;
//     int width  = chan_node_1->data.width;

//     for (int i = 0; i < num_boxes; i++) {
//         int x = (int)boxes[i].x;
//         int y = (int)boxes[i].y;
//         float dx = *(float*)&chan_node_1->data.output_ptr[(y*height)+x];
//         float dy = *(float*)&chan_node_2->data.output_ptr[(y*height)+x];
//         float dw = *(float*)&chan_node_3->data.output_ptr[(y*height)+x];
//         float dh = *(float*)&chan_node_4->data.output_ptr[(y*height)+x];
//         printf("box %d -  (%d, %d) dx(%f) dy(%f) dw(%f) dh(%f) \n", i, x, y, dx, dy, dw, dh);

//         boxes[i].x = x - dx * width;
//         boxes[i].y = y - dy * height;
//         boxes[i].w = width + dw * width;
//         boxes[i].h = height + dh * height;
//     }
// }

float calculate_iou(BoundingBox box1, BoundingBox box2) {


    printf("calculate_iou start first(%d) second(%d) \n", box1.index, box2.index);
    float x1 = fmax(box1.q1_x, box2.q1_x);
    float y1 = fmax(box1.q1_y, box2.q1_y);
    float x2 = fmin(box1.q2_x, box2.q2_x);
    float y2 = fmin(box1.q2_y, box2.q2_y);
    printf("calculate_iou start 1 \n");
    float inter_area = fmax(0, x2 - x1) * fmax(0, y2 - y1);
    float box1_area = (box1.q2_x - box1.q1_x) * (box1.q2_y - box1.q1_y);
    float box2_area = (box2.q2_x - box2.q1_x) * (box2.q2_y - box2.q1_y);
    printf("calculate_iou start 2 \n");
    if ((inter_area == 0 || ((box1_area + box2_area - inter_area) == 0))){
        printf("calculate_iou 0 \n");
        return 0.0f;
    }

    printf("inter area %f : (%f, %f) - (%f, %f) \n", (inter_area / (box1_area + box2_area - inter_area)), 
        box1.q1_x, box1.q1_y, box2.q1_x, box2.q1_y);
    printf("calculate_iou end \n");
    return inter_area / (box1_area + box2_area - inter_area);
}

// #define NMS_THRESHOLD 0.5

void non_max_suppression(BoundingBox_Node* boxes, int *num_boxes) {
    BoundingBox_Node* upper = boxes;
    BoundingBox_Node* inner = boxes;
    // u8* keep = (u8*)malloc(*num_boxes * sizeof(u8));
    // for (int i = 0; i < *num_boxes; i++) {
    //     keep[i] = 1;
    // }

    // for (int i = 0; i < *num_boxes; i++) {
    //     if (!keep[i]) continue;
    //     for (int j = i + 1; j < *num_boxes; j++) {
    //         if (keep[j] && calculate_iou(boxes[i], boxes[j]) > NMS_THRESHOLD) {
    //             keep[j] = 0;
    //         }
    //     }
    // }

    // int k = 0;
    // for (int i = 0; i < *num_boxes; i++) {
    //     if (keep[i]) {
    //         boxes[k++] = boxes[i];
    //     }
    // }
    // *num_boxes = k;

    // free(keep);

    // check whether the channel loaded
    if(upper == NULL || inner == NULL){
        xil_printf("No output channel available \r\n");
        return;
    }

    float iou = 0.0f;

    while (upper != NULL){
        while(inner != NULL){
            if(!(upper->data.index == inner->data.index)){
                printf("non_max_suppression 0 \n");
                iou = calculate_iou(upper->data, inner->data);
                printf("non_max_suppression 1 iou(%f) thres(%f)\n", iou, NMS_THRESHOLD);
                if ( iou > (float)NMS_THRESHOLD) {
                    printf("Start removed nms index upper(%d) inner(%d) \n", upper->data.index, inner->data.index);
                    removeAtIndex(&upper, upper->data.index);
                    printf("End removed nms index upper(%d) inner(%d) \n", upper->data.index, inner->data.index);
                }
            }

            inner = inner->next;
        }
        // xil_printf(" before nms index %d \n", upper->data.index);
        upper = upper->next;
    }

    upper = boxes;
    int count = 0;
    int prev_index = 0;

    while (upper != NULL){
        prev_index = upper->data.index;
        upper->data.index = count;
        count++;
        upper = upper->next;

        //rerec(&upper->data);
        //adjust_box(&upper->data);
        // printf("R I(%d) score(%f) nscore(%f) q1_x(%f) q1_y(%f) q2_x(%f) q2_y(%f) dx1(%f) dy1(%f) dx2(%f) dy2(%f)\n",
        //     upper->data.index, upper->data.score, upper->data.nscore, upper->data.q1_x, upper->data.q1_y , 
        //     upper->data.q2_x, upper->data.q2_y, upper->data.dx1, upper->data.dy1, upper->data.dx2, upper->data.dy2
        // );
    }

    *num_boxes = count;

}

void rerec(BoundingBox* boxes) {
    float w = boxes->q2_x - boxes->q1_x;
    float h = boxes->q2_y - boxes->q1_y;

    if (w < h) {
        float offset = (h - w) * 0.5f;
        boxes->q1_x -= offset;
        boxes->q2_x += offset;
    } else {
        float offset = (w - h) * 0.5f;
        boxes->q1_y -= offset;
        boxes->q2_y += offset;
    }

    // Ensure the bounding box does not go out of bounds
    if (boxes->q1_x < 0) boxes->q1_x = 0;
    if (boxes->q1_y < 0) boxes->q1_y = 0;
    if (boxes->q2_x > 1) boxes->q2_x = 1; // Assuming normalized coordinates
    if (boxes->q2_y > 1) boxes->q2_y = 1;
}

void adjust_box(BoundingBox* boxes) {
    float regw = boxes->q2_x - boxes->q1_x;
    float regh = boxes->q2_y - boxes->q1_y;

    boxes->q1_x += boxes->dx1 * regw;
    boxes->q1_y += boxes->dy1 * regh;
    boxes->q2_x += boxes->dx2 * regw;
    boxes->q2_y += boxes->dy2 * regh;
}

void image_resize(float* input, float* output, u32 height, u32 width, float scale_factor){
    int in_width  = width;
    int in_height = height;

    int out_width  = round(in_width * scale_factor);
    int out_height = round(in_height * scale_factor);
    // printf("in_width(%d), in_height(%d), out_width(%d), out_height(%d) \n", in_width, in_height, out_width, out_height);

    for (int i = 0; i < (in_width * in_height); i++) {
        output[i] = 0.0f;
    }

    for (int y = 0; y < out_height; y++) {
        for (int x = 0; x < out_width; x++) {

            float gx = (float)(x * (in_width - 1)) / (out_width - 1);
            float gy = (float)(y * (in_height - 1)) / (out_height - 1);
            int gxi = (int)gx;
            int gyi = (int)gy;
            float fx = gx - gxi;
            float fy = gy - gyi;

            if (gxi >= in_width - 1) gxi = in_width - 2;
            if (gyi >= in_height - 1) gyi = in_height - 2;

            float top_left = input[gyi * in_width + gxi];
            float top_right = input[gyi * in_width + (gxi + 1)];
            float bottom_left = input[(gyi + 1) * in_width + gxi];
            float bottom_right = input[(gyi + 1) * in_width + (gxi + 1)];

            float top = top_left * (1 - fx) + top_right * fx;
            float bottom = bottom_left * (1 - fx) + bottom_right * fx;
            output[y * out_width + x] = top * (1 - fy) + bottom * fy;
        }
    }
}



