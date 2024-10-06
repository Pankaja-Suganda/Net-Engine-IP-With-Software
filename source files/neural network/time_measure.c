#include "time_measure.h"
#include "xparameters.h"
#include "xgpio_l.h"

#include "sleep.h"
#include <stdio.h>

#define  MEASURE_OUT           0x01
#define  MEASURE_SIGNAL_ADDR   XPAR_AXI_GPIO_0_BASEADDR
#define  MEASURE_SIGNAL_CHAN   1


void measure_init(){
    XGpio_WriteReg((MEASURE_SIGNAL_ADDR),
        ((MEASURE_SIGNAL_CHAN - 1) * XGPIO_CHAN_OFFSET) +
        XGPIO_TRI_OFFSET, 0);

}


void measure_start(u32 signal){
    u32 Data;
    Data = XGpio_ReadReg(MEASURE_SIGNAL_ADDR,
            ((MEASURE_SIGNAL_CHAN - 1) * XGPIO_CHAN_OFFSET) +
                XGPIO_DATA_OFFSET);

    XGpio_WriteReg((MEASURE_SIGNAL_ADDR),
            ((MEASURE_SIGNAL_CHAN - 1) * XGPIO_CHAN_OFFSET) +
            XGPIO_DATA_OFFSET, Data | (1 << (signal-1)));
}

void measure_end(u32 signal){
    u32 Data;
    Data = XGpio_ReadReg(MEASURE_SIGNAL_ADDR,
            ((MEASURE_SIGNAL_CHAN - 1) * XGPIO_CHAN_OFFSET) +
                XGPIO_DATA_OFFSET);

    XGpio_WriteReg((MEASURE_SIGNAL_ADDR),
				((MEASURE_SIGNAL_CHAN - 1) * XGPIO_CHAN_OFFSET) +
				XGPIO_DATA_OFFSET,  Data & ~(1 << (signal - 1)));
}