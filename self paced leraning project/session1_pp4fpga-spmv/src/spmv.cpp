#include "spmv.h"

void spmv(int rowPtr[NUM_ROWS+1], int columnIndex[NNZ],
		DTYPE values[NNZ], DTYPE y[SIZE], DTYPE x[SIZE])
{
L1: for (int i = 0; i < NUM_ROWS; i++) {
//#pragma HLS pipeline
//#pragma HLS unroll factor=2
		DTYPE y0 = 0;
	L2: for (int k = rowPtr[i]; k < rowPtr[i+1]; k++) {
#pragma HLS loop tripcount min=1 max=4 avg=2
//#pragma HLS pipeline II = 32
//#pragma HLS unroll factor=8
//#pragma HLS ARRAY_PARTITION variable=columnIndex cyclic factor=4 dim=1
//#pragma HLS ARRAY_PARTITION variable=values cyclic factor=4 dim=1
//#pragma HLS ARRAY_PARTITION variable=x cyclic factor=4 dim=1
//#pragma HLS ARRAY_PARTITION variable=columnIndex factor=9 block
//#pragma HLS ARRAY_PARTITION variable=values factor=9 block
//#pragma HLS ARRAY_PARTITION variable=x factor=4 block
			y0 += values[k] * x[columnIndex[k]];
		}
		y[i] = y0;
	}
}
