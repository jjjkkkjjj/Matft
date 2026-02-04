// clapack_helper.c
// Wrapper implementations that call CLAPACK functions with correct void signatures.

#include "include/clapack_helper.h"

// Declare the actual CLAPACK functions with correct void return type
// These are the real signatures from the f2c-generated code
extern void dgetrf_(
    clapack_int *m,
    clapack_int *n,
    double *a,
    clapack_int *lda,
    clapack_int *ipiv,
    clapack_int *info
);

extern void dgetri_(
    clapack_int *n,
    double *a,
    clapack_int *lda,
    clapack_int *ipiv,
    double *work,
    clapack_int *lwork,
    clapack_int *info
);

void clapack_dgetrf_wrapper(
    clapack_int *m,
    clapack_int *n,
    double *a,
    clapack_int *lda,
    clapack_int *ipiv,
    clapack_int *info
) {
    dgetrf_(m, n, a, lda, ipiv, info);
}

void clapack_dgetri_wrapper(
    clapack_int *n,
    double *a,
    clapack_int *lda,
    clapack_int *ipiv,
    double *work,
    clapack_int *lwork,
    clapack_int *info
) {
    dgetri_(n, a, lda, ipiv, work, lwork, info);
}
