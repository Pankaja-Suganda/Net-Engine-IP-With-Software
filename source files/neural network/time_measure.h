
#ifndef TIME_MEASURE_H
#define TIME_MEASURE_H

#include <xil_types.h>

#define TIME_MEASURE_SIGNAL_0 1
#define TIME_MEASURE_SIGNAL_1 2
#define TIME_MEASURE_SIGNAL_2 3
#define TIME_MEASURE_SIGNAL_3 4
#define TIME_MEASURE_SIGNAL_4 5


void measure_init();

void measure_start(u32 signal);

void measure_end(u32 signal);

#endif // !TIME_MEASURE_H