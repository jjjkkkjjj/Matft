#  About Function

## Calculation

- Binary operation

we should call `vDSP_v~~D(const double *__A, vDSP_Stride __IA, const double *__B, vDSP_Stride __IB, double *__C, vDSP_Stride __IC, vDSP_Length __N)`.

,however, we cannot call vDSP function simply. So we must properly convert` __A, __IA, __B,  __IB`.
So we calculate ` __A + offsetA, __IA, __B + offsetB,  __IB`. `A` means left mfarray and `B` means right one.

Example: We have mfarray such as (shape=[4,2,2], strides=[1,4,8])

	[[[ 1,  9],
   	[ 5, 13]],
                                      
  	[[ 2, 10],
   	[ 6, 14]],
                                      
  	[[ 3, 11],
   	[ 7, 15]],
                                      
  	[[ 4, 12],
	[ 8, 16]]]

and (shape=[4,2,2], strides=[0,0,1]) which is broadcasted

	[1,2]

Then, 

| offsetA | strideA | offsetB | strideB |
|:-------:|:-------:|:-------:|:-------:|
|    0    |    1    |    0    |    0    |
|    8    |    1    |    1    |    0    |
|    6    |    1    |    0    |    0    |
|    12   |    1    |    1    |    0    |

(shape=[2,2,4], strides=[8,4,1])

	[[[ 0,  1,  2,  3],
	[ 4,  5,  6,  7]],
                                     
	[[ 8,  9, 10, 11],
	[12, 13, 14, 15]]]

(shape=[2,2,4], strides=[0,0,1])

	[0,  1,  2,  3]

| offsetA | strideA | offsetB | strideB |
|:-------:|:-------:|:-------:|:-------:|
|    0    |    8    |    0    |    0    |
|    1    |    8    |    1    |    0    |
|    2    |    8    |    2    |    0    |
|    3    |    8    |    3    |    0    |
|    4    |    8    |    0    |    0    |
|    5    |    8    |    1    |    0    |
|    6    |    8    |    2    |    0    |
|    7    |    8    |    3    |    0    |

but above is bad efficiency. Below is better

| offsetA | strideA | offsetB | strideB |
|:-------:|:-------:|:-------:|:-------:|
|    0    |    1    |    0    |    1    |
|    4    |    1    |    0    |    1    |
|    8    |    1    |    0    |    1    |
|    12   |    1    |    0    |    1    |



## Conversion

- Transpose

