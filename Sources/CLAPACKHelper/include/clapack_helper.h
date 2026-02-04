// clapack_helper.h
// This header provides correct function signatures for CLAPACK functions.
// The CLAPACK header incorrectly declares these as returning int,
// but the actual f2c-generated implementation returns void.

#ifndef CLAPACK_HELPER_H
#define CLAPACK_HELPER_H

// On wasm32, long is 32-bit
typedef long clapack_int;

// Wrapper functions that call CLAPACK with correct void return type
void clapack_dgetrf_wrapper(
    clapack_int *m,
    clapack_int *n,
    double *a,
    clapack_int *lda,
    clapack_int *ipiv,
    clapack_int *info
);

void clapack_dgetri_wrapper(
    clapack_int *n,
    double *a,
    clapack_int *lda,
    clapack_int *ipiv,
    double *work,
    clapack_int *lwork,
    clapack_int *info
);

#endif // CLAPACK_HELPER_H
